import 'package:get/get.dart';
import 'package:pure_live/common/services/setting_mixin/setting_part.dart';
import 'package:pure_live/common/utils/pref_util.dart';

/// 码率
mixin SettingVideoPlayMixin {
  static var videoPlayTypeKey = "videoPlayType";
  static var videoPlayTypeList = ["flv", "m3u8"];
  static var videoPlayTypeDefault = videoPlayTypeList[0];
  final videoPlayType = (PrefUtil.getString(videoPlayTypeKey) ?? videoPlayTypeDefault).obs;

  static var videoPlayCodecKey = "videoPlayCodec";
  static var videoPlayCodecList = ["avc", "hevc", "av1"];
  static var videoPlayCodecDefault = videoPlayCodecList[0];
  final videoPlayCodec = (PrefUtil.getString(videoPlayCodecKey) ?? videoPlayCodecDefault).obs;

  void initVideoPlay(SettingPartList settingPartList) {
    videoPlayType.listen((value) {
      PrefUtil.setString(videoPlayTypeKey, value);
    });

    videoPlayCodec.listen((value) {
      PrefUtil.setString(videoPlayCodecKey, value);
    });

    settingPartList.fromJsonList.add(fromJsonVideoPlay);
    settingPartList.toJsonList.add(toJsonVideoPlay);
    settingPartList.defaultConfigList.add(defaultConfigVideoPlay);
  }

  //// -------------- 默认
  void fromJsonVideoPlay(Map<String, dynamic> json) {
    videoPlayType.value = json[videoPlayTypeKey] ?? videoPlayTypeDefault;
    videoPlayCodec.value = json[videoPlayCodecKey] ?? videoPlayCodecDefault;
  }

  void toJsonVideoPlay(Map<String, dynamic> json) {
    json[videoPlayTypeKey] = videoPlayType.value;
    json[videoPlayCodecKey] = videoPlayCodec.value;
  }

  void defaultConfigVideoPlay(Map<String, dynamic> json) {
    json[videoPlayTypeKey] = videoPlayTypeDefault;
    json[videoPlayCodecKey] = videoPlayCodecDefault;
  }
}
