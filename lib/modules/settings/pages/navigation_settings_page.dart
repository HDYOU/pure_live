import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/app_settings_controller.dart';

class NavigationSettingsPage extends StatelessWidget {
  const NavigationSettingsPage({super.key});

  AppSettingsController get _app => Get.find<AppSettingsController>();

  static const List<Map<String, dynamic>> _menuItems = [
    {'id': 'favorites', 'name': 'favorites', 'icon': Remix.heart_line},
    {'id': 'popular', 'name': 'popular', 'icon': Remix.fire_line},
    {'id': 'areas', 'name': 'areas', 'icon': Remix.apps_2_line},
    {'id': 'categories', 'name': 'categories', 'icon': Remix.grid_line},
    {'id': 'search', 'name': 'search', 'icon': Remix.search_line},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n("navigation_display_settings"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("bottom_navigation")),
          context.buildModernCard([
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: _menuItems.map((menu) {
                  final isVisible = _app.savedMenuIds.v.contains(menu['id']);
                  return SwitchListTile(
                    secondary: Icon(menu['icon']),
                    title: Text(i18n(menu['name'])),
                    value: isVisible,
                    onChanged: (bool value) {
                      final list = List<String>.from(_app.savedMenuIds.v);
                      if (value) {
                        if (!list.contains(menu['id'])) list.add(menu['id']);
                      } else {
                        list.remove(menu['id']);
                      }
                      _app.savedMenuIds.v = list;
                    },
                  );
                }).toList(),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
