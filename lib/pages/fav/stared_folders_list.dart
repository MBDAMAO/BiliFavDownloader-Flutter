import 'package:bili_tracker/apis/bilibili_api.dart';
import 'package:bili_tracker/repo/stared_folder_repository.dart';
import 'package:bili_tracker/di.dart';
import 'package:bili_tracker/models/stared_folder.dart';
import 'package:bili_tracker/utils/ext.dart';
import 'package:bili_tracker/utils/toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'fav_item_screen.dart';

class StaredFoldersList extends StatefulWidget {
  const StaredFoldersList({super.key});

  @override
  State<StaredFoldersList> createState() => _StaredFoldersListState();
}

class _StaredFoldersListState extends State<StaredFoldersList> {
  late Future<List<StaredFolder>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _foldersFuture = _fetchFolders();
  }

  Future<List<StaredFolder>> _fetchFolders() async {
    return await getIt<StaredFolderRepository>().findAllStaredFolder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('特别关注收藏夹'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    title: const Text('添加收藏夹'),
                    content: TextField(
                      controller: controller,
                      maxLines: 1,
                      decoration: const InputDecoration(hintText: '请输入收藏夹ID'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('取消'),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            final folderId = int.parse(controller.text);
                            final exists = await getIt<StaredFolderRepository>()
                                .findStaredFolderById(folderId);
                            if (exists != null) {
                              throw Exception("已存在");
                            }
                            final resp = await BilibiliApi.getFolderInfo(
                              folderId,
                            );
                            await getIt<StaredFolderRepository>()
                                .insertStaredFolder(
                                  StaredFolder(
                                    ownerName: resp.data.upper.name,
                                    ownerAvatar: resp.data.upper.face,
                                    folderId: folderId,
                                    name: resp.data.title,
                                    cover: resp.data.cover,
                                  ),
                                );
                          } catch (e) {
                            toastError("添加失败 $e");
                          } finally {
                            Navigator.pop(context);
                          }
                        },
                        child: Text('确定'),
                      ),
                    ],
                  );
                },
              );
              setState(() {
                _foldersFuture = _fetchFolders();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<StaredFolder>>(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('没有收藏夹'));
          } else {
            final folders = snapshot.data!;
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return InkWell(
                  onLongPress: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                folders[index].name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              ListTile(
                                title: Text('删除'),
                                onTap: () async {
                                  await getIt<StaredFolderRepository>()
                                      .deleteStaredFolder(folder);
                                  setState(() {
                                    _foldersFuture = _fetchFolders();
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FavItemScreen(
                              favId: folder.folderId,
                              title: folder.name,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: folder.cover,
                            width: 142,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) =>
                                    Container(color: Colors.transparent),
                            errorWidget:
                                (context, url, error) =>
                                    Icon(Icons.broken_image),
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                  folders[index].name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // 副标题
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: folders[index].ownerAvatar,
                                        height: 20,
                                        width: 20,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Container(
                                              color: Colors.transparent,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      overflow: TextOverflow.ellipsis,
                                      folders[index].ownerName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
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
            );
          }
        },
      ),
    );
  }
}
