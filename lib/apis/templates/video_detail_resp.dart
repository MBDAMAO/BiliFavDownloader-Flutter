import 'package:json_annotation/json_annotation.dart';

part 'video_detail_resp.g.dart';

@JsonSerializable()
class VideoDetailResp {
  @JsonKey(name: 'code')
  int code;

  @JsonKey(name: 'message')
  String message;

  @JsonKey(name: 'data')
  Data data;

  VideoDetailResp({
    required this.code,
    required this.message,
    required this.data,
  });

  factory VideoDetailResp.fromJson(Map<String, dynamic> json) =>
      _$VideoDetailRespFromJson(json);
}

@JsonSerializable()
class Data {
  @JsonKey(name: 'bvid')
  String bvid;

  @JsonKey(name: 'aid')
  int aid;

  @JsonKey(name: 'videos')
  int videos;

  @JsonKey(name: 'pic')
  String pic;

  @JsonKey(name: 'title')
  String title;

  @JsonKey(name: 'desc')
  String desc;

  @JsonKey(name: 'pubdate')
  int pubdate;

  @JsonKey(name: 'ctime')
  int ctime;

  @JsonKey(name: 'duration')
  int duration;

  @JsonKey(name: 'owner')
  Owner owner;

  @JsonKey(name: 'stat')
  Stat stat;

  @JsonKey(name: 'cid')
  int cid;

  Data({
    required this.aid,
    required this.bvid,
    required this.videos,
    required this.pic,
    required this.title,
    required this.desc,
    required this.pubdate,
    required this.ctime,
    required this.duration,
    required this.owner,
    required this.stat,
    required this.cid,
  });

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@JsonSerializable()
class Owner {
  @JsonKey(name: 'mid')
  int mid;
  @JsonKey(name: 'name')
  String name;
  @JsonKey(name: 'face')
  String face;

  Owner({required this.mid, required this.name, required this.face});

  factory Owner.fromJson(Map<String, dynamic> json) => _$OwnerFromJson(json);
}

@JsonSerializable()
class Stat {
  @JsonKey(name: 'aid')
  int aid;
  @JsonKey(name: 'view')
  int view;
  @JsonKey(name: 'danmaku')
  int danmaku;
  @JsonKey(name: 'reply')
  int reply;
  @JsonKey(name: 'favorite')
  int favorite;
  @JsonKey(name: 'coin')
  int coin;
  @JsonKey(name: 'share')
  int share;
  @JsonKey(name: 'now_rank')
  int nowRank;
  @JsonKey(name: 'his_rank')
  int hisRank;
  @JsonKey(name: 'like')
  int like;
  @JsonKey(name: 'dislike')
  int dislike;
  @JsonKey(name: 'evaluation')
  String evaluation;

  Stat({
    required this.aid,
    required this.view,
    required this.danmaku,
    required this.reply,
    required this.favorite,
    required this.coin,
    required this.share,
    required this.like,
    required this.dislike,
    required this.evaluation,
    required this.nowRank,
    required this.hisRank,
  });

  factory Stat.fromJson(Map<String, dynamic> json) => _$StatFromJson(json);
}
