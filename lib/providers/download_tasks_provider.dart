import 'dart:collection';

import 'package:bili_tracker/models/task.dart';
import 'package:bili_tracker/utils/download_manager.dart';
import 'package:flutter/material.dart';

import 'package:bili_tracker/repo/task_repository.dart';

class DownloadTasksProvider with ChangeNotifier {
  final TaskRepository taskRepository;

  DownloadTasksProvider(this.taskRepository);

  final LinkedHashMap<int, Task> _allTasks = LinkedHashMap();
  final LinkedHashMap<int, Task> _runningTasks = LinkedHashMap();
  final LinkedHashMap<int, Task> _completedTasks = LinkedHashMap();
  final LinkedHashMap<int, Task> _failedTasks = LinkedHashMap();
  final LinkedHashMap<int, Task> _pausedTasks = LinkedHashMap();
  final LinkedHashMap<int, Task> _pendingTasks = LinkedHashMap();

  Task? getTask(int taskId) => _allTasks[taskId];

  List<Task> get allTasks => _allTasks.values.toList();

  List<Task> get runningTasks => _runningTasks.values.toList();

  List<Task> get completedTasks => _completedTasks.values.toList().reversed.toList();

  List<Task> get failedTasks => _failedTasks.values.toList();

  List<Task> get pausedTasks => _pausedTasks.values.toList();

  List<Task> get pendingTasks => _pendingTasks.values.toList();

  /// 启动APP时调用
  Future<void> initializeTasks() async {
    taskRepository.resetRunningTasks();
    List<Task> allTasks = await taskRepository.findAllTasks();
    for (Task task in allTasks) {
      _allTasks[task.id] = task;
      switch (task.status) {
        case TaskStatus.running:
          _runningTasks[task.id] = task;
          break;
        case TaskStatus.complete:
          _completedTasks[task.id] = task;
          break;
        case TaskStatus.failed:
          _failedTasks[task.id] = task;
          break;
        case TaskStatus.paused:
          _pausedTasks[task.id] = task;
          break;
        case TaskStatus.enqueued:
          _pendingTasks[task.id] = task;
          break;
        case null:
          // TODO: Handle this case.
          throw UnimplementedError();
        case TaskStatus.unknown:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    }
  }

  Future<void> addTask(Task task) async {
    task.status = TaskStatus.paused;
    taskRepository.insertTask(task);
    _allTasks[task.id] = task;
    _pausedTasks[task.id] = task;
    await DownloadManager.addDownloadTask(task);
    notifyListeners();
  }

  Future<void> batchAddTasks(List<Task> tasks) async {
    for (var task in tasks) {
      task.status = TaskStatus.paused;
    }
    taskRepository.batchInsertTask(tasks);
    for (int i = 0; i < tasks.length; i++) {
      _allTasks[tasks[i].id] = tasks[i];
      _pausedTasks[tasks[i].id] = tasks[i];
    }
    await DownloadManager.batchAddDownloadTasks(tasks);
    notifyListeners();
  }

  Future<void> updateTaskMessageById(int taskId, String message) async {
    taskRepository.updateTaskMessageById(taskId, message);
    _allTasks[taskId]?.message = message;
    notifyListeners();
  }

  Future<void> cancelTask(int taskId) async {
    Task? task = _allTasks[taskId];
    if (task == null) {
      throw "任务不存在";
    }
    if (task.status == TaskStatus.running ||
        task.status == TaskStatus.enqueued) {
      await DownloadManager.pauseDownloadTask(taskId);
    } // 其他状态说明不在下载器管理中

    taskRepository.deleteTaskById(taskId);
    _runningTasks.remove(taskId);
    _completedTasks.remove(taskId);
    _failedTasks.remove(taskId);
    _pausedTasks.remove(taskId);
    _pendingTasks.remove(taskId);
    _allTasks.remove(taskId);
    notifyListeners();
  }

  Future<void> pauseTask(int taskId) async {
    bool isPaused = await DownloadManager.pauseDownloadTask(taskId);
    if (!isPaused) return;
    taskRepository.updateTaskStatusById(taskId, TaskStatus.paused);
    _runningTasks.remove(taskId);
    _allTasks[taskId]?.status = TaskStatus.paused;
    _pausedTasks[taskId] = _allTasks[taskId]!;
    notifyListeners();
  }

  Future<void> resumeTask(int taskId) async {
    Task? task = _allTasks[taskId];
    if (task == null) {
      throw "任务不存在";
    }
    await DownloadManager.resumeDownloadTask(task);
    notifyListeners();
  }

  Future<void> batchResumeTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    await DownloadManager.batchAddDownloadTasks(tasks);
    notifyListeners();
  }

  Future<void> updateTaskQualityById(
    int taskId,
    String videoQuality,
    String audioQuality,
  ) async {
    Task? task = _allTasks[taskId];
    if (task == null) {
      throw "任务不存在";
    }
    task.videoQuality = videoQuality;
    task.audioQuality = audioQuality;
    taskRepository.updateTaskQualityById(taskId, videoQuality, audioQuality);
    notifyListeners();
  }

  Future<void> updateTaskExceptStatus(Task task) async {
    taskRepository.updateTask(task);
    _allTasks[task.id] = task;
    if (task.status == TaskStatus.running) {
      _runningTasks.remove(task.id);
      _runningTasks[task.id] = task;
    }
    notifyListeners();
  }

  Future<void> updateTaskPhaseById(int taskId, TaskPhase phase) async {
    taskRepository.updateTaskPhaseById(taskId, phase);
    _allTasks[taskId]?.phase = phase;
    notifyListeners();
  }

  Future<void> clearCompletedTasks() async {
    // 先从内存找到已完成的，仅清除这几个
    List<int> ids = _completedTasks.keys.toList();
    if (ids.isEmpty) return;
    taskRepository.deleteTasksByIds(ids);
    for (var id in ids) {
      _allTasks.remove(id);
      _completedTasks.remove(id);
    }
    notifyListeners();
  }

  Future<void> continueAllTasks() async {
    if (_pausedTasks.isEmpty) return;
    await batchResumeTasks(_pausedTasks.values.toList());
  }

  Future<void> retryAllFailedTasks() async {
    if (_failedTasks.isEmpty) return;
    await batchResumeTasks(_failedTasks.values.toList());
  }

  Future<void> batchUpdateTaskStatusByIds(
    List<int> ids,
    TaskStatus status,
  ) async {
    taskRepository.updateTaskStatusByIds(ids, status);
    for (var id in ids) {
      _allTasks[id]?.status = status;
      _runningTasks.remove(id);
      _completedTasks.remove(id);
      _failedTasks.remove(id);
      _pausedTasks.remove(id);
      _pendingTasks.remove(id);
      if (status == TaskStatus.running) {
        _runningTasks[id] = _allTasks[id]!;
      } else if (status == TaskStatus.complete) {
        _completedTasks[id] = _allTasks[id]!;
      } else if (status == TaskStatus.failed) {
        _failedTasks[id] = _allTasks[id]!;
      } else if (status == TaskStatus.paused) {
        _pausedTasks[id] = _allTasks[id]!;
      } else if (status == TaskStatus.enqueued) {
        _pendingTasks[id] = _allTasks[id]!;
      }
    }
    notifyListeners();
  }

  Future<void> updateProgressById(
    int taskId,
    int progress,
    String speed,
    String total,
    String current,
  ) async {
    taskRepository.updateTaskProgressById(taskId, progress);
    _allTasks[taskId]?.progress = progress;
    _allTasks[taskId]?.speed = speed;
    _allTasks[taskId]?.total = total;
    _allTasks[taskId]?.current = current;
    notifyListeners();
  }

  // 仅仅做一个状态上的更新
  Future<void> updateTaskStatusById(int taskId, TaskStatus status) async {
    Task? task = _allTasks[taskId];
    if (task == null) {
      throw "任务不存在";
    }
    if (task.status == status) {
      return;
    }
    taskRepository.updateTaskStatusById(taskId, status);
    if (task.status == TaskStatus.running) {
      _runningTasks.remove(taskId);
    } else if (task.status == TaskStatus.complete) {
      _completedTasks.remove(taskId);
    } else if (task.status == TaskStatus.failed) {
      _failedTasks.remove(taskId);
    } else if (task.status == TaskStatus.paused) {
      _pausedTasks.remove(taskId);
    } else if (task.status == TaskStatus.enqueued) {
      _pendingTasks.remove(taskId);
    }
    if (status == TaskStatus.running) {
      _runningTasks[taskId] = task;
    } else if (status == TaskStatus.complete) {
      _completedTasks[taskId] = task;
    } else if (status == TaskStatus.failed) {
      _failedTasks[taskId] = task;
    } else if (status == TaskStatus.paused) {
      _pausedTasks[taskId] = task;
    } else if (status == TaskStatus.enqueued) {
      _pendingTasks[taskId] = task;
    }
    task.status = status;
    notifyListeners();
  }
}
