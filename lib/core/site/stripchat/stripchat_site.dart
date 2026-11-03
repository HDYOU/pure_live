import 'dart:convert';

import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/services/settings_service.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/core/interface/live_site.dart';
import 'package:pure_live/core/site/m3u8_file_util.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/model/live_play_quality_play_url_info.dart';
import 'package:pure_live/model/live_search_result.dart';
import 'package:pure_live/modules/util/json_util.dart';
import 'package:pure_live/plugins/extension/string_extension.dart';

import '../live_util.dart';
import 'stripchat_danmaku.dart';
import 'stripchat_site_mixin.dart';

class StripChatSite extends LiveSite with StripChatSiteMixin {
  @override
  String get id => 'stripchat';

  @override
  String get name => 'StripChat';

  @override
  LiveDanmaku getDanmaku() => StripChatDanmaku();

  static const defaultUa = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36";
  static const baseUrl = "https://www.stripchat.com";
  static const apiHost = "https://zh.virtualtaboo.live";

  Map<String, String> getHeaders() {
    return {
      'Accept': '*/*',
      'Origin': apiHost,
      'Referer': '$apiHost/',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-site',
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
      "Cookie": SettingsService.instance.siteCookies[id] ?? "",
    };
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) async {
    return Future.value(LiveCategoryResult(hasMore: false, items: <LiveRoom>[]));
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) async {
    List<LivePlayQuality> qualities = <LivePlayQuality>[];
    CoreLog.d("detail.data: ${jsonEncode(detail.data)}");
    var data = (detail.data as Map);
    var camData = data['cam'] ?? {};
    var streamName = camData['streamName'] ?? detail.userId;
    var userId = detail.userId ?? "";

    var hlsBaseUrl = "$apiHost/hls/$userId/master/$streamName.m3u8";
    CoreLog.d("hlsBaseUrl: $hlsBaseUrl");

    try {
      var response = await HttpClient.instance.getText(hlsBaseUrl, header: getHeaders());
      var list = M3u8FileUtil.parseM3u8File(response, info: "");
      qualities.addAll(list);
    } catch (e) {
      CoreLog.error("解析HLS失败: $hlsBaseUrl $e");
    }

    if (qualities.isEmpty) {
      var autoUrl = "$apiHost/hls/$userId/master/$streamName_auto.m3u8";
      try {
        var response = await HttpClient.instance.getText(autoUrl, header: getHeaders());
        var list = M3u8FileUtil.parseM3u8File(response, info: "");
        qualities.addAll(list);
      } catch (e) {
        CoreLog.error("解析auto HLS失败: $autoUrl $e");
      }
    }

    if (qualities.isNotEmpty) {
      var firstQuality = qualities.first;
      var firstUrl = firstQuality.playUrlList.isNotEmpty ? firstQuality.playUrlList[0].playUrl : "";
      var fallbackUrl = firstUrl.replaceFirst(RegExp(r'_\d+p\.m3u8$'), '.m3u8');
      if (firstUrl != fallbackUrl && fallbackUrl.isNotEmpty) {
        var resolutionNum = 720;
        var bitRate = M3u8FileUtil.resolutionToBitRate(resolutionNum);
        var qualityName = M3u8FileUtil.resolutionToQualityName(resolutionNum);
        var fallbackQuality = LivePlayQuality(quality: qualityName, sort: bitRate, bitRate: bitRate);
        fallbackQuality.playUrlList.add(LivePlayQualityPlayUrlInfo(playUrl: fallbackUrl, info: "($qualityName avc)"));
        qualities.add(fallbackQuality);
      }
    }

    qualities = LiveUtil.combineLivePlayQuality(qualities);
    qualities.sort((a, b) => b.bitRate.compareTo(a.bitRate));
    return Future.value(qualities);
  }

  @override
  Future<List<LivePlayQualityPlayUrlInfo>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    return quality.playUrlList;
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) async {
    var pageSize = 60;
    var offset = (page - 1) * pageSize;
    var url = "$apiHost/api/front/models";
    var result = await HttpClient.instance.getJson(
      url,
      queryParameters: {
        "removeShows": "false",
        "recInFeatured": "false",
        "limit": pageSize,
        "offset": offset,
        "primaryTag": "girls",
        "filterGroupTags": "[[\"tagLanguageChinese\"]]",
        "sortBy": "stripRanking",
        "parentTag": "tagLanguageChinese",
        "nic": "true",
        "byw": "false",
        "rcmGrp": "A",
        "rbCnGr": "true",
        "iem": "true",
        "mvPrm": "false",
        "decMb": "false",
        "ctryTop": "false",
      },
      header: getHeaders(),
    );
    var items = <LiveRoom>[];
    CoreLog.d("getRecommendRooms result length: ${result.toString().length}");
    result = JsonUtil.decode(result);
    var models = result["models"] as List? ?? result["blocks"]?[0]?["models"] as List? ?? [];
    for (var item in models) {
      var liveRoom = parseToLiveRoom(item);
      items.add(liveRoom);
    }
    var hasMore = items.length >= pageSize;
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoom> getRoomDetail({required LiveRoom detail}) async {
    try {
      var roomId = detail.roomId ?? "";
      var url = "$apiHost/api/front/v2/models/username/${roomId}/cam";
      var resultText = await HttpClient.instance.getJson(
        url,
        queryParameters: {"timezoneOffset": "-480", "triggerRequest": "loadCam", "withRecentShow": "1"},
        header: getHeaders(),
      );

      CoreLog.d("resultText keys: ${resultText?.keys}");
      resultText = JsonUtil.decode(resultText);

      var userObj = resultText['user']?['user'] ?? {};
      var camObj = resultText['cam'] ?? {};
      var configObj = resultText['config'] ?? {};

      roomId = userObj["username"].toString();
      var userId = userObj["id"].toString();
      var streamName = (camObj["streamName"] ?? userId).toString();
      var status = userObj["status"]?.toString() ?? "offline";
      var isLive = status == "public";

      var websocketUrl = configObj["websocketUrl"]?.toString() ?? "";
      var websocketToken = configObj["websocketToken"]?.toString() ?? "";
      CoreLog.d("websocketUrl: $websocketUrl, websocketToken: $websocketToken, streamName: $streamName");

      var danmakuArgs = StripChatDanmakuArgs(
        roomId: roomId,
        token: websocketToken,
        userId: userId,
        websocketUrl: websocketUrl,
      );
      var liveRoom = parseToLiveRoom(userObj, camObj: camObj);
      liveRoom.danmakuData = danmakuArgs;
      liveRoom.data = resultText;
      liveRoom.userId = userId;
      liveRoom.status = isLive;
      liveRoom.liveStatus = isLive ? LiveStatus.live : LiveStatus.offline;

      return liveRoom;
    } catch (e) {
      CoreLog.error("getRoomDetail error: $e");
      return getLiveRoomWithError(detail);
    }
  }

  dynamic getByKeyList(Map jsonObj, List<String> keys) {
    for (var key in keys) {
      if (jsonObj.containsKey(key)) {
        return jsonObj[key];
      }
    }
    return null;
  }

  LiveRoom parseToLiveRoom(Map jsonObj, {Map<dynamic, dynamic>? camObj}) {
    var status = jsonObj["status"]?.toString() ?? "offline";
    var isLive = status == "public";
    var topic = camObj?["topic"]?.toString() ?? jsonObj["topic"]?.toString() ?? "";
    var viewers = jsonObj["viewersCount"]?.toString() ?? jsonObj["favoritedCount"]?.toString() ?? "0";
    var snapshotTimestamp = jsonObj["snapshotTimestamp"];
    var userId = jsonObj["id"].toString();
    var cover = "";
    if (snapshotTimestamp != null) {
      cover = "$apiHost/thumbs/$snapshotTimestamp/$userId";
    }

    return LiveRoom(
      roomId: jsonObj["username"].toString(),
      userId: userId,
      nick: jsonObj["username"].toString(),
      title: topic,
      watching: viewers,
      cover: cover.toString().replaceFirst("https://", "https://i2.wp.com/"),
      avatar: (getByKeyList(jsonObj, ["previewUrlThumbSmall", "avatarUrl"]) ?? "").toString().replaceFirst("https://", "https://i2.wp.com/"),
      area: '',
      introduction: jsonObj["description"]?.toString() ?? '',
      notice: '',
      status: isLive,
      liveStatus: isLive ? LiveStatus.live : LiveStatus.offline,
      platform: id,
    );
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    var pageSize = 60;
    var offset = (page - 1) * pageSize;
    var url = "$apiHost/api/front/v4/models/search/suggestion";
    var result = await HttpClient.instance.getJson(
      url,
      queryParameters: {
        "query": keyword,
        "limit": pageSize,
        "primaryTag": "girls",
      },
      header: getHeaders(),
    );
    var items = <LiveRoom>[];
    CoreLog.d("searchRooms result: ${result.toString().length}");
    result = JsonUtil.decode(result);
    var models = result["models"] as List? ?? [];
    for (var item in models) {
      var liveRoom = parseToLiveRoom(item);
      items.add(liveRoom);
    }
    var hasMore = items.length >= pageSize;
    return LiveSearchRoomResult(hasMore: hasMore, items: items);
  }
}
