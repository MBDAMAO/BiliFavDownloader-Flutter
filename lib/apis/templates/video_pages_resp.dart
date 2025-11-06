import 'package:json_annotation/json_annotation.dart';

part 'video_pages_resp.g.dart';

@JsonSerializable()
class VideoPagesResp {
  @JsonKey(name: 'code')
  int code;

  @JsonKey(name: 'message')
  String message;

  @JsonKey(name: 'data')
  List<VideoPageData> data;

  VideoPagesResp({required this.code, required this.message, required this.data});

  factory VideoPagesResp.fromJson(Map<String, dynamic> json) =>
      _$VideoPagesRespFromJson(json);
}

@JsonSerializable()
class VideoPageData {
  @JsonKey(name: 'cid')
  int cid;

  @JsonKey(name: 'page')
  int page;

  @JsonKey(name: 'part')
  String part;

  @JsonKey(name: 'duration')
  int duration;

  @JsonKey(name: 'from')
  String from;

  @JsonKey(name: 'vid')
  String vid;

  @JsonKey(name: 'first_frame')
  String firstFrame;

  @JsonKey(name: 'weblink')
  String weblink;

  VideoPageData({
    required this.cid,
    required this.page,
    required this.part,
    required this.duration,
    required this.from,
    required this.vid,
    required this.firstFrame,
    required this.weblink,
  });

  factory VideoPageData.fromJson(Map<String, dynamic> json) => _$VideoPageDataFromJson(json);
}

