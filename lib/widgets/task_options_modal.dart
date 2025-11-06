import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskOptionsModal extends StatelessWidget {
  final Task task;
  final Function() onOpenFile;
  final Function() onPause;
  final Function() onResume;
  final Function() onRetry;
  final Function() onOpenFolder;
  final Function() onRemove;

  const TaskOptionsModal({
    super.key,
    required this.task,
    required this.onOpenFile,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
    required this.onOpenFolder,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Task Details'),
            subtitle: Text(
              '${task.filename}\nStatus: ${task.status}\nProgress: ${task.progress}% phase: ${task.phase}',
            ),
          ),
          const Divider(),
          if (task.status == TaskStatus.complete)
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Open Downloaded File'),
              onTap: onOpenFile,
            ),
          if (task.status == TaskStatus.running)
            ListTile(
              leading: const Icon(Icons.pause),
              title: const Text('Pause Download'),
              onTap: onPause,
            ),
          if (task.status == TaskStatus.paused)
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Resume Download'),
              onTap: onResume,
            ),
          if (task.status == TaskStatus.failed)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Retry Download'),
              onTap: onRetry,
            ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Open Folder'),
            onTap: onOpenFolder,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Remove Download'),
            onTap: onRemove,
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
