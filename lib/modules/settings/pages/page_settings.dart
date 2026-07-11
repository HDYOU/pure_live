import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/page_settings_controller.dart';

class PageSettingsPage extends StatelessWidget {
  const PageSettingsPage({super.key});

  PageSettingsController get _page => Get.find<PageSettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n('page_settings'))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n('page_display')),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n('show_page_size_selector'),
              subtitle: '',
              value: _page.showPageSizeSelector,
              icon: Remix.list_check,
            ),
            context.buildSwitchTile(
              title: i18n('show_goto_button'),
              subtitle: '',
              value: _page.showGotoButton,
              icon: Remix.skip_forward_line,
            ),
            context.buildSwitchTile(
              title: i18n('show_scroll_to_top'),
              subtitle: '',
              value: _page.showScrollToTopBtn,
              icon: Remix.arrow_up_line,
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n('default_page_size')),
          context.buildModernCard([
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: _page.pageSizeOptions.map<Widget>((size) {
                  return RadioListTile<int>(
                    title: Text('$size'),
                    value: size,
                    groupValue: _page.defaultPageSize.v,
                    onChanged: (int? value) {
                      if (value != null) {
                        _page.defaultPageSize.v = value;
                      }
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
