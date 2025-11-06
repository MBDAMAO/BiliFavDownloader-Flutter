import 'package:bili_tracker/pages/downloads/video_page.dart';
import 'package:bili_tracker/utils/ext.dart';
import 'package:bili_tracker/widgets/tip_with_choice.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart' as p;
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'dart:io';

import '../utils/platform.dart';

class LocalFilesList extends StatefulWidget {
  const LocalFilesList({super.key});

  @override
  LocalFilesListState createState() => LocalFilesListState();
}

class LocalFilesListState extends State<LocalFilesList> {
  final Map<String, String?> _thumbnailCache = {};
  final List<FileSystemEntity> _localFiles = [];
  bool _isLoading = false;

  @override
  initState() {
    super.initState();
    _loadLocalFiles();
  }

  @override
  void dispose() {
    _thumbnailCache.clear();
    super.dispose();
  }

  Future<void> _loadLocalFiles() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      Directory? downloadDir = await getDownloadDirectory();
      List<FileSystemEntity> files = downloadDir.listSync();
      setState(() {
        _localFiles.clear();
        _localFiles.addAll(files.whereType<File>().toList());
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载失败: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 新增：下拉刷新方法
  Future<void> _handleRefresh() async {
    await Future.delayed(Duration(milliseconds: 500));
    await _loadLocalFiles();
    _refreshController.refreshCompleted();
  }

  Future<String?> _getThumbnail(String videoName) async {
    final coverDir = await getCoverDirectory();
    final coverFile = File(
      p.join(coverDir.path, '${videoName.replaceAll('.mp4', '')}.png'),
    );
    if (coverFile.existsSync()) {
      return coverFile.path;
    } else {
      return null;
    }
  }

  String _getFileSize(String path) {
    final file = File(path);
    final sizeInBytes = file.lengthSync();
    if (sizeInBytes < 1024) {
      return '${sizeInBytes}B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      onRefresh: _handleRefresh,
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      header: CustomHeader(
        builder: (context, mode) {
          return SizedBox(
            height: 40.0,
            child: Center(
              child:
                  mode == RefreshStatus.refreshing
                      ? CircularProgressIndicator()
                      : Text("下拉刷新"),
            ),
          );
        },
      ),
      child:
          _localFiles.isEmpty
              ? Center(
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('无本地文件'),
              )
              : ListView.builder(
                itemCount: _localFiles.length,
                itemBuilder: (context, index) {
                  final file = _localFiles[_localFiles.length - index - 1];
                  final fileName = path.basename(file.path);
                  final filePath = file.path;
                  final fileSize = _getFileSize(filePath);
                  return InkWell(
                    onTap: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => VideoPage(videoPath: filePath),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FutureBuilder<String?>(
                            future: _getThumbnail(fileName),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(snapshot.data!),
                                    width: 100,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return Container(
                                width: 100,
                                height: 60,
                                color: Colors.transparent,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName.replaceAll('.mp4', ''),
                                  style: Theme.of(context).textTheme.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.storage, size: 14),
                                    const SizedBox(width: 4),
                                    Text(fileSize),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          // 修改的IconButton部分
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 24, // 稍大一点的图标更容易触发hover
                            ),
                            // 增加点击反馈区域
                            splashRadius: 24,
                            // hover时的背景色
                            hoverColor: Colors.red.withValues(alpha: 0.1),
                            // 点击时的水波纹颜色
                            splashColor: Colors.red.withValues(alpha: 0.2),
                            // 增加padding使交互区域更大
                            padding: const EdgeInsets.all(8),
                            // 鼠标悬停时的提示
                            tooltip: '删除文件',
                            onPressed: () async {
                              bool isDelete = await showTipWithChoice(
                                context,
                                content: Text('是否删除此文件$fileName?'),
                                choiceKey: 'delete_local_file',
                              );
                              if (isDelete) {
                                final file = _localFiles[index];
                                try {
                                  await file.delete();
                                  await File(
                                    await _getThumbnail(
                                          p.basename(file.path),
                                        ) ??
                                        "",
                                  ).delete();
                                  setState(() {
                                    _localFiles.removeAt(index);
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('删除失败: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ).cardx;
                },
              ),
    );
  }
}
