import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/widgets/settings/settings_card_v2.dart';
import 'package:pure_live/common/widgets/settings/settings_list_item.dart';
import 'package:pure_live/common/widgets/settings/settings_switch.dart';
import 'package:pure_live/common/widgets/utils.dart';

import '../common/platform_selector_dialog.dart';

final class SettingsNetwork {
  /// 网络管理
  static Future<void> showSettingsNetworkSetDialog() async {
    Utils.showRightOrBottomSheet(
        title: "网络管理",
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SettingsCardV2(children: [
            Obx(() => SettingsSwitch(
                  leading: const Icon(Icons.image_search_outlined),
                  title: Text("图片代理"),
                  subtitle: Text("代理图片请求"),
                  value: SettingsService.instance.networkImageProxy.value,
                  onChanged: (bool value) => SettingsService.instance.networkImageProxy.value = value,
                )),
            SettingsListItem(
              leading: const Icon(Icons.vaping_rooms_outlined),
              title: Text("API请求代理"),
              onTap: () async {
                PlatformSelectorDialog.showPreferPlatformSelectorDialog("API请求代理", SettingsService.instance.networkApiProxy);
              },
            ),
          ])
        ]));
  }
}
