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
  static const gplApiUrl = "https://pure-bat-46.deno.dev/https://gql.twitch.tv/gql";

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
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    // CoreLog.d("getCategores .....");
    var liveGpl = buildPersistedRequest("SearchCategoryTags", "b4cb189d8d17aadf29c61e9d7c7e7dcfc932e93b77b3209af5661bffb484195f", {"userQuery": "", "limit": 100});

    var response = await HttpClient.instance.postJson(
      gplApiUrl,
      header: headers,
      data: liveGpl,
    );

    List<LiveCategory> categories = [];
    // CoreLog.d("response:${jsonEncode(response)}");
    var data = response['data'];
    var searchCategoryTags = data['searchCategoryTags'];
    for (var item in searchCategoryTags) {
      categories.add(LiveCategory(id: item["id"], name: item["tagName"], children: []));
    }

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
      // CoreLog.d("getAllSubCategores: ${subsArea}");
      allSubCategores.addAll(subsArea);
      return allSubCategores;
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
    var off = (page - 1) * pageSize;
    var params = {
      "off": off,
      "blk": 0,
      "sub": {
        "1": {"off": off, "tot": 100},
        "2": {"off": 0, "tot": 180},
        "3": {"off": 0, "tot": 0}
      }
    };

    List<int> bytes = utf8.encode(jsonEncode(params));
    String cursor = base64.encode(bytes);
    var liveGpl = buildPersistedRequest(
      "BrowsePage_AllDirectories",
      "2f67f71ba89f3c0ed26a141ec00da1defecb2303595f5cda4298169549783d9e",
      {
        "limit": pageSize,
        "options": {
          "recommendationsContext": {"platform": "web"},
          "requestID": "JIRA-VXP-2397",
          "sort": "RELEVANCE",
          "tags": [liveCategory.id]
        },
        // "cursor": cursor,
      },
    );
    var response = await HttpClient.instance.postJson(
      gplApiUrl,
      header: headers,
      data: liveGpl,
    );

    // CoreLog.d("data response:${jsonEncode(response).substring(0,1000)}");
    var directoriesWithTags = response['data']['directoriesWithTags'];
    var edges = directoriesWithTags['edges'];
    var pageInfo = directoriesWithTags['pageInfo'];
    var hasNextPage = pageInfo['hasNextPage'];
    List<LiveArea> subs = [];
    for (var item in edges) {
      var node = item['node'];
      var subCategory = LiveArea(
        areaId: node["id"],
        areaName: node["name"],
        shortName: node["slug"],
        // node["displayName"] node["slug"]
        areaType: liveCategory.id,
        platform: id,
        areaPic: (node["avatarURL"] ?? "").toString().replaceFirst("https://", "https://i2.wp.com/"),
        typeName: liveCategory.name,
      );
      subs.add(subCategory);
    }
    return subs;
  }

  /// 读取类目下房间
  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) async {
    var params = [
      {
        "operationName": "DirectoryPage_Game",
        "variables": {
          "imageWidth": 50,
          "slug": category.shortName,
          "options": {
            "sort": "RELEVANCE",
            "recommendationsContext": {"platform": "web"},
            "requestID": "JIRA-VXP-2397",
            "freeformTags": null,
            "tags": [],
            "broadcasterLanguages": [],
            "systemFilters": []
          },
          "sortTypeIsRecency": false,
          "limit": 100,
          "includeCostreaming": true,
          // "cursor": "eyJvZmYiOjI2LCJibGsiOjEsInN1YiI6eyIxIjp7Im9mZiI6MjYsInRvdCI6MTAwfSwiMiI6eyJvZmYiOjAsInRvdCI6MTc5fSwiMyI6eyJvZmYiOjAsInRvdCI6MH19fQ=="
        },
        "extensions": {
          "persistedQuery": {"version": 1, "sha256Hash": "76cb069d835b8a02914c08dc42c421d0dafda8af5b113a3f19141824b901402f"}
        }
      }
    ];
    // var liveGpl = buildPersistedRequest(
    //   "DirectoryPage_Game",
    //   "76cb069d835b8a02914c08dc42c421d0dafda8af5b113a3f19141824b901402f",
    //     {
    //       "imageWidth": 50,
    //       "slug": category.shortName,
    //       "options": {
    //         "sort": "RELEVANCE",
    //         "recommendationsContext": {
    //           "platform": "web"
    //         },
    //         "requestID": "JIRA-VXP-2397",
    //         "freeformTags": null,
    //         "tags": [],
    //         "broadcasterLanguages": [],
    //         "systemFilters": []
    //       },
    //       "sortTypeIsRecency": false,
    //       "limit": 30,
    //       "includeCostreaming": true
    //     },
    // );
    var liveGpl = jsonEncode(params);
    var response = await HttpClient.instance.postJson(
      gplApiUrl,
      header: headers,
      data: liveGpl,
    );

    // CoreLog.d("data response:${jsonEncode(response)}");
    var directoriesWithTags = response[0]['data']['game']['streams'];
    var edges = directoriesWithTags['edges'];
    var pageInfo = directoriesWithTags['pageInfo'];
    var hasNextPage = pageInfo['hasNextPage'];
    List<LiveRoom> subs = [];
    for (var item in edges) {
      var node = item['node'];
      var subItem = LiveRoom(
          roomId: node["broadcaster"]["login"],
          title: node["title"],
          cover: node["previewImageURL"].replaceFirst("https://", "https://i2.wp.com/"),
          nick: node["broadcaster"]["displayName"],
          avatar: node["broadcaster"]["profileImageURL"].replaceFirst("https://", "https://i2.wp.com/"),
          watching: (node["viewersCount"] ?? 0).toString(),
          status: true,
          introduction: "",
          notice: "",
          danmakuData: node["broadcaster"]["id"],
          platform: id,
          liveStatus: LiveStatus.live,
          area: node["game"]["name"],
          data: null);
      subs.add(subItem);
    }
    return Future.value(LiveCategoryResult(hasMore: false, items: subs));
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
      // CoreLog.d("bandwidthList: ${jsonEncode(bandwidthList)}");
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
    if (bandwidth > 200000) return '160P';
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

  /// 读取推荐的房间
  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) {
    var liveArea = LiveArea(platform: id, shortName: "just-chatting", areaName: "Just Chatting");
    return getCategoryRooms(liveArea);
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
    // CoreLog.d("user.stream?.game? : ${jsonEncode(user.stream?.game?.name)}");
    return LiveRoom(
        roomId: userOrError?.login ?? detail.roomId,
        title: title,
        cover: userOrError?.bannerImageUrl.replaceFirst("https://", "https://i2.wp.com/"),
        nick: userOrError!.displayName,
        avatar: user.profileImageUrl.replaceFirst("https://", "https://i2.wp.com/"),
        watching: ((userOrError.stream ?? user.stream)?.viewersCount ?? 0).toString(),
        status: online,
        link: "$baseUrl/${detail.roomId}",
        introduction: "",
        notice: "",
        danmakuData: detail.roomId,
        platform: id,
        liveStatus: online ? LiveStatus.live : LiveStatus.offline,
        area: user.stream?.game?.name,
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
    // CoreLog.i("twitch-queries:$requestQuery");
    getRequestHeaders();
    var response = await HttpClient.instance.postJson(
      gplApiUrl,
      header: headers,
      data: requestQuery,
    );
    // CoreLog.d("twitch-response:${jsonEncode(response)}");

    final List<dynamic> decoded = response;
    final responses = decoded.map((item) => TwitchResponse.fromJson(item as Map<String, dynamic>)).toList();
    if (responses.length < 2) {
      CoreLog.error('Invalid response from Twitch API');
    }
    return responses;
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    var liveGpl = buildPersistedRequest(
      "SearchResultsPage_SearchResults",
      "7f3580f6ac6cd8aa1424cff7c974a07143827d6fa36bba1b54318fe7f0b68dc5",
      {
        "platform": "web",
        "query": keyword,
        "options": {
          "targets": null,
          "shouldSkipDiscoveryControl": false
        },
        "requestID": "808c9f2e-f52e-431c-8dc7-d2e3c1831d77",
        "includeIsDJ": true
      },
    );
    var response = await HttpClient.instance.postJson(
      gplApiUrl,
      header: headers,
      data: liveGpl,
    );

    // CoreLog.d("data response:${jsonEncode(response)}");
    var directoriesWithTags = response['data']['searchFor']['channels'];
    var edges = directoriesWithTags['edges'];
    List<LiveRoom> subs = [];
    for (var item in edges) {
      var node = item['item'];
      // CoreLog.d("node: ${jsonEncode(node)}");
      var stream = node["stream"];
      var status = stream != null;
      var subItem = LiveRoom(
          roomId: node["login"],
          title: node["broadcastSettings"]["title"],
          cover: (node["stream"]?["previewImageURL"] ?? "").replaceFirst("https://", "https://i2.wp.com/"),
          nick: node["displayName"],
          avatar: node["profileImageURL"].replaceFirst("https://", "https://i2.wp.com/"),
          watching: (node["stream"]?["viewersCount"] ?? 0).toString(),
          status: status,
          introduction: "",
          notice: "",
          danmakuData: node["login"],
          platform: id,
          liveStatus: status? LiveStatus.live : LiveStatus.offline,
          area: node["stream"]?["game"]?["name"] ?? "",
          data: null);
      subs.add(subItem);
    }
    return Future.value(LiveSearchRoomResult(hasMore: false, items: subs));
  }
}
