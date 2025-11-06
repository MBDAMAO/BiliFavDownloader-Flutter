import 'package:bili_tracker/di.dart';
import 'package:bili_tracker/providers/settings_provider.dart';
import 'package:flutter/material.dart';

class SaveQualityPage extends StatefulWidget {
  const SaveQualityPage({super.key});

  @override
  _SaveQualityPageState createState() => _SaveQualityPageState();
}

class _SaveQualityPageState extends State<SaveQualityPage> {
  final List<Map<String, dynamic>> videoQualities = [
    {'value': -1, 'name': '自动选择最高质量', 'note': '根据视频实际可用质量自动选择最高'},
    {'value': 127, 'name': '8K 超高清', 'note': '需要大会员认证'},
    {'value': 126, 'name': '杜比视界', 'note': '大会员认证'},
    {'value': 125, 'name': 'HDR 真彩色', 'note': '需要大会员认证'},
    {'value': 120, 'name': '4K 超清', 'note': '需要大会员认证'},
    {'value': 116, 'name': '1080P60 高帧率', 'note': '需要大会员认证'},
    {'value': 112, 'name': '1080P+ 高码率', 'note': '需要大会员认证'},
    {'value': 100, 'name': '智能修复', 'note': '人工智能增强画质，需要大会员认证'},
    {'value': 80, 'name': '1080P 高清', 'note': 'TV 端与 APP 端默认值'},
    {'value': 74, 'name': '720P60 高帧率', 'note': '需要登录认证'},
    {'value': 64, 'name': '720P 高清', 'note': 'WEB 端默认值'},
    {'value': 32, 'name': '480P 清晰', 'note': ''},
    {'value': 16, 'name': '360P 流畅', 'note': ''},
  ];

  final List<Map<String, dynamic>> audioQualities = [
    {'value': -1, 'name': '自动选择最高音质', 'note': '根据音频实际可用质量自动选择最高'},
    {'value': 30251, 'name': 'Hi-Res无损', 'note': ''},
    {'value': 30250, 'name': '杜比全景声', 'note': ''},
    {'value': 30280, 'name': '192K', 'note': ''},
    {'value': 30232, 'name': '132K', 'note': ''},
    {'value': 30216, 'name': '64K', 'note': ''},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = getIt<SettingsProvider>();
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择保存质量'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 视频质量
            Text(
              '视频质量',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4),
              child: Text(
                '提示：长按可拖动调整优先级（自动选择最高质量固定在最上方）',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            Container(
              color: colorScheme.surface,
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex == 0 || newIndex == 0) return;
                  if (newIndex > oldIndex) newIndex--;
                  setState(() {
                    final item = videoQualities.removeAt(oldIndex);
                    videoQualities.insert(newIndex, item);
                    // 保存排序到 provider（如有需要持久化）
                  });
                },
                children: [
                  for (int i = 0; i < videoQualities.length; i++)
                    ListTile(
                      key: ValueKey(videoQualities[i]['value']),
                      title: Text(
                        videoQualities[i]['name'],
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      subtitle:
                          videoQualities[i]['note'].isNotEmpty
                              ? Text(
                                videoQualities[i]['note'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              )
                              : null,
                      trailing: i == 0 ? null : const Icon(Icons.drag_handle),
                      leading: Radio<int>(
                        value: videoQualities[i]['value'],
                        groupValue: settings.videoQuality,
                        onChanged: (value) {
                          setState(() {
                            provider.changeVideoQuality(value!);
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 音频质量
            Text(
              '音频质量',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4),
              child: Text(
                '提示：长按可拖动调整优先级（自动选择最高音质固定在最上方）',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            Container(
              color: colorScheme.surface,
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex == 0 || newIndex == 0) return;
                  if (newIndex > oldIndex) newIndex--;
                  setState(() {
                    final item = audioQualities.removeAt(oldIndex);
                    audioQualities.insert(newIndex, item);
                    // 保存排序到 provider（如有需要持久化）
                  });
                },
                children: [
                  for (int i = 0; i < audioQualities.length; i++)
                    ListTile(
                      key: ValueKey(audioQualities[i]['value']),
                      title: Text(
                        audioQualities[i]['name'],
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      trailing: i == 0 ? null : const Icon(Icons.drag_handle),
                      leading: Radio<int>(
                        value: audioQualities[i]['value'],
                        groupValue: settings.audioQuality,
                        onChanged: (value) {
                          setState(() {
                            provider.changeAudioQuality(value!);
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 固定提示
            Container(
              padding: const EdgeInsets.all(12),
              color: colorScheme.surfaceContainerHighest,
              child: Text(
                '注意：部分高质量选项需要登录或会员权限才能使用。',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
