import 'package:get/get.dart';
import 'package:pure_live/common/l10n/generated/l10n.dart';
import 'package:pure_live/common/services/setting_mixin/setting_part.dart';
import 'package:pure_live/common/services/setting_mixin/setting_rx.dart';
import 'package:pure_live/common/utils/pref_util.dart';

/// 码率
mixin SettingBitRateMixin {
  /// 码率
  /// 流畅 250
  /// 标清 500
  /// 高清 1000
  /// 超清 2000
  ///
  /// 蓝光4M 4000
  /// 蓝光8M 8000
  /// 蓝光10M 10_000
  /// 蓝光20M 20_000
  /// 蓝光30M 30_000
  ///
  /// 原画 0
  /// 选择码率
  List<int> bitRateList = [0, 30000, 20000, 10000, 8000, 4000, 2000, 1000, 500, 250];

  String getBitRateName(int bitRate){
    var s = S.of(Get.context!);
    switch(bitRate) {
      case 0:
        return s.bit_rate_0;
      case 250:
        return s.bit_rate_250;
      case 500:
        return s.bit_rate_500;
      case 1000:
        return s.bit_rate_1000;
      case 2000:
        return s.bit_rate_2000;
    }
    var data = bitRate / 1000;
    var txt = "${s.bit_rate_4000}${data.toInt()}M";
    return txt;
  }

  /// 码率
  final bitRateBuild = SettingRxBuild(key: "bitRate", defaultValue: 4000);
  late final bitRate = bitRateBuild.rxValue;

  /// 码率
  final bitRateMobileBuild = SettingRxBuild(key: "bitRateMobile", defaultValue: 250);
  late final bitRateMobile = bitRateMobileBuild.rxValue;
  
  void initBitRate(SettingPartList settingPartList) {
    var list = [bitRateBuild, bitRateMobileBuild];
    for (var value in list) {
      settingPartList.fromJsonList.add(value.fromJsonFunc);
      settingPartList.toJsonList.add(value.toJsonFunc);
      settingPartList.defaultConfigList.add(value.defaultConfigFunc);
    }
  }
}
