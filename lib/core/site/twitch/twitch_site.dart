import 'dart:convert';
import 'dart:math';

import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/core/interface/live_site.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/model/live_play_quality_play_url_info.dart';
import 'package:pure_live/model/live_search_result.dart';

import 'models.dart';
import 'twitch_danmaku.dart';
import 'twitch_site_mixin.dart';

class TwitchSite extends LiveSite with TwitchSiteMixin {
  @override
  String get id => 'twitch';

  @override
  String get name => 'Twitch';

  @override
  LiveDanmaku getDanmaku() => TwitchDanmaku();

  static const defaultUa = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36";
  static const gplApiUrl = "https://gql.twitch.tv/gql";

  static const baseUrl = "https://www.twitch.tv";

  Map<String, String> headers = {
    'user-agent': defaultUa,
    'accept-language': 'en-US,en;q=0.9',
    'accept': 'application/vnd.twitchtv.v5+json',
    'accept-encoding': 'gzip, deflate',
    'client-id': 'kimne78kx3ncx6brgo4mv6wki5h1ko',
  };

  final playSessionIds = ["bdd22331a986c7f1073628f2fc5b19da", "064bc3ff1722b6f53b0b5b8c01e46ca5"];

  void getRequestHeaders() {
    headers['device-id'] = getDeviceId();
// no token
// no cookie
  }

// 生成设备id
  String getDeviceId() {
    final random = Random();
    final deviceId = 1000000000000000 + random.nextInt(1 << 32);
    return deviceId.toString();
  }

  String buildPersistedRequest(String operationName, String sha265Hash, Map<String, dynamic> variables) {
    final variablesJson = jsonEncode(variables);
    final query = '''
     {
       "operationName": "$operationName",
       "extensions": {
         "persistedQuery": {
           "version": 1,
           "sha256Hash": "$sha265Hash"
         }
       },
       "variables": $variablesJson
     }
     ''';
    return query.trim();
  }

  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) {
    return Future.value(<LiveCategory>[]);
  }

  /// 读取类目下房间
  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) {
    return Future.value(LiveCategoryResult(hasMore: false, items: <LiveRoom>[]));
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) async {
    List<LivePlayQuality> qualities = <LivePlayQuality>[];
    var liveGpl = buildPersistedRequest(
      "PlaybackAccessToken",
      "ed230aa1e33e07eebb8928504583da78a5173989fadfb1ac94be06a04f3cdbe9",
      {"isLive": true, "login": detail.roomId, "isVod": false, "vodID": "", "playerType": "site", "isClip": false, "clipID": "", "platform": "site"},
    );
    var response = await HttpClient.instance.postJson(
      gplApiUrl,
      header: headers,
      data: liveGpl,
    );
    var token = response['data']['streamPlaybackAccessToken']['value'];
    var sign = response['data']['streamPlaybackAccessToken']['signature'];
    var liveStatus = detail.status;
    if (liveStatus == true) {
// 随机选择一个sessionId
      var random = Random();
      var playSessionId = playSessionIds[random.nextInt(playSessionIds.length)];
      var epochSecondsStr = DateTime.timestamp().second.toString();
      var params = {
        "acmb": "e30=",
        "allow_source": "true",
        "cdm": "wv",
        "fast_bread": "true",
        "p": epochSecondsStr,
        "platform": "web",
        "play_session_id": playSessionId,
        "player_backend": "mediaplayer",
        "player_version": "1.28.0-rc.1",
        "playlist_include_framerate": "true",
        "reassignments_supported": "true",
        "sig": sign,
        "token": token,
        "transcode_mode": "cbr_v1"
      };
      var m3u8Url = "https://usher.ttvnw.net/api/channel/hls/${detail.roomId}.m3u8";
      var content = await HttpClient.instance.getText(
        m3u8Url,
        queryParameters: params,
        header: headers,
      );
      // 这里需要一个 m3u8解析器
      var playUrlList = <String>[];
      playUrlList.clear(); // 重置
      final lines = content.split("\n");

      for (var i in lines) {
        if (i.startsWith("https://")) {
          playUrlList.add(i.trim());
        }
      }

      if (playUrlList.isEmpty) {
        for (final i in lines) {
          if (i.trim().endsWith('m3u8')) {
            playUrlList.add(i.trim());
          }
        }
      }
      // 匹配带宽信息
      final bandwidthPattern = RegExp(r'BANDWIDTH=(\d+)');
      final bandwidthList = bandwidthPattern.allMatches(content).map((match) => match.group(1)!).toList();
      // 映射
      final urlToBandwidth = <String, int>{};
      for (int i = 0; i < playUrlList.length; i++) {
        final bandwidth = i < bandwidthList.length ? int.parse(bandwidthList[i]) : 0;
        urlToBandwidth[playUrlList[i]] = bandwidth;
      }
      playUrlList.sort((a, b) => urlToBandwidth[b]!.compareTo(urlToBandwidth[a]!));

      Map<int, LivePlayQuality> livePlayQualityMap = {};

      for (var url in playUrlList) {
        final bandwidth = urlToBandwidth[url] ?? 0;
        var livePlayQuality = livePlayQualityMap.putIfAbsent(
            bandwidth,
            () => LivePlayQuality(
                  quality: _getQualityName(bandwidth),
                  data: url, // 这里data直接存储播放URL
                  sort: bandwidth,
                  bitRate: _toBitRate(bandwidth),
                ));
        livePlayQuality.playUrlList.add(LivePlayQualityPlayUrlInfo(playUrl: url, info: ""));
      }
      qualities = livePlayQualityMap.values.toList();
    }
    return qualities;
  }

  // twitch的清晰度转换
  String _getQualityName(int bandwidth) {
    if (bandwidth > 5000000) return '1080P';
    if (bandwidth > 2500000) return '720P';
    if (bandwidth > 1000000) return '480P';
    if (bandwidth > 500000) return '360P';
    return '自动';
  }

  // twitch的清晰度转换
  int _toBitRate(int bandwidth) {
    // if (bandwidth > 5000000) return 10000;
    // if (bandwidth > 2500000) return 8000;
    // if (bandwidth > 1000000) return 2000;
    // if (bandwidth > 500000) return 1000;
    return (bandwidth / 1000).toInt();
  }

  @override
  Future<List<LivePlayQualityPlayUrlInfo>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    return quality.playUrlList;
  }

  @override

  /// 读取推荐的房间
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) {
    return Future.value(LiveCategoryResult(hasMore: false, items: <LiveRoom>[]));
  }

  @override
  Future<LiveRoom> getRoomDetail({required LiveRoom detail}) async {
    var roomInfo = await _getRoomInfo(detail.roomId!);
    var channelShell = roomInfo.first;
    var streamMetaData = roomInfo[1];

    final userOrError = channelShell.data.userOrError;
    if (userOrError == null) {
      final error = channelShell.data.userOrError;
      if (error?.typename == 'UserNotFoundError') {
        CoreLog.e('User not found: ${error?.displayName}', StackTrace.empty);
        throw Exception('Could not find user_or_error');
      }
    }
    var user = streamMetaData.data.user;
    if (user == null) {
      CoreLog.e('User not found: ${userOrError?.displayName}', StackTrace.empty);
      throw Exception('Could not find user');
    }
    bool online = switch (user.stream) {
      Stream stream when stream.streamType == 'live' => true,
      _ => false,
    };
    var title = user.lastBroadcast?.title ?? "null";
    return LiveRoom(
        roomId: detail.roomId,
        title: title,
        cover: user.profileImageUrl,
        nick: userOrError!.displayName,
        avatar: user.profileImageUrl,
        watching: (online ? user.stream!.viewersCount : 0).toString(),
        status: online,
        link: "$baseUrl/${detail.roomId}",
        introduction: "",
        notice: "",
        danmakuData: detail.roomId,
        platform: id,
        liveStatus: online? LiveStatus.live: LiveStatus.offline,
        // area: category.areaName,
        data: null);
  }

  Future<List<TwitchResponse>> _getRoomInfo(String roomId) async {
    var queries = [
      buildPersistedRequest(
        "ChannelShell",
        "fea4573a7bf2644f5b3f2cbbdcbee0d17312e48d2e55f080589d053aad353f11",
        {
          "login": roomId,
        },
      ),
      buildPersistedRequest(
        "StreamMetadata",
        "b57f9b910f8cd1a4659d894fe7550ccc81ec9052c01e438b290fd66a040b9b93",
        {
          "channelLogin": roomId,
          "includeIsDJ": true,
        },
      )
    ];
    String requestQuery = "[${queries.map((q) => q.toString()).join(',')}]";
    CoreLog.i("twitch-queries:$requestQuery");
    getRequestHeaders();
    var response = await HttpClient.instance.postJson(
      gplApiUrl,
      header: headers,
      data: requestQuery,
    );
    CoreLog.d("twitch-response:$response");

    final List<dynamic> decoded = response;
    final responses = decoded.map((item) => TwitchResponse.fromJson(item as Map<String, dynamic>)).toList();
    if (responses.length < 2) {
      CoreLog.error('Invalid response from Twitch API');
    }
    return responses;
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) {
    throw Exception("twitch暂不支持搜索主播");
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) {
    throw Exception("twitch暂不支持搜索房间");
  }
}
