import 'package:objectbox/objectbox.dart';

/// 下载游标实体类
/// 用于记录每个收藏夹下载最前的位置，下载全部时不会请求此后的页面，防止被风控
@Entity()
class DownloadCursor {
  @Id()
  int id;

  int folderId; // 文件夹ID

  int cursor; // 下载游标，为视频的aid

  DownloadCursor({this.id = 0, required this.folderId, required this.cursor});
}
