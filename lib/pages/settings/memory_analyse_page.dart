import 'package:flutter/material.dart';
import 'dart:io'; // 用于文件系统操作，如Directory, File, FileSystemEntity
import 'dart:math' as math;

import '../../utils/platform.dart'; // 导入 math 库以使用 log 函数

extension on num {
  double log() => _log(toDouble());
  double _log(double x) => x == 0 ? double.negativeInfinity : math.log(x);
}

class MemoryAnalysePage extends StatefulWidget {
  const MemoryAnalysePage({super.key});

  @override
  State<MemoryAnalysePage> createState() => _MemoryAnalysePageState();
}

class _MemoryAnalysePageState extends State<MemoryAnalysePage> {
  bool _isLoading = true; // 标记是否正在加载磁盘占用数据
  Map<String, int> _folderSizes = {}; // 存储文件夹名称及其对应的字节大小
  String? _errorMessage; // 存储错误信息，如果分析过程中发生错误

  @override
  void initState() {
    super.initState();
    _analyzeDiskUsage(); // 页面初始化时开始分析磁盘占用
  }

  /// 辅助函数：将字节数格式化为人类可读的字符串 (例如：1.23 MB)
  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B"; // 如果字节数为0或负数，返回 "0 B"
    const suffixes = ["B", "KB", "MB", "GB", "TB"]; // 存储单位后缀
    // 计算合适的单位索引
    int i = (bytes > 0 ? (bytes.toDouble().log() / 1024.0.log()).floor() : 0);
    // 确保索引不超出范围
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }
    // 格式化并返回字符串
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// 递归函数：计算指定目录的总大小
  /// 遍历目录中的所有文件和子目录，并累加文件大小
  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0; // 初始化总大小
    try {
      if (!await dir.exists()) {
        return 0; // 如果目录不存在，返回0
      }
      // 列出目录中所有文件和子目录（递归，不跟随符号链接）
      final List<FileSystemEntity> entities = dir.listSync(recursive: true, followLinks: false);
      for (FileSystemEntity entity in entities) {
        if (entity is File) {
          // 如果是文件
          try {
            totalSize += await entity.length(); // 累加文件大小
          } catch (e) {
            // 打印错误信息，但继续处理其他文件
            debugPrint('Error getting file length for ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      // 打印错误信息，并返回0，表示无法访问该目录
      debugPrint('Error accessing directory ${dir.path}: $e');
      return 0;
    }
    return totalSize; // 返回计算出的总大小
  }

  /// 执行磁盘占用分析的主要逻辑
  Future<void> _analyzeDiskUsage() async {
    setState(() {
      _isLoading = true; // 设置加载状态为 true
      _errorMessage = null; // 清除之前的错误信息
    });

    Map<String, int> sizes = {}; // 用于存储各目录大小的临时 Map
    try {
      // 首先请求必要的权限，特别是存储权限 (对于 Android 13+，视频和音频权限也间接涵盖了存储访问)
      // await requestVideoPermission();

      final cacheDir = await getCachePath();
      sizes['缓存目录'] = await _calculateDirectorySize(cacheDir);

      final databaseDir = await getDatabaseDirectory();
      sizes['数据库目录'] = await _calculateDirectorySize(databaseDir);

      final downloadDir = await getDownloadDirectory();
      sizes['下载目录'] = await _calculateDirectorySize(downloadDir);

      final coverDir = await getCoverDirectory();
      sizes['封面目录'] = await _calculateDirectorySize(coverDir);

      final logsDir = await getLogsDirectory();
      sizes['日志目录'] = await _calculateDirectorySize(logsDir);

      final tempDir = await getTempDirectory();
      sizes['临时目录'] = await _calculateDirectorySize(tempDir);

      // 计算总占用空间
      int totalAppSize = 0;
      for (var size in sizes.values) {
        totalAppSize += size;
      }
      sizes['总占用空间'] = totalAppSize; // 将总占用空间添加到结果中

    } catch (e) {
      // 捕获分析过程中可能发生的任何错误
      _errorMessage = '无法获取磁盘占用信息: $e';
      debugPrint('Error during disk analysis: $e');
    } finally {
      setState(() {
        _folderSizes = sizes; // 更新文件夹大小数据
        _isLoading = false; // 设置加载状态为 false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前主题的颜色方案，以便应用 Material 3 风格
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('磁盘占用分析'), // 应用栏标题
      ),
      body: Container(
        child: _isLoading
            ? Center(
          // 如果正在加载，显示加载指示器
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary), // 圆形加载指示器
              const SizedBox(height: 16),
              Text('正在分析磁盘占用...',
                  style: Theme.of(context).textTheme.bodyLarge), // 加载提示文本
            ],
          ),
        )
            : _errorMessage != null
            ? Center(
          // 如果有错误信息，显示错误提示
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: colorScheme.error), // 错误图标
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: colorScheme.error), // 错误信息文本
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _analyzeDiskUsage, // 点击重试按钮重新分析
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary, // 按钮背景色
                    foregroundColor: colorScheme.onPrimary, // 按钮前景色
                  ),
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          // 如果加载完成且无错误，显示磁盘占用列表
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: _folderSizes.length, // 列表项数量为文件夹数量
          itemBuilder: (context, index) {
            final entry = _folderSizes.entries.elementAt(index);
            final folderName = entry.key; // 文件夹名称
            final sizeInBytes = entry.value; // 文件夹大小（字节）
            final formattedSize = _formatBytes(sizeInBytes); // 格式化后的文件大小

            return Card(
              elevation: 0, // 卡片阴影
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        folderName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                            color: colorScheme.onSurfaceVariant), // 文件夹名称文本样式
                        overflow: TextOverflow.ellipsis, // 文本溢出时显示省略号
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      formattedSize,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant), // 文件大小文本样式
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
