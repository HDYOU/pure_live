import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/services/settings_service.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/core/interface/live_site.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/model/live_play_quality_play_url_info.dart';
import 'package:pure_live/model/live_search_result.dart';
import 'package:pure_live/plugins/extension/string_extension.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';


import '../../../modules/util/json_util.dart';
import 'my_youtube_http_client.dart';
import 'youtube_danmaku.dart';
import 'youtube_site_mixin.dart';


class YoutubeSite extends LiveSite with YoutubeSiteMixin {
  @override
  String get id => "youtube";

  @override
  String get name => "YouTube";

  @override
  LiveDanmaku getDanmaku() => YoutubeDanmaku();

  /// API 基础地址
  final String BASE_URL = 'https://www.youtube.com';
  final String API_BASE = 'https://www.youtube.com/youtubei/v1';

  /// 公开的API KEY (和Python原代码一致)
  final Map<String, String> API_KEYS = {
    'web': 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
    'mweb': 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
    'android': 'AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w',
    'ios': 'AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc',
  };

  /// 客户端信息 (模拟真实浏览器/移动端，完全复刻Python)
  final Map<String, Map<String, dynamic>> CLIENTS = {
    'web': {
      'clientName': 'WEB',
      'clientVersion': '2.20241111.01.00',
      'platform': 'DESKTOP',
      'osName': 'Windows',
      'osVersion': '10.0',
      'browserName': 'Chrome',
      'browserVersion': '131.0.0.0',
    },
    'mweb': {
      'clientName': 'MWEB',
      'clientVersion': '2.20241111.08.00',
      'platform': 'MOBILE',
      'osName': 'Android',
      'osVersion': '14',
    },
    'android': {
      'clientName': 'ANDROID',
      'clientVersion': '19.15.36',
      'androidSdkVersion': 34,
      'platform': 'MOBILE',
      'osName': 'Android',
      'osVersion': '14',
    },
    'ios': {
      'clientName': 'IOS',
      'clientVersion': '19.15.1',
      'platform': 'MOBILE',
      'osName': 'iOS',
      'osVersion': '17.5.1',
      'deviceMake': 'Apple',
      'deviceModel': 'iPhone15,2',
    },
  };

  /// 实例属性
  String clientType= 'web';
  String language= 'web';
  String region = 'US';
  bool useHttps= true;
  late String apiKey = API_KEYS[clientType] ?? API_KEYS['web']!;

  /// 创建API上下文 (核心：无认证模式)
  Map<String, dynamic> _createContext() {
    Map<String, dynamic> clientInfo = Map.from(CLIENTS[clientType] ?? CLIENTS['web']!);
    String visitorData = _generateVisitorData();

    Map<String, dynamic> context = {
      'client': clientInfo,
      'request': {
        'useSsl': useHttps,
        'internalExperimentFlags': [],
      },
      'user': {
        'lockedSafetyMode': false,
      },
    };

    // 添加语言/地区
    if (language.isNotEmpty) {
      context['client']['hl'] = language;
    }
    if (region.isNotEmpty) {
      context['client']['gl'] = region;
    }

    // 添加匿名访客数据
    context['client']['visitorData'] = visitorData;

    return context;
  }

  /// 生成匿名访客数据 替代Python的随机字符串生成
  String _generateVisitorData() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(11, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// 配置请求头 完全复刻Python的请求头规则，绕过认证校验的核心
  Map<String, String> getHeaders() {
    Map<String, String> userAgents = {
      'web': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      'mweb': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6778.39 Mobile Safari/537.36',
      'android': 'com.google.android.youtube/19.15.36 (Linux; U; Android 14) gzip',
      'ios': 'com.google.ios.youtube/19.15.1 (iPhone15,2; U; CPU iOS 17_5_1 like Mac OS X)',
    };

    Map<String, String> headers = {
      'User-Agent': userAgents[clientType] ?? userAgents['web']!,
      'Accept-Language': '$language,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Origin': BASE_URL,
      'Referer': '$BASE_URL/',
      'Content-Type': 'application/json',
    };

    // WEB/MWEB 专属关键请求头 - 告诉YouTube 未登录状态
    if (clientType == 'web' || clientType == 'mweb') {
      headers.addAll({
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-Mode': 'same-origin',
        'X-Youtube-Bootstrap-Logged-In': 'false',
        'X-Youtube-Client-Name': clientType == 'web' ? '1' : '2',
        'X-Youtube-Client-Version': (CLIENTS[clientType] ?? CLIENTS['web']!)['clientVersion'] as String,
      });
    }
    var cookie = SettingsService.instance.siteCookies[id] ?? "";
    if(cookie.isNotNullOrEmpty) headers["Cookie"] = cookie;
    return headers;
  }

  /// 核心API请求方法 替代Python的 _call_api
  Future<Map<String, dynamic>> _callApi(String endpoint, {Map<String, dynamic>? data, Map<String, dynamic>? params}) async {
    String url = '$API_BASE/$endpoint';
    Map<String, dynamic> urlParams = {'key': apiKey};
    if (params != null) urlParams.addAll(params);

    Map<String, dynamic> requestData = data ?? {};
    requestData['context'] = _createContext();

    try {
      var response = await HttpClient.instance.postJson(
        url,
        queryParameters: urlParams,
        data: requestData,
        header: getHeaders(),
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('API error: ${e.toString()}');
    }
  }

  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    List<LiveCategory> categories = [
      LiveCategory(id: "1", name: "热门", children: []),
    ];

    List<Future> futures = [];
    for (var item in categories) {
      futures.add(Future(() async {
        var items = await getAllSubCategores(item, 1, 120, []);
        item.children.addAll(items);
      }));
    }
    await Future.wait(futures);
    return categories;
  }

  Future<List<LiveArea>> getAllSubCategores(LiveCategory liveCategory, int page, int pageSize, List<LiveArea> allSubCategores) async {
    try {
      var subsArea = await getSubCategores(liveCategory, page, pageSize);
      CoreLog.d("getAllSubCategores: ${subsArea}");
      allSubCategores.addAll(subsArea);
      var hasMore = subsArea.length >= pageSize;
      if (hasMore) {
        page++;
        await getAllSubCategores(liveCategory, page, pageSize, allSubCategores);
      }
      return allSubCategores;
    } catch (e) {
      CoreLog.error(e);
      return allSubCategores;
    }
  }

  Future<List<LiveArea>> getSubCategores(LiveCategory liveCategory, int page, int pageSize) async {
    var resultText = await HttpClient.instance.getJson(
      "https://sch.youtubelive.co.kr/api.php",
      queryParameters: {
        "m": "categoryList",
        "szKeyword": "",
        "szOrder": "view_cnt",
        "nPageNo": page,
        "nListCnt": pageSize,
        "nOffset": "0",
        "szPlatform": "pc",
      },
      header: getHeaders(),
    );
    var result = JsonUtil.decode(resultText);

    List<LiveArea> subs = [];
    for (var item in result["data"]["list"] ?? []) {
      var subCategory = LiveArea(
        areaId: item["category_no"],
        areaName: item["category_name"],
        areaType: liveCategory.id,
        platform: Sites.youtubeSite,
        areaPic: item["cate_img"],
        typeName: liveCategory.name,
      );
      subs.add(subCategory);
    }

    return subs;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) async {
    var pageSize = 60;
    var result = await HttpClient.instance.getJson(
      "https://sch.youtubelive.co.kr/api.php",
      queryParameters: {"m": "categoryContentsList", "szType": "live", "nPageNo": page, "nListCnt": pageSize, "szPlatform": "pc", "szOrder": "view_cnt_desc", "szCateNo": category.areaId},
      header: getHeaders(),
    );
    result = JsonUtil.decode(result);
    var items = <LiveRoom>[];
    for (var item in result["data"]["list"]) {
      var roomItem = LiveRoom(
        roomId: item["user_id"] ?? '',
        title: item['broad_title'] ?? '',
        cover: validImgUrl(item['thumbnail'] ?? ''),
        nick: item["user_nick"].toString(),
        watching: item["view_cnt"].toString(),
        avatar: validImgUrl(item["user_profile_img"]),
        area: category.areaName,
        liveStatus: LiveStatus.live,
        status: true,
        platform: Sites.youtubeSite,
      );
      items.add(roomItem);
    }
    var hasMore = items.length >= pageSize;
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) {
    List<LivePlayQuality> qualities = <LivePlayQuality>[];
    Map<String, LivePlayQuality> qualityMap = HashMap();
    CoreLog.d("detail.data: ${jsonEncode(detail.data)}");
    var data = (detail.data as Map);
    for (var quality in data["viewpreset"]) {
      var key = quality["name"];
      if (key == "auto") {
        continue;
      }
      qualityMap.putIfAbsent(key, () {
        return LivePlayQuality(
          quality: quality["name"],
          sort: quality["bps"],
          data: <String>[],
          bitRate: quality["bps"] ?? 0,
        );
      });
    }
    qualities = qualityMap.values.toList();
    qualities.sort((a, b) => b.sort.compareTo(a.sort));
    return Future.value(qualities);
  }

  @override
  Future<List<LivePlayQualityPlayUrlInfo>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    quality.playUrlList.add(LivePlayQualityPlayUrlInfo(playUrl: "", info: ""));
    return quality.playUrlList;
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) async {
    var pageSize = 60;
    var result = await HttpClient.instance.getJson(
      "https://live.youtubelive.co.kr/api/main_broad_list_api.php",
      queryParameters: {
        "selectType": "action",
        "selectValue": "all",
        "orderType": "view_cnt",
        "pageNo": page,
        "lang": "ko_KR",
      },
      header: getHeaders(),
    );
    var items = <LiveRoom>[];
    CoreLog.d("$result");
    result = JsonUtil.decode(result);
    for (var item in result["broad"]) {
      var roomId = item["user_id"] ?? '';
      var roomItem = LiveRoom(
        roomId: roomId,
        title: item['broad_title'] ?? '',
        cover: validImgUrl(item['broad_thumb'] ?? ''),
        nick: item["user_nick"].toString(),
        watching: item["current_view_cnt"].toString(),
        avatar: getAvatarUrlByRoomId(roomId),
        area: item["category_name"],
        liveStatus: LiveStatus.live,
        status: true,
        platform: Sites.youtubeSite,
      );
      items.add(roomItem);
    }
    var hasMore = items.length >= pageSize;
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoom> getRoomDetail({required LiveRoom detail}) async {
    try {
      var yt = YoutubeExplode(httpClient: MyYoutubeHttpClient(HttpClient.instance));

      // var manifest = await yt.videos.streams.getManifest("Dpp1sIL1m5Q");
      // CoreLog.d("manifest: ${manifest}");
      var video = await yt.videos.get("Dpp1sIL1m5Q");
      CoreLog.d("video: ${video}");

      // Map<String, dynamic> data1 = {
      //   'videoId': detail.roomId,
      //   'contentCheckOk': true,
      //   'racyCheckOk': true,
      // };
      // Map<String, dynamic> response = await _callApi('player', data: data1);
      // CoreLog.d("response: ${jsonEncode(response)}");
      return getLiveRoomWithError(detail);

      var resultText = JsonUtil.decode("");
      CoreLog.d("live roome: ${jsonEncode(resultText)}");
      CoreLog.d("code: ${resultText['data']['code']}");
      var code = resultText['data']['code'] ?? 1;
      var jsonObj = resultText['data'];
      var bno = jsonObj["broad_no"].toString();
      var nick = jsonObj["user_nick"];
      //CoreLog.d(jsonEncode(jsonObj));

      var jsonObj2 = jsonObj["category_tags"];
      var area = "";
      if (jsonObj2 != null) {
        var sList = (jsonObj2 as List);
        if (sList.isNotEmpty) {
          area = sList[0];
        }
      }
      var millisecondsSinceEpoch2 = DateTime.now().millisecondsSinceEpoch;
      var cover = validImgUrl("${jsonObj['thumbnail']}?_t=$millisecondsSinceEpoch2");
      var avatar = validImgUrl("${jsonObj['profile_thumbnail']}");
      var data = {
        // "hls_authentication_key": jsonObj["hls_authentication_key"],
        // "broad_bps": jsonObj["broad_bps"],
        "viewpreset": jsonObj["viewpreset"],
      };
      var isLiving = jsonObj["viewpreset"] != null;
      CoreLog.d("$jsonObj");
      return LiveRoom(
        cover: cover,
        watching: jsonObj["view_cnt"].toString(),
        roomId: jsonObj["bj_id"].toString(),
        userId: bno,
        area: area,
        title: jsonObj["broad_title"].toString(),
        nick: nick,
        avatar: avatar,
        introduction: '',
        notice: '',
        status: isLiving,
        liveStatus: isLiving ? LiveStatus.live : LiveStatus.offline,
        platform: Sites.youtubeSite,
        link: jsonObj["share"]["url"],
        data: data,
        danmakuData: null,
      );
    } catch (e) {
      CoreLog.error(e);
      return getLiveRoomWithError(detail);
    }
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://sch.youtubelive.co.kr/api.php",
      queryParameters: {
        "l": "DF",
        "m": "liveSearch",
        "c": "UTF-8",
        "w": "webk",
        "isMobile": "0",
        "onlyParent": "1",
        "szType": "json",
        "szOrder": "score",
        "szKeyword": keyword,
        "nPageNo": page,
        "nListCnt": "40",
        "tab": "live",
        "location": "total_search",
        "isHashSearch": "0",
        "v": "2.0",
      },
      header: getHeaders(),
    );
    var result = JsonUtil.decode(resultText);
    var items = <LiveRoom>[];
    var queryList = result["REAL_BROAD"] ?? [];
    for (var item in queryList) {
      var cover = item["broad_img"].toString();
      var userId = item["user_id"].toString();
      var title = item["broad_title"]?.toString() ?? "";
      var area = item["standard_broad_cate_name"]?.toString() ?? "";

      var roomItem = LiveRoom(
        roomId: userId,
        title: title,
        cover: validImgUrl(cover),
        nick: item["user_nick"].toString(),
        area: area,
        status: true,
        liveStatus: LiveStatus.live,
        avatar: getAvatarUrlByRoomId(userId),
        watching: item["current_view_cnt"].toString(),
        platform: Sites.youtubeSite,
      );
      items.add(roomItem);
    }
    return LiveSearchRoomResult(hasMore: queryList.length > 0, items: items);
  }

  String getAvatarUrlByRoomId(String roomId) {
    if (roomId.isEmpty || roomId.length < 2) {
      return "";
    }
    var part = roomId.substring(0, 2);
    return "https://stimg.youtubelive.co.kr/LOGO/$part/$roomId/m/$roomId.webp";
  }

  String validImgUrl(String imgUrl) {
    if (imgUrl.isEmpty) {
      return "";
    }
    if (imgUrl.startsWith("//")) {
      return "https:$imgUrl";
    }
    return imgUrl;
  }
}
