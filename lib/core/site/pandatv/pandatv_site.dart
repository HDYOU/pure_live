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
import 'pandatv_danmaku.dart';
import 'pandatv_site_mixin.dart';

class PandaTvSite extends LiveSite with PandaTvSiteMixin {
  @override
  String get id => 'pandatv';

  @override
  String get name => 'PandaTV';

  @override
  LiveDanmaku getDanmaku() => PandaTvDanmaku();

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

    List<Future<List<LivePlayQuality>>> futures = [];
    for (var key in playList.keys) {
      var item = playList[key];
      if (item is! List) continue;
      if (item.isEmpty) continue;
      for (var urlItem in item) {
        var url = urlItem["url"];
        if (url == null) continue;
        // var parseHlsPlaylist = await _parseHlsPlaylist(url, key);
        // qualities.addAll(parseHlsPlaylist);
        futures.add(_parseHlsPlaylist(url, key));
      }
    }

    var list = await Future.wait(futures);
    for (var item in list) {
      qualities.addAll(item);
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
        otherInfoPattern: RegExp("VIDEO=\"([a-zA-Z0-9]+)\""),
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
    var pageSize = 24;
    var offset = (page - 1) * pageSize;
    var url = "https://api.pandalive.co.kr/v1/live";
    var result = await HttpClient.instance.postJson(
      url,
      formUrlEncoded: true,
      data: {
        'orderBy': "user",
        'onlyNewBj': "N",
        'limit': pageSize,
        'offset': offset,
      },
      header: getHeaders(),
    );
    var items = <LiveRoom>[];
    CoreLog.d("$result");
    result = JsonUtil.decode(result);
    for (var item in result["list"]) {
      var liveRoom = parseToLiveRoom(item);
      items.add(liveRoom);
    }
    var hasMore = items.length >= pageSize;
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoom> getRoomDetail({required LiveRoom detail}) async {
    var roomId = detail.roomId ?? "";
    var url = "https://api.pandalive.co.kr/v1/live/play";
    var resultText = await HttpClient.instance.postJson(
      url,
      formUrlEncoded: true,
      data: {
        'userId': roomId,
        'action': 'watch',
      },
      header: getHeaders(),
    );
    try {
      CoreLog.d("resultText: ${jsonEncode(resultText)}");
      resultText = JsonUtil.decode(resultText);
      if (resultText['result'] != true) {
        // 离线状态
        return getLiveRoomWithError(detail);
      }
      var jsonObj = resultText['media'];
      roomId = jsonObj["userId"].toString();
      var userId = jsonObj["userIdx"].toString();
      var chatServerToken = resultText["token"];
      var danmakuArgs = PandaTvDanmakuArgs(roomId: roomId, token: chatServerToken, userId: userId);
      var liveRoom = parseToLiveRoom(jsonObj);
      liveRoom.danmakuData = danmakuArgs;
      liveRoom.data = resultText;

      return liveRoom;
    } catch (e) {
      CoreLog.error(e);
      return getLiveRoomWithError(detail);
    }
  }

  LiveRoom parseToLiveRoom(Map jsonObj) {
    var isLive = jsonObj["isLive"] ?? false;
    // var startTime = jsonObj["startTime"].toString(); // "startTime": "2025-12-23 11:02:51", "endTime": "0000-00-00 00:00:00",
    var roomId = jsonObj["userId"].toString();
    var userId = jsonObj["userIdx"].toString();
    return LiveRoom(
      roomId: roomId,
      userId: userId,
      nick: jsonObj["userNick"].toString(),
      title: jsonObj["title"].toString(),
      watching: jsonObj["playCnt"].toString(),
      cover: (jsonObj["thumbUrl"] ?? "").toString().appendTxt("?&t=${DateTime.now().millisecondsSinceEpoch ~/ 1000}"),
      avatar: jsonObj["userImg"],
      // ivsThumbnail
      area: jsonObj["category"],
      introduction: '',
      notice: '',
      status: isLive,
      liveStatus: isLive ? LiveStatus.live : LiveStatus.offline,
      platform: id,
    );
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    return LiveSearchRoomResult(hasMore: false, items: []);
  }
}
