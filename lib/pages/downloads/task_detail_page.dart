import 'package:flutter/material.dart';
import '../../repo/task_repository.dart';
import '../../di.dart';
import '../../models/task.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Task? task;
  bool isLoading = true;
  String errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _filenameController;
  late TextEditingController _savePathController;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDetail();
  }

  @override
  void dispose() {
    _filenameController.dispose();
    _savePathController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskDetail() async {
    try {
      final loadedTask = getIt<TaskRepository>().findTaskById(widget.taskId);

      if (mounted) {
        setState(() {
          task = loadedTask;
          _filenameController = TextEditingController(text: task?.filename);
          _savePathController = TextEditingController(text: task?.savePath);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = '加载任务详情失败: $e';
        });
      }
    }
  }

  Future<void> _saveChanges() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("任务详情"),
        actions: [
          if (!isLoading && task != null && !isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = '';
                isEditing = false;
              });
              _loadTaskDetail();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadTaskDetail, child: const Text('重试')),
          ],
        ),
      );
    }

    if (task == null) {
      return const Center(child: Text('未找到任务详情'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: isEditing ? _buildEditForm() : _buildDetailView(),
    );
  }

  Widget _buildDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem('任务ID', task?.id.toString() ?? '未知'),
        _buildDetailItem('任务名称', task?.filename ?? '未命名'),
        _buildDetailItem('保存路径', task?.savePath ?? '未设置'),
        _buildDetailItem('创建时间', task?.createTime.toString() ?? '未知'),
        _buildDetailItem('状态', _getStatusText(task?.status)),
        _buildDetailItem('阶段', _getPhaseText(task?.phase)),
        if (task?.progress != null)
          _buildDetailItem('进度', '${task?.progress}%'),
        if (task?.message != null)
          _buildDetailItem('描述', task?.message ?? 'none'),
        if (task?.speed != null) _buildDetailItem('速度', task?.speed ?? ''),
        const SizedBox(height: 20),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _filenameController,
            decoration: const InputDecoration(
              labelText: '任务名称',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入任务名称';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _savePathController,
            decoration: const InputDecoration(
              labelText: '保存路径',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入保存路径';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(onPressed: _saveChanges, child: const Text('保存')),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    isEditing = false;
                  });
                },
                child: const Text('取消'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: 20),
        ],
      ),
    );
  }

  String _getStatusText(TaskStatus? status) {
    if (status == null) return '未知';
    switch (status) {
      case TaskStatus.enqueued:
        return '排队中';
      case TaskStatus.running:
        return '运行中';
      case TaskStatus.complete:
        return '已完成';
      case TaskStatus.failed:
        return '失败';
      case TaskStatus.paused:
        return '已暂停';
      case TaskStatus.unknown:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _getPhaseText(TaskPhase? phase) {
    if (phase == null) return '未知';
    switch (phase) {
      case TaskPhase.undefined:
        return '未定义';
      case TaskPhase.acquiringInfo:
        return '获取信息中';
      case TaskPhase.acquiringStream:
        return '获取流信息中';
      case TaskPhase.downloadingAudio:
        return '下载音频中';
      case TaskPhase.downloadingVideo:
        return '下载视频中';
      case TaskPhase.merging:
        return '合并中';
      case TaskPhase.completed:
        return '已完成';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (task?.status == TaskStatus.enqueued ||
            task?.status == TaskStatus.paused)
          ElevatedButton(
            onPressed: () {
              // 执行任务的逻辑
            },
            child: const Text('开始任务'),
          ),
        if (task?.status == TaskStatus.running)
          ElevatedButton(
            onPressed: () {
              // 暂停任务的逻辑
            },
            child: const Text('暂停任务'),
          ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () {
            // 其他操作
          },
          child: const Text('更多操作'),
        ),
      ],
    );
  }
}
