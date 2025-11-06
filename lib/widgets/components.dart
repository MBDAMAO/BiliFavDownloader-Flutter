import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/task.dart';

class SmoothColorProgressIndicator extends StatefulWidget {
  final int? progress;
  final TaskStatus status;
  final Color successColor;
  final Color errorColor;
  final Color downloadingColor;

  const SmoothColorProgressIndicator({
    required this.progress,
    required this.status,
    required this.successColor,
    required this.errorColor,
    required this.downloadingColor,
    super.key,
  });

  @override
  SmoothColorProgressIndicatorState createState() =>
      SmoothColorProgressIndicatorState();
}

class SmoothColorProgressIndicatorState
    extends State<SmoothColorProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _valueAnimation;
  late Color _currentColor;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = (widget.progress ?? 0).toDouble();
    _currentColor = _getColorForStatus(widget.status);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _setupAnimations();
  }

  @override
  void didUpdateWidget(SmoothColorProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.progress != widget.progress) {
      _setupAnimations();
    }
  }

  void _setupAnimations() {
    final endColor = _getColorForStatus(widget.status);
    final endValue = (widget.progress ?? 0).toDouble() / 100;

    _colorAnimation = ColorTween(
      begin: _currentColor,
      end: endColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _valueAnimation = Tween<double>(
        begin: _currentValue / 100,
        end: endValue,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {
          _currentColor = _colorAnimation.value ?? endColor;
          _currentValue = _valueAnimation.value * 100;
        });
      });

    _controller.reset();
    _controller.forward();
  }

  Color _getColorForStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.failed:
        return widget.errorColor;
      case TaskStatus.complete:
        return widget.successColor;
      default:
        return widget.downloadingColor;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: _valueAnimation.value,
      backgroundColor: Theme.of(context).colorScheme.surface,
      valueColor: AlwaysStoppedAnimation<Color>(_currentColor),
    );
  }
}

class EmptyStatus extends StatelessWidget {
  final String message;
  const EmptyStatus({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class ErrorStatus extends StatelessWidget {
  final String message;
  const ErrorStatus({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
/// 可折叠标题 + 固定信息栏 + 展开内容
Widget buildExpandableSection({
  required BuildContext context,
  required String title,
  required Widget infoBar,
  required Widget expandableContent,
}) {
  return _ExpandableSection(
    title: title,
    infoBar: infoBar,
    expandableContent: expandableContent,
  );
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final Widget infoBar;
  final Widget expandableContent;

  const _ExpandableSection({
    required this.title,
    required this.infoBar,
    required this.expandableContent,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection>
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
    _arrowAnimation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _expandCurve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
    final titleStyle = const TextStyle(
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 标题 + 箭头
        GestureDetector(
          onTap: _toggleExpand,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 标题裁剪动画区域
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return LayoutBuilder(builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final textSpan =
                      TextSpan(text: widget.title, style: titleStyle);
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
                                    widget.title,
                                    style: titleStyle,
                                    softWrap: true,
                                    overflow: (!_expanded && _controller.isDismissed)
                                        ? TextOverflow.ellipsis
                                        : TextOverflow.visible,
                                    maxLines: (!_expanded && _controller.isDismissed) ? 1 : null,

                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    });
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

        /// 永远显示的中间信息栏
        widget.infoBar,

        const SizedBox(height: 6),

        /// 可折叠内容区域
        SizeTransition(
          sizeFactor: _expandCurve,
          axisAlignment: -1,
          child: widget.expandableContent,
        ),
      ],
    );
  }
}
