import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/services/setting_mixin/setting_part.dart';
import 'package:pure_live/common/services/setting_mixin/setting_rx.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/iptv/src/general_utils_object_extension.dart';
import 'package:pure_live/modules/util/rx_util.dart';
import 'package:webdav_client/webdav_client.dart';

import '../../utils/snackbar_util.dart';
import '../settings_service.dart';

/// 码率
mixin SettingWebdavMixin {
  /// url
  /// 坚果云
  final webdavUrlBuild = SettingRxBuild(key: "webdavUrl", defaultValue: "https://dav.jianguoyun.com/dav/");
  late final webdavUrl = webdavUrlBuild.rxValue;

  /// 用户名
  final webdavUserBuild = SettingRxBuild(key: "webdavUser", defaultValue: "");
  late final webdavUser = webdavUserBuild.rxValue;

  /// 密码
  final webdavPwdBuild = SettingRxBuild(key: "webdavPwd", defaultValue: "");
  late final webdavPwd = webdavPwdBuild.rxValue;

  /// 路径
  final webdavPathBuild = SettingRxBuild(key: "webdavPath", defaultValue: "pure_live");
  late final webdavPath = webdavPathBuild.rxValue;

  /// webDav同步时间
  final webdavSyncTimeBuild = SettingRxBuild(key: "webdavSyncTime", defaultValue: 0);
  late final webdavSyncTime = webdavSyncTimeBuild.rxValue;

  void initWebdav(SettingPartList settingPartList) {
    var list = {webdavUrlBuild, webdavUserBuild, webdavPwdBuild, webdavPathBuild};
    for (var value in list) {
      settingPartList.fromJsonList.add(value.fromJsonFunc);
      settingPartList.toJsonList.add(value.toJsonFunc);
      settingPartList.defaultConfigList.add(value.defaultConfigFunc);
    }
  }

  Future<bool> _retryZone(Future<bool> Function() fn) async {
    int time = 1;
    while (time < 1 << 3) {
      var res = await fn();
      if (res) {
        return true;
      }
      await Future.delayed(Duration(seconds: time));
      time *= 2;
    }
    return false;
  }

  bool _isOperating = false;

  bool _haveWaitingTask = false;

  bool isMkdir = false;

  Future<void> createWebDevDir(Client client) async {
    if (!isMkdir) {
      await client.mkdirAll(webdavPath.value);
      isMkdir = true;
    }
  }

  /// Sync current data to webdav server. Return true if success.
  Future<bool> uploadData() async {
    var flag = checkWebdavConfig();
    if (!flag) return false;

    if (_haveWaitingTask) {
      return true;
    }
    if (_isOperating) {
      _haveWaitingTask = true;
      while (_isOperating) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    _haveWaitingTask = false;
    _isOperating = true;

    CoreLog.d("Uploading Data");
    var client = newClient(
      webdavUrl.value,
      user: webdavUser.value,
      password: webdavPwd.value,
      debug: false,
    );
    client.setHeaders({'content-type': 'text/plain'});
    try {
      var currentDays = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ 86400;
      webdavSyncTime.updateValueNotEquate(currentDays);
      await createWebDevDir(client);
      var files = await client.readDir(webdavPath.value);
      for (var file in files) {
        var name = file.name;
        if (name != null) {
          var version = name.split(".").first;
          if (version.isNum) {
            var days = int.parse(version) ~/ 86400;
            if (currentDays == days && file.path != null) {
              client.remove(file.path!);
              break;
            }
          }
        }
      }
      // CoreLog.d("currentDays: ${currentDays} ${DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ 86400} ${DateTime.now().millisecondsSinceEpoch} ${DateTime.now().millisecondsSinceEpoch ~/ 1000}");
      client.write("${webdavPath.value}/$currentDays.pure_live.json", stringToUint8List(jsonEncode(SettingsService.instance.toJson())));
      SnackBarUtil.success("文件上传成功");
    } catch (e, s) {
      CoreLog.error("Failed to upload data to webdav server.\n$e\n$s");
      SnackBarUtil.error("文件上传失败");
      _isOperating = false;
      return false;
    }
    _isOperating = false;
    return true;
  }

  Uint8List stringToUint8List(String str) {
    return utf8.encode(str);
  }

  void toastError(String msg) {
    SmartDialog.showToast(msg);
    CoreLog.error(msg);
    // SnackBarUtil.error(msg);
  }

  bool checkWebdavConfig() {
    if (webdavUrl.value.isNullOrEmpty) {
      toastError("webdav Url is null!");
      return false;
    }
    if (webdavUser.value.isNullOrEmpty) {
      toastError("webdav User is null!");
      return false;
    }
    if (webdavPwd.value.isNullOrEmpty) {
      toastError("webdav Password is null!");
      return false;
    }
    // if(webdavPath.value.isNullOrEmpty) {
    //   toastError("webdav Path is null!");
    //   return false;
    // }

    return true;
  }

  Future<bool> downloadData() async {
    _isOperating = true;
    bool force = true;
    try {
      var curWebdavUrl = webdavUrl.value;
      var curWebdavUser = webdavUser.value;
      var curWebdavPwd = webdavPwd.value;
      var curWebdavPath = webdavPath.value;
      CoreLog.d("Downloading Data");
      var flag = checkWebdavConfig();
      if (!flag) return false;
      var client = newClient(
        curWebdavUrl,
        user: curWebdavUser,
        password: curWebdavPwd,
        debug: false,
      );

      client.setConnectTimeout(8000);
      try {
        await createWebDevDir(client);
        var files = await client.readDir(webdavPath.value);
        int? maxVersion;
        for (var file in files) {
          var name = file.name;
          if (name != null) {
            var version = name.split(".").first;
            if (version.isNum) {
              maxVersion = max(maxVersion ?? 0, int.parse(version));
            }
          }
        }

        final fileName = maxVersion != null ? "$maxVersion.pure_live.json" : "pure_live.json";
        webdavSyncTime.updateValueNotEquate(maxVersion ?? 0);

        var list = await client.read("$curWebdavPath/$fileName");
        var text = utf8.decode(list);
        SettingsService.instance.fromJson(jsonDecode(text));
        SnackBarUtil.success('文件下载成功');
        return true;
      } catch (e, s) {
        SnackBarUtil.error('文件下载失败');
        CoreLog.error("Failed to download data from webdav server.\n$e\n$s");
        return false;
      }
    } finally {
      _isOperating = false;
    }
  }

  void syncData() async {
    var flag = checkWebdavConfig();
    if (!flag) return;

    /// 一天只同步一次
    var currentDays = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ 86400;
    var value = webdavSyncTime.value;
    if (currentDays == value) {
      return;
    }
    //webdavSyncTime.updateValueNotEquate(currentDays);

    SmartDialog.showToast("同步数据中");
    var res = await _retryZone(uploadData);
    await Future.delayed(const Duration(milliseconds: 50));
    if (!res) {
      // SmartDialog.showToast("上传数据失败, 已禁用同步");
      SnackBarUtil.error("上传数据失败, 已禁用同步");
    } else {
      ///
    }
  }
}
