import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/font_settings_controller.dart';
import 'package:pure_live/common/services/settings/danmaku_settings_controller.dart';

class FontFamilyManagerPage extends StatelessWidget {
  final bool isDanmakuSettings;

  const FontFamilyManagerPage({super.key, this.isDanmakuSettings = false});

  FontSettingsController get _font => Get.find<FontSettingsController>();
  DanmakuSettingsController get _danmaku => Get.find<DanmakuSettingsController>();

  @override
  Widget build(BuildContext context) {
    final currentFont = isDanmakuSettings
        ? _danmaku.danmakuFontFamilyName.v
        : _font.fontFamilyName.v;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDanmakuSettings
            ? i18n("change_danmaku_font_family")
            : i18n("change_font_family")),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("system_fonts")),
          context.buildModernCard([
            _buildFontTile(context, 'Default', 'Default', currentFont),
            _buildFontTile(context, 'Roboto', 'Roboto', currentFont),
            _buildFontTile(context, 'System UI', 'System UI', currentFont),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("custom_fonts")),
          context.buildModernCard([
            ListTile(
              title: Text(i18n("no_custom_fonts")),
              subtitle: Text(i18n("download_fonts_hint")),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFontTile(BuildContext context, String name, String id, String currentFont) {
    final isSelected = id == currentFont;
    return ListTile(
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        if (isDanmakuSettings) {
          _danmaku.danmakuFontFamilyName.v = id;
        } else {
          _font.fontFamilyName.v = id;
        }
      },
    );
  }
}
