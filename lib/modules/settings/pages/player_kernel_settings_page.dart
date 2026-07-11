import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/style/app_text_styles.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/common/services/settings/player_settings_controller.dart';

class PlayerKernelSettingsPage extends StatelessWidget {
  const PlayerKernelSettingsPage({super.key});

  PlayerSettingsController get _player => Get.find<PlayerSettingsController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(i18n("player_kernel"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("player_kernel")),
          context.buildModernCard([
            Obx(
              () => context.buildTile(
                icon: Remix.cpu_line,
                title: i18n("player_kernel"),
                subtitle: PlayerConsts.names[_player.videoPlayerKey.v] ?? _player.videoPlayerKey.v,
                onTap: () => _showPlayerSelectorDialog(context),
                trailing: Text(
                  PlayerConsts.names[_player.videoPlayerKey.v] ?? _player.videoPlayerKey.v,
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("video_fit")),
          context.buildModernCard([
            Obx(
              () => context.buildTile(
                icon: Remix.aspect_ratio_line,
                title: i18n("video_fit"),
                onTap: () => _showVideoFitDialog(context),
                trailing: Text(
                  _videoFitNames[_player.videoFitIndex.v] ?? 'Default',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("hardware_acceleration")),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n("enable_codec"),
              subtitle: "",
              value: _player.enableCodec,
              icon: Remix.microscope_line,
            ),
            context.buildSwitchTile(
              title: i18n("compat_mode"),
              subtitle: "",
              value: _player.playerCompatMode,
              icon: Remix.settings_2_line,
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("advanced_settings")),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n("custom_output"),
              subtitle: "",
              value: _player.customPlayerOutput,
              icon: Remix.video_upload_line,
            ),
            Obx(
              () => context.buildTile(
                icon: Remix.computer_line,
                title: i18n("video_output_driver"),
                subtitle: _player.videoOutputDriver.v,
                onTap: _player.customPlayerOutput.v ? () => _showVideoOutputDialog(context) : null,
              ),
            ),
            Obx(
              () => context.buildTile(
                icon: Remix.volume_up_line,
                title: i18n("audio_output_driver"),
                subtitle: _player.audioOutputDriver.v,
                onTap: _player.customPlayerOutput.v ? () => _showAudioOutputDialog(context) : null,
              ),
            ),
            Obx(
              () => context.buildTile(
                icon: Remix.cpu_line,
                title: i18n("hardware_decoder"),
                subtitle: _player.videoHardwareDecoder.v,
                onTap: _player.customPlayerOutput.v ? () => _showHardwareDecoderDialog(context) : null,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildModernCard([
            ListTile(
              title: Text(i18n("reset_player_settings"), style: const TextStyle(color: Colors.red)),
              leading: const Icon(Remix.restart_line, color: Colors.red),
              onTap: () {
                _player.resetMpvPlayerSettings();
              },
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static const List<String> _videoFitNames = [
    'Contain',
    'Cover',
    'Fill',
    'Fit Height',
    'Fit Width',
    'Scale Down',
  ];

  void _showPlayerSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(i18n("player_kernel")),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: PlayerConsts.engines.keys.map<Widget>((key) {
                  return RadioListTile<String>(
                    title: Text(PlayerConsts.names[key] ?? key),
                    value: key,
                    groupValue: _player.videoPlayerKey.v,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        _player.videoPlayerKey.v = value;
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

  void _showVideoFitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(i18n("video_fit")),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_videoFitNames.length, (index) {
                  return RadioListTile<int>(
                    title: Text(_videoFitNames[index]),
                    value: index,
                    groupValue: _player.videoFitIndex.v,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (int? value) {
                      if (value != null) {
                        _player.videoFitIndex.v = value;
                        Navigator.of(context).pop();
                      }
                    },
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVideoOutputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(i18n("video_output_driver")),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: PlayerConsts.videoOutputDrivers.entries.map<Widget>((entry) {
                  return RadioListTile<String>(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: _player.videoOutputDriver.v,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        _player.videoOutputDriver.v = value;
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

  void _showAudioOutputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(i18n("audio_output_driver")),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: PlayerConsts.audioOutputDrivers.entries.map<Widget>((entry) {
                  return RadioListTile<String>(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: _player.audioOutputDriver.v,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        _player.audioOutputDriver.v = value;
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

  void _showHardwareDecoderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(i18n("hardware_decoder")),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: PlayerConsts.hardwareDecoder.entries.map<Widget>((entry) {
                  return RadioListTile<String>(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: _player.videoHardwareDecoder.v,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        _player.videoHardwareDecoder.v = value;
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
