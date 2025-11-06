import 'package:objectbox/objectbox.dart';

@Entity()
class Task {
  @Id()
  int id;

  @Transient()
  TaskStatus? status;

  int? get dbTaskStatus {
    _ensureStableEnumValues();
    return status?.index;
  }

  set dbTaskStatus(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      status = null;
    } else {
      status = TaskStatus.values[value];
      status = value >= 0 && value < TaskStatus.values.length
          ? TaskStatus.values[value]
          : TaskStatus.unknown;
    }
  }

  void _ensureStableEnumValues() {
    assert(TaskStatus.enqueued.index == 0);
    assert(TaskStatus.running.index == 1);
    assert(TaskStatus.complete.index == 2);
    assert(TaskStatus.failed.index == 3);
    assert(TaskStatus.paused.index == 4);
  }

  int? progress;

  @Transient()
  TaskType? type;

  int? get dbTaskType {
    _ensureStableEnumValues();
    return type?.index;
  }

  set dbTaskType(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      type = null;
    } else {
      type = TaskType.values[value];
      type = value >= 0 && value < TaskType.values.length
          ? TaskType.values[value]
          : TaskType.downloadAllPages;
    }
  }

  String? filename;
  String? cover;

  @Property()
  String? savePath;

  @Transient()
  TaskPhase? phase;

  int? get dbTaskPhase {
    _ensureStableEnumValues();
    return phase?.index;
  }

  set dbTaskPhase(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      phase = null;
    } else {
      phase = TaskPhase.values[value];
      phase = value >= 0 && value < TaskPhase.values.length
          ? TaskPhase.values[value]
          : TaskPhase.undefined;
    }
  }

  @Property()
  String? videoQuality;

  @Property()
  String? audioQuality;

  String? metadata;

  final int aid;

  int? cid;
  String? message;
  String? speed;

  String? current;
  String? total;

  @Property()
  @Index()
  String createTime;

  Task({
    this.id = 0,
    required this.createTime,
    required this.aid,
    this.cid,
    this.speed,
    this.message,
    this.metadata,
    this.progress,
    this.cover,
    this.videoQuality,
    this.audioQuality,
    this.current,
    this.total,
    required this.filename,
    this.savePath,
  }) {
    progress ??= 0;
  }
}

enum TaskStatus {
  enqueued,
  running,
  complete,
  failed,
  paused,
  unknown;
}

enum TaskPhase {
  undefined,
  acquiringInfo,
  acquiringStream,
  downloadingAudio,
  downloadingVideo,
  merging,
  completed;
}

enum TaskType {
  downloadAllPages,
  downloadSinglePage;
}