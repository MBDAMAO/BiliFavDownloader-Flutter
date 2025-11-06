import 'package:bili_tracker/providers/settings_provider.dart';
import 'package:bili_tracker/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeSettings extends StatefulWidget {
  const ThemeSettings({super.key});

  @override
  State<ThemeSettings> createState() => _ThemeSettingsState();
}

class _ThemeSettingsState extends State<ThemeSettings> {
  // 预设颜色种子列表
  final List<Color> _presetColors = [
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.indigo,
  ];

  // 获取颜色名称
  String _getColorName(Color color) {
    if (color == Colors.purple) return "紫色";
    if (color == Colors.blue) return "蓝色";
    if (color == Colors.teal) return "青色";
    if (color == Colors.green) return "绿色";
    if (color == Colors.orange) return "橙色";
    if (color == Colors.red) return "红色";
    if (color == Colors.pink) return "粉色";
    if (color == Colors.indigo) return "靛蓝色";
    return "自定义颜色";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主题设置'), elevation: 0),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final currentThemeColor = settingsProvider.settings.themeColor;
          final currentThemeMode = settingsProvider.settings.themeMode;
          final themeModes = [
            ThemeMode.system,
            ThemeMode.light,
            ThemeMode.dark,
          ];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 暗黑模式设置卡片
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            getThemeModeIcon(currentThemeMode),
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '暗黑模式',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  getThemeModeName(currentThemeMode),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 主题模式选择器
                      Row(
                        children: themeModes.map((ThemeMode mode) {
                          final isSelected = mode == currentThemeMode;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (!isSelected) {
                                  await settingsProvider.changeThemeMode(mode);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      getThemeModeIcon(mode),
                                      size: 20,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      getThemeModeName(mode),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // 当前主题预览卡片
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: currentThemeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '当前主题色',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getColorName(currentThemeColor),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '基于当前颜色种子生成的主题，应用于整个应用界面元素',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 主题颜色选择标题
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '选择主题颜色',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 主题颜色网格（预设颜色种子）
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _presetColors.length,
                itemBuilder: (context, index) {
                  final color = _presetColors[index];
                  final isSelected = color == currentThemeColor;

                  return GestureDetector(
                    onTap: () async {
                      if (!isSelected) {
                        await settingsProvider.changeTheme(color);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                        ],
                      ),
                      child: isSelected
                          ? Center(
                        child: Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary ,
                          size: 20,
                        ),
                      )
                          : null,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 主题预览说明
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '设置说明',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 暗黑模式设置：\n'
                            '  - 跟随系统：根据系统设置自动切换明暗模式\n'
                            '  - 明亮模式：始终使用浅色主题\n'
                            '  - 暗黑模式：始终使用深色主题\n\n'
                            '• 主题颜色：选择预设颜色种子，应用于整个应用的强调色\n'
                            '• 更改设置后会立即生效',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}