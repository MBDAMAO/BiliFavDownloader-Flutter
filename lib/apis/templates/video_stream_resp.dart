import 'package:json_annotation/json_annotation.dart';

part 'video_stream_resp.g.dart';

@JsonSerializable()
class VideoStreamResp {
  @JsonKey(name: 'code')
  int code;

  @JsonKey(name: 'message')
  String message;

  @JsonKey(name: 'data')
  Data data;

  VideoStreamResp({
    required this.code,
    required this.message,
    required this.data,
  });

  factory VideoStreamResp.fromJson(Map<String, dynamic> json) =>
      _$VideoStreamRespFromJson(json);
}

@JsonSerializable()
class Data {
  @JsonKey(name: 'quality')
  int quality;

  @JsonKey(name: 'format')
  String format;

  @JsonKey(name: 'timelength')
  int timelength;

  @JsonKey(name: 'accept_description')
  List<String> acceptDescription;

  @JsonKey(name: 'accept_quality')
  List<int> acceptQuality;

  @JsonKey(name: 'video_codecid')
  int videoCodecid;

  @JsonKey(name: 'dash')
  Dash? dash;

  @JsonKey(name: 'durl')
  List<Durl>? durl;

  Data({
    required this.quality,
    required this.format,
    required this.timelength,
    required this.acceptDescription,
    required this.acceptQuality,
    required this.videoCodecid,
    this.dash,
    this.durl,
  });

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}

@JsonSerializable()
class Dash {
  @JsonKey(name: 'duration')
  int duration;

  @JsonKey(name: 'minBufferTime')
  double minBufferTime;

  @JsonKey(name: 'video')
  List<Video> video;

  @JsonKey(name: 'audio')
  List<Audio> audio;

  Dash({
    required this.duration,
    required this.minBufferTime,
    required this.video,
    required this.audio,
  });

  factory Dash.fromJson(Map<String, dynamic> json) => _$DashFromJson(json);
}

@JsonSerializable()
class Video {
  @JsonKey(name: 'id')
  int id;

  @JsonKey(name: 'baseUrl')
  String baseUrl;

  @JsonKey(name: 'backupUrl')
  List<String>? backupUrl;

  @JsonKey(name: 'bandwidth')
  int bandwidth;

  @JsonKey(name: 'codecid')
  int codecid;

  @JsonKey(name: 'frameRate')
  String frameRate;

  @JsonKey(name: 'height')
  int height;

  @JsonKey(name: 'width')
  int width;

  @JsonKey(name: 'mimeType')
  String mimeType;

  @JsonKey(name: 'sar')
  String sar;

  @JsonKey(name: 'startWithSap')
  int startWithSap;

  Video({
    required this.id,
    required this.baseUrl,
    this.backupUrl,
    required this.bandwidth,
    required this.codecid,
    required this.frameRate,
    required this.height,
    required this.width,
    required this.mimeType,
    required this.sar,
    required this.startWithSap,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}

@JsonSerializable()
class Audio {
  @JsonKey(name: 'id')
  int id;

  @JsonKey(name: 'baseUrl')
  String baseUrl;

  @JsonKey(name: 'backupUrl')
  List<String>? backupUrl;

  @JsonKey(name: 'bandwidth')
  int bandwidth;

  @JsonKey(name: 'codecid')
  int codecid;

  @JsonKey(name: 'mimeType')
  String mimeType;

  Audio({
    required this.id,
    required this.baseUrl,
    this.backupUrl,
    required this.bandwidth,
    required this.codecid,
    required this.mimeType,
  });

  factory Audio.fromJson(Map<String, dynamic> json) => _$AudioFromJson(json);
}

@JsonSerializable()
class Durl {
  @JsonKey(name: 'url')
  String url;

  @JsonKey(name: 'backup_url')
  List<String>? backupUrl;

  @JsonKey(name: 'length')
  int length;

  @JsonKey(name: 'order')
  int order;

  Durl({
    required this.url,
    this.backupUrl,
    required this.length,
    required this.order,
  });

  factory Durl.fromJson(Map<String, dynamic> json) => _$DurlFromJson(json);
}