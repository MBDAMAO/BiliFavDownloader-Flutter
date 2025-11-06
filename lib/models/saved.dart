import 'package:objectbox/objectbox.dart';
enum Status {
  completed,
  enqueued,
  unknown
}

@Entity()
class Saved {
  @Id()
  int id;

  @Index()
  final int aid;

  final int cid;

  @Transient()
  Status? status;

  int? get dbStatue {
    _ensureStableEnumValues();
    return status?.index;
  }
  set dbStatue(int? value) {
    _ensureStableEnumValues();
    if (value == null) {
      status = null;
    } else {
      status = Status.values[value];
      status = value >= 0 && value < Status.values.length
          ? Status.values[value]
          : Status.unknown;
    }
  }
  void _ensureStableEnumValues() {
    assert(Status.completed.index == 0);
    assert(Status.enqueued.index == 1);
  }

  @Index()
  final String? createTime;

  String? get aidCidKey => '$aid::$cid';

  Saved({
    this.id = 0,
    required this.createTime,
    required this.aid,
    required this.cid,
  });
  Saved copyWith({
    int? id,
    int? aid,
    int? cid,
    String? createTime,
  }) {
    return Saved(
      id: id ?? this.id,
      aid: aid ?? this.aid,
      cid: cid ?? this.cid,
      createTime: createTime ?? this.createTime,
    );
  }
}
