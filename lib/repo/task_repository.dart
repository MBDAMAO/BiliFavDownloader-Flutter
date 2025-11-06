import '../models/task.dart';
import '../objectbox.g.dart';

class TaskRepository {
  final Store store;
  final Box<Task> taskBox;

  TaskRepository(this.store) : taskBox = store.box<Task>();

  Future<List<Task>> findAllTasks() async {
    List<Task> tasks = taskBox.getAll();
    tasks.sort((a, b) {
      return a.createTime.compareTo(b.createTime);
    });
    return tasks;
  }

  Task? findTaskById(int id) {
    return taskBox.query(Task_.id.equals(id)).build().findFirst();
  }

  List<Task> findTasksByType(TaskType type) {
    return taskBox.query(Task_.dbTaskType.equals(type.index)).build().find();
  }

  void updateTaskQualityById(
    int taskId,
    String videoQuality,
    String audioQuality,
  ) {
    final task = findTaskById(taskId);
    if (task != null) {
      task.videoQuality = videoQuality;
      task.audioQuality = audioQuality;
      taskBox.put(task);
    }
  }

  void updateTaskMessageById(int taskId, String message) {
    final task = findTaskById(taskId);
    if (task != null) {
      task.message = message;
      taskBox.put(task);
    }
  }

  void insertTask(Task task) {
    taskBox.put(task);
  }

  void batchInsertTask(List<Task> tasks) {
    taskBox.putMany(tasks);
  }

  void updateTask(Task task) {
    taskBox.put(task);
  }

  void updateTaskStatusById(int taskId, TaskStatus status) {
    final task = findTaskById(taskId);
    if (task != null) {
      task.status = status;
      taskBox.put(task);
    }
  }

  void updateTaskPhaseById(int taskId, TaskPhase phase) {
    final task = findTaskById(taskId);
    if (task != null) {
      task.phase = phase;
      taskBox.put(task);
    }
  }

  void updateTaskStatusByIds(List<int> ids, TaskStatus status) {
    final tasks = ids.map(findTaskById).whereType<Task>().toList();
    for (final task in tasks) {
      task.status = status;
    }
    taskBox.putMany(tasks);
  }

  void updateTaskProgressById(int taskId, int progress) {
    final task = findTaskById(taskId);
    if (task != null) {
      task.progress = progress;
      taskBox.put(task);
    }
  }

  void deleteTask(Task task) {
    taskBox.remove(task.id);
  }

  void deleteAllTask() {
    taskBox.removeAll();
  }

  void deleteTaskById(int id) {
    taskBox.remove(id);
  }

  void deleteTasksByIds(List<int> ids) {
    for (final id in ids) {
      taskBox.remove(id);
    }
  }

  void resetRunningTasks() {
    final query =
        taskBox
            .query(
              Task_.dbTaskStatus.equals(TaskStatus.running.index) |
                  Task_.dbTaskStatus.equals(TaskStatus.enqueued.index),
            )
            .build();

    final tasks = query.find();
    for (final task in tasks) {
      task.status = TaskStatus.paused;
    }
    taskBox.putMany(tasks);
  }
}
