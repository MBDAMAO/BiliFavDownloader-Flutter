import 'package:bili_tracker/apis/bilibili_api.dart';
import 'package:bili_tracker/apis/templates/video_detail_resp.dart';
import 'package:bili_tracker/repo/download_cursor_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apis/templates/all_my_fav_resp.dart';
import '../apis/templates/fav_info_resp.dart';
import '../apis/templates/fav_list.dart';
import '../di.dart';
import '../models/task.dart';
import '../providers/download_tasks_provider.dart';

class BilibiliService {
  static Future<VideoDetail> getVideoDetail({String? bvid, int? avid}) async {
    if (bvid == null && avid == null) {
      throw Exception('bvid or avid is null');
    }
    VideoDetailResp videoDetailResp;
    if (avid != null) {
      videoDetailResp = await BilibiliApi.getVideoInfoWithAVId(avid);
    } else {
      videoDetailResp = await BilibiliApi.getVideoInfoWithBVId(bvid!);
    }
    return VideoDetail(
      title: videoDetailResp.data.title,
      cover: videoDetailResp.data.pic,
      pages: videoDetailResp.data.videos,
      cid: videoDetailResp.data.cid,
    );
  }

  // static Future<List<VideoPage>> getVideoPages({String? bvid, int? avid}) async {
  // }
  //

  static Future<void> downloadAllVideos(List<Media> videos) async {
    for (var video in videos) {
      if (video.attr != 0) {
        videos.remove(video);
        continue;
      }
    }
    List<Task> taskList = [];
    for (var video in videos) {
      final task = Task(
        aid: video.id,
        cover: video.cover,
        filename: video.title,
        createTime: DateTime.now().toString(),
      );
      task.status = TaskStatus.enqueued;
      task.type = TaskType.downloadAllPages;
      task.phase = TaskPhase.undefined;

      taskList.add(task);
    }
    await getIt<DownloadTasksProvider>().batchAddTasks(taskList);
  }

  static Future<void> addDownloadTask({
    required int aid,
    required String cover,
    required String filename,
  }) async {
    final task = Task(
      progress: 0,
      aid: aid,
      cover: cover,
      filename: filename,
      createTime: DateTime.now().toString(),
    );
    task.status = TaskStatus.enqueued;
    task.type = TaskType.downloadAllPages;
    task.phase = TaskPhase.undefined;
    await getIt<DownloadTasksProvider>().addTask(task);
  }

  static Future<List<Media>> fetchAllVideos({
    required int mediaId,
    required Function callback,
  }) async {
    final cursor = await getIt<DownloadCursorRepository>().findCursorByFolderId(
      mediaId,
    );
    int cursorAid = cursor?.cursor ?? 0;

    List<Media> favList = [];
    int page = 1;
    bool hasMore = true;
    int total = 0;
    callback(page, total);
    while (hasMore) {
      final resp = await BilibiliApi.getFavList(mediaId, page, 40);
      total += resp.data.medias.length;
      page++;
      callback(page, total);
      for (var media in resp.data.medias) {
        if (media.id != cursorAid) {
          favList.add(media);
        } else {
          return favList;
        }
      }
      hasMore = resp.data.hasMore;
      favList.addAll(resp.data.medias);
    }
    return favList;
  }

  static Future<void> downloadSelectedVideoPages(
    Map<int, Map<String, dynamic>> pages,
  ) async {
    List<Task> taskList = [];
    for (var page in pages.values) {
      final task = Task(
        progress: 0,
        aid: page["aid"],
        cid: page['cid'],
        cover: page['cover'],
        filename: page['title'],
        createTime: DateTime.now().toString(),
      );
      task.status = TaskStatus.enqueued;
      task.type = TaskType.downloadSinglePage;
      task.phase = TaskPhase.undefined;
      taskList.add(task);
    }
    await getIt<DownloadTasksProvider>().batchAddTasks(taskList);
  }

  static void updateCachedFavCover(int mediaId) async {
    final cover = await BilibiliApi.getFolderInfo(
      mediaId,
    ).then((value) => value.data.cover);
    if (cover.isEmpty) return;
    await SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(mediaId.toString(), cover),
    );
  }

  static Future<(List<MyFavFolder>?, Map<int, String>)>
  getAllMyFavWithCover() async {
    AllMyFavResp favList = await BilibiliApi.getAllMyFav();
    List<int>? mediaIds = favList.data.list.map((media) => media.id).toList();
    Map<int, String>? coverMap = {};
    for (int mediaId in mediaIds) {
      final coverLocal = await SharedPreferences.getInstance().then(
        (prefs) => prefs.getString(mediaId.toString()),
      );
      if (coverLocal != null && coverLocal != "") {
        coverMap[mediaId] = coverLocal;
        continue;
      } else {
        FavInfoResp coverInfo = await BilibiliApi.getFolderInfo(mediaId);
        coverMap[mediaId] = coverInfo.data.cover;
        await SharedPreferences.getInstance().then(
          (prefs) => prefs.setString(mediaId.toString(), coverInfo.data.cover),
        );
      }
    }
    return (favList.data.list, coverMap);
  }

  static Future<List<SaveFolderVideo>> getSaveFolderVideos(
    int folderId,
    int pageNumber,
    int pageCount,
  ) async {
    final resp = await BilibiliApi.getFavList(folderId, pageNumber, pageCount);
    List<SaveFolderVideo> videos =
        resp.data.medias
            .map(
              (media) => SaveFolderVideo(
                title: media.title,
                cover: media.cover,
                duration: media.duration,
                plays: media.cntInfo.play,
                saves: media.cntInfo.reply,
                ownerCover: media.upper.face,
                ownerName: media.upper.name,
                pages: media.page,
                aid: media.id,
              ),
            )
            .toList();
    return videos;
  }
}

class VideoDetail {
  final String title;
  final String cover;
  final int pages;
  final int cid;

  VideoDetail({
    required this.pages,
    required this.cid,
    required this.title,
    required this.cover,
  });
}

class VideoStream {}

class VideoPage {
  final String title;
  final String cover;
  final int index;
  final int cid;

  VideoPage({
    required this.index,
    required this.title,
    required this.cover,
    required this.cid,
  });
}

class SaveFolderInfo {
  final String title;
  final String cover;
  final int counts;

  SaveFolderInfo({
    required this.title,
    required this.cover,
    required this.counts,
  });
}

class SaveFolderVideo {
  final String title;
  final String cover;
  final int duration;
  final int plays;
  final int saves;
  final String ownerCover;
  final String ownerName;
  final int pages;
  final int aid;

  SaveFolderVideo({
    required this.title,
    required this.cover,
    required this.duration,
    required this.plays,
    required this.saves,
    required this.ownerCover,
    required this.ownerName,
    required this.pages,
    required this.aid,
  });
}
