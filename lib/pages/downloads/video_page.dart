import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPage extends StatefulWidget {
  final String videoPath;

  const VideoPage({super.key, required this.videoPath});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late final player = Player(
    configuration: const PlayerConfiguration(logLevel: MPVLogLevel.error),
  );

  late final controller = VideoController(
    player,
    configuration: VideoControllerConfiguration(
      enableHardwareAcceleration: true,
      androidAttachSurfaceAfterVideoParameters: false,
    ),
  );

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    player.open(Media(widget.videoPath));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await player.dispose();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Video(controller: controller),
          ),
        ),
      ),
    );
  }
}
