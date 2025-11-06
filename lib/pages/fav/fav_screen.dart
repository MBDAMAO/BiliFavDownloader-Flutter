import 'dart:io';

import 'package:bili_tracker/models/stared_folder.dart';
import 'package:bili_tracker/pages/fav/fav_item_screen.dart';
import 'package:bili_tracker/pages/fav/stared_folders_list.dart';
import 'package:bili_tracker/apis/templates/all_my_fav_resp.dart';
import 'package:bili_tracker/services/bilibili_service.dart';
import 'package:bili_tracker/utils/ext.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../apis/bilibili_api.dart';
import '../../repo/stared_folder_repository.dart';
import '../../di.dart';
import '../../utils/exceptions.dart';
import '../../widgets/download_all.dart';
import '../settings/login_page.dart'; // API 请求封装

class FavScreen extends StatefulWidget {
  const FavScreen({super.key});

  @override
  FavScreenState createState() => FavScreenState();
}

class FavScreenState extends State<FavScreen> with WindowListener {
  List<dynamic> favs = [];
  bool _isLoading = false;
  Exception? _error;
  Map<int, String> _coverMap = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 设置窗口监听器
    windowManager.addListener(this);
    // 初始化时检查窗口是否置顶
    if (Platform.isWindows) {
      _checkIsPinned();
    }
    _fetchFavList();
  }

  @override
  void dispose() {
    // 移除窗口监听器
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _fetchFavList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      var (favList, coverMap) = await BilibiliService.getAllMyFavWithCover();
      setState(() {
        _coverMap = coverMap;
        favs = favList?.map((item) => item).toList() ?? [];
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is Exception) {
            _error = e;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的收藏夹'),
        actions: [
          if (Platform.isWindows)
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: _togglePinState,
            ),
          IconButton(
            icon: Icon(Icons.star_rate_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StaredFoldersList()),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorScreen(context, _error)
              : ListView.builder(
                controller: _scrollController,
                physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: favs.length,
                itemBuilder: (context, index) {
                  final fav = favs[index];
                  return InkWell(
                    onLongPress: () => _showFavOptionsModal(context, fav),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FavItemScreen(
                                favId: fav.id,
                                title: fav.title,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      // 直接设置整体高度
                      height: 100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          // 左侧图片
                          if (_coverMap[fav.id] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: _coverMap[fav.id] ?? '',
                                width: 142,
                                height: 80,
                                fit: BoxFit.cover,
                                errorWidget:
                                    (context, url, error) => Icon(Icons.error),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              // 调整文本与图片的间距
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                // 垂直方向居中对齐
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 标题
                                  Text(
                                    fav.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // 副标题
                                  const SizedBox(height: 8),
                                  Text(
                                    '收藏数量: ${fav.mediaCount}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).cardx;
                },
              ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, Exception? error) {
    if (error is NoLoginException) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error),
            Text('请先登录'),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (item) => const LoginPage()),
                );
                await _fetchFavList();
              },
              child: Text('去登录'),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error),
            Text('发生错误'),
            SizedBox(width: 200.0, child: Text(error.toString())),
            ElevatedButton(
              onPressed: () {
                _fetchFavList();
              },
              child: Text('重试'),
            ),
          ],
        ),
      );
    }
  }

  // 检查窗口是否置顶
  Future<void> _checkIsPinned() async {
    final isPinned = await windowManager.isAlwaysOnTop();
    setState(() {
      _isPinned = isPinned;
    });
  }

  bool _isPinned = false;

  @override
  void onAlwaysOnTopChanged(bool isAlwaysOnTop) {
    setState(() {
      _isPinned = isAlwaysOnTop;
    });
  }

  // 切换窗口置顶状态
  Future<void> _togglePinState() async {
    final newState = !_isPinned;
    await windowManager.setAlwaysOnTop(newState);
    setState(() {
      _isPinned = newState;
    });

    // 显示状态变化提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newState ? '窗口已置顶' : '窗口已取消置顶'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showFavOptionsModal(BuildContext context, MyFavFolder fav) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fav.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.download),
                  title: Text('批量下载'),
                  onTap: () async {
                    showDownloadConfirmation(context, fav.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.star),
                  title: Text('添加到特别Star'),
                  onTap: () async {
                    final favInfo = await BilibiliApi.getFolderInfo(fav.id);
                    await getIt<StaredFolderRepository>().insertStaredFolder(
                      StaredFolder(
                        ownerName: favInfo.data.upper.name,
                        ownerAvatar: favInfo.data.upper.face,
                        cover: favInfo.data.cover,
                        folderId: fav.id,
                        name: fav.title,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }
}
