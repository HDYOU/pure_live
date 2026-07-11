import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:window_manager/window_manager.dart';
import 'package:pure_live/common/style/app_text_styles.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/utils/toast_util.dart';
import 'package:pure_live/common/services/settings/app_settings_controller.dart';
import 'package:pure_live/common/services/settings/exit_settings_controller.dart';
import 'package:pure_live/common/services/settings/startup_controller.dart';
import 'package:pure_live/common/services/settings/window_size_controller.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  AppSettingsController get _app => Get.find<AppSettingsController>();
  ExitSettingsController get _exit => Get.find<ExitSettingsController>();
  StartupController get _startup => Get.find<StartupController>();
  WindowSizeController get _window => Get.find<WindowSizeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n("general"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("general")),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n('splash_animation'),
              subtitle: i18n("splash_animation_subtitle"),
              value: _app.showSplashPage,
              icon: Remix.rocket_2_line,
            ),
            context.buildSwitchTile(
              title: i18n('enable_auto_check_update'),
              subtitle: "",
              value: _app.enableAutoCheckUpdate,
              icon: Remix.refresh_line,
            ),
            context.buildSwitchTile(
              title: i18n('enable_countdown_close'),
              subtitle: i18n('enable_countdown_close_subtitle'),
              value: _exit.enableAutoShutDownTime,
              icon: Remix.timer_line,
            ),
            Obx(() {
              final bool isEnabled = _exit.enableAutoShutDownTime.v;
              final int configMinutes = _exit.autoShutDownTime.v;

              return StreamBuilder<int>(
                key: ValueKey('${isEnabled}_$configMinutes'),
                stream: _exit.stopWatchTimer.rawTime,
                builder: (context, snapshot) {
                  final int value = snapshot.data ?? 0;
                  String subtitleText = "";

                  if (!isEnabled || value == 0) {
                    subtitleText = "$configMinutes ${i18n('minutes')}";
                  } else {
                    final displayTime = StopWatchTimer.getDisplayTime(value, hours: false, milliSecond: false);
                    subtitleText = "${i18n('remaining_time')}: $displayTime";
                  }

                  return context.buildTile(
                    icon: Remix.time_line,
                    title: i18n('countdown_duration'),
                    subtitle: subtitleText,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showCountdownDurationDialog(context),
                  );
                },
              );
            }),
            if (Platform.isWindows) ...[
              context.buildSwitchTile(
                title: i18n("startup"),
                subtitle: "",
                value: _startup.enableStartUp,
                icon: Remix.windows_line,
              ),
              Obx(
                () => context.buildTile(
                  icon: Remix.aspect_ratio_line,
                  title: i18n("window_size"),
                  subtitle: "${_window.storedWidth.v.toInt()} × ${_window.storedHeight.v.toInt()}",
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showWindowSizeDialog(context),
                ),
              ),
              context.buildSwitchTile(
                title: i18n("no_exit_confirm"),
                subtitle: "",
                value: _exit.dontAskExit,
                icon: Remix.error_warning_line,
              ),
            ],
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showWindowSizeDialog(BuildContext context) {
    final widthController = TextEditingController(text: _window.storedWidth.v.toInt().toString());
    final heightController = TextEditingController(text: _window.storedHeight.v.toInt().toString());

    final presets = [
      {'name': '1080 × 720', 'w': 1080.0, 'h': 720.0},
      {'name': '1280 × 720 (720P)', 'w': 1280.0, 'h': 720.0},
      {'name': '1600 × 900', 'w': 1600.0, 'h': 900.0},
      {'name': '1920 × 1080 (1080P)', 'w': 1920.0, 'h': 1080.0},
      {'name': '2560 × 1440 (2K)', 'w': 2560.0, 'h': 1440.0},
    ];

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(i18n("window_size")),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i18n("preset_options"), style: AppTextStyles.t13.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((preset) {
                      return ActionChip(
                        label: Text(preset['name'] as String),
                        onPressed: () {
                          widthController.text = (preset['w'] as double).toInt().toString();
                          heightController.text = (preset['h'] as double).toInt().toString();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widthController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: i18n("width"),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("×"),
                      ),
                      Expanded(
                        child: TextField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: i18n("height"),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(i18n("cancel"))),
            TextButton(
              onPressed: () async {
                final double? w = double.tryParse(widthController.text);
                final double? h = double.tryParse(heightController.text);
                if (w != null && h != null && w > 0 && h > 0) {
                  _window.storedWidth.v = w;
                  _window.storedHeight.v = h;
                  _window.updateSize(Size(w, h));
                  await windowManager.setSize(Size(w, h), animate: true);
                  await windowManager.center();
                  _window.setTracking(true);
                  Navigator.pop(Get.context!);
                  ToastUtil.show(i18n("save_success"));
                } else {
                  ToastUtil.show(i18n("invalid_input"));
                }
              },
              child: Text(i18n("confirm")),
            ),
          ],
        );
      },
    );
  }

  void _showCountdownDurationDialog(BuildContext context) {
    final List<int> minutesOptions = [15, 30, 45, 60, 90, 120, 180];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(i18n('select_countdown_duration')),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Obx(() {
                final selectedValue = _exit.autoShutDownTime.v;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: minutesOptions.map<Widget>((minutes) {
                    final bool isSelected = selectedValue == minutes;
                    return ChoiceChip(
                      label: Text("$minutes ${i18n('minutes')}"),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          _exit.updateShutDownTime(minutes);
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  }).toList(),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
