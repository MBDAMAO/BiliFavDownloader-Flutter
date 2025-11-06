import 'package:bili_tracker/apis/templates/fav_list.dart';
import 'package:bili_tracker/models/saved.dart';
import 'package:bili_tracker/repo/saved_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../di.dart';
import '../services/bilibili_service.dart';

void showDownloadConfirmation(BuildContext context, int id) async {
  int currentPage = 1;
  int totalPages = 0;

  StateSetter? dialogSetState;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            dialogSetState = setDialogState; // 保存引用
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  if (totalPages > 0)
                    Text('正在获取第$currentPage页/已获取$totalPages个')
                  else
                    const Text('正在获取视频列表...'),
                ],
              ),
            );
          },
        ),
  );

  List<Media> videos;
  try {
    videos = await _downloadFav(id, (page, total) {
      currentPage = page;
      totalPages = total;
      if (dialogSetState != null) {
        dialogSetState!(() {});
      }
    });

    if (!context.mounted) return;
    Navigator.of(context).pop(); // 关闭加载对话框
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    // toastError(e.toString());
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final selectedIndices = <int>{};
      for (var i = 0; i < videos.length; i++) {
        if (videos[i].isSaved == null && videos[i].attr == 0) {
          selectedIndices.add(videos[i].id);
        }
      }

      final expiredVideos = videos.where((v) => v.attr != 0).toList();
      final savedVideos = videos.where((v) => v.isSaved != null).toList();
      final unsavedVideos =
          videos.where((v) => v.isSaved == null && v.attr == 0).toList();
      return DefaultTabController(
        length: 3,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // 顶部标题和全选控制
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '可下载视频 (${videos.length - expiredVideos.length}个)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            selectedIndices.isEmpty ||
                                    selectedIndices.length !=
                                        videos.length - expiredVideos.length
                                ? '全选'
                                : '取消全选',
                          ),
                          Checkbox(
                            value:
                                selectedIndices.length ==
                                videos.length - expiredVideos.length,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  for (int i = 0; i < videos.length; i++) {
                                    if (!expiredVideos.contains(videos[i])) {
                                      selectedIndices.add(videos[i].id);
                                    }
                                  }
                                } else {
                                  selectedIndices.clear();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // 视频列表
                  TabBar(
                    tabs: [
                      Tab(text: '未保存(${unsavedVideos.length})'),
                      Tab(text: '已保存(${savedVideos.length})'),
                      Tab(text: '已失效(${expiredVideos.length})'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.secondary,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 全部视频
                        _buildVideoListView(
                          unsavedVideos,
                          selectedIndices,
                          setState,
                        ),
                        // 已保存视频
                        _buildVideoListView(
                          savedVideos,
                          selectedIndices,
                          setState,
                        ),
                        // 未保存视频
                        _buildVideoListView(
                          expiredVideos,
                          selectedIndices,
                          setState,
                        ),
                      ],
                    ),
                  ),
                  // 底部按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(120, 48),
                        ),
                        child: Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // 过滤出选中的视频
                          final selectedVideos =
                              videos
                                  .where((v) => selectedIndices.contains(v.id))
                                  .toList();
                          if (selectedVideos.isNotEmpty) {
                            BilibiliService.downloadAllVideos(selectedVideos);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(120, 48),
                        ),
                        child: Text('下载(${selectedIndices.length})'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Widget _buildVideoListView(
  List<Media> videos,
  Set<int> selectedIndices,
  StateSetter setState,
) {
  final controller = ScrollController();
  return videos.isEmpty
      ? Center(child: Text("无内容"))
      : Scrollbar(
        controller: controller,
        child: ListView.builder(
          controller: controller,
          physics: AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return Material(
              color: Colors.transparent,
              child: ListTile(
                horizontalTitleGap: 10,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CachedNetworkImage(
                        imageUrl: video.cover,
                        width: 93,
                        height: 70,
                        fit: BoxFit.cover,
                        errorWidget:
                            (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                      ),
                      if (video.isSaved != null)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  video.isSaved != null
                                      ? Colors.green.withValues(alpha: 0.7)
                                      : Colors.orange.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                title: Tooltip(
                  message: video.title,
                  child: Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Text(_formatDuration(video.duration), maxLines: 1),
                    SizedBox(width: 8),
                    if (video.page != 1)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_copy_outlined,
                              size: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                            SizedBox(width: 4),
                            Text('${video.page}P'),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: Checkbox(
                  isError: video.attr != 0,
                  value: selectedIndices.contains(video.id),
                  onChanged:
                      video.attr == 0
                          ? (value) {
                            setState(() {
                              if (value == true) {
                                selectedIndices.add(video.id);
                              } else {
                                selectedIndices.remove(video.id);
                              }
                            });
                          }
                          : null,
                ),
                onTap: () {
                  if (video.attr != 0) return;
                  setState(() {
                    if (selectedIndices.contains(video.id)) {
                      selectedIndices.remove(video.id);
                    } else {
                      selectedIndices.add(video.id);
                    }
                  });
                },
              ),
            );
          },
        ),
      );
}

String _formatDuration(int seconds) {
  int hours = seconds ~/ 3600;
  int remainingMinutes = (seconds % 3600) ~/ 60;
  int remainingSeconds = seconds % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  } else {
    return '${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

Future<List<Media>> _downloadFav(int favId, Function(int, int) callback) async {
  var medias = await BilibiliService.fetchAllVideos(
    mediaId: favId,
    callback: callback, // 传递回调函数
  );

  List<int> allAidList = medias.map((media) => media.id).cast<int>().toList();
  final savedMedias = await getIt<SavedRepository>().findSavedByAidList(
    allAidList,
  );

  for (var savedMedia in savedMedias) {
    final index = medias.indexWhere((media) => media.id == savedMedia.aid);
    if (index != -1) {
      medias[index].isSaved = Status.completed;
    }
  }
  return medias;
}
