// all_my_fav_resp.dart
import 'package:json_annotation/json_annotation.dart';

part 'all_my_fav_resp.g.dart';

/// 根对象
@JsonSerializable()
class AllMyFavResp {
  @JsonKey(name: 'code')
  int code;

  @JsonKey(name: 'message')
  String message;

  @JsonKey(name: 'data')
  AllMyFavData data;

  AllMyFavResp({required this.code, required this.message, required this.data});

  factory AllMyFavResp.fromJson(Map<String, dynamic> json) =>
      _$AllMyFavRespFromJson(json);

  Map<String, dynamic> toJson() => _$AllMyFavRespToJson(this);
}

/// data 对象
@JsonSerializable()
class AllMyFavData {
  @JsonKey(name: 'count')
  int count; // 该用户创建的收藏夹总数

  @JsonKey(name: 'list')
  List<MyFavFolder> list; // 收藏夹列表

  AllMyFavData({required this.count, required this.list});

  factory AllMyFavData.fromJson(Map<String, dynamic> json) =>
      _$AllMyFavDataFromJson(json);

  Map<String, dynamic> toJson() => _$AllMyFavDataToJson(this);
}

/// list 数组中的单个收藏夹对象
@JsonSerializable()
class MyFavFolder {
  @JsonKey(name: 'id')
  int id; // 完整收藏夹 id（mlid）

  @JsonKey(name: 'fid')
  int fid; // 原始收藏夹 id

  @JsonKey(name: 'mid')
  int mid; // 创建者 mid

  @JsonKey(name: 'attr')
  int attr; // 二进制属性位

  @JsonKey(name: 'title')
  String title; // 收藏夹标题

  @JsonKey(name: 'fav_state')
  int favState; // 目标资源是否已在此收藏夹：1 存在 0 不存在

  @JsonKey(name: 'media_count')
  int mediaCount; // 收藏夹内媒体数量

  MyFavFolder({
    required this.id,
    required this.fid,
    required this.mid,
    required this.attr,
    required this.title,
    required this.favState,
    required this.mediaCount,
  });

  factory MyFavFolder.fromJson(Map<String, dynamic> json) =>
      _$MyFavFolderFromJson(json);

  Map<String, dynamic> toJson() => _$MyFavFolderToJson(this);
}