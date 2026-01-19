import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pure_live/common/l10n/generated/l10n.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/services/settings_service.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/interface/live_site_mixin.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../sites.dart';

mixin YoutubeSiteMixin on SiteMixin {
  @override
  String getJumpToNativeUrl(LiveRoom liveRoom) {
    try {
      var appUrl = "youtube://player/live?channel=${liveRoom.roomId}";
      return appUrl;
    } catch (e) {
      return "";
    }
  }

  @override
  String getJumpToWebUrl(LiveRoom liveRoom) {
    try {
      var webUrl = "https://www.youtube.com/channel/${liveRoom.roomId}";
      return webUrl;
    } catch (e) {
      return "";
    }
  }

  /// ------------------ 登录
  @override
  bool isSupportLogin() => true;

  @override
  bool isSupportQrLogin() => false;

  final Map<String, String> loginHeaders = {
    'User-Agent':
        // 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
        "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1 Edg/118.0.0.0",
    'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
    'connection': 'keep-alive',
    'sec-ch-ua': 'Google Chrome;v=107, Chromium;v=107, Not=A?Brand;v=24',
    'sec-ch-ua-platform': 'macOS',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-User': '?1',
    'origin': 'https://www.youtube.com',
    'x-origin': 'https://www.youtube.com',
    'referer': 'https://www.youtube.com/',
    'x-referer': 'https://www.youtube.com/',
  };

  @override
  URLRequest webLoginURLRequest() {
    return URLRequest(
      url: WebUri("https://www.youtube.com/"),
      headers: loginHeaders,
    );
  }

  @override
  bool webLoginHandle(WebUri? uri) {
    if (uri == null) {
      return false;
    }
    return uri.host == "www.youtube.com";
  }

  @override
  Future<bool> loadUserInfo(Site site, String cookie) async {
    try {
      userName.value = "Cookie";
      uid = 0;
      var flag = true;
      isLogin.value = flag;
      userCookie.value = cookie;
      SettingsService settings = SettingsService.instance;
      settings.siteCookies[site.id] = cookie;
      return flag;
    } catch (e) {
      CoreLog.error(e);
      SmartDialog.showToast(Sites.getSiteName(site.id) + S.current.login_failed);
    }
    return false;
  }

  @override
  Future<SiteParseBean> parse(String url) async {
    String realUrl = getHttpUrl(url);
    var siteParseBean = emptySiteParseBean;
    if (realUrl.isEmpty) return siteParseBean;
    // 解析跳转
    List<RegExp> regExpJumpList = [
      // 网站 解析跳转
    ];
    siteParseBean = await parseJumpUrl(regExpJumpList, realUrl);
    if (siteParseBean.roomId.isNotEmpty) {
      return siteParseBean;
    }

    List<RegExp> regExpBeanList = [
      RegExp(r'youtube\.com/channel/([^/?]+)'),
    ];
    siteParseBean = await parseUrl(regExpBeanList, realUrl, id);
    CoreLog.d("siteParseBean: ${siteParseBean}");
    if(siteParseBean != emptySiteParseBean) {
      return siteParseBean;
    }

    // 匹配 watch 视频地址
    CoreLog.d("watchReg url: ${url}");
    RegExp watchReg = RegExp(r'youtube\.com/watch\?v=([^/?]+)');
    RegExpMatch? watchMatch = watchReg.firstMatch(url);
    if (watchMatch != null) {
      String vid = watchMatch.group(1)!;
      var resp = await HttpClient.instance.getText("https://www.youtube.com/embed/$vid",header: loginHeaders);
      RegExp cidReg = RegExp(r'\"\channelId\":\"(.{24})\"');
      CoreLog.d("resp: $resp");
      RegExpMatch? cidMatch = cidReg.firstMatch(resp);
      if (cidMatch != null) {
        var channelId = cidMatch.group(1)!;
        return SiteParseBean(roomId: channelId, platform: id);
      }
    }

    return siteParseBean;
  }

  @override
  List<OtherJumpItem> jumpItems(LiveRoom liveRoom) {
    List<OtherJumpItem> list = [];

    return list;
  }
}
