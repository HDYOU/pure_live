import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pure_live/common/models/bilibili_user_info_page.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/interface/live_site_mixin.dart';
import 'package:pure_live/core/site/bilibili_site.dart';
import 'package:pure_live/core/sites.dart';

mixin BilibiliSiteMixin on SiteAccount{

  /// ------------------ 登录
  @override
  bool isSupportLogin() => true;

  @override
  URLRequest webLoginURLRequest(){
    return URLRequest(
      url: WebUri("https://passport.bilibili.com/login"),
    );
  }

  @override
  bool webLoginHandle(WebUri? uri){
    if (uri == null) {
      return false;
    }
    return uri.host == "m.bilibili.com" || uri.host == "www.bilibili.com";
  }

  /// 加载二维码
  @override
  Future<QRBean> loadQRCode() async{
    var qrBean = QRBean();
    try {
      qrBean.qrStatus = QRStatus.loading;

      var result = await HttpClient.instance.getJson(
        "https://passport.bilibili.com/x/passport-login/web/qrcode/generate",
      );
      if (result["code"] != 0) {
        throw result["message"];
      }
      qrBean.qrcodeKey = result["data"]["qrcode_key"];
      qrBean.qrcodeUrl = result["data"]["url"];
      qrBean.qrStatus = QRStatus.unscanned;
    } catch (e) {
      CoreLog.error(e);
      SmartDialog.showToast(e.toString());
      qrBean.qrStatus = QRStatus.failed;
    }
    return qrBean;
  }

  ///  获取二维码扫描状态
  @override
  Future<QRBean> pollQRStatus(Site site, QRBean qrBean) async{
    try {
      var response = await HttpClient.instance.get(
        "https://passport.bilibili.com/x/passport-login/web/qrcode/poll",
        queryParameters: {
          "qrcode_key": qrBean.qrcodeKey,
        },
      );
      if (response.data["code"] != 0) {
        throw response.data["message"];
      }
      var data = response.data["data"];
      var code = data["code"];
      if (code == 0) {
        var cookies = <String>[];
        response.headers["set-cookie"]?.forEach((element) {
          var cookie = element.split(";")[0];
          cookies.add(cookie);
        });
        if (cookies.isNotEmpty) {
          var cookieStr = cookies.join(";");
          await loadUserInfo(site, cookieStr);
          qrBean.qrStatus = QRStatus.success;
        }
      } else if (code == 86038) {
        qrBean.qrStatus = QRStatus.expired;
        qrBean.qrcodeKey = "";
      } else if (code == 86090) {
        qrBean.qrStatus = QRStatus.scanned;
      }
    } catch (e) {
      CoreLog.error(e);
      SmartDialog.showToast(e.toString());
    }
    return qrBean;
  }

  @override
  Future<bool> loadUserInfo(Site site, String cookie) async {
    try {
      var result = await HttpClient.instance.getJson(
        "https://api.bilibili.com/x/member/web/account",
        header: {
          "Cookie": cookie,
        },
      );
      if (result["code"] == 0) {
        var info = BiliBiliUserInfoModel.fromJson(result["data"]);
        userName.value = info.uname ?? "未登录";
        uid = info.mid ?? 0;
        var flag = info.uname != null;
        isLogin.value = flag;
        CoreLog.d("isLogin: ${flag}");
        userCookie.value = cookie;
        var liveSite = site.liveSite as BiliBiliSite;
        liveSite.cookie = cookie;
        return flag;
      } else {
        SmartDialog.showToast("${site.name}登录已失效，请重新登录");
        logout(site);
      }
    } catch (e) {
      CoreLog.error(e);
      SmartDialog.showToast("获取${site.name}用户信息失败，可前往账号管理重试");
    }
    return false;
  }
}