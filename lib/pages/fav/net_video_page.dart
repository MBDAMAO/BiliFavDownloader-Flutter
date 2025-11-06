import 'dart:io';

import 'package:bili_tracker/apis/bilibili_api.dart';
import 'package:bili_tracker/utils/net.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../apis/templates/video_stream_resp.dart' hide Video;

class VideoAudioSelectorPage extends StatefulWidget {
  final int aid;

  const VideoAudioSelectorPage({super.key, required this.aid});

  @override
  State<VideoAudioSelectorPage> createState() => _VideoAudioSelectorPageState();
}

class _VideoAudioSelectorPageState extends State<VideoAudioSelectorPage> {
  late final Player player;
  late final VideoController controller;
  int selectedAudioTrackId = 0;
  double? videoAspectRatio; // 视频宽高比
  final double maxHeightRatio = 0.6; // 最大高度占屏幕高度的比例
  bool isLoading = true; // 加载状态

  String videoTitle = ''; // 视频标题
  String videoDescription = ''; // 视频简介

  List<int> allSupportQuality = []; // 支持的所有清晰度代码
  List<String> allAcceptDescription = []; // 支持的所有清晰度描述
  int? selectedQualityCode; // 播放清晰度
  int? selectedDownloadQualityCode; // 下载清晰度（独立）

  VideoStreamResp? _videoStreamData; // 存储完整的视频流数据，用于切换清晰度

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    MediaKit.ensureInitialized();
    await _initPlayer();
  }

  Future<void> _initPlayer() async {
    player = Player(
      configuration: const PlayerConfiguration(logLevel: MPVLogLevel.error),
    );
    controller = VideoController(player);
    var pp = player.platform as NativePlayer;

    final videoInfo = await BilibiliApi.getVideoInfoWithAVId(widget.aid);
    final titleUnsafe = videoInfo.data.title;
    final description = videoInfo.data.desc;

    final cid = videoInfo.data.cid;
    final videoStreamData = await BilibiliApi.getVideoStreamUrl(widget.aid, cid);
    _videoStreamData = videoStreamData;
    final dash = videoStreamData.data.dash;
    if (dash == null) throw Exception('Dash 数据为空');

    allSupportQuality = videoStreamData.data.acceptQuality;
    allAcceptDescription = videoStreamData.data.acceptDescription;

    selectedQualityCode = allSupportQuality.isNotEmpty ? allSupportQuality[0] : null; // 默认最高清
    selectedDownloadQualityCode = selectedQualityCode;

    final initialVideo = dash.video[0];
    final initialAudio = dash.audio[0];
    final width = initialVideo.width;
    final height = initialVideo.height;

    setState(() {
      videoAspectRatio = width / height;
      videoTitle = titleUnsafe;
      videoDescription = description;
      isLoading = false; // 加载完成
    });

    await pp.setProperty(
      'audio-files',
      Platform.isWindows
          ? initialAudio.baseUrl.replaceAll(';', '\\;')
          : initialAudio.baseUrl.replaceAll(':', '\\:'),
    );
    await pp.setProperty("volume-max", "100");
    await player.setAudioTrack(AudioTrack.auto());
    player.open(Media(httpHeaders: Network.headers, initialVideo.baseUrl));
    player.play();
  }

  // 切换视频清晰度（播放）
  Future<void> _changeVideoQuality(int qualityCode) async {
    if (_videoStreamData == null) return;

    setState(() {
      isLoading = true; // 重新加载时显示加载状态（转圈）
      selectedQualityCode = qualityCode;
    });

    final dash = _videoStreamData!.data.dash;
    if (dash == null) return;

    // 找到对应清晰度的视频流
    final selectedVideo = dash.video.firstWhere(
      (element) => element.id == qualityCode,
      orElse: () => dash.video[0], // 如果找不到，默认为第一个
    );

    final newVideoUrl = selectedVideo.baseUrl;
    final newAudioUrl = dash.audio[0].baseUrl; // 音频通常是通用的

    await player.stop(); // 停止当前播放
    var pp = player.platform as NativePlayer;

    await pp.setProperty(
      'audio-files',
      Platform.isWindows
          ? newAudioUrl.replaceAll(';', '\\;')
          : newAudioUrl.replaceAll(':', '\\:'),
    );

    await player.open(Media(httpHeaders: Network.headers, newVideoUrl));
    await player.play();

    // 更新宽高比，因为不同清晰度可能有不同分辨率
    setState(() {
      videoAspectRatio = selectedVideo.width / selectedVideo.height;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final maxVideoHeight = screenHeight * maxHeightRatio;

    // 外层容器始终使用全屏宽度；高度按比例计算，仅在高度上收缩
    double containerHeight = maxVideoHeight; // 加载时固定高度
    if (!isLoading && videoAspectRatio != null) {
      containerHeight = screenWidth / videoAspectRatio!;
      if (containerHeight > maxVideoHeight) {
        containerHeight = maxVideoHeight;
        // 注意：保持外层容器 width 仍为 screenWidth，不缩窄，从而保证水平居中（Video 内部 BoxFit.contain 居中）
      }
    }

    return PopScope(
      canPop: false, // 拦截返回
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await player.dispose();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(videoTitle.isNotEmpty ? videoTitle : '加载中...'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部视频区域：全宽 + 按高度动画过渡；加载时显示转圈
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: screenWidth,
              height: containerHeight,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 视频（加载完成后显示，使用 BoxFit.contain 保证水平/垂直居中）
                  if (!isLoading)
                    Video(
                      controller: controller,
                      fit: BoxFit.contain,
                    ),
                  // 加载转圈（遮罩在上，避免黑块突变）
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),

            // 下方信息与选择
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      videoDescription,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3, // 限制简介行数
                      overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                    ),
                    const SizedBox(height: 16),

                    // 播放清晰度（保持原逻辑）
                    if (allSupportQuality.isNotEmpty && !isLoading)
                      Row(
                        children: [
                          const Text('播放清晰度: '),
                          DropdownButton<int>(
                            value: selectedQualityCode,
                            items: allSupportQuality.asMap().entries.map((entry) {
                              final index = entry.key;
                              final quality = entry.value;
                              final description = allAcceptDescription[index];
                              return DropdownMenuItem<int>(
                                value: quality,
                                child: Text(description),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                _changeVideoQuality(newValue);
                              }
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // 下载清晰度（与播放分离）
                    if (allSupportQuality.isNotEmpty)
                      Row(
                        children: [
                          const Text('下载清晰度: '),
                          DropdownButton<int>(
                            value: selectedDownloadQualityCode,
                            items: allSupportQuality.asMap().entries.map((entry) {
                              final index = entry.key;
                              final q = entry.value;
                              return DropdownMenuItem<int>(
                                value: q,
                                child: Text(allAcceptDescription[index]),
                              );
                            }).toList(),
                            onChanged: (int? v) {
                              setState(() => selectedDownloadQualityCode = v);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // 下载逻辑不实现，仅提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('准备下载清晰度: ${selectedDownloadQualityCode ?? ''}'),
                                ),
                              );
                            },
                            child: const Text('下载'),
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
    );
  }
}
