import 'dart:collection';
import 'dart:math';

import 'package:bili_tracker/apis/bilibili_api.dart';
import 'package:bili_tracker/apis/templates/video_detail_resp.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../apis/templates/video_pages_resp.dart';
import '../services/bilibili_service.dart';

class AddDownloadDialog extends StatefulWidget {
  const AddDownloadDialog({super.key});

  @override
  AddDownloadDialogState createState() => AddDownloadDialogState();
}

class AddDownloadDialogState extends State<AddDownloadDialog> {
  final TextEditingController _textEditingController = TextEditingController();
  String? videoTitle;
  String? cover;
  int? _aid;

  // 在State类中添加一个ScrollController
  final ScrollController _scrollController = ScrollController();

  // 在State类中添加一个集合来存储选中的分P索引
  Map<int, Map<String, dynamic>> selectedPages = HashMap();
  List<VideoPageData>? pageList;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() {
      isLoading = true;
      videoTitle = null;
      selectedPages.clear();
      cover = null;
      _aid = null;
      pageList = null;
    });
    if (_textEditingController.text == '') {
      setState(() {
        isLoading = false;
        videoTitle = '输入不能为空';
      });
      return;
    }
    String? vid = await parseUrlToVid(_textEditingController.text);
    if (vid == null) {
      setState(() {
        isLoading = false;
        videoTitle = '解析失败，请检查格式是否正确';
      });
      return;
    }

    VideoDetailResp videoInfo;
    int? aid;
    String? bvid;
    int cid;

    if (vid.startsWith('BV')) {
      bvid = vid;
      videoInfo = await BilibiliApi.getVideoInfoWithBVId(vid);
      aid = videoInfo.data.aid;
      cid = videoInfo.data.cid;
      _aid = aid;
    } else {
      aid = int.parse(vid.substring(2));
      _aid = aid;
      videoInfo = await BilibiliApi.getVideoInfoWithAVId(aid);
      cid = videoInfo.data.cid;
      bvid = videoInfo.data.bvid.toString();
    }

    final pagesNum = videoInfo.data.videos;
    final title = videoInfo.data.title;
    final coverUrl = videoInfo.data.pic;

    if (pagesNum > 1) {
      VideoPagesResp page = await BilibiliApi.getVideoPageList(
        aid: aid,
        bvid: bvid,
      );
      final list = page.data;
      setState(() {
        pageList = list;
        videoTitle = title;
        cover = coverUrl;
        isLoading = false;
      });
    } else {
      // 只有1P：也显示标题
      pageList = [
        VideoPageData(
          cid: cid,
          page: 1,
          part: "1",
          duration: 12,
          from: "1",
          vid: vid,
          firstFrame: coverUrl,
          weblink: "weblink",
        ),
      ];
      setState(() {
        videoTitle = title;
        cover = coverUrl;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加下载任务'),
      actions: [
        if (selectedPages.isNotEmpty)
          TextButton(
            child: Text('下载 (${selectedPages.length})'),
            onPressed: () async {
              await BilibiliService.downloadSelectedVideoPages(selectedPages);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        TextButton(
          child: const Text('取消'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(onPressed: _handleConfirm, child: const Text('解析链接')),
      ],
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _textEditingController,
              maxLines: 1,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _textEditingController.clear();
                  },
                ),
                hintText: 'BV/分享链接/网址',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading) const CircularProgressIndicator(),
            if (videoTitle != null) ...[
              if (cover != null)
                CachedNetworkImage(imageUrl: cover ?? "", width: 100),
              Text(
                videoTitle!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            if (pageList != null)
              SizedBox(
                height: min(pageList!.length * 80, 320),
                // or any appropriate fixed height
                width: 500,
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    physics: AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: pageList!.length,
                    itemBuilder: (context, index) {
                      final page = pageList![index];
                      final isSelected = selectedPages.containsKey(index);

                      return Container(
                        decoration: BoxDecoration(
                          border:
                              isSelected
                                  ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2.0,
                                  )
                                  : Border.all(
                                    color: Colors.transparent,
                                    width: 2.0,
                                  ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: CachedNetworkImage(
                              imageUrl: page.firstFrame,
                              width: 100,
                              errorWidget:
                                  (_, _, _) =>
                                      const Icon(Icons.broken_image),
                            ),
                            title: Tooltip(
                              // <-- Added Tooltip here
                              message: page.part,
                              // Full title shown on long press
                              child: Text(
                                page.part,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            subtitle: Text(
                              'CID: ${page.cid}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedPages.remove(index);
                                } else {
                                  selectedPages.putIfAbsent(
                                    index,
                                    () => {
                                      "aid": _aid,
                                      "cid": page.cid,
                                      "cover": cover,
                                      "title":
                                          "${videoTitle!}-P${page.page.toString()}",
                                    },
                                  );
                                }
                              });
                            },
                            selected: isSelected,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 支持的解析链接格式
  /// 1.BV号     BV1TJE8zoEJa
  /// 2.av号     av85440373
  /// 2.网页端网址 https://www.bilibili.com/video/BV1TJE8zoEJa/?xxx=xxx
  /// 3.网页端分享 【VAE原理动画拆解 🎬】 https://www.bilibili.com/video/BV1TJE8zoEJa/?xxx=xxx
  /// 4.手机端分享 【VAE原理动画拆解 🎬-哔哩哔哩】 https://b23.tv/ZSCaD5d 需重定向
  Future<String?> parseUrlToVid(String url) async {
    try {
      // Handle mobile share URL (case 4)
      if (url.contains('b23.tv')) {
        // 清理URL
        url = url.replaceAll(RegExp(r'[【】]'), '').trim();
        final urlRegExp = RegExp(r'(https?://[^\s]+)');
        final match = urlRegExp.firstMatch(url);
        if (match != null) {
          url = match.group(0)!;
        }
        final redirectUrl = await getRedirectLocation(url);
        if (redirectUrl != null) {
          url = redirectUrl;
        } else {
          return null;
        }
      }

      // Extract from text (cases 2, 3)
      final uriRegExp = RegExp(
        r'(?:https?://)?(?:www\.)?bilibili\.com/video/((?:BV|av)[a-zA-Z0-9]+)',
      );
      final match = uriRegExp.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }

      // Check for direct BV/av codes in text
      final directCodeRegExp = RegExp(
        r'(BV[a-zA-Z0-9]{10}|av\d+)',
        caseSensitive: false,
      );
      final directMatch = directCodeRegExp.firstMatch(url);
      if (directMatch != null) {
        return directMatch.group(0);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRedirectLocation(String url) async {
    final client = http.Client();

    try {
      final uri = Uri.parse(url);

      final request =
          http.Request('GET', uri)
            ..followRedirects = false
            ..headers.addAll({
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1',
              'Referer': 'https://www.bilibili.com/',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            });

      final response = await client.send(request);
      final statusCode = response.statusCode;

      if (statusCode == 301 ||
          statusCode == 302 ||
          statusCode == 303 ||
          statusCode == 307 ||
          statusCode == 308) {
        final location = response.headers['location'];
        if (location != null) {
          return Uri.parse(url).resolve(location).toString();
        }
      } else {
        print('非重定向响应: $statusCode');
      }
    } catch (e) {
      print('发生异常: $e');
    } finally {
      client.close();
    }

    return null;
  }
}
