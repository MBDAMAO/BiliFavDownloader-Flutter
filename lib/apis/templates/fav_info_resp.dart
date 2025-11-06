// fav_info_resp.dart
import 'package:json_annotation/json_annotation.dart';

part 'fav_info_resp.g.dart';

/// 根对象
@JsonSerializable()
class FavInfoResp {
  @JsonKey(name: 'code')
  int code;

  @JsonKey(name: 'message')
  String message;

  @JsonKey(name: 'data')
  FavFolderMeta data;

  FavInfoResp({required this.code, required this.message, required this.data});

  factory FavInfoResp.fromJson(Map<String, dynamic> json) =>
      _$FavInfoRespFromJson(json);

  Map<String, dynamic> toJson() => _$FavInfoRespToJson(this);
}

/// data 对象
@JsonSerializable()
class FavFolderMeta {
  @JsonKey(name: 'id')
  int id; // 完整收藏夹 id（mlid）

  @JsonKey(name: 'fid')
  int fid; // 原始收藏夹 id

  @JsonKey(name: 'mid')
  int mid; // 创建者 mid

  @JsonKey(name: 'attr')
  int attr; // 属性位

  @JsonKey(name: 'title')
  String title; // 收藏夹标题

  @JsonKey(name: 'cover')
  String cover; // 封面 url

  @JsonKey(name: 'upper')
  Upper upper; // 创建者信息

  @JsonKey(name: 'cover_type')
  int coverType;

  @JsonKey(name: 'cnt_info')
  CntInfo cntInfo; // 状态数

  @JsonKey(name: 'type')
  int type;

  @JsonKey(name: 'intro')
  String intro; // 备注

  @JsonKey(name: 'ctime')
  int ctime; // 创建时间戳

  @JsonKey(name: 'mtime')
  int mtime; // 收藏时间戳

  @JsonKey(name: 'state')
  int state;

  @JsonKey(name: 'fav_state')
  int favState; // 当前用户是否收藏该收藏夹

  @JsonKey(name: 'like_state')
  int likeState; // 当前用户是否点赞

  @JsonKey(name: 'media_count')
  int mediaCount; // 收藏夹内内容数量

  FavFolderMeta({
    required this.id,
    required this.fid,
    required this.mid,
    required this.attr,
    required this.title,
    required this.cover,
    required this.upper,
    required this.coverType,
    required this.cntInfo,
    required this.type,
    required this.intro,
    required this.ctime,
    required this.mtime,
    required this.state,
    required this.favState,
    required this.likeState,
    required this.mediaCount,
  });

  factory FavFolderMeta.fromJson(Map<String, dynamic> json) =>
      _$FavFolderMetaFromJson(json);

  Map<String, dynamic> toJson() => _$FavFolderMetaToJson(this);
}

/// upper 对象
@JsonSerializable()
class Upper {
  @JsonKey(name: 'mid')
  int mid;

  @JsonKey(name: 'name')
  String name;

  @JsonKey(name: 'face')
  String face;

  @JsonKey(name: 'followed')
  bool followed;

  @JsonKey(name: 'vip_type')
  int vipType;

  @JsonKey(name: 'vip_statue')
  int vipStatue;

  Upper({
    required this.mid,
    required this.name,
    required this.face,
    required this.followed,
    required this.vipType,
    required this.vipStatue,
  });

  factory Upper.fromJson(Map<String, dynamic> json) => _$UpperFromJson(json);

  Map<String, dynamic> toJson() => _$UpperToJson(this);
}

/// cnt_info 对象
@JsonSerializable()
class CntInfo {
  @JsonKey(name: 'collect')
  int collect;

  @JsonKey(name: 'play')
  int play;

  @JsonKey(name: 'thumb_up')
  int thumbUp;

  @JsonKey(name: 'share')
  int share;

  CntInfo({required this.collect, required this.play, required this.thumbUp, required this.share});

  factory CntInfo.fromJson(Map<String, dynamic> json) =>
      _$CntInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CntInfoToJson(this);
}