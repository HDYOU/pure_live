import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/services/utils/hive_rx.dart';
export 'package:pure_live/common/services/utils/hive_rx.dart';
import 'package:pure_live/common/style/theme.dart';
import 'package:pure_live/common/services/settings/danmaku_settings_controller.dart';

class FontSettingsController extends GetxController {
  final RxDouble textScaleFactor = hiveDouble('textScaleFactor', 1.0);
  final RxDouble fontSizeBodySmall = hiveDouble('fontSizeBodySmall', 12.0);
  final RxDouble fontSizeBodyMedium = hiveDouble('fontSizeBodyMedium', 13.0);
  final RxDouble fontSizeBodyLarge = hiveDouble('fontSizeBodyLarge', 14.0);
  final RxDouble fontSizeTitleMedium = hiveDouble('fontSizeTitleMedium', 15.0);
  final RxDouble fontSizeTitleLarge = hiveDouble('fontSizeTitleLarge', 20.0);
  final RxString fontFamilyName = hiveString('fontFamilyName', 'Default');

  @override
  void onInit() {
    super.onInit();

    everAll([
      fontSizeBodySmall,
      fontSizeBodyMedium,
      fontSizeBodyLarge,
      fontSizeTitleMedium,
      fontSizeTitleLarge,
      fontFamilyName,
    ], (_) => refreshSystemTheme());
  }

  void refreshSystemTheme() {
    final theme = MyTheme(primaryColor: Get.theme.primaryColor);
    Get.changeTheme(Get.isDarkMode ? theme.darkThemeData : theme.lightThemeData);
  }

  Future<void> activateDanmakuFontFamily(String fontId) async {
    Get.find<DanmakuSettingsController>().danmakuFontFamilyName.v = fontId;
  }

  Map<String, dynamic> toJson() {
    return {
      'textScaleFactor': textScaleFactor.v,
      'fontSizeBodySmall': fontSizeBodySmall.v,
      'fontSizeBodyMedium': fontSizeBodyMedium.v,
      'fontSizeBodyLarge': fontSizeBodyLarge.v,
      'fontSizeTitleMedium': fontSizeTitleMedium.v,
      'fontSizeTitleLarge': fontSizeTitleLarge.v,
      'fontFamilyName': fontFamilyName.v,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    textScaleFactor.v = json['textScaleFactor'] ?? 1.0;
    fontSizeBodySmall.v = json['fontSizeBodySmall'] ?? 12.0;
    fontSizeBodyMedium.v = json['fontSizeBodyMedium'] ?? 13.0;
    fontSizeBodyLarge.v = json['fontSizeBodyLarge'] ?? 14.0;
    fontSizeTitleMedium.v = json['fontSizeTitleMedium'] ?? 15.0;
    fontSizeTitleLarge.v = json['fontSizeTitleLarge'] ?? 20.0;
    fontFamilyName.v = json['fontFamilyName'] ?? 'Default';
  }

  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final font = rootConfig?['font'] as Map<String, dynamic>? ?? {};
    return {
      'textScaleFactor': (font['textScaleFactor'] ?? 1.0).toDouble(),
      'fontSizeBodySmall': (font['fontSizeBodySmall'] ?? 12.0).toDouble(),
      'fontSizeBodyMedium': (font['fontSizeBodyMedium'] ?? 13.0).toDouble(),
      'fontSizeBodyLarge': (font['fontSizeBodyLarge'] ?? 14.0).toDouble(),
      'fontSizeTitleMedium': (font['fontSizeTitleMedium'] ?? 15.0).toDouble(),
      'fontSizeTitleLarge': (font['fontSizeTitleLarge'] ?? 20.0).toDouble(),
      'fontFamilyName': font['fontFamilyName'] ?? 'Default',
    };
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    final font = Map<String, dynamic>.from(rootConfig['font'] ?? {});
    updateFields.forEach((k, v) => font[k] = v);
    rootConfig['font'] = font;
    return rootConfig;
  }
}
