import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bili_tracker/di.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/exceptions.dart';
import '../providers/settings_provider.dart';

class Network {
  static const String baseUrl = 'https://api.bilibili.com';
  static bool isInitialized = false;
  static String? _cookie;

  static Map<int, String> videoQualityMap = {
    6: '240P 极速',
    16: '360P 流畅',
    32: '480P 清晰',
    64: '720P 高清',
    74: '720P60 高帧率',
    80: '1080P 高清',
    100: '智能修复',
    112: '1080P+ 高码率',
    116: '1080P60 高帧率',
    120: '4K 超清',
    125: 'HDR 真彩色',
    126: '杜比视界',
    127: '8K 超高清',
  };

  static Map<int, String> audioQualityMap = {
    30216: '64K',
    30232: '132K',
    30280: '192K',
    30250: '杜比全景声',
    30251: 'Hi-Res无损',
  };

  static Future<void> init() async {
    if (isInitialized) return;
    isInitialized = true;

    // 预加载cookie到内存
    var prefs = await SharedPreferences.getInstance();
    _cookie = prefs.getString('cookies');
  }

  static Future<void> updateCookie(String cookie) async {
    _cookie = cookie;
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('cookies', cookie);
  }

  static Map<String, String> headers = {
    'Accept': 'application/json',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.190 Safari/537.36',
    'Origin': 'https://www.bilibili.com',
    'Referer': 'https://www.bilibili.com/',
  };

  // WBI签名算法实现
  static const List<int> mixinKeyEncTab = [
    46,
    47,
    18,
    2,
    53,
    8,
    23,
    32,
    15,
    50,
    10,
    31,
    58,
    3,
    45,
    35,
    27,
    43,
    5,
    49,
    33,
    9,
    42,
    19,
    29,
    28,
    14,
    39,
    12,
    38,
    41,
    13,
    37,
    48,
    7,
    16,
    24,
    55,
    40,
    61,
    26,
    17,
    0,
    1,
    60,
    51,
    30,
    4,
    22,
    25,
    54,
    21,
    56,
    59,
    6,
    63,
    57,
    62,
    11,
    36,
    20,
    34,
    44,
    52,
  ];

  /// 对 imgKey 和 subKey 进行字符顺序打乱编码
  static String _getMixinKey(String orig) {
    final sb = StringBuffer();
    for (var i in mixinKeyEncTab) {
      if (i < orig.length) {
        sb.write(orig[i]);
      }
    }
    return sb.toString().substring(0, 32);
  }

  /// 为请求参数进行 wbi 签名
  static Map<String, String> encWbi(
    Map<String, dynamic> params,
    String imgKey,
    String subKey,
  ) {
    final mixinKey = _getMixinKey(imgKey + subKey);
    final currTime = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    // 创建参数副本并添加wts
    final newParams = Map<String, dynamic>.from(params)..['wts'] = currTime;

    // 按键名排序
    final sortedKeys = newParams.keys.toList()..sort();

    // 过滤特殊字符并构建查询字符串
    final filteredParams = <String, String>{};
    for (var key in sortedKeys) {
      final value = newParams[key].toString().replaceAll(
        RegExp(r"[!'()*]"),
        '',
      );
      filteredParams[key] = value;
    }

    final query = Uri(queryParameters: filteredParams).query;
    final wbiSign = md5.convert(utf8.encode(query + mixinKey)).toString();

    return {...filteredParams, 'w_rid': wbiSign};
  }

  /// 获取最新的 img_key 和 sub_key
  static Future<Map<String, String>> getWbiKeys() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.bilibili.com/x/web-interface/nav'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get WBI keys: HTTP ${response.statusCode}');
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final imgUrl = jsonData['data']['wbi_img']['img_url'] as String;
      final subUrl = jsonData['data']['wbi_img']['sub_url'] as String;

      final imgKey = imgUrl.split('/').last.split('.').first;
      final subKey = subUrl.split('/').last.split('.').first;

      return {'img_key': imgKey, 'sub_key': subKey};
    } catch (e) {
      throw Exception('Failed to get WBI keys: $e');
    }
  }

  /// 签名参数并返回签名后的Map
  static Future<Map<String, String>> signParams(
    Map<String, dynamic> params,
  ) async {
    final wbiKeys = await getWbiKeys();
    return encWbi(params, wbiKeys['img_key']!, wbiKeys['sub_key']!);
  }

  static Future<Map<String, String>> getHeaders() async {
    var prefs = await SharedPreferences.getInstance();
    var cookie = prefs.getString('cookies');
    return {...headers, 'Cookie': cookie ?? ""};
  }

  static Future<Map<String, dynamic>> getWithSign(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final headers = await getHeaders();
    final signedParams = await Network.signParams(queryParameters!);
    final urlWithAllParams =
        'https://api.bilibili.com/x/space/wbi/acc/info?${signedParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final response = await http.get(
      Uri.parse(urlWithAllParams),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load data: HTTP ${response.statusCode}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getWithCookies(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await init();
    if (_cookie == null || _cookie!.isEmpty) {
      throw NoLoginException("未登录");
    }

    try {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParameters?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );

      final response = await http.get(
        uri,
        headers: {...headers, 'Cookie': _cookie!},
      );

      if (response.statusCode == 401) {
        final settingsProvider = getIt.get<SettingsProvider>();
        settingsProvider.changeCookies("");
        settingsProvider.changeUid("");
        settingsProvider.changeUsername("");
        settingsProvider.changeRank("");
        throw LoginExpiredException("登录已过期");
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load data: HTTP ${response.statusCode}');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  static Future<Map<String, dynamic>> getWithNoCookies(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await init();
    int retryCount = 0;
    var headers = await getHeaders();

    while (retryCount < 3) {
      try {
        final uri = Uri.parse(path).replace(
          queryParameters: queryParameters?.map(
            (k, v) => MapEntry(k, v.toString()),
          ),
        );

        final response = await http.get(uri, headers: headers);

        if (response.statusCode != 200) {
          throw Exception('Failed to load data: HTTP ${response.statusCode}');
        }

        return json.decode(response.body) as Map<String, dynamic>;
      } on HandshakeException {
        retryCount++;
      } on SocketException {
        throw SocketException('网络异常');
      } catch (e) {
        throw Exception('Failed to load data: $e');
      }
    }
    throw Exception('Failed to load data, max retries exceeded');
  }

  static Future<Map<String, dynamic>> getWiHeaders(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(path).replace(
        queryParameters: queryParameters?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );

      final response = await http.get(uri, headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Failed to load data: HTTP ${response.statusCode}');
      }

      return {'body': json.decode(response.body), 'headers': response.headers};
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
}
