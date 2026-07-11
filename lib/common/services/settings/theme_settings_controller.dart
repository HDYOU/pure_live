import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:pure_live/common/l10n/generated/l10n.dart';
import 'package:pure_live/common/services/utils/hive_rx.dart';
import 'package:pure_live/common/style/theme.dart';
import 'package:pure_live/common/services/settings/font_settings_controller.dart';

class ThemeSettingsController extends GetxController {
  final RxString themeModeName = hiveString('themeMode', "System");
  final RxBool enableDynamicTheme = hiveBool('enableDynamicTheme', false);
  final RxString themeColorSwitch = hiveString('themeColorSwitch', Colors.blue.hex);
  final RxString languageName = hiveString('language', "简体中文");
  final RxDouble crossAxisSpacing = hiveDouble('crossAxisSpacing', 6.0);
  final RxDouble mainAxisSpacing = hiveDouble('mainAxisSpacing', 6.0);
  final RxString loadingStyle = hiveString('loadingStyle', 'default');
  final RxString loadingStyleColorSwitch = hiveString('loadingStyleColorSwitch', '');

  static const Map<String, ThemeMode> themeModes = {
    "System": ThemeMode.system,
    "Dark": ThemeMode.dark,
    "Light": ThemeMode.light,
  };

  static const Map<String, Locale> languages = {
    "English": Locale('en'),
    "简体中文": Locale('zh', 'CN'),
  };

  static Map<String, Color> themeColors = {
    "Crimson": const Color.fromARGB(255, 220, 20, 60),
    "Orange": Colors.orange,
    "Chrome": const Color.fromARGB(255, 230, 184, 0),
    "Grass": Colors.lightGreen,
    "Teal": Colors.teal,
    "SeaFoam": const Color.fromARGB(255, 112, 193, 207),
    "Ice": const Color.fromARGB(255, 115, 155, 208),
    "Blue": Colors.blue,
    "Indigo": Colors.indigo,
    "Violet": Colors.deepPurple,
    "Primary": const Color(0xFF6200EE),
    "Orchid": const Color.fromARGB(255, 218, 112, 214),
    "Variant": const Color(0xFF3700B3),
    "Secondary": const Color(0xFF03DAC6),
  };

  ThemeMode get themeMode => themeModes[themeModeName.v]!;
  Locale get language => languages[languageName.v]!;

  final Map<ColorSwatch<Object>, String> colorsNameMap = themeColors.map(
    (k, v) => MapEntry(ColorTools.createPrimarySwatch(v), k),
  );

  @override
  void onInit() {
    super.onInit();
    everAll([crossAxisSpacing, mainAxisSpacing], (_) {
      Get.find<FontSettingsController>().refreshSystemTheme();
    });
  }

  void changeThemeMode(String mode) {
    themeModeName.v = mode;
    Get.changeThemeMode(themeMode);
  }

  void changeThemeColorSwitch(String hex) {
    final color = HexColor(hex);
    final t = MyTheme(primaryColor: color);
    Get.changeTheme(t.lightThemeData);
    Get.changeTheme(t.darkThemeData);
  }

  Future<void> changeLanguage(String v) async {
    languageName.v = v;
    final newLocale = language;
    EasyLocalization.of(Get.context!)?.setLocale(newLocale);
    Get.updateLocale(newLocale);
    await S.load(newLocale);
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeModeName.v,
      'enableDynamicTheme': enableDynamicTheme.v,
      'themeColorSwitch': themeColorSwitch.v,
      'language': languageName.v,
      'crossAxisSpacing': crossAxisSpacing.v,
      'mainAxisSpacing': mainAxisSpacing.v,
      'loadingStyle': loadingStyle.v,
      'loadingStyleColorSwitch': loadingStyleColorSwitch.v,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    themeModeName.v = json['themeMode'] ?? "System";
    enableDynamicTheme.v = json['enableDynamicTheme'] ?? false;
    themeColorSwitch.v = json['themeColorSwitch'] ?? const Color.fromARGB(255, 218, 70, 12).hex;
    languageName.v = json['language'] ?? "简体中文";
    crossAxisSpacing.v = json['crossAxisSpacing'] ?? 6.0;
    mainAxisSpacing.v = json['mainAxisSpacing'] ?? 6.0;
    loadingStyle.v = json['loadingStyle'] ?? 'default';
    loadingStyleColorSwitch.v = json['loadingStyleColorSwitch'] ?? '';
  }

  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final theme = rootConfig?['theme'] as Map<String, dynamic>? ?? {};
    return {
      'themeMode': theme['themeMode'] ?? "System",
      'enableDynamicTheme': theme['enableDynamicTheme'] ?? false,
      'themeColorSwitch': theme['themeColorSwitch'] ?? Colors.blue.hex,
      'language': theme['language'] ?? "简体中文",
      'crossAxisSpacing': (theme['crossAxisSpacing'] ?? 6.0).toDouble(),
      'mainAxisSpacing': (theme['mainAxisSpacing'] ?? 6.0).toDouble(),
      'loadingStyle': theme['loadingStyle'] ?? 'default',
      'loadingStyleColorSwitch': theme['loadingStyleColorSwitch'] ?? '',
    };
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    final theme = Map<String, dynamic>.from(rootConfig['theme'] ?? {});
    updateFields.forEach((k, v) => theme[k] = v);
    rootConfig['theme'] = theme;
    return rootConfig;
  }
}
