import 'package:get/get.dart';
import 'package:pure_live/common/services/setting_mixin/setting_part.dart';
import 'package:pure_live/common/services/setting_mixin/setting_rx.dart';
import 'package:pure_live/common/utils/pref_util.dart';

/// 码率
mixin SettingNetworkProxy {
  /// API 请求网络代理
  final networkApiProxyBuild = SettingRxStringListBuild(key: "networkApiProxy", defaultValue: <String>[]);
  late final networkApiProxy = networkApiProxyBuild.rxValue;

  /// 图片代理
  final networkImageProxyBuild = SettingRxBuild(key: "networkImageProxy", defaultValue: true);
  late final networkImageProxy = networkImageProxyBuild.rxValue;

  void initNetworkApiProxy(SettingPartList settingPartList) {
    var list = [networkApiProxyBuild, networkImageProxyBuild];
    for (var value in list) {
      settingPartList.fromJsonList.add(value.fromJsonFunc);
      settingPartList.toJsonList.add(value.toJsonFunc);
      settingPartList.defaultConfigList.add(value.defaultConfigFunc);
    }
  }
}
