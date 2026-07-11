import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/cache_controller.dart';

class CacheDataSettingsPage extends StatelessWidget {
  const CacheDataSettingsPage({super.key});

  CacheController get _cache => Get.find<CacheController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n("cache_and_data"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("cache_manage")),
          context.buildModernCard([
            Obx(
              () => context.buildTile(
                icon: Icons.cleaning_services_outlined,
                title: i18n("cache_size"),
                subtitle: "${_cache.cacheSizeMB.value.toStringAsFixed(2)} MB",
                onTap: () => _cache.getCacheSize(),
              ),
            ),
            ListTile(
              leading: const Icon(Remix.delete_bin_line, color: Colors.red),
              title: Text(i18n("clear_cache"), style: const TextStyle(color: Colors.red)),
              onTap: () async {
                final result = await Get.dialog(
                  AlertDialog(
                    title: Text(i18n("clear_cache")),
                    content: Text(i18n("clear_cache_confirm")),
                    actions: [
                      TextButton(onPressed: () => Get.back(result: false), child: Text(i18n("cancel"))),
                      TextButton(onPressed: () => Get.back(result: true), child: Text(i18n("confirm"))),
                    ],
                  ),
                );
                if (result == true) {
                  await _cache.clearCache();
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
