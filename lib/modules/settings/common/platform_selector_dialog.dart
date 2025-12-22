import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/widgets/settings/settings_card_v2.dart';
import 'package:pure_live/common/widgets/settings/settings_switch.dart';
import 'package:pure_live/common/widgets/utils.dart';

import '../../../common/widgets/app_style.dart';
import '../../../plugins/extension/list_extension.dart';
import '../../hot_areas/hot_areas_controller.dart';
import '../../util/site_logo_widget.dart';

final class PlatformSelectorDialog {
  /// 平台列表开关
  static void showPreferPlatformSelectorDialog(String title, RxList rsList) {
    Utils.showRightOrBottomSheet(
        title: title,
        child: Obx(() => ListView(
                // shrinkWrap: true,
                children: [
                  SettingsCardV2(children: [
                    ///
                    ...Sites.supportSites
                        .map((site) {
                          var show = rsList.contains(site.id);
                          var area = HotAreasModel(id: site.id, name: site.name, show: show);
                          return area;
                        })
                        .map((site) {
                          return SettingsSwitch(
                              leading: SiteWidget.getSiteLogeImage(site.id)!,
                              title: Text(Sites.getSiteName(site.id)),
                              value: site.show,
                              onChanged: (bool value) {
                                var data = site.id.toString();
                                if (value) {
                                  if (!rsList.contains(data)) {
                                    rsList.add(data);
                                  }
                                } else {
                                  rsList.remove(data);
                                }
                                SmartDialog.showToast('重启后生效');
                              }) as StatelessWidget;
                        })
                        .toList()
                        .joinItem(AppStyle.divider)
                  ])
                ])));
  }
}
