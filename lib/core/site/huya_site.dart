import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/services/settings_service.dart';
// import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/danmaku/huya_danmaku.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/core/interface/live_site.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/model/live_anchor_item.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/model/live_search_result.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'huya_site_mixin.dart';

class HuyaSite extends LiveSite with HuyaSiteMixin {
  @override
  String get id => "huya";

  @override
  String get name => "虎牙直播";

  @override
  LiveDanmaku getDanmaku() => HuyaDanmaku();

  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    List<LiveCategory> categories = [
      LiveCategory(id: "1", name: "网游", children: []),
      LiveCategory(id: "2", name: "单机", children: []),
      LiveCategory(id: "8", name: "娱乐", children: []),
      LiveCategory(id: "3", name: "手游", children: []),
    ];

    List<Future> futures = [];
    for (var item in categories) {
      futures.add(Future(() async {
        var items = await getSubCategores(item);
        item.children.addAll(items);
      }));
    }
    await Future.wait(futures);
    return categories;
  }

  final String kUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36";

  Future<List<LiveArea>> getSubCategores(LiveCategory liveCategory) async {
    var result = await HttpClient.instance.getJson(
      "https://live.cdn.huya.com/liveconfig/game/bussLive",
      queryParameters: {
        "bussType": liveCategory.id,
      },
    );

    List<LiveArea> subs = [];
    for (var item in result["data"]) {
      var gid = (item["gid"])?.toInt().toString();
      var subCategory = LiveArea(
          areaId: gid!,
          areaName: item["gameFullName"].toString(),
          areaType: liveCategory.id,
          platform: Sites.huyaSite,
          areaPic: "https://huyaimg.msstatic.com/cdnimage/game/$gid-MS.jpg",
          typeName: liveCategory.name);
      subs.add(subCategory);
    }

    return subs;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://www.huya.com/cache.php",
      queryParameters: {
        "m": "LiveList",
        "do": "getLiveListByPage",
        "tagAll": 0,
        "gameId": category.areaId,
        "page": page
      },
    );
    var result = json.decode(resultText);
    var items = <LiveRoom>[];
    for (var item in result["data"]["datas"]) {
      var cover = item["screenshot"].toString();
      if (!cover.contains("?")) {
        cover += "?x-oss-process=style/w338_h190&";
      }
      var title = item["introduction"]?.toString() ?? "";
      if (title.isEmpty) {
        title = item["roomName"]?.toString() ?? "";
      }
      var roomItem = LiveRoom(
        roomId: item["profileRoom"].toString(),
        title: title,
        cover: cover,
        nick: item["nick"].toString(),
        watching: item["totalCount"].toString(),
        avatar: item["avatar180"],
        area: item["gameFullName"].toString(),
        liveStatus: LiveStatus.live,
        status: true,
        platform: Sites.huyaSite,
      );
      items.add(roomItem);
    }
    var hasMore = result["data"]["page"] < result["data"]["totalPage"];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) {
    List<LivePlayQuality> qualities = <LivePlayQuality>[];
    var urlData = detail.data as HuyaUrlDataModel;
    if (urlData.bitRates.isEmpty) {
      urlData.bitRates = [
        HuyaBitRateModel(
          name: "原画",
          bitRate: 0,
        ),
        HuyaBitRateModel(name: "高清", bitRate: 2000),
      ];
    }
    for (var item in urlData.bitRates) {
      var urls = <String>[];
      for (var line in urlData.lines) {
        var src = line.line;
        src += "/${line.streamName}";
        if (line.lineType == HuyaLineType.flv) {
          src += ".flv";
        }
        if (line.lineType == HuyaLineType.hls) {
          src += ".m3u8";
        }
        var parms = processAnticode(
          line.lineType == HuyaLineType.flv ? line.flvAntiCode : line.hlsAntiCode,
          urlData.uid,
          line.streamName,
        );
        src += "?$parms";
        if (item.bitRate > 0) {
          src += "&ratio=${item.bitRate}";
        }
        urls.add(src);
      }
      qualities.add(LivePlayQuality(
        data: urls,
        quality: item.name,
      ));
    }

    return Future.value(qualities);
  }

  @override
  Future<List<String>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    return quality.data as List<String>;
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://www.huya.com/cache.php",
      queryParameters: {"m": "LiveList", "do": "getLiveListByPage", "tagAll": 0, "page": page},
    );
    var result = json.decode(resultText);
    var items = <LiveRoom>[];
    for (var item in result["data"]["datas"]) {
      var cover = item["screenshot"].toString();
      if (!cover.contains("?")) {
        cover += "?x-oss-process=style/w338_h190&";
      }
      var title = item["introduction"]?.toString() ?? "";
      if (title.isEmpty) {
        title = item["roomName"]?.toString() ?? "";
      }
      var roomItem = LiveRoom(
        roomId: item["profileRoom"].toString(),
        title: title,
        cover: cover,
        area: item["gameFullName"].toString(),
        nick: item["nick"].toString(),
        avatar: item["avatar180"],
        watching: item["totalCount"].toString(),
        platform: Sites.huyaSite,
        liveStatus: LiveStatus.live,
        status: true,
      );
      items.add(roomItem);
    }
    var hasMore = result["data"]["page"] < result["data"]["totalPage"];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoom> getRoomDetail(
      {required String nick, required String platform, required String roomId, required String title}) async {
    var resultText = await HttpClient.instance.getText(
        'https://mp.huya.com/cache.php?m=Live'
        '&do=profileRoom&roomid=$roomId',
        header: {
          "user-agent": kUserAgent,
        });
    var result = json.decode(resultText);
    if (result['status'] == 200 && result['data']['stream'] != null) {
      dynamic data = result['data'];
      var topSid = 0;
      var subSid = 0;
      // CoreLog.d("data: $data");
      var huyaLines = <HuyaLineModel>[];
      var huyaBiterates = <HuyaBitRateModel>[];
      //读取可用线路
      var lines = data['stream']['flv']['multiLine'];
      var baseSteamInfoList = data['stream']['baseSteamInfoList'];
      for (var item in lines) {
        if ((item["url"]?.toString() ?? "").isNotEmpty) {
          var currentStream =
              baseSteamInfoList.firstWhere((element) => element["sCdnType"] == item["cdnType"], orElse: () => null);
          if (currentStream != null) {
            topSid = currentStream["lChannelId"];
            subSid = currentStream["lSubChannelId"];
            huyaLines.add(HuyaLineModel(
              line: currentStream['sFlvUrl'],
              lineType: HuyaLineType.flv,
              flvAntiCode: currentStream["sFlvAntiCode"].toString(),
              hlsAntiCode: currentStream["sHlsAntiCode"].toString(),
              streamName: currentStream["sStreamName"].toString(),
            ));
          }
        }
      }
      //清晰度
      var biterates = data['liveData']['bitRateInfo'] != null
          ? jsonDecode(data['liveData']['bitRateInfo'])
          : data['stream']['flv']['rateArray'];
      for (var item in biterates) {
        var name = item["sDisplayName"].toString();
        if (huyaBiterates.map((e) => e.name).toList().every((element) => element != name)) {
          huyaBiterates.add(HuyaBitRateModel(
            bitRate: item["iBitRate"],
            name: name,
          ));
        }
      }
      return LiveRoom(
        cover: data['liveData']?['screenshot'] ?? '',
        watching: data['liveData']?['userCount']?.toString() ?? '',
        roomId: roomId,
        area: data['liveData']?['gameFullName'] ?? '',
        title: data['liveData']?['introduction'] ?? '',
        nick: data['profileInfo']?['nick'] ?? '',
        avatar: data['profileInfo']?['avatar180'] ?? '',
        introduction: data['liveData']?['introduction'] ?? '',
        notice: data['welcomeText'] ?? '',
        status: data['liveStatus'] == "ON" || data['liveStatus'] == "REPLAY",
        liveStatus: data['liveStatus'] == "ON" || data['liveStatus'] == "REPLAY" ? LiveStatus.live : LiveStatus.offline,
        platform: Sites.huyaSite,
        data: HuyaUrlDataModel(
          url: "",
          lines: huyaLines,
          bitRates: huyaBiterates,
          uid: getUid(t: 13, e: 10),
        ),
        danmakuData: HuyaDanmakuArgs(
          ayyuid: data["profileInfo"]["yyid"] ?? 0,
          topSid: topSid,
          subSid: subSid,
        ),
        link: "https://www.huya.com/$roomId",
      );
    } else {
      final SettingsService settings = Get.find<SettingsService>();
      LiveRoom liveRoom = settings.getLiveRoomByRoomId(roomId, platform);
      liveRoom.liveStatus = LiveStatus.offline;
      liveRoom.status = false;
      return liveRoom;
    }
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://search.cdn.huya.com/",
      queryParameters: {
        "m": "Search",
        "do": "getSearchContent",
        "q": keyword,
        "uid": 0,
        "v": 4,
        "typ": -5,
        "livestate": 0,
        "rows": 20,
        "start": (page - 1) * 20,
      },
    );
    var result = json.decode(resultText);
    var items = <LiveRoom>[];
    var queryList = result["response"]["3"]["docs"] ?? [];
    for (var item in queryList) {
      var cover = item["game_screenshot"].toString();
      if (!cover.contains("?")) {
        cover += "?x-oss-process=style/w338_h190&";
      }

      var title = item["game_introduction"]?.toString() ?? "";
      if (title.isEmpty) {
        title = item["game_roomName"]?.toString() ?? "";
      }
      var roomItem = LiveRoom(
        roomId: item["room_id"].toString(),
        title: title,
        cover: cover,
        nick: item["game_nick"].toString(),
        area: item["gameName"].toString(),
        status: true,
        liveStatus: LiveStatus.live,
        avatar: item["game_imgUrl"].toString(),
        watching: item["game_total_count"].toString(),
        platform: Sites.huyaSite,
      );
      items.add(roomItem);
    }
    return LiveSearchRoomResult(hasMore: queryList.length > 0, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) async {
    var resultText = await HttpClient.instance.getJson(
      "https://search.cdn.huya.com/",
      queryParameters: {
        "m": "Search",
        "do": "getSearchContent",
        "q": keyword,
        "uid": 0,
        "v": 1,
        "typ": -5,
        "livestate": 0,
        "rows": 20,
        "start": (page - 1) * 20,
      },
    );
    var result = json.decode(resultText);
    var items = <LiveAnchorItem>[];
    for (var item in result["response"]["1"]["docs"]) {
      var anchorItem = LiveAnchorItem(
        roomId: item["room_id"].toString(),
        avatar: item["game_avatarUrl180"].toString(),
        userName: item["game_nick"].toString(),
        liveStatus: item["gameLiveOn"],
      );
      items.add(anchorItem);
    }
    var hasMore = result["response"]["1"]["numFound"] > (page * 20);
    return LiveSearchAnchorResult(hasMore: hasMore, items: items);
  }

  @override
  Future<bool> getLiveStatus(
      {required String nick, required String platform, required String roomId, required String title}) async {
    var resultText = await HttpClient.instance.getText("https://m.huya.com/$roomId", queryParameters: {}, header: {
      "user-agent": kUserAgent,
    });
    var text =
        RegExp(r"window\.HNF_GLOBAL_INIT.=.\{(.*?)\}.</script>", multiLine: false).firstMatch(resultText)?.group(1);
    var jsonObj = json.decode("{$text}");
    return jsonObj["roomInfo"]["eLiveStatus"] == 2;
  }

  /// 匿名登录获取uid
  Future<String> getAnonymousUid() async {
    var result = await HttpClient.instance.postJson(
      "https://udblgn.huya.com/web/anonymousLogin",
      data: {"appId": 5002, "byPass": 3, "context": "", "version": "2.4", "data": {}},
      header: {
        "user-agent": kUserAgent,
      },
    );
    return result["data"]["uid"].toString();
  }

  String getUUid() {
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    var randomValue = Random().nextInt(4294967295);
    var result = (currentTime % 10000000000 * 1000 + randomValue) % 4294967295;
    return result.toString();
  }

  String getUid({int? t, int? e}) {
    var n = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".split("");
    var o = List.filled(36, '');
    if (t != null) {
      for (var i = 0; i < t; i++) {
        o[i] = n[Random().nextInt(e ?? n.length)];
      }
    } else {
      o[8] = o[13] = o[18] = o[23] = "-";
      o[14] = "4";
      for (var i = 0; i < 36; i++) {
        if (o[i].isEmpty) {
          var r = Random().nextInt(16);
          o[i] = n[19 == i ? 3 & r | 8 : r];
        }
      }
    }
    return o.join("");
  }
  // String getRealUrl(String e) {
  //   //https://github.com/wbt5/real-url/blob/master/huya.py
  //   //使用ChatGPT转换的Dart代码,ChatGPT真好用
  //   List<String> iAndB = e.split('?');
  //   String i = iAndB[0];
  //   String b = iAndB[1];
  //   List<String> r = i.split('/');
  //   String s = r[r.length - 1].replaceAll(RegExp(r'.(flv|m3u8)'), '');
  //   List<String> bs = b.split('&');
  //   List<String> c = [];
  //   c.addAll(bs.take(3));
  //   c.add(bs.skip(3).join("&"));
  //   Map<String, String> n = {};
  //   for (var str in c) {
  //     List<String> keyValue = str.split('=');
  //     n[keyValue[0]] = keyValue[1];
  //   }
  //   String fm = Uri.decodeFull(n['fm'] ?? "").split("&")[0];
  //   String u = utf8.decode(base64Decode(fm));
  //   String p = u.split('_')[0];
  //   String f = (DateTime.now().millisecondsSinceEpoch * 1000).toString();
  //   String l = n['wsTime'] ?? "";
  //   String t = '0';
  //   String h = [p, t, s, f, l].join("_");
  //   String m = md5.convert(utf8.encode(h)).toString();
  //   String y = c[c.length - 1];
  //   String url = "$i?wsSecret=$m&wsTime=$l&u=$t&seqid=$f&$y";
  //   url = url.replaceAll("&ctype=tars_mobile", "");
  //   url = url.replaceAll(RegExp(r"ratio=\d+&"), "");
  //   url = url.replaceAll(RegExp(r"imgplus_\d+"), "imgplus");
  //   return url;
  // }

  String processAnticode(String anticode, String uid, String streamname) {
    // 来源：https://github.com/iceking2nd/real-url/blob/master/huya.py
    // https://github.com/SeaHOH/ykdl/blob/master/ykdl/extractors/huya/live.py
    // 通过ChatGPT转换的Dart代码
    var query = Uri.splitQueryString(anticode);
    query["t"] = "103";
    query["ctype"] = "tars_mobile";

    final wsTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 21600).toRadixString(16);
    final seqId = (DateTime.now().millisecondsSinceEpoch + int.parse(uid)).toString();

    final fm = utf8.decode(base64.decode(Uri.decodeComponent(query['fm']!)));
    final wsSecretPrefix = fm.split('_').first;
    final wsSecretHash = md5.convert(utf8.encode('$seqId|${query["ctype"]}|${query["t"]}')).toString();
    final wsSecret =
        md5.convert(utf8.encode('${wsSecretPrefix}_${uid}_${streamname}_${wsSecretHash}_$wsTime')).toString();
    tz.initializeTimeZones();
    final location = tz.getLocation('Asia/Shanghai');
    final now = tz.TZDateTime.now(location);
    final formatter = DateFormat('yyyyMMddHH');
    final formatted = formatter.format(now);
    return Uri(queryParameters: {
      "wsSecret": wsSecret,
      "wsTime": wsTime,
      "seqid": seqId,
      "ctype": query["ctype"]!,
      "ver": "1",
      "fs": query["fs"]!,
      // "sphdcdn": query["sphdcdn"] ?? "",
      // "sphdDC": query["sphdDC"] ?? "",
      // "sphd": query["sphd"] ?? "",
      // "exsphd": query["exsphd"] ?? "",
      "dMod": "mseh-0",
      "sdkPcdn": "1_1",
      "uid": uid,
      "uuid": getUUid(),
      "t": query["t"]!,
      "sv": "202411221719", // formatted
      "sdk_sid": "1732862566708",
      "a_block": "0"
    }).query;
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) {
    //尚不支持
    return Future.value([]);
  }
}

class HuyaUrlDataModel {
  final String url;
  final String uid;
  List<HuyaLineModel> lines;
  List<HuyaBitRateModel> bitRates;
  HuyaUrlDataModel({
    required this.bitRates,
    required this.lines,
    required this.url,
    required this.uid,
  });
}

enum HuyaLineType {
  flv,
  hls,
}

class HuyaLineModel {
  final String line;
  final String flvAntiCode;
  final String hlsAntiCode;
  final String streamName;
  final HuyaLineType lineType;

  HuyaLineModel({
    required this.line,
    required this.lineType,
    required this.flvAntiCode,
    required this.hlsAntiCode,
    required this.streamName,
  });
}

class HuyaBitRateModel {
  final String name;
  final int bitRate;
  HuyaBitRateModel({
    required this.bitRate,
    required this.name,
  });
}
