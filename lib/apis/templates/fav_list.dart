import 'package:bili_tracker/models/saved.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fav_list.g.dart';

@JsonSerializable()
class FavList {
  @JsonKey(name: 'code')
  int code;

  @JsonKey(name: 'message')
  String message;

  @JsonKey(name: 'data')
  Data data;

  FavList({required this.code, required this.message, required this.data});

  factory FavList.fromJson(Map<String, dynamic> json) =>
      _$FavListFromJson(json);
}

@JsonSerializable()
class Data {
  @JsonKey(name: 'info')
  Info info;

  @JsonKey(name: 'medias')
  List<Media> medias;

  @JsonKey(name: 'has_more')
  bool hasMore;

  Data({
    required this.info,
    required this.medias,
    this.hasMore = true,
  });

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@JsonSerializable()
class Info {
  @JsonKey(name: 'id')
  int id;

  @JsonKey(name: 'title')
  String title;

  @JsonKey(name: 'cover')
  String cover;

  @JsonKey(name: 'media_count')
  int mediaCount;

  Info({required this.id, required this.title, required this.cover, required this.mediaCount});

  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);
}

@JsonSerializable()
class Media {
  @JsonKey(name: 'id')
  int id;

  @JsonKey(name: 'type')
  int type;

  Status? isSaved;

  @JsonKey(name: 'title')
  String title;

  @JsonKey(name: 'cover')
  String cover;

  @JsonKey(name: 'duration')
  int duration;

  @JsonKey(name: 'attr')
  int attr;

  @JsonKey(name: 'page')
  int page;

  @JsonKey(name: 'upper')
  Upper upper;

  @JsonKey(name: 'cnt_info')
  CntInfo cntInfo;

  Media({
    required this.id,
    required this.type,
    required this.title,
    required this.cover,
    required this.duration,
    required this.attr,
    required this.page,
    required this.upper,
    required this.cntInfo,
  });

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);
}

@JsonSerializable()
class Upper {
  @JsonKey(name: 'mid')
  int mid;
  @JsonKey(name: 'name')
  String name;
  @JsonKey(name: 'face')
  String face;

  Upper({required this.mid, required this.name, required this.face});

  factory Upper.fromJson(Map<String, dynamic> json) => _$UpperFromJson(json);
}

@JsonSerializable()
class CntInfo {
  @JsonKey(name: 'play')
  int play;
  @JsonKey(name: 'danmaku')
  int danmaku;
  @JsonKey(name: 'collect')
  int reply;

  CntInfo({required this.play, required this.danmaku, required this.reply});

  factory CntInfo.fromJson(Map<String, dynamic> json) =>
      _$CntInfoFromJson(json);
}
