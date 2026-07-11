import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/refresh_config_controller.dart';

class RefreshSettingsPage extends StatelessWidget {
  const RefreshSettingsPage({super.key});

  RefreshConfigController get _refresh => Get.find<RefreshConfigController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n("refresh_settings"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("auto_refresh")),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n("auto_refresh_favorite"),
              subtitle: i18n("auto_refresh_favorite_subtitle"),
              value: _refresh.autoRefreshFavorite,
              icon: Icons.refresh,
            ),
            Obx(
              () => Visibility(
                visible: _refresh.autoRefreshFavorite.v,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Remix.time_line),
                      title: Text(i18n("refresh_interval")),
                      subtitle: Text("${_refresh.autoRefreshInterval.v} ${i18n('seconds')}"),
                      onTap: () => _showIntervalDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Remix.stack_line),
                      title: Text(i18n("max_concurrent_refresh")),
                      subtitle: "${_refresh.maxConcurrentRefresh.v}",
                      onTap: () => _showMaxConcurrentDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showIntervalDialog(BuildContext context) {
    final List<int> options = [15, 30, 60, 120, 300, 600];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n("refresh_interval")),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((val) {
              return RadioListTile<int>(
                title: Text("$val ${i18n('seconds')}"),
                value: val,
                groupValue: _refresh.autoRefreshInterval.v,
                onChanged: (int? value) {
                  if (value != null) {
                    _refresh.autoRefreshInterval.v = value;
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showMaxConcurrentDialog(BuildContext context) {
    final List<int> options = [1, 2, 3, 5, 8, 10];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n("max_concurrent_refresh")),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((val) {
              return RadioListTile<int>(
                title: Text("$val"),
                value: val,
                groupValue: _refresh.maxConcurrentRefresh.v,
                onChanged: (int? value) {
                  if (value != null) {
                    _refresh.maxConcurrentRefresh.v = value;
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
