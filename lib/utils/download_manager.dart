import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'package:bili_tracker/repo/saved_repository.dart';
import 'package:bili_tracker/di.dart';
import 'package:bili_tracker/models/saved.dart';
import 'package:bili_tracker/providers/download_tasks_provider.dart';
import 'package:bili_tracker/providers/settings_provider.dart';
import 'package:bili_tracker/utils/converter.dart';
import 'package:bili_tracker/utils/download_util.dart';
import 'package:bili_tracker/utils/logger.dart';
import 'package:bili_tracker/utils/platform.dart';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:bili_tracker/apis/bilibili_api.dart';
import 'package:synchronized/synchronized.dart';

import '../models/task.dart';
import 'net.dart';

typedef ProgressCallback = void Function(int received, int total);

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  static bool _isInitialized = false;
  static final lock = Lock();
  static final _globalLock = Lock();
  DownloadTasksProvider? _provider;
  SavedRepository? _savedRepository;
  final List<Task> _pendingTasks = [];
  final Set<int> _runningTasks = {};
  final Map<int, SendPort> _cancelPorts = {};
  final Map<int, Isolate> _activeIsolates = {};
  final Map<int, Completer<bool>> _pauseCompleters = {};
  final ReceivePort _receivePort = ReceivePort();

  DownloadManager._internal();

  static DownloadManager get instance {
    if (!_isInitialized) {
      throw Exception('DownloadManager must be initialized first');
    }
    return _instance;
  }

  static Future<void> initialize(
    DownloadTasksProvider provider,
    SavedRepository savedRepository,
  ) async {
    _instance._provider = provider;
    _instance._savedRepository = savedRepository;
    await _instance._initialize();
    _isInitialized = true;
  }

  static Future<bool> addDownloadTask(Task task) async {
    return await _globalLock.synchronized(() async {
      return await instance._addDownloadTask(task);
    });
  }

  static Future<bool> batchAddDownloadTasks(List<Task> tasks) async {
    return await _globalLock.synchronized(() async {
      return await instance._batchAddDownloadTasks(tasks);
    });
  }

  static Future<bool> pauseDownloadTask(int taskId) async {
    return await _globalLock.synchronized(() async {
      return await instance._pauseDownloadTask(taskId);
    });
  }

  static Future<bool> pauseAllDownloads() async {
    return await _globalLock.synchronized(() async {
      return await instance._pauseAllDownloads();
    });
  }

  static Future<bool> resumeDownloadTask(Task task) async {
    return await _globalLock.synchronized(() async {
      return await instance._resumeDownloadTask(task);
    });
  }

  static Future<void> dispose() {
    return instance._dispose();
  }

  Future<void> _initialize() async {
    _receivePort.listen((message) {
      if (message is _TaskCompleteMessage) {
        _handleTaskCompletion(message.taskId);
      }
    });
  }

  static void _downloadInIsolate(_IsolateStartMessage message) async {
    final cancelToken = CancelToken();
    final cancelReceivePort = ReceivePort();
    message.cancelPort.send(cancelReceivePort.sendPort);
    cancelReceivePort.listen((msg) {
      if (msg == 'cancel') {
        cancelToken.cancel('Cancelled by user');
      }
    });
    final rootIsolateToken = message.rootIsolateToken;
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken!);
    final sendPort = message.sendPort;
    final taskId = message.taskId;
    final managerPort = message.managerPort;
    Saved? saved;
    File? audioFile;
    File? videoFile;
    File? coverFile;

    try {
      sendPort.send(_IsolateTaskStatusMessage(status: TaskStatus.running));
      sendPort.send(_IsolatePhaseMessage(phase: TaskPhase.acquiringInfo));
      final videoInfoJson = await BilibiliApi.getVideoInfoWithAVId(message.aid);
      final titleUnsafe = videoInfoJson.data.title;
      final title = titleUnsafe.replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ');
      var cid = videoInfoJson.data.cid;
      var cover = videoInfoJson.data.pic;
      if (message.type == 'single') {
        cid = message.cid;
      }
      saved = Saved(
        cid: cid,
        aid: message.aid,
        createTime: DateTime.now().toString(),
        id: 0,
      );
      saved.status = Status.enqueued;
      sendPort.send(_IsolatePhaseMessage(phase: TaskPhase.acquiringStream));
      final videoStreamResp = await BilibiliApi.getVideoStreamUrl(message.aid, cid);
      final dash = videoStreamResp.data.dash;
      if (dash == null) throw Exception('Dash 数据为空');
      if (kDebugMode) {
        // print("acceptDescription: ${videoStreamResp.data.acceptDescription}");
        // print(
        //   "dash.video[0].id: ${BilibiliApi.videoQualityMap[dash.video[0].id]}",
        // );
      }
      final videoUrl = dash.video[0].baseUrl;
      final audioUrl = dash.audio[0].baseUrl;
      final videoQuality = Network.videoQualityMap[dash.video[0].id];
      final audioQuality = Network.audioQualityMap[dash.audio[0].id];

      sendPort.send(
        _IsolateQualityMessage(
          videoQuality: videoQuality ?? '未知',
          audioQuality: audioQuality ?? '未知',
        ),
      );

      final tempDir = await getTempDirectory();
      final downloadDir = await getDownloadDirectory();
      final coverDir = await getCoverDirectory();
      videoFile = File(
        p.join(tempDir.path, '$title-${message.aid}-$cid-video.mp4'),
      );
      audioFile = File(
        p.join(tempDir.path, '$title-${message.aid}-$cid-audio.m4a'),
      );
      final outputFile = File(
        p.join(downloadDir.path, '$title-${message.aid}-$cid.mp4'),
      );
      coverFile = File(p.join(coverDir.path, '$title-${message.aid}-$cid.png'));
      if (coverFile.existsSync()) {
        coverFile.deleteSync();
      }
      if (videoFile.existsSync()) {
        videoFile.deleteSync();
      }
      if (audioFile.existsSync()) {
        audioFile.deleteSync();
      }

      await DownloadUtil.downloadFile(
        url: cover,
        file: coverFile,
        onProgress: (int received, int total) {},
        cancelToken: cancelToken,
      );

      sendPort.send(_IsolatePhaseMessage(phase: TaskPhase.downloadingAudio));
      await _downloadWithProgress(
        url: audioUrl,
        file: audioFile,
        sendPort: sendPort,
        cancelToken: cancelToken,
        phaseLabel: "Audio",
      );
      sendPort.send(_IsolatePhaseMessage(phase: TaskPhase.downloadingVideo));
      await _downloadWithProgress(
        url: videoUrl,
        file: videoFile,
        sendPort: sendPort,
        cancelToken: cancelToken,
        phaseLabel: "Video",
      );
      sendPort.send(_IsolatePhaseMessage(phase: TaskPhase.merging));
      sendPort.send(
        _IsolateMergeMessage(
          videoPath: videoFile.path,
          audioPath: audioFile.path,
          outputPath: outputFile.path,
          totalDurationMs: dash.duration,
          aid: message.aid,
          cid: cid,
        ),
      );
      sendPort.send(_IsolateCompleteMessage());
      managerPort.send(_TaskCompleteMessage(taskId: taskId));
    } on CancelException {
      for (final file in [coverFile, videoFile, audioFile]) {
        if (file != null) {
          if (file.existsSync()) await file.delete();
        }
      }
      managerPort.send(_TaskCompleteMessage(taskId: taskId));
    } catch (e) {
      for (final file in [coverFile, videoFile, audioFile]) {
        if (file != null) {
          if (file.existsSync()) await file.delete();
        }
      }
      if (e.toString() == 'Exception: 用户取消下载') {
        managerPort.send(_TaskCompleteMessage(taskId: taskId));
        return;
      }
      final logger = await MyLogger.create();
      logger.e(e.toString());
      if (kDebugMode) print(e);
      if (saved != null) {}
      sendPort.send(_IsolateTaskStatusMessage(status: TaskStatus.failed));
      sendPort.send(_IsolateErrorMessage(error: e));
      managerPort.send(_TaskCompleteMessage(taskId: taskId));
    }
  }

  static Future<void> _downloadWithProgress({
    required String url,
    required File file,
    required SendPort sendPort,
    required CancelToken cancelToken,
    required String phaseLabel,
  }) async {
    final speedSamples = <int>[];
    const maxSamples = 6;
    int lastReceived = 0;
    int lastTime = DateTime.now().millisecondsSinceEpoch;

    await DownloadUtil.downloadFile(
      url: url,
      file: file,
      cancelToken: cancelToken,
      onProgress: (received, total) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final speed =
            ((received - lastReceived) * 8 * 1000 ~/ (now - lastTime));
        lastTime = now;
        lastReceived = received;

        speedSamples.add(speed);
        if (speedSamples.length > maxSamples) speedSamples.removeAt(0);
        final avgSpeed =
            speedSamples.reduce((a, b) => a + b) ~/ speedSamples.length;

        sendPort.send(
          _IsolateProgressMessage(
            progress: (received * 100 ~/ total),
            total: DataUnitConverter.formatBits(total * 8),
            current: DataUnitConverter.formatBits(received * 8),
            speed: '${DataUnitConverter.formatBits(avgSpeed)}/s',
          ),
        );
      },
    );
  }

  Future<bool> _addDownloadTask(Task task) async {
    await lock.synchronized(() async {
      if (_pendingTasks.any((element) => element.id == task.id)) {
        return false;
      }
      _pendingTasks.add(task);
    });
    await _provider?.updateTaskStatusById(task.id, TaskStatus.enqueued);
    _scheduleTasks();
    return true;
  }

  Future<bool> _batchAddDownloadTasks(List<Task> tasks) async {
    await lock.synchronized(() async {
      _pendingTasks.addAll(tasks);
    });
    await _provider?.batchUpdateTaskStatusByIds(
      tasks.map((e) => e.id).toList(),
      TaskStatus.enqueued,
    );
    _scheduleTasks();
    return true;
  }

  Future<bool> _pauseDownloadTask(int taskId) async {
    await _provider?.updateTaskStatusById(taskId, TaskStatus.paused);

    await lock.synchronized(() async {
      _pendingTasks.removeWhere((task) => task.id == taskId);
    });

    final cancelPort = _cancelPorts[taskId];
    if (cancelPort != null) {
      final completer = Completer<bool>();
      _pauseCompleters[taskId] = completer;

      cancelPort.send('cancel');
      _cancelPorts.remove(taskId);
      _activeIsolates.remove(taskId);

      return completer.future; // ⬅️ 等待任务完成
    } else {
      // 没有 cancelPort，说明任务可能还没启动或已完成，立即返回
      return true;
    }
  }

  Future<bool> _pauseAllDownloads() async {
    List allTasks = [];
    allTasks.addAll(_pendingTasks);
    for (final taskId in _activeIsolates.keys) {
      await _pauseDownloadTask(taskId);
    }
    return true;
  }

  Future<bool> _resumeDownloadTask(Task task) async {
    await lock.synchronized(() async {
      _pendingTasks.add(task);
    });
    await _provider?.updateTaskStatusById(task.id, TaskStatus.enqueued);
    _scheduleTasks();
    return true;
  }

  void _scheduleTasks() async {
    final maxConcurrency =
        getIt<SettingsProvider>().settings.maxTaskConcurrency;
    await lock.synchronized(() async {
      while (_activeIsolates.length < maxConcurrency &&
          _pendingTasks.isNotEmpty) {
        final task = _pendingTasks.removeAt(0);
        await _startTaskInIsolate(task); // 须等待，不然全部启动了
      }
    });
  }

  Future<void> _startTaskInIsolate(Task task) async {
    _runningTasks.add(task.id);
    final logger = await MyLogger.create();
    final completer = Completer<void>();
    final taskId = task.id;
    final rootIsolateToken = RootIsolateToken.instance;
    bool isProcessing = false;
    final messageQueue = Queue();
    final port = ReceivePort();
    final cancelPort = ReceivePort();

    final saved = Saved(
      id: 0,
      createTime: DateTime.now().toString(),
      aid: task.aid,
      cid: task.cid ?? 0,
    );
    saved.status = Status.enqueued;

    await _savedRepository?.insertSaved(saved);

    final isolate = await Isolate.spawn(
      _downloadInIsolate,
      _IsolateStartMessage(
        cid: task.cid ?? 0,
        aid: task.aid,
        sendPort: port.sendPort,
        taskId: taskId,
        managerPort: _receivePort.sendPort,
        cancelPort: cancelPort.sendPort,
        rootIsolateToken: rootIsolateToken,
        type: task.type == TaskType.downloadSinglePage ? 'single' : 'multi',
      ),
    );

    cancelPort.listen((data) {
      _cancelPorts[taskId] = data;
    });

    _activeIsolates[taskId] = isolate;

    Future<void> processMessage(dynamic message) async {
      if (message is _IsolateProgressMessage) {
        await _provider?.updateProgressById(
          taskId,
          message.progress,
          message.speed,
          message.total,
          message.current,
        );
      } else if (message is _IsolatePhaseMessage) {
        await _provider?.updateTaskPhaseById(taskId, message.phase);
      } else if (message is _IsolateTaskStatusMessage) {
        await _provider?.updateTaskStatusById(taskId, message.status);
      } else if (message is _IsolateCompleteMessage) {
        port.close();
        completer.complete();
      } else if (message is _IsolateQualityMessage) {
        await _provider?.updateTaskQualityById(
          taskId,
          message.videoQuality,
          message.audioQuality,
        );
      } else if (message is _IsolateErrorMessage) {
        port.close();
        await _provider?.updateTaskMessageById(
          taskId,
          message.error.toString(),
        );
        completer.completeError(message.error);
      } else if (message is _IsolateMergeMessage) {
        final videoFile = message.videoPath;
        final audioFile = message.audioPath;
        final outputFile = message.outputPath;
        final totalDurationMs = message.totalDurationMs;
        final ffmpegCommand =
            '-i "$videoFile" -i "$audioFile" -c copy "$outputFile"';
        if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
          await FFmpegKit.executeAsync(
            ffmpegCommand,
            (FFmpegSession completedSession) async {
              if (kDebugMode) {
                print('FFmpeg处理完成');
              }
              await _provider?.updateTaskStatusById(
                taskId,
                TaskStatus.complete,
              );
              await _provider?.updateTaskPhaseById(taskId, TaskPhase.completed);

              final saved = Saved(
                id: 0,
                createTime: DateTime.now().toString(),
                aid: message.aid,
                cid: message.cid,
              );
              saved.status = Status.completed;
              await _savedRepository?.insertSaved(
                saved
              );
              try {
                await File(videoFile).delete();
                await File(audioFile).delete();
              } catch (e) {
                logger.e('⚠️ 清理失败: $e');
              }
            },
            (log) {},
            (Statistics stats) {
              if (totalDurationMs > 0) {
                final progress =
                    (stats.getTime() * 10 / (totalDurationMs * 100))
                        .clamp(0, 100)
                        .toInt();
                _provider?.updateProgressById(taskId, progress, '0', '0', '0');
              }
            },
          );
        } else if (Platform.isWindows ||
            Platform.isLinux ||
            Platform.isFuchsia) {
          try {
            ProcessResult result = await Process.run("ffmpeg", [
              '-i',
              videoFile,
              "-i",
              audioFile,
              "-c",
              "copy",
              outputFile,
            ]);
            if (result.exitCode == 0) {
              _provider?.updateProgressById(taskId, 100, '0', '0', '0');
              await _provider?.updateTaskStatusById(
                taskId,
                TaskStatus.complete,
              );
              await _provider?.updateTaskPhaseById(taskId, TaskPhase.completed);
              final saved = Saved(
                id: 0,
                createTime: DateTime.now().toString(),
                aid: message.aid,
                cid: message.cid,
              );
              saved.status = Status.completed;
              await _savedRepository?.insertSaved(
                  saved
              );
            }
          } catch (e) {
            await _provider?.updateTaskMessageById(taskId, e.toString());
            logger.e('⚠️ FFmpeg处理失败: $e');
          }
          try {
            await File(videoFile).delete();
            await File(audioFile).delete();
          } catch (e) {
            logger.e('⚠️ 清理失败: $e');
          }
        }
      }
    }

    port.listen((message) async {
      messageQueue.add(message);
      if (isProcessing) return; // 如果正在处理，暂不处理新消息

      isProcessing = true;
      while (messageQueue.isNotEmpty) {
        final nextMessage = messageQueue.removeFirst();
        await processMessage(nextMessage); // 异步处理，但等待完成
      }
      isProcessing = false;
    });
    return;
  }

  void _handleTaskCompletion(int taskId) {
    _activeIsolates.remove(taskId);
    _cancelPorts.remove(taskId);
    _runningTasks.remove(taskId);

    if (_pauseCompleters.containsKey(taskId)) {
      _pauseCompleters.remove(taskId)?.complete(true);
    }

    _scheduleTasks();
  }

  Future<void> _dispose() async {
    _receivePort.close();
    for (final isolate in _activeIsolates.values) {
      isolate.kill();
    }
    _activeIsolates.clear();
    _isInitialized = false;
  }
}

class CancelException implements Exception {}

class _IsolateStartMessage {
  final SendPort sendPort;
  final int taskId;
  final int aid;
  final int cid;
  final String type;
  final SendPort managerPort;
  final SendPort cancelPort;
  final RootIsolateToken? rootIsolateToken;

  _IsolateStartMessage({
    required this.sendPort,
    required this.taskId,
    required this.managerPort,
    required this.cancelPort,
    this.rootIsolateToken,
    required this.aid,
    required this.cid,
    required this.type,
  });
}

class _IsolateProgressMessage {
  final int progress;
  final String total;
  final String current;
  final String speed;

  _IsolateProgressMessage({
    required this.progress,
    required this.total,
    required this.current,
    required this.speed,
  });
}

class _IsolateQualityMessage {
  final String videoQuality;
  final String audioQuality;

  _IsolateQualityMessage({
    required this.videoQuality,
    required this.audioQuality,
  });
}

class _IsolatePhaseMessage {
  final TaskPhase phase;

  _IsolatePhaseMessage({required this.phase});
}

class _IsolateTaskStatusMessage {
  final TaskStatus status;

  _IsolateTaskStatusMessage({required this.status});
}

class _IsolateCompleteMessage {}

class _IsolateErrorMessage {
  final dynamic error;

  _IsolateErrorMessage({required this.error});
}

class _IsolateMergeMessage {
  final String videoPath;
  final String audioPath;
  final String outputPath;
  final int aid;
  final int cid;
  final int totalDurationMs;

  _IsolateMergeMessage({
    required this.videoPath,
    required this.audioPath,
    required this.outputPath,
    required this.totalDurationMs,
    required this.aid,
    required this.cid,
  });
}

class _TaskCompleteMessage {
  final int taskId;

  _TaskCompleteMessage({required this.taskId});
}
