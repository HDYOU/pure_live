import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/common/services/settings/favorite_room_controller.dart';

class PlatformSettingsPage extends StatelessWidget {
  const PlatformSettingsPage({super.key});

  FavoriteRoomController get _fav => Get.find<FavoriteRoomController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n("platform_settings"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("hot_areas_platforms")),
          context.buildModernCard([
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: Sites.supportSites.map((site) {
                  final isEnabled = _fav.hotAreasList.v.contains(site.id);
                  return SwitchListTile(
                    secondary: Text(site.id, style: const TextStyle(fontSize: 12)),
                    title: Text(Sites.getSiteName(site.id)),
                    value: isEnabled,
                    onChanged: (bool value) {
                      final list = List<String>.from(_fav.hotAreasList.v);
                      if (value) {
                        if (!list.contains(site.id)) list.add(site.id);
                      } else {
                        list.remove(site.id);
                      }
                      _fav.hotAreasList.v = list;
                    },
                  );
                }).toList(),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("prefer_platform")),
          context.buildModernCard([
            Obx(
              () => context.buildTile(
                icon: Remix.star_line,
                title: i18n("prefer_platform"),
                subtitle: Sites.getSiteName(_fav.preferPlatform.v),
                onTap: () => _showPreferPlatformDialog(context),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showPreferPlatformDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(i18n("prefer_platform")),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: Sites.supportSites.map<Widget>((site) {
                  return RadioListTile<String>(
                    title: Text(Sites.getSiteName(site.id)),
                    value: site.id,
                    groupValue: _fav.preferPlatform.v,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        _fav.changePreferPlatform(value);
                        Navigator.of(context).pop();
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
