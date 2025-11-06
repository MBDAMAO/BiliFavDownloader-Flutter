import 'package:bili_tracker/di.dart';
import 'package:bili_tracker/pages/downloads/task_detail_page.dart';
import 'package:bili_tracker/providers/download_tasks_provider.dart';
import 'package:bili_tracker/providers/settings_provider.dart';
import 'package:bili_tracker/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../widgets/add_download_dialog.dart';
import '../../widgets/task_item.dart';
import '../../widgets/task_options_modal.dart';
import '../../widgets/local_file_list.dart';
import '../../widgets/tip_with_choice.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  DownloadScreenState createState() => DownloadScreenState();
}

class DownloadScreenState extends State<DownloadPage>
    with SingleTickerProviderStateMixin {
  late Logger logger;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() async {
    logger = await MyLogger.create();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Consumer<DownloadTasksProvider>(
        builder: (context, downloadTasksProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(
                downloadTasksProvider.runningTasks +
                    downloadTasksProvider.pendingTasks +
                    downloadTasksProvider.pausedTasks,
                'current',
              ),
              _buildTaskList(downloadTasksProvider.completedTasks, 'completed'),
              _buildTaskList(downloadTasksProvider.failedTasks, 'failed'),
              LocalFilesList(),
            ],
          );
        },
      ),
    );
  }

  bool _privateMode = false;

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('下载任务'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AddDownloadDialog(),
            );
          },
        ),
        IconButton(
          icon:
              _privateMode
                  ? const Icon(Icons.visibility_off)
                  : const Icon(Icons.visibility), // 眼镜图标
          onPressed: () {
            // 在这里切换隐藏/显示任务名称的状态
            setState(() => _privateMode = !_privateMode);
          },
        ),
        PopupMenuButton(
          itemBuilder:
              (context) => [
                // const PopupMenuItem(value: 1, child: Text("清除所有任务")),
                // const PopupMenuItem(value: 2, child: Text("清除当前任务")),
                // const PopupMenuItem(value: 3, child: Text("清除已完成任务")),
                // const PopupMenuItem(value: 4, child: Text("清除失败任务")),
              ],
          onSelected: (value) {
            // 处理菜单项选择
            switch (value) {
              case 1:
                // 选项1的操作
                break;
              case 2:
                // 选项2的操作
                break;
              case 3:
                // 选项3的操作
                break;
              case 4:
                // 选项4的操作
                break;
            }
          },
          icon: const Icon(Icons.more_vert), // 三点图标
        ),
      ],
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      dividerColor: Colors.transparent,
      controller: _tabController,
      tabs: [
        Tab(text: '当前'),
        Tab(text: '已完成'),
        Tab(text: '失败'),
        const Tab(text: '本地'),
      ],
    );
  }

  Widget _buildTaskList(List<Task> tasks, String type) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '共 ${tasks.length} 个',
          style: TextStyle(
            fontSize: 13,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: 30,
        actionsPadding: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (type == 'current')
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.5), // 调整内边距
                minimumSize: Size(0, 0), // 移除最小尺寸限制
              ),
              onPressed: () {},
              child: GestureDetector(
                onTap: () {
                  _showDownloadConcurrencyModal(context);
                },
                child: Row(
                  children: [
                    Text(
                      '同时下载：',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Consumer<SettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        return Text(
                          '${settingsProvider.settings.maxTaskConcurrency}个',
                          style: TextStyle(
                            fontSize: 13,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (type == 'current')
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.5), // 调整内边距
                minimumSize: Size(0, 0), // 移除最小尺寸限制
              ),
              onPressed: () {
                getIt<DownloadTasksProvider>().continueAllTasks();
              },
              child: Text('全部继续', style: TextStyle(fontSize: 13)),
            ),
          if (type == 'completed')
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.5), // 调整内边距
                minimumSize: Size(0, 0), // 移除最小尺寸限制
              ),
              onPressed: () {
                getIt<DownloadTasksProvider>().clearCompletedTasks();
              },
              child: Text('清空', style: TextStyle(fontSize: 13)),
            ),
          if (type == 'failed')
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.5), // 调整内边距
                minimumSize: Size(0, 0), // 移除最小尺寸限制
              ),
              onPressed: () {
                getIt<DownloadTasksProvider>().retryAllFailedTasks();
              },
              child: Text('全部重试', style: TextStyle(fontSize: 13)),
            ),
          SizedBox(width: 10),
        ],
      ),
      body:
          tasks.isEmpty
              ? const Center(
                child: // 空盒子
                    SizedBox(
                  height: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty, size: 40),
                      SizedBox(height: 10),
                      Text('暂无任务'),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: tasks.length,
                itemBuilder:
                    (context, index) => DownloadTaskItem(
                      privateMode: _privateMode,
                      task: tasks[index],
                      onPause: _pauseDownload,
                      onResume: _resumeDownload,
                      onRetry: _resumeDownload,
                      onRemove: _removeDownload,
                      onTap:
                          (task) => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      TaskDetailPage(taskId: tasks[index].id),
                            ),
                          ),

                      onLongPress:
                          (task) =>
                              _showTaskOptionsModal(context, tasks[index]),
                    ),
              ),
    );
  }

  // 弹出底部菜单的方法
  void _showDownloadConcurrencyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 仅占用必要高度
              children: [
                Text(
                  "选择同时下载的任务数",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // 四个选项按钮
                Wrap(
                  spacing: 8, // 按钮间距
                  children:
                      [1, 2, 3, 4].map((count) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(60, 40), // 按钮大小
                          ),
                          onPressed: () {
                            Navigator.pop(context); // 关闭菜单
                            _updateConcurrentDownloads(count); // 更新并发数
                          },
                          child: Text("$count个"),
                        );
                      }).toList(),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _updateConcurrentDownloads(int count) {
    getIt<SettingsProvider>().changeMaxConcurrency(count);
  }

  void _showTaskOptionsModal(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => TaskOptionsModal(
            task: task,
            onOpenFile: () => (),
            onPause: () async => await _pauseDownload(task.id),
            onResume: () async => await _resumeDownload(task.id),
            onRetry: () async => await _resumeDownload(task.id),
            onOpenFolder: () => (),
            onRemove: () async => await _removeDownload(task.id),
          ),
    );
  }

  Future<void> _pauseDownload(int taskId) async {
    await getIt<DownloadTasksProvider>().pauseTask(taskId);
  }

  Future<void> _resumeDownload(int taskId) async {
    await getIt<DownloadTasksProvider>().resumeTask(taskId);
  }

  Future<void> _removeDownload(int? taskId) async {
    bool choice = await showTipWithChoice(
      context,
      choiceKey: 'delete_task',
      content: Text('确定要删除此任务吗？'),
    );
    if (!choice) return;
    if (taskId == null) return;
    await getIt<DownloadTasksProvider>().cancelTask(taskId);
  }
}

Future navigateToDownloadPage(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (context) => DownloadPage()));
}
