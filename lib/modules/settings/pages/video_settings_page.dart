import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/style/app_text_styles.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/common/services/settings/player_settings_controller.dart';
import 'package:pure_live/common/services/settings/app_settings_controller.dart';
import 'package:pure_live/common/services/settings/volume_settings_controller.dart';
import 'package:pure_live/common/services/settings/danmaku_settings_controller.dart';

class VideoSettingsPage extends StatelessWidget {
  const VideoSettingsPage({super.key});

  PlayerSettingsController get _player => Get.find<PlayerSettingsController>();
  AppSettingsController get _app => Get.find<AppSettingsController>();
  VolumeSettingsController get _vol => Get.find<VolumeSettingsController>();
  DanmakuSettingsController get _danmaku => Get.find<DanmakuSettingsController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(i18n("video_settings"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("audio_settings")),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n("global_mute"),
              subtitle: i18n("global_mute_subtitle"),
              value: _vol.globalVolumeMute,
              icon: _vol.globalVolumeMute.v ? Remix.volume_mute_line : Remix.volume_up_line,
            ),
            if (Platform.isAndroid || Platform.isIOS)
              Obx(
                () => _buildSliderTile(
                  context,
                  icon: Remix.phone_line,
                  title: i18n("mobile_default_volume"),
                  value: _vol.defaultMobileVolume.v * 100,
                  min: 0.0,
                  max: 100.0,
                  displayValue: "${(_vol.defaultMobileVolume.v * 100).toStringAsFixed(0)}%",
                  onChanged: (val) => _vol.defaultMobileVolume.v = val / 100,
                ),
              ),
            if (!Platform.isAndroid && !Platform.isIOS)
              Obx(
                () => _buildSliderTile(
                  context,
                  icon: Remix.computer_line,
                  title: i18n("desktop_default_volume"),
                  value: _vol.defaultDesktopVolume.v * 100,
                  min: 0.0,
                  max: 100.0,
                  displayValue: "${(_vol.defaultDesktopVolume.v * 100).toStringAsFixed(0)}%",
                  onChanged: (val) => _vol.defaultDesktopVolume.v = val / 100,
                ),
              ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("video_quality_settings")),
          context.buildModernCard([
            Obx(
              () => context.buildTile(
                icon: Remix.hd_line,
                title: i18n("prefer_resolution"),
                subtitle: i18n("prefer_resolution_subtitle"),
                onTap: () => _showResolutionDialog(context, isWifi: true),
                trailing: Text(
                  _player.preferResolution.v,
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Obx(
              () => context.buildTile(
                icon: Remix.signal_tower_line,
                title: i18n("mobile_quality"),
                subtitle: i18n("mobile_quality_subtitle"),
                onTap: () => _showResolutionDialog(context, isWifi: false),
                trailing: Text(
                  _player.preferResolutionCellular.v,
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("playback_behavior_settings")),
          context.buildModernCard([
            if (Platform.isAndroid)
              context.buildSwitchTile(
                icon: Remix.music_2_line,
                title: i18n("enable_background_play"),
                subtitle: i18n("enable_background_play_subtitle"),
                value: _app.enableBackgroundPlay,
              ),
            context.buildSwitchTile(
              title: i18n("exit_float_window"),
              subtitle: i18n("exit_float_window_subtitle"),
              value: _player.floatPlay,
              icon: Remix.picture_in_picture_2_line,
            ),
            context.buildSwitchTile(
              title: i18n('enable_fullscreen_default'),
              subtitle: i18n('enable_fullscreen_default_subtitle'),
              value: _app.enableFullScreenDefault,
              icon: Remix.fullscreen_line,
            ),
            if (Platform.isAndroid)
              context.buildSwitchTile(
                title: i18n('enable_screen_keep_on'),
                subtitle: i18n('enable_screen_keep_on_subtitle'),
                value: _app.enableScreenKeepOn,
                icon: Remix.lightbulb_line,
              ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("danmaku_settings")),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n('show_danmaku'),
              subtitle: i18n('show_danmaku_subtitle'),
              value: _danmaku.enableDanmakuDisplay,
              icon: Remix.chat_smile_2_line,
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
    required String displayValue,
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
          trailing: Text(displayValue, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
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

  void _showResolutionDialog(BuildContext context, {required bool isWifi}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(isWifi ? i18n("prefer_resolution") : i18n("prefer_resolution_cellular")),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: PlayerConsts.resolutions.map<Widget>((name) {
                  final currentValue = isWifi ? _player.preferResolution.v : _player.preferResolutionCellular.v;
                  return RadioListTile<String>(
                    title: Text(name),
                    value: name,
                    groupValue: currentValue,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        if (isWifi) {
                          _player.changePreferResolution(value);
                        } else {
                          _player.changePreferResolutionCellular(value);
                        }
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
