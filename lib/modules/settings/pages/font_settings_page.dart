import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/style/app_text_styles.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/font_settings_controller.dart';

class FontSettingsPage extends StatelessWidget {
  const FontSettingsPage({super.key});

  FontSettingsController get _font => Get.find<FontSettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n("font_settings_title"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("font_size_body_small")),
          context.buildModernCard([
            Obx(
              () => _buildSliderTile(
                context,
                icon: Remix.font_size,
                title: i18n("font_size_body_small"),
                value: _font.fontSizeBodySmall.v,
                min: 10,
                max: 20,
                onChanged: (val) => _font.fontSizeBodySmall.v = val,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("font_size_body_medium")),
          context.buildModernCard([
            Obx(
              () => _buildSliderTile(
                context,
                icon: Remix.font_size,
                title: i18n("font_size_body_medium"),
                value: _font.fontSizeBodyMedium.v,
                min: 11,
                max: 22,
                onChanged: (val) => _font.fontSizeBodyMedium.v = val,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("font_size_body_large")),
          context.buildModernCard([
            Obx(
              () => _buildSliderTile(
                context,
                icon: Remix.font_size,
                title: i18n("font_size_body_large"),
                value: _font.fontSizeBodyLarge.v,
                min: 12,
                max: 24,
                onChanged: (val) => _font.fontSizeBodyLarge.v = val,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("font_size_title_medium")),
          context.buildModernCard([
            Obx(
              () => _buildSliderTile(
                context,
                icon: Remix.font_size,
                title: i18n("font_size_title_medium"),
                value: _font.fontSizeTitleMedium.v,
                min: 13,
                max: 26,
                onChanged: (val) => _font.fontSizeTitleMedium.v = val,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("font_size_title_large")),
          context.buildModernCard([
            Obx(
              () => _buildSliderTile(
                context,
                icon: Remix.font_size,
                title: i18n("font_size_title_large"),
                value: _font.fontSizeTitleLarge.v,
                min: 16,
                max: 32,
                onChanged: (val) => _font.fontSizeTitleLarge.v = val,
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          horizontalTitleGap: 12,
          minLeadingWidth: 0,
          minVerticalPadding: 0,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
          title: Text(title, style: AppTextStyles.t15.copyWith(fontWeight: FontWeight.w600)),
          trailing: Text(value.toStringAsFixed(1),
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
