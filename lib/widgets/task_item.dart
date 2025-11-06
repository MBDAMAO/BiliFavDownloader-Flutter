import 'package:bili_tracker/utils/ext.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import './components.dart';

class DownloadTaskItem extends StatefulWidget {
  final Task task;
  final bool privateMode;
  final Function(int id) onPause;
  final Function(int id) onResume;
  final Function(int id) onRetry;
  final Function(int id) onRemove;
  final Function(int id) onLongPress;
  final Function(int id) onTap;

  const DownloadTaskItem({
    super.key,
    required this.privateMode,
    required this.task,
    required this.onTap,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
    required this.onRemove,
    required this.onLongPress,
  });

  @override
  State<DownloadTaskItem> createState() => _DownloadTaskItemState();
}

class _DownloadTaskItemState extends State<DownloadTaskItem> {
  bool _isProcessing = false;

  Future<void> _handleTapAction() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final status = widget.task.status;
      if (status == TaskStatus.running || status == TaskStatus.enqueued) {
        await widget.onPause(widget.task.id);
      } else if (status == TaskStatus.paused) {
        await widget.onResume(widget.task.id);
      } else if (status == TaskStatus.failed) {
        await widget.onRetry(widget.task.id);
      }
    } catch (e) {
      debugPrint("Tap action failed: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRemoveAction() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onRemove(widget.task.id);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTapAction,
      onLongPress: () => widget.onLongPress(widget.task.id),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (!widget.privateMode) _buildCoverImage(),
                const SizedBox(width: 12),
                Expanded(child: _buildTaskInfo(context)),
              ],
            ),
          ),
          if (_isProcessing)
            const Positioned(
              right: 16,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    ).cardx;
  }

  Widget _buildCoverImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          image: DecorationImage(
            image:
                widget.task.cover != null
                    ? NetworkImage(widget.task.cover!)
                    : const AssetImage('assets/default_cover.png')
                        as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.privateMode
                    ? widget.task.aid.toString()
                    : widget.task.filename ?? 'Unknown file',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _handleRemoveAction,
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (widget.task.status == TaskStatus.complete ||
                widget.task.status == TaskStatus.failed) ...[
              _buildStatusTag(context),
              const SizedBox(width: 6),
            ],
            if (widget.task.status != TaskStatus.enqueued &&
                widget.task.status != TaskStatus.complete &&
                widget.task.status != TaskStatus.paused) ...[
              _buildPhaseTag(context),
              const SizedBox(width: 6),
            ],
            if (widget.task.videoQuality != null &&
                widget.task.audioQuality != null) ...[
              _buildQualityTag(context),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SmoothColorProgressIndicator(
          progress: widget.task.progress,
          status: widget.task.status ?? TaskStatus.unknown,
          successColor: Theme.of(context).colorScheme.tertiary,
          errorColor: Theme.of(context).colorScheme.error,
          downloadingColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        if (widget.task.status == TaskStatus.running &&
            widget.task.phase == TaskPhase.merging)
          Text(
            '${widget.task.progress}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if ((widget.task.status == TaskStatus.running ||
                widget.task.status == TaskStatus.enqueued ||
                widget.task.status == TaskStatus.paused) &&
            widget.task.phase != TaskPhase.merging &&
            widget.task.current != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.task.current}/${widget.task.total}',
                style: const TextStyle(fontSize: 12),
              ),
              if (widget.task.status == TaskStatus.running)
                Text(
                  '${widget.task.speed}',
                  style: const TextStyle(fontSize: 12),
                ),
              if (widget.task.status == TaskStatus.paused)
                Text('已暂停', style: Theme.of(context).textTheme.bodySmall),
              if (widget.task.status == TaskStatus.enqueued)
                Text('等待中', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }

  Widget _buildQualityTag(BuildContext context) {
    return _buildTag(
      '${widget.task.videoQuality} / ${widget.task.audioQuality}',
      Colors.grey.withAlpha(50),
      Colors.grey,
    );
  }

  Widget _buildStatusTag(BuildContext context) {
    final status = widget.task.status;
    final Color backgroundColor;
    final Color textColor;
    final String text;

    switch (status) {
      case TaskStatus.enqueued:
        backgroundColor = Colors.cyanAccent.withAlpha(50);
        textColor = Colors.cyanAccent;
        text = '等待';
        break;
      case TaskStatus.running:
        backgroundColor = Colors.blue.withAlpha(50);
        textColor = Colors.blue;
        text = '下载中';
        break;
      case TaskStatus.paused:
        backgroundColor = Colors.orange.withAlpha(50);
        textColor = Colors.orange;
        text = '暂停';
        break;
      case TaskStatus.failed:
        backgroundColor = Colors.red.withAlpha(50);
        textColor = Colors.red;
        text = '失败';
        break;
      case TaskStatus.complete:
        backgroundColor = Colors.green.withAlpha(50);
        textColor = Colors.green;
        text = '完成';
        break;
      default:
        backgroundColor = Colors.grey.withAlpha(50);
        textColor = Colors.grey;
        text = '未知';
    }

    return _buildTag(text, backgroundColor, textColor);
  }

  Widget _buildPhaseTag(BuildContext context) {
    final phase = widget.task.phase;
    Color backgroundColor;
    Color textColor;
    String text;

    switch (phase) {
      case TaskPhase.acquiringStream:
        backgroundColor = Colors.blue.withAlpha(50);
        textColor = Colors.blue;
        text = '获取流';
        break;
      case TaskPhase.downloadingAudio:
        backgroundColor = Colors.purple.withAlpha(50);
        textColor = Colors.purple;
        text = '下载音频';
        break;
      case TaskPhase.downloadingVideo:
        backgroundColor = Colors.teal.withAlpha(50);
        textColor = Colors.teal;
        text = '下载视频';
        break;
      case TaskPhase.merging:
        backgroundColor = Colors.yellow.withAlpha(50);
        textColor = Colors.yellow[800]!;
        text = '合并';
        break;
      case TaskPhase.completed:
        backgroundColor = Colors.green.withAlpha(50);
        textColor = Colors.green;
        text = '完成';
        break;
      default:
        backgroundColor = Colors.grey.withAlpha(50);
        textColor = Colors.grey;
        text = '等待';
    }

    return _buildTag(text, backgroundColor, textColor);
  }

  Widget _buildTag(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
