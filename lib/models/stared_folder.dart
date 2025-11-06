import 'package:objectbox/objectbox.dart';

@Entity()
class StaredFolder {
  @Id()
  int id;

  @Index()
  final int folderId;

  String cover;

  final String name;

  String ownerName;

  String ownerAvatar;

  @Property()
  @Index()
  final String? createTime;

  StaredFolder({
    required this.ownerName,
    required this.ownerAvatar,
    this.id = 0,
    required this.cover,
    this.createTime,
    required this.folderId,
    required this.name,
  });

  StaredFolder copyWith({
    int? id,
    int? folderId,
    String? name,
    String? createTime,
    String? cover,
    String? ownerName,
    String? ownerAvatar,
  }) {
    return StaredFolder(
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      id: id ?? this.id,
      cover: cover ?? this.cover,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      createTime: createTime ?? this.createTime,
    );
  }
}