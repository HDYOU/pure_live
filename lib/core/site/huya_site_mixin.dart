import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pure_live/common/models/bilibili_user_info_page.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/interface/live_site_mixin.dart';
import 'package:pure_live/core/site/bilibili_site.dart';
import 'package:pure_live/core/sites.dart';

mixin HuyaSiteMixin on SiteAccount {
  /// ------------------ 登录
  @override
  bool isSupportLogin() => false;

  @override
  URLRequest webLoginURLRequest() {
    // https://passport.douyu.com/member/login?
    return URLRequest(
      url: WebUri("https://passport.douyu.com/h5/loginActivity?"),
    );
  }

  @override
  bool webLoginHandle(WebUri? uri) {
    if (uri == null) {
      return false;
    }
    return uri.host == "m.huya.com" || uri.host == "www.huya.com";
  }

  /// 加载二维码
  @override
  Future<QRBean> loadQRCode() async {
    var qrBean = QRBean();
    try {
      qrBean.qrStatus = QRStatus.loading;

      var result = await HttpClient.instance
          .postJson("https://udblgn.huya.com/qrLgn/getQrId"
          , data: {
        "uri": "70001",
        "version": "2.6",
        "context":
            "WB-58916e5b37344847bb1e992697fab1d0-CAEA8C3B19D00001867416302D4D1A06-0a7db71f78dff9667001473048303f3d",
        "appId": "5002",
        "appSign": "1ce3bf682483d03f146f58232ec10635",
        "authId": "",
        "sdid":
            "0UnHUgv0_qmfD4KAKlwzhqcAY7-3gj360qkcN5k4wYdI0XJtscrVr62o1YYZzg1B4zkULKxJq6oV-2xAQpnZ5xbqJSN_H8_Q3j8DgA3cO31XWVkn9LtfFJw_Qo4kgKr8OZHDqNnuwg612sGyflFn1dlDml87FNjrVrYPzfR4qgh-nojBVXkQR-6PcXF4Egs16",
        "lcid": "2052",
        "byPass": "3",
        "requestId": "54445967",
        "data": {
          "behavior":
              "%7B%22furl%22%3A%22https%3A%2F%2Fwww.huya.com%2Fkasha233%22%2C%22curl%22%3A%22https%3A%2F%2Fwww.huya.com%2Fg%22%2C%22user_action%22%3A%5B%5D%7D",
          "type": "",
          "domainList": "",
          "page": "https%3A%2F%2Fwww.huya.com%2F"
        }
      });
      CoreLog.d("result: ${result}");
      if (result["returnCode"] != 0) {
        throw result["message"];
      }
      /// 验证码链接
      /// https://udblgn.huya.com/qrLgn/getQrImg?k=doOvYRrvpvvuYqDVEa&appId=5002
      var qrCode = result["data"]["qrId"];
      var appId = "5002";
      var qrcodeUrl="https://udblgn.huya.com/qrLgn/getQrImg?k=${qrCode}&appId=${appId}";
      var qrcodeImageResp = await HttpClient.instance.get(qrcodeUrl);
      qrBean.qrcodeKey = qrCode;
      qrBean.qrcodeUrl = qrcodeImageResp.data;
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
  Future<QRBean> pollQRStatus(Site site, QRBean qrBean) async {
    try {
      var milliseconds = DateTime.now().millisecondsSinceEpoch;
      var response = await HttpClient.instance
          .postJson("https://udblgn.huya.com/qrLgn/tryQrLogin",
           queryParameters: {"uri":"70003","version":"2.6","context":"WB-58916e5b37344847bb1e992697fab1d0-CAEA8C3B19D00001867416302D4D1A06-0a7db71f78dff9667001473048303f3d","appId":"5002","appSign":"1ce3bf682483d03f146f58232ec10635","authId":"","sdid":"0UnHUgv0_qmfD4KAKlwzhqZsHXvm4vLFryBc-n8pgX2AFXa8OP8eAbEAn4uaK4tX6xLV5iPDs18bgLfmm9W7t7aaP-ya6EOTIx0jAeaKPRUXWVkn9LtfFJw_Qo4kgKr8OZHDqNnuwg612sGyflFn1dlDml87FNjrVrYPzfR4qgh-nojBVXkQR-6PcXF4Egs16","lcid":"2052","byPass":"3","requestId":"54449589","data":{"qrId":"doOvYRrvpvvuYqDVEa","remember":"1","domainList":"","behavior":"%7B%22furl%22%3A%22https%3A%2F%2Fwww.huya.com%2Fkasha233%22%2C%22curl%22%3A%22https%3A%2F%2Fwww.huya.com%2Fg%22%2C%22user_action%22%3A%5B%5D%7D","page":"https%3A%2F%2Fwww.huya.com%2"}},
           header: {
        "referer": "https://www.huya.com/",
      });
      // if (response.data["error"] != 0) {
      //   throw response.data["msg"];
      // }
      /// error -2 msg "客户端还未扫码"
      /// error -1 msg "code不存在或者是已经过期"
      CoreLog.d("response: ${response}");
      /// {
      //     "uri": 70004,
      //     "version": null,
      //     "context": "WB-58916e5b37344847bb1e992697fab1d0-CAEA8C3B19D00001867416302D4D1A06-0a7db71f78dff9667001473048303f3d",
      //     "requestId": 54449589,
      //     "returnCode": 0,
      //     "message": null,
      //     "description": "",
      //     "traceid": null,
      //     "data": {
      //         "stage": 0,
      //         "wupData": null,
      //         "domainUrlList": null
      //     }
      // }
      var data = response.data["data"];
      var code = response.data["returnCode"];
      var message = response.data["message"];
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
      } else if (code == -1) {
        qrBean.qrStatus = QRStatus.expired;
        qrBean.qrcodeKey = "";
      } else if (code == 86090) {
        qrBean.qrStatus = QRStatus.scanned;
      } else {
        qrBean.qrStatus = QRStatus.unscanned;
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