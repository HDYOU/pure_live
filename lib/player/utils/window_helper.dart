import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

/// 窗口布局模式
enum WindowLayoutMode { normal, pip }

/// 窗口辅助工具类
/// 用于桌面端窗口管理，包括 PIP 画中画模式
class WindowHelper {
  static final WindowHelper instance = WindowHelper._internal();
  WindowHelper._internal();

  final Size defaultSize = const Size(1280, 720);
  WindowLayoutMode currentMode = WindowLayoutMode.normal;

  Size _savedSize = const Size(1280, 720);
  Offset _savedPosition = Offset.zero;

  /// 切换 PIP 模式
  Future<void> togglePiP(double videoRatio) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    if (currentMode == WindowLayoutMode.normal) {
      await enterPiP(videoRatio);
    } else {
      await exitPiP();
    }
  }

  /// 进入 PIP 画中画模式
  Future<void> enterPiP(double videoRatio) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    currentMode = WindowLayoutMode.pip;

    _savedSize = await windowManager.getSize();
    _savedPosition = await windowManager.getPosition();

    Display display = await screenRetriever.getPrimaryDisplay();
    Size safeSize = display.visibleSize ?? display.size;
    Offset safeOffset = display.visiblePosition ?? Offset.zero;

    double w, h;

    if (videoRatio > 1.05) {
      double maxSide = 360.0;
      w = maxSide;
      h = maxSide / videoRatio;
    } else if (videoRatio < 0.95) {
      double maxSide = 380.0;
      h = maxSide;
      w = h * videoRatio;
      if (w < 140) {
        w = 140;
        h = w / videoRatio;
      }
    } else {
      double maxSide = 280.0;
      if (videoRatio >= 1.0) {
        w = maxSide;
        h = maxSide / videoRatio;
      } else {
        h = maxSide;
        w = h * videoRatio;
      }
    }

    double x = (safeOffset.dx + safeSize.width) - w - 20;
    double y = (safeOffset.dy + safeSize.height) - h - 20;

    if (x < safeOffset.dx) x = safeOffset.dx + 20;
    if (y < safeOffset.dy) y = safeOffset.dy + 20;

    await windowManager.setAlwaysOnTop(true);
    await windowManager.setMinimumSize(Size.zero);

    await windowManager.setSize(Size(w, h));
    await windowManager.setPosition(Offset(x, y));
  }

  /// 退出 PIP 画中画模式
  Future<void> exitPiP() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    currentMode = WindowLayoutMode.normal;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setMinimumSize(const Size(800, 600));
    await windowManager.setSize(_savedSize);
    await windowManager.setPosition(_savedPosition);
  }
}
