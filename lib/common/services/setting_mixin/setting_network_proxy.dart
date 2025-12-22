import 'package:get/get.dart';
import 'package:pure_live/common/services/setting_mixin/setting_part.dart';
import 'package:pure_live/common/utils/pref_util.dart';

/// 码率
mixin SettingNetworkProxy {
  /// API 请求网络代理
  static var networkApiProxyKey = "networkApiProxy";
  static var networkApiProxyDefault = <String>[];
  final networkApiProxy = (PrefUtil.getStringList(networkApiProxyKey) ?? networkApiProxyDefault).obs;

  /// 图片代理
  static var networkImageKey = "networkImageProxy";
  static var networkImageDefault = true;
  final networkImageProxy = (PrefUtil.getBool(networkApiProxyKey) ?? networkImageDefault).obs;

  void initNetworkApiProxy(SettingPartList settingPartList) {
    networkApiProxy.listen((value) {
      PrefUtil.setStringList(networkApiProxyKey, value.toList());
    });

    networkImageProxy.listen((value) {
      PrefUtil.setBool(networkImageKey, value);
    });

    var settingPartBean = SettingPartBean(
      fromJsonFunc: (Map<String, dynamic> json) {
        networkApiProxy.value = json[networkApiProxyKey] ?? networkApiProxyDefault;
      },
      toJsonFunc: (Map<String, dynamic> json) {
        json[networkApiProxyKey] = networkApiProxy.value;
      },
      defaultConfigFunc: (Map<String, dynamic> json) {
        json[networkApiProxyKey] = networkApiProxyDefault;
      },
    );

    settingPartList.fromJsonList.add(settingPartBean.fromJsonFunc);
    settingPartList.toJsonList.add(settingPartBean.toJsonFunc);
    settingPartList.defaultConfigList.add(settingPartBean.defaultConfigFunc);
  }
}
