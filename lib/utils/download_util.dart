import 'dart:io';
import 'dart:async';
import 'package:bili_tracker/utils/net.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadUtil {
  static Dio _createDioWithThrottle(int? maxBytesPerSecond) {
    final dio = Dio(
      BaseOptions(
        receiveTimeout: const Duration(minutes: 30),
        sendTimeout: const Duration(minutes: 30),
      ),
    );

    if (maxBytesPerSecond != null) {
      dio.interceptors.add(ThrottleInterceptor(maxBytesPerSecond));
    }

    return dio;
  }

  static Future<void> downloadFile({
    required String url,
    required File file,
    required void Function(int received, int total) onProgress,
    required CancelToken cancelToken,
    bool enableResume = true,
    int? maxSpeed,
    Duration progressInterval = const Duration(
      milliseconds: 1000,
    ), // 新增参数：进度回调间隔
  }) async {
    final dio = _createDioWithThrottle(maxSpeed);

    // 创建节流后的进度回调
    final throttledOnProgress = _throttle(onProgress, progressInterval);

    try {
      // 断点续传逻辑
      int startByte = 0;
      if (enableResume && await file.exists()) {
        startByte = file.lengthSync();
      }

      Map<String, String> headers =
          startByte > 0 ? {'Range': 'bytes=$startByte-'} : {};
      headers.addAll(await Network.getHeaders());
      // var total;
      final response = await dio.download(
        url,
        file.path,
        onReceiveProgress: (received, total) {
          // 调用节流后的回调
          total = total;
          throttledOnProgress(received, total);
        },
        cancelToken: cancelToken,
        options: Options(
          headers: headers,
          extra: {'throttle': maxSpeed != null}, // 启用限速
        ),
        deleteOnError: false,
      );

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: '下载失败: HTTP ${response.statusCode}',
        );
      }
      onProgress(1, 1);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('下载异常: $e');
    }
  }

  /// 获取下载目录
  static Future<Directory> getDownloadDirectory() async {
    final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 处理Dio特定错误
  static Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('连接超时');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('接收数据超时');
    } else if (e.type == DioExceptionType.cancel) {
      return Exception('用户取消下载');
    } else if (e.response?.statusCode == 404) {
      return Exception('文件不存在');
    } else if (e.response?.statusCode == 403) {
      return Exception('无权限访问');
    } else {
      return Exception('下载失败: ${e.message}');
    }
  }

  /// 函数节流工具方法
  static Function _throttle(
    Function(int received, int total) func,
    Duration duration,
  ) {
    Timer? timer;
    int? lastReceived;
    int? lastTotal;

    return (int received, int total) {
      // 保存最新进度
      lastReceived = received;
      lastTotal = total;

      // 如果定时器不存在，启动一个新的
      timer ??= Timer(duration, () {
        // 定时器结束后，检查是否有新的进度需要发送
        if (lastReceived != null && lastTotal != null) {
          func(lastReceived!, lastTotal!);
        }
        timer = null;
      });
    };
  }
}

class ThrottleInterceptor extends Interceptor {
  final int maxBytesPerSecond; // 每秒最大字节数
  final _bucket = <int>[];
  DateTime? _lastUpdateTime;
  int _remainingBytes = 0;

  ThrottleInterceptor(this.maxBytesPerSecond);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.extra['throttle'] == false) {
      return handler.next(response);
    }

    final data = response.data;
    if (data is! List<int>) {
      return handler.next(response);
    }

    _bucket.addAll(data);
    response.data = _createThrottledStream();
    handler.next(response);
  }

  Stream<List<int>> _createThrottledStream() async* {
    while (_bucket.isNotEmpty) {
      final now = DateTime.now();
      final elapsed =
          _lastUpdateTime != null
              ? now.difference(_lastUpdateTime!).inMilliseconds / 1000
              : 0;

      _remainingBytes += (elapsed * maxBytesPerSecond).toInt();
      _lastUpdateTime = now;

      if (_remainingBytes > 0) {
        final chunkSize = _remainingBytes.clamp(0, 1024 * 8); // 每次最多8KB
        final chunk = _bucket.sublist(0, chunkSize.clamp(0, _bucket.length));
        _bucket.removeRange(0, chunk.length);
        _remainingBytes -= chunk.length;

        yield chunk;
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
