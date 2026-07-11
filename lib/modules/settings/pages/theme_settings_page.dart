import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pure_live/common/style/theme.dart';
import 'package:pure_live/common/style/app_text_styles.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/theme_settings_controller.dart';
import 'package:pure_live/common/services/settings/font_settings_controller.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  ThemeSettingsController get _theme => Get.find<ThemeSettingsController>();
  FontSettingsController get _font => Get.find<FontSettingsController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(i18n("theme_customization"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("theme_customization")),
          context.buildModernCard([
            context.buildTile(
              icon: Remix.moon_clear_line,
              title: i18n("change_theme_mode"),
              subtitle: i18n("change_theme_mode_subtitle"),
              onTap: () => _showThemeModeSelectorDialog(context),
            ),
            Obx(
              () => context.buildTile(
                icon: Remix.palette_line,
                title: i18n("change_theme_color"),
                subtitle: i18n("change_theme_color_subtitle"),
                onTap: () => _colorPickerDialog(),
                trailing: ColorIndicator(
                  width: 28,
                  height: 28,
                  borderRadius: 6,
                  color: HexColor(_theme.themeColorSwitch.v),
                  onSelectFocus: false,
                ),
              ),
            ),
            context.buildSwitchTile(
              title: i18n("enable_dynamic_color"),
              subtitle: i18n("enable_dynamic_color_subtitle"),
              value: _theme.enableDynamicTheme,
              icon: Remix.magic_line,
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("grid_spacing_settings")),
          context.buildModernCard([
            context.buildTile(
              icon: Remix.arrow_left_right_line,
              title: i18n("cross_axis_spacing"),
              subtitle: i18n("cross_axis_spacing_subtitle"),
              onTap: () => _showSpacingDialog(
                context: context,
                title: i18n("cross_axis_spacing"),
                currentValue: _theme.crossAxisSpacing.v,
                onSelected: (value) => _theme.crossAxisSpacing.v = value,
              ),
            ),
            context.buildTile(
              icon: Remix.arrow_up_down_line,
              title: i18n("main_axis_spacing"),
              subtitle: i18n("main_axis_spacing_subtitle"),
              onTap: () => _showSpacingDialog(
                context: context,
                title: i18n("main_axis_spacing"),
                currentValue: _theme.mainAxisSpacing.v,
                onSelected: (value) => _theme.mainAxisSpacing.v = value,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("localization_settings")),
          context.buildModernCard([
            context.buildTile(
              icon: Remix.global_line,
              title: i18n("change_language"),
              subtitle: i18n("change_language_subtitle"),
              onTap: () => _showLanguageSelectorDialog(context),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("text_size_settings")),
          context.buildModernCard([
            Obx(
              () => _buildSliderTile(
                context,
                icon: Remix.text_spacing,
                title: i18n("text_size_title"),
                value: _font.textScaleFactor.v,
                min: 0.5,
                max: 2.0,
                displayValue: _font.textScaleFactor.v.toStringAsFixed(2),
                onChanged: (val) {
                  _font.textScaleFactor.v = val;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.center,
                child: Text(i18n("text_size_preview"), style: TextStyle(color: theme.colorScheme.outline)),
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

  void _showThemeModeSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(i18n('change_theme_mode')),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: ThemeSettingsController.themeModes.keys.map<Widget>((name) {
                  return RadioListTile<String>(
                    title: Text(name),
                    value: name,
                    groupValue: _theme.themeModeName.v,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        _theme.changeThemeMode(value);
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

  Future<bool> _colorPickerDialog() async {
    return ColorPicker(
      color: HexColor(_theme.themeColorSwitch.v),
      onColorChanged: (Color color) {
        _theme.themeColorSwitch.v = color.hex;
        final themeColor = color;
        final lightTheme = MyTheme(primaryColor: themeColor).lightThemeData;
        final darkTheme = MyTheme(primaryColor: themeColor).darkThemeData;
        Get.changeTheme(lightTheme);
        Get.changeTheme(darkTheme);
      },
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(i18n("theme_color"), style: Theme.of(Get.context!).textTheme.titleMedium),
      subheading: Text(i18n("select_opacity"), style: Theme.of(Get.context!).textTheme.titleMedium),
      wheelSubheading: Text(i18n("theme_color_opacity"), style: Theme.of(Get.context!).textTheme.titleMedium),
      showMaterialName: false,
      showColorName: false,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(longPressMenu: true),
      materialNameTextStyle: Theme.of(Get.context!).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(Get.context!).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(Get.context!).textTheme.bodyMedium,
      colorCodePrefixStyle: Theme.of(Get.context!).textTheme.bodySmall,
      selectedPickerTypeColor: Theme.of(Get.context!).colorScheme.primary,
      customColorSwatchesAndNames: ThemeSettingsController.themeColors.map(
        (k, v) => MapEntry(ColorTools.createPrimarySwatch(v), k),
      ),
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
    ).showPickerDialog(
      Get.context!,
      actionsPadding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 480, minWidth: 375, maxWidth: 420),
    );
  }

  void _showLanguageSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(i18n("change_language")),
          children: [
            Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: ThemeSettingsController.languages.keys.map<Widget>((name) {
                  return RadioListTile<String>(
                    title: Text(name),
                    value: name,
                    groupValue: _theme.languageName.v,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        _theme.languageName.v = value;
                        final locale = ThemeSettingsController.languages[value]!;
                        EasyLocalization.of(Get.context!)!.setLocale(locale);
                        Get.updateLocale(locale);
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

  void _showSpacingDialog({
    required BuildContext context,
    required String title,
    required double currentValue,
    required ValueChanged<double> onSelected,
  }) {
    final List<double> quickOptions = [0.0, 4.0, 6.0, 8.0, 12.0, 16.0];
    final textController = TextEditingController(text: currentValue.toStringAsFixed(0));
    double selectedValue = currentValue;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final theme = Theme.of(context);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickOptions.map((value) {
                      final isSelected = value == selectedValue;
                      return ChoiceChip(
                        label: Text("${value.toInt()} px"),
                        selected: isSelected,
                        showCheckmark: false,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedValue = value;
                              textController.text = value.toStringAsFixed(0);
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: i18n("custom_value"),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      setDialogState(() {
                        selectedValue = parsed;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(i18n("cancel"))),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          onSelected(selectedValue);
                          Navigator.of(context).pop();
                        },
                        child: Text(i18n("confirm")),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
