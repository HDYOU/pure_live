import 'package:get/get.dart';
import 'package:pure_live/common/services/setting_mixin/setting_part.dart';
import 'package:pure_live/common/services/setting_mixin/setting_rx.dart';
import 'package:pure_live/common/utils/pref_util.dart';

/// 码率
mixin SettingVideoPlayMixin {
  static var videoPlayTypeList = ["flv", "m3u8"];
  final videoPlayTypeBuild = SettingRxBuild(key: "videoPlayType", defaultValue: videoPlayTypeList[0]);
  late final videoPlayType = videoPlayTypeBuild.rxValue;

  static var videoPlayCodecList = ["avc", "hevc", "av1"];
  final videoPlayCodecBuild = SettingRxBuild(key: "videoPlayCodec", defaultValue: videoPlayCodecList[0]);
  late final videoPlayCodec = videoPlayCodecBuild.rxValue;

  void initVideoPlay(SettingPartList settingPartList) {
    var list = [videoPlayTypeBuild, videoPlayCodecBuild];
    for (var value in list) {
      settingPartList.fromJsonList.add(value.fromJsonFunc);
      settingPartList.toJsonList.add(value.toJsonFunc);
      settingPartList.defaultConfigList.add(value.defaultConfigFunc);
    }
  }

}
