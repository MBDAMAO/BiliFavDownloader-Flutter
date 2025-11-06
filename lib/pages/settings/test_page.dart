import 'package:flutter/material.dart';
import 'dart:math' as math;

class WashingMachinePage extends StatefulWidget {
  const WashingMachinePage({super.key});

  @override
  _CatAnimationPageState createState() => _CatAnimationPageState();
}

class _CatAnimationPageState extends State<WashingMachinePage>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _arrowAnimation;
  late final Animation<double> _expandCurve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _arrowAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _expandCurve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const titleText =
        '这是一个标题示例，当展开时会显示完整内容，否则只显示一行。这是为了测试文本在展开后不被截断，同时保持收起时平滑过渡效果。Flutter 动画可以通过 ClipRect 实现平滑遮挡，而不是通过改变 maxLines 引起布局抖动。';
    const descriptionText = '这是标题下方的简介部分。当你点击标题时，会展开这段文字。点击标题再次收起时，这段文字会消失。';
    const viewCount = '12.3万播放';
    const danmakuCount = '1.8万弹幕';
    const publishDate = '2025-10-06 发布';

    final titleStyle = const TextStyle(
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w600,
    );

    final infoStyle = TextStyle(fontSize: 13, color: Colors.grey.shade700);

    return Scaffold(
      appBar: AppBar(title: const Text('标题完整展开 + 视频信息栏')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 标题 + 箭头
            GestureDetector(
              onTap: _toggleExpand,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 标题区域
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final textSpan = TextSpan(
                              text: titleText,
                              style: titleStyle,
                            );
                            final textDir = Directionality.of(context);

                            // 单行 & 全文高度计算
                            final tpSingle = TextPainter(
                              text: textSpan,
                              textDirection: textDir,
                              maxLines: 1,
                              ellipsis: '...',
                            )..layout(maxWidth: maxWidth);

                            final tpFull = TextPainter(
                              text: textSpan,
                              textDirection: textDir,
                            )..layout(maxWidth: maxWidth);

                            final singleHeight = tpSingle.height;
                            final fullHeight = tpFull.height;
                            final t = _expandCurve.value;
                            final currentHeight =
                                singleHeight + (fullHeight - singleHeight) * t;
                            return Stack(
                              children: [
                                SizedBox(
                                  height: currentHeight,
                                  child: ClipRect(
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: SizedBox(
                                        height: fullHeight,
                                        child: Text(
                                          titleText,
                                          style: titleStyle,
                                          softWrap: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  /// 箭头动画
                  AnimatedBuilder(
                    animation: _arrowAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _arrowAnimation.value,
                        child: const Icon(Icons.keyboard_arrow_down, size: 28),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            /// 视频信息栏（永远显示，不受折叠控制）
            Row(
              children: [
                Icon(
                  Icons.play_circle_fill,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(viewCount, style: infoStyle),
                const SizedBox(width: 12),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 15,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(danmakuCount, style: infoStyle),
                const SizedBox(width: 12),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(publishDate, style: infoStyle),
              ],
            ),

            const SizedBox(height: 6),

            /// 简介部分（随展开动画变化）
            SizeTransition(
              sizeFactor: _expandCurve,
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  children: [
                    Text(descriptionText, style: const TextStyle(fontSize: 15)),
                    SizedBox(height: 6),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
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

void main() => runApp(MaterialApp(home: WashingMachinePage()));
