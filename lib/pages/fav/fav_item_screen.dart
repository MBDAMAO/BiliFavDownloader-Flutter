import 'package:bili_tracker/models/download_cursor.dart';
import 'package:bili_tracker/models/saved.dart';
import 'package:bili_tracker/repo/download_cursor_repo.dart';
import 'package:bili_tracker/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../apis/bilibili_api.dart';
import '../../repo/saved_repository.dart';
import '../../di.dart';
import '../../apis/templates/fav_list.dart';

import '../../services/bilibili_service.dart';
import '../../widgets/download_all.dart';
import '../../widgets/tip_with_choice.dart';
import 'net_video_page.dart';

class FavItemScreen extends StatefulWidget {
  final int favId;
  final String? title;

  const FavItemScreen({super.key, required this.favId, this.title});

  @override
  FavListPageState createState() => FavListPageState();
}

class FavListPageState extends State<FavItemScreen> {
  List<Media> medias = [];
  bool _isLoading = false;
  int _cursor = 0;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFavList();
    getIt<DownloadCursorRepository>().findCursorByFolderId(widget.favId).then((
      cursor,
    ) {
      if (cursor != null) {
        setState(() => _cursor = cursor.cursor);
      }
    });
  }

  @override
  dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadFavList(page: _currentPage + 1);
    }
  }

  Future<void> _loadFavList({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final favList = await BilibiliApi.getFavList(widget.favId, page, 20);
      BilibiliService.updateCachedFavCover(widget.favId);
      final newMedias = favList.data.medias;
      List<int> allAidList =
          newMedias.map((media) => media.id).cast<int>().toList();
      final savedMedias = await getIt<SavedRepository>().findSavedByAidList(
        allAidList,
      );
      for (var savedMedia in savedMedias) {
        final index = newMedias.indexWhere(
          (media) => media.id == savedMedia.aid,
        );
        if (index != -1) {
          newMedias[index].isSaved = savedMedia.status;
        }
      }
      if (!mounted) return;
      setState(() {
        if (page == 1) {
          medias = newMedias;
        } else {
          medias.addAll(newMedias);
        }
        _hasMore = favList.data.hasMore;
        _currentPage = page;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title ?? "收藏夹"),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 1, child: Text("下载所有视频")),
                  // const PopupMenuItem(value: 2, child: Text("批量操作")),
                  // const PopupMenuItem(value: 3, child: Text("全部标记为已保存")),
                  // const PopupMenuItem(value: 4, child: Text("全部标记为未保存")),
                ],
            onSelected: (value) async {
              // 处理菜单项选择
              switch (value) {
                case 1:
                  showDownloadConfirmation(context, widget.favId);
                  break;
                case 2:
                  break;
                case 3:
                  final choice = await showTipWithChoice(
                    context,
                    choiceKey: 'mark_all_saved',
                    content: Text('确定要标记所有视频为已保存吗？'),
                  );
                  if (choice) {
                    List<Saved> savedList = [];
                    final allVideos = await BilibiliService.fetchAllVideos(
                      mediaId: widget.favId,
                      callback: (a, b) {},
                    );
                    for (var video in allVideos) {
                      final saved = Saved(
                        id: 0,
                        aid: video.id,
                        cid: 0,
                        createTime: DateTime.now().toString(),
                      );
                      saved.status = Status.completed;
                      savedList.add(saved);
                    }
                    await getIt<SavedRepository>().batchInsertSaved(savedList);
                  }
                  break;
                case 4:
                  final choice = await showTipWithChoice(
                    context,
                    choiceKey: 'mark_all_unsaved',
                    content: Text('确定要标记所有视频为未保存吗？'),
                  );
                  if (choice) {
                    // final db = await DBUtil.getDatabase();
                    // final savedDao = db.savedDao;
                    // List<Saved> saveds = [];
                  }
                  break;
              }
            },
            icon: const Icon(Icons.more_vert), // 三点图标
          ),
        ],
      ),
      body:
          _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                onRefresh: () => _loadFavList(page: 1),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  // padding: EdgeInsets.all(12),
                  itemCount: medias.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= medias.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final media = medias[index];
                    if (media.id == _cursor) {
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Container(
                              height: 1,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          _buildVideoItem(media, context),
                        ],
                      );
                    }
                    return _buildVideoItem(media, context);
                  },
                ),
              ),
    );
  }

  Widget _buildVideoItem(Media media, BuildContext context) {
    return InkWell(
      onTap:
          () => {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoAudioSelectorPage(aid: media.id),
              ),
            ),
          },
      onLongPress: () => _showDownloadOptions(media, context),
      child: Container(
        margin: EdgeInsets.only(bottom: 6, top: 6, right: 12, left: 12),
        height: 90,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CachedNetworkImage(
                    imageUrl: media.cover,
                    width: 160,
                    height: 100,
                    fadeInDuration: Duration(milliseconds: 180),
                    useOldImageOnUrlChange: true,
                    // 如果 URL 未变，直接使用缓存
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(color: Colors.transparent),
                    errorWidget:
                        (context, url, error) => Icon(Icons.broken_image),
                  ),
                  if (media.page != 1)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${media.page} P',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (media.isSaved != null)
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
                              media.isSaved == Status.completed
                                  ? Colors.green.withValues(alpha: 0.7)
                                  : Colors.orange.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          media.isSaved == Status.completed ? '已保存' : '下载中',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    margin: EdgeInsets.all(4),
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(media.duration),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    style: TextStyle(fontWeight: FontWeight.normal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.transparent,
                        backgroundImage: CachedNetworkImageProvider(
                          media.upper.face,
                        ),
                        child: Icon(Icons.person, size: 12),
                      ),
                      SizedBox(width: 6),
                      Text(
                        media.upper.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildStat(Icons.play_arrow, media.cntInfo.play),
                      const SizedBox(width: 32),
                      _buildStat(Icons.star, media.cntInfo.reply),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to format duration (assuming duration is in seconds)
  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.secondary),
        SizedBox(width: 2),
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  void _showDownloadOptions(Media media, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // 允许弹窗全屏
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width, // 设置最大宽度为屏幕宽度
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.download),
                  title: Text('下载视频'),
                  onTap: () async {
                    Navigator.pop(context);
                    // final status =
                    //     await Permission.manageExternalStorage.request();
                    // if (!status.isGranted) {
                    //   toastError("请授予存储权限！");
                    //   return;
                    // }
                    BilibiliService.addDownloadTask(
                      aid: media.id,
                      filename: media.title.toString(),
                      cover: media.cover.toString(),
                    );
                    toastInfo("已添加下载任务");
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cut),
                  title: Text('标记为请求底线'),
                  onTap: () async {
                    getIt<DownloadCursorRepository>().insertOrUpdateCursor(
                      DownloadCursor(folderId: widget.favId, cursor: media.id),
                    );
                    Navigator.pop(context);
                  },
                ),
                media.isSaved == null || media.isSaved != Status.completed
                    ? ListTile(
                      leading: Icon(Icons.outlined_flag),
                      title: Text('标记为已下载'),
                      onTap: () async {
                        final saved = Saved(
                          id: 0,
                          aid: media.id,
                          cid: 0,
                          createTime: DateTime.now().toString(),
                        );
                        saved.status = Status.completed;

                        await getIt<SavedRepository>().insertSaved(saved);
                        if (context.mounted) {
                          Navigator.pop(context); // 关闭弹窗
                        }
                      },
                    )
                    : ListTile(
                      leading: Icon(Icons.info),
                      title: Text('从已保存中移除'),
                      onTap: () async {
                        Navigator.pop(context); // 关闭弹窗
                        await getIt<SavedRepository>().deleteSavedByAid(
                          media.id,
                        );
                      },
                    ),
              ],
            ),
          ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}万';
    return count.toString();
  }
}
