import 'dart:convert';

import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/services/settings_service.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/danmaku/empty_danmaku.dart';
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
  LiveDanmaku getDanmaku() => EmptyDanmaku();

  static const defaultUa = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36";
  static const baseUrl = "https://www.pandalive.co.kr";
  static const String apiUrl = "https://api.pandalive.co.kr";

  Map<String, String> getHeaders() {
    return {
      'Accept': '*/*',
      'Origin': baseUrl,
      'Referer': '$baseUrl/',
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
    var playList = data["PlayList"] ?? {};

    var url = "https://edge-hls.growcdnssedge.com/hls/${detail.userId}/master/${detail.userId}_auto.m3u8";
    var parseHlsPlaylist = await _parseHlsPlaylist(url, "");
    qualities.addAll(parseHlsPlaylist);
    if (parseHlsPlaylist.isNotEmpty) {
      var livePlyer = parseHlsPlaylist[0];
      var playUrlInfo = livePlyer.playUrlList[0];
      // https://media-hls.growcdnssedge.com/b-hls-29/200729634/200729634_480p.m3u8
      var playUrl = playUrlInfo.playUrl;
      var info = playUrlInfo.info;
      var replacePlayUrl = playUrl.replaceFirst(RegExp(r"_\d+p\.m3u8"), ".m3u8");
      if (playUrl != replacePlayUrl) {
        var resolutionNum = 720;
        var bitRate = M3u8FileUtil.resolutionToBitRate(resolutionNum);
        var qualityName = M3u8FileUtil.resolutionToQualityName(resolutionNum);
        var livePlayQuality = LivePlayQuality(quality: qualityName, sort: bitRate, bitRate: bitRate);

        livePlayQuality.playUrlList.add(LivePlayQualityPlayUrlInfo(playUrl: replacePlayUrl, info: "($qualityName avc)"));

        qualities.add(livePlayQuality);
      }
    }
    qualities = LiveUtil.combineLivePlayQuality(qualities);
    qualities.sort((a, b) => b.bitRate.compareTo(a.bitRate));
    return Future.value(qualities);
  }

  /// 解析HLS播放列表
  Future<List<LivePlayQuality>> _parseHlsPlaylist(String hlsUrl, String info) async {
    try {
      final response = await HttpClient.instance.getText(
        hlsUrl,
        header: getHeaders(),
      );
      CoreLog.d("response: ${response}");
      var list = M3u8FileUtil.parseM3u8File(
        response,
        info: info,
        otherInfoPattern: RegExp("NAME=\"([a-zA-Z0-9]+)\""),
      );
      return list;
    } catch (e) {
      CoreLog.error("解析HLS播放列表失败: key:${info} url: ${hlsUrl} ${e.toString()}");
    }
    return [];
  }

  @override
  Future<List<LivePlayQualityPlayUrlInfo>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    return quality.playUrlList;
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) async {
    var pageSize = 60;
    var offset = (page - 1) * pageSize;
    var url = "https://zh.stripchat.com/api/front/models";
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
        //"guestHash": "4a00b9494986dce513af898b5d752ac88598038de7d540b00a8b038b57e088c6",
        //"uniq": "j2c15d4kb79ny83p"
      },
      header: getHeaders(),
    );
    var items = <LiveRoom>[];
    CoreLog.d("$result");
    result = JsonUtil.decode(result);
    for (var item in result["models"]) {
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
      var url = "https://zh.stripchat.com/api/front/v2/models/username/${roomId}/cam";
      var resultText = await HttpClient.instance.getJson(
        url,
        queryParameters: {},
        header: getHeaders(),
      );

      CoreLog.d("resultText: ${jsonEncode(resultText)}");
      resultText = JsonUtil.decode(resultText);
      var jsonObj = resultText['user']['user'];
      roomId = jsonObj["username"].toString();
      var userId = jsonObj["id"].toString();
      var danmakuArgs = StripChatDanmakuArgs(roomId: roomId, token: "", userId: userId);
      var liveRoom = parseToLiveRoom(jsonObj);
      liveRoom.danmakuData = danmakuArgs;
      liveRoom.data = resultText;

      return liveRoom;
    } catch (e) {
      CoreLog.error(e);
      return getLiveRoomWithError(detail);
    }
  }

  dynamic getByKeyList(Map jsonObj, List<String> keys) {
    for (var key in keys) {
      if(jsonObj.containsKey(key)){
        return jsonObj[key];
      }
    }
    return null;
  }

  LiveRoom parseToLiveRoom(Map jsonObj) {
    var isLive = jsonObj["isLive"] ?? false;
    // var startTime = jsonObj["startTime"].toString(); // "startTime": "2025-12-23 11:02:51", "endTime": "0000-00-00 00:00:00",
    var roomId = jsonObj["username"].toString();
    var userId = jsonObj["id"].toString();
    var snapshotTimestamp = jsonObj["snapshotTimestamp"];
    var cover = "";
    if (snapshotTimestamp != null) {
      cover = "https:///img.doppiocdn.org/thumbs/$snapshotTimestamp/$userId?r=.jpg";
    }

    // CoreLog.d("cover: ${cover}");

    return LiveRoom(
      roomId: roomId,
      userId: userId,
      nick: jsonObj["username"].toString(),
      title: (getByKeyList(jsonObj, ["offlineStatus", "groupShowTopic", "topic"])).toString(),
      watching: (getByKeyList(jsonObj, ["favoritedCount", "viewersCount"])).toString(),
      cover: cover.toString(),
      avatar: (getByKeyList(jsonObj, ["previewUrlThumbSmall"])).toString().replaceFirst("https://", "https://i2.wp.com/"),
      // ivsThumbnail
      area: '',
      introduction: '',
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
    var url = "https://zh.stripchat.com/api/front/v5/models/search/group/all";
    var result = await HttpClient.instance.getJson(
      url,
      queryParameters: {
        "query": keyword,
        "limit": pageSize,
        "offset": offset,
        "primaryTag": "girls",
        "includeCvSearchResults": "false",
        "rcmGrp": "A",
        "oRcmGrp": "A",
      //  "uniq": "av5tfx71r2036wse"
      },
      header: getHeaders(),
    );
    var items = <LiveRoom>[];
    CoreLog.d("$result");
    result = JsonUtil.decode(result);
    for (var item in result["groups"]?["username"]?["models"]) {
      var liveRoom = parseToLiveRoom(item);
      items.add(liveRoom);
    }
    var hasMore = items.length >= pageSize;
    return LiveSearchRoomResult(hasMore: hasMore, items: items);
  }
}
