import 'package:get/get.dart';
import 'package:pure_live/common/utils/pref_util.dart';

/// IPTV 设置 Mixin - 适配上游 IPTV 系统
mixin IptvSettingsMixin {
  final selectedSourceName = (PrefUtil.getString('iptv_selectedSourceName') ?? '').obs;
  final selectedSourceId = (PrefUtil.getString('iptv_selectedSourceId') ?? '').obs;
  final isAutoSyncEnabled = (PrefUtil.getBool('iptv_isAutoSyncEnabled') ?? false).obs;
  final autoSyncHoursInterval = (PrefUtil.getInt('iptv_autoSyncHoursInterval') ?? 24).obs;
  final customIptvUserAgent = (PrefUtil.getString('iptv_customIptvUserAgent') ?? '').obs;
  final m3uDirectory = (PrefUtil.getString('iptv_m3uDirectory') ?? 'm3uDirectory').obs;

  void initIptvSettings() {
    selectedSourceName.listen((value) {
      PrefUtil.setString('iptv_selectedSourceName', value);
    });
    selectedSourceId.listen((value) {
      PrefUtil.setString('iptv_selectedSourceId', value);
    });
    isAutoSyncEnabled.listen((value) {
      PrefUtil.setBool('iptv_isAutoSyncEnabled', value);
    });
    autoSyncHoursInterval.listen((value) {
      PrefUtil.setInt('iptv_autoSyncHoursInterval', value);
    });
    customIptvUserAgent.listen((value) {
      PrefUtil.setString('iptv_customIptvUserAgent', value);
    });
    m3uDirectory.listen((value) {
      PrefUtil.setString('iptv_m3uDirectory', value);
    });
  }
}

/// IPTV 设置控制器 - 供 SettingsService.to.iptv 使用
class IptvSettingsController extends GetxController {
  final RxString selectedSourceName = ''.obs;
  final RxString selectedSourceId = ''.obs;
  final RxBool isAutoSyncEnabled = false.obs;
  final RxInt autoSyncHoursInterval = 24.obs;
  final RxString customIptvUserAgent = ''.obs;
  final RxString m3uDirectory = 'm3uDirectory'.obs;

  @override
  void onInit() {
    super.onInit();
    selectedSourceName.value = PrefUtil.getString('iptv_selectedSourceName') ?? '';
    selectedSourceId.value = PrefUtil.getString('iptv_selectedSourceId') ?? '';
    isAutoSyncEnabled.value = PrefUtil.getBool('iptv_isAutoSyncEnabled') ?? false;
    autoSyncHoursInterval.value = PrefUtil.getInt('iptv_autoSyncHoursInterval') ?? 24;
    customIptvUserAgent.value = PrefUtil.getString('iptv_customIptvUserAgent') ?? '';
    m3uDirectory.value = PrefUtil.getString('iptv_m3uDirectory') ?? 'm3uDirectory';

    selectedSourceName.listen((value) {
      PrefUtil.setString('iptv_selectedSourceName', value);
    });
    selectedSourceId.listen((value) {
      PrefUtil.setString('iptv_selectedSourceId', value);
    });
    isAutoSyncEnabled.listen((value) {
      PrefUtil.setBool('iptv_isAutoSyncEnabled', value);
    });
    autoSyncHoursInterval.listen((value) {
      PrefUtil.setInt('iptv_autoSyncHoursInterval', value);
    });
    customIptvUserAgent.listen((value) {
      PrefUtil.setString('iptv_customIptvUserAgent', value);
    });
    m3uDirectory.listen((value) {
      PrefUtil.setString('iptv_m3uDirectory', value);
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedSourceName': selectedSourceName.value,
      'selectedSourceId': selectedSourceId.value,
      'isAutoSyncEnabled': isAutoSyncEnabled.value,
      'autoSyncHoursInterval': autoSyncHoursInterval.value,
      'customIptvUserAgent': customIptvUserAgent.value,
      'm3uDirectory': m3uDirectory.value,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    selectedSourceName.value = json['selectedSourceName'] ?? '';
    selectedSourceId.value = json['selectedSourceId'] ?? '';
    isAutoSyncEnabled.value = json['isAutoSyncEnabled'] ?? false;
    autoSyncHoursInterval.value = json['autoSyncHoursInterval'] ?? 24;
    customIptvUserAgent.value = json['customIptvUserAgent'] ?? '';
    m3uDirectory.value = json['m3uDirectory'] ?? 'm3uDirectory';
  }
}
