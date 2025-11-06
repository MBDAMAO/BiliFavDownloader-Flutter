import 'package:bili_tracker/apis/templates/fav_list.dart';
import 'package:bili_tracker/apis/templates/video_detail_resp.dart';
import 'package:bili_tracker/apis/templates/video_pages_resp.dart';
import 'package:bili_tracker/apis/templates/video_stream_resp.dart';
import 'package:bili_tracker/apis/templates/all_my_fav_resp.dart';
import 'package:bili_tracker/apis/templates/fav_info_resp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/net.dart';

class BilibiliApi {
  static const String baseUrl = 'https://api.bilibili.com';

  static Future<FavList> getFavList(
    int mediaId,
    int pageNumber,
    int pageCount,
  ) async {
    return FavList.fromJson(
      await Network.getWithCookies(
        '/x/v3/fav/resource/list',
        queryParameters: {
          'media_id': mediaId.toString(),
          'pn': pageNumber.toString(),
          'ps': pageCount.toString(),
        },
      ),
    );
  }

  static Future<Map<String, dynamic>> selfInfo() async {
    return Network.getWithCookies('/x/member/web/account');
  }

  static Future<FavInfoResp> getFolderInfo(int mediaId) async {
    return FavInfoResp.fromJson(
      await Network.getWithCookies(
        '/x/v3/fav/folder/info',
        queryParameters: {'media_id': mediaId.toString()},
      ),
    );
  }

  static Future<Map<String, dynamic>> getUserSpaceInfo(int mid) async {
    return Network.getWithSign(
      '/x/space/acc/info',
      queryParameters: {'mid': mid.toString()},
    );
  }

  static Future<AllMyFavResp> getAllMyFav() async {
    final mid = await SharedPreferences.getInstance().then(
      (prefs) => prefs.getString('mid'),
    );
    return AllMyFavResp.fromJson(
      await Network.getWithCookies(
        '/x/v3/fav/folder/created/list-all',
        queryParameters: {'up_mid': mid},
      ),
    );
  }

  static Future<Map<String, dynamic>> getLoginStatus(String key) async {
    return Network.getWiHeaders(
      'https://passport.bilibili.com/x/passport-login/web/qrcode/poll',
      queryParameters: {'qrcode_key': key},
    );
  }

  static Future<Map<String, dynamic>> getLoginQRCode() async {
    return Network.getWithNoCookies(
      'https://passport.bilibili.com/x/passport-login/web/qrcode/generate',
    );
  }

  static Future<VideoDetailResp> getVideoInfoWithBVId(String bvid) async {
    return VideoDetailResp.fromJson(
      await Network.getWithCookies(
        '/x/web-interface/view',
        queryParameters: {'bvid': bvid},
      ),
    );
  }

  static Future<VideoDetailResp> getVideoInfoWithAVId(int aid) async {
    return VideoDetailResp.fromJson(
      await Network.getWithCookies(
        '/x/web-interface/view',
        queryParameters: {'aid': aid},
      ),
    );
  }

  static Future<VideoPagesResp> getVideoPageList({
    int? aid,
    String? bvid,
  }) async {
    return VideoPagesResp.fromJson(
      await Network.getWithCookies(
        '/x/player/pagelist',
        queryParameters: {'aid': aid, 'bvid': bvid},
      ),
    );
  }

  static Future<VideoStreamResp> getVideoStreamUrl(int aid, int cid) async {
    return VideoStreamResp.fromJson(
      await Network.getWithCookies(
        '/x/player/wbi/playurl',
        queryParameters: {
          'avid': aid,
          'cid': cid,
          'fnval': '4048',
          'fnver': '0',
          'fourk': '1',
        },
      ),
    );
  }
}
