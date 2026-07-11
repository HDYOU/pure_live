import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/services/setting_mixin/setting_video_fit.dart';
import '../video_controller.dart' as video_player;
import '../video_controller_panel.dart';
import 'video_play_impl.dart';

import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/player/models/player_engine.dart';

/// 全局播放器适配器
/// 将 GlobalPlayerService 包装为 VideoPlayerInterFace，
/// 使其可以通过 VideoPlayerFactory 使用，同时获得全局播放器架构的所有功能：
/// - 播放器池 (PlayerPool)
/// - 预加载 (PreloadPlayerManager)
/// - 引擎降级 (EngineFallbackManager)
/// - 线路降级 (LineFallbackManager)
/// - PIP 画中画 (桌面端窗口模式)
/// - Texture 保活 (TextureKeeper)
class GlobalVideoPlay extends VideoPlayerInterFace {
  @override
  late final String playerName;

  final PlayerEngine engine;

  GlobalVideoPlay({
    required this.playerName,
    required this.engine,
  });

  late video_player.VideoController controller;

  bool _initialized = false;

  @override
  void init({required video_player.VideoController controller}) {
    this.controller = controller;
    _initialized = true;
  }

  /// 确保全局播放器服务已初始化
  Future<void> _ensureService() async {
    if (!GlobalPlayerService.instance.initialized) {
      await GlobalPlayerService.instance.initialize(defaultEngine: engine);
    }
  }

  @override
  Future<void> openVideo(String datasource, Map<String, String> headers) async {
    isBuffering.value = true;
    isPlaying.value = false;

    if (datasource.isEmpty) {
      hasError.value = true;
      return;
    } else {
      hasError.value = false;
    }

    try {
      await _ensureService();
      await GlobalPlayerService.instance.playerManager.play(
        datasource,
        [datasource], // 单线路，后续可扩展为多线路
        headers,
      );

      // 监听状态变化
      _listenToPlayerState();
    } catch (e) {
      hasError.value = true;
      isBuffering.value = false;
    }
  }

  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _widthSub;
  StreamSubscription? _heightSub;

  void _listenToPlayerState() {
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _errorSub?.cancel();
    _widthSub?.cancel();
    _heightSub?.cancel();

    final manager = GlobalPlayerService.instance.playerManager;

    _playingSub = manager.onPlaying.listen((playing) {
      isPlaying.value = playing;
    });

    _bufferingSub = manager.onLoading.listen((loading) {
      isBuffering.value = loading;
    });

    _errorSub = manager.onError.listen((error) {
      hasError.value = true;
    });

    _widthSub = manager.width.listen((w) {
      if (w != null && w > 0) {
        final h = manager.currentHeight;
        isVertical.value = (h ?? 9) > w;
      }
    });

    _heightSub = manager.height.listen((h) {
      if (h != null && h > 0) {
        final w = manager.currentWidth;
        isVertical.value = h > (w ?? 16);
      }
    });
  }

  @override
  Future<void> play() async {
    await GlobalPlayerService.instance.playerManager.resume();
  }

  @override
  Future<void> pause() async {
    await GlobalPlayerService.instance.playerManager.pause();
  }

  @override
  Future<void> togglePlayPause() async {
    await GlobalPlayerService.instance.playerManager.togglePlayPause();
  }

  @override
  Future<void> enterFullscreen() async {
    // 由上层 UI 控制全屏
  }

  @override
  Future<void> exitFullScreen() async {
    // 由上层 UI 控制全屏
  }

  @override
  Future<void> toggleFullScreen() async {
    isFullscreen.toggle();
  }

  @override
  void setVideoFit(SettingVideoFit fit) {
    // 由上层 UI 控制视频填充
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _errorSub?.cancel();
    _widthSub?.cancel();
    _heightSub?.cancel();
    _playingSub = null;
    _bufferingSub = null;
    _errorSub = null;
    _widthSub = null;
    _heightSub = null;
    GlobalPlayerService.instance.playerManager.softStop();
  }

  @override
  Future<void> setVolume(double volume) async {
    await GlobalPlayerService.instance.playerManager.setVolume(volume);
  }

  @override
  bool get supportPip =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS || Platform.isAndroid || Platform.isIOS;

  @override
  void enterPipMode() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await GlobalPlayerService.instance.playerManager.enablePip();
      isPipMode.value = true;
    }
  }

  @override
  List<String> get supportPlatformList => ["linux", "macos", "windows", "android", "ios"];

  @override
  Widget getVideoPlayerWidget() {
    if (!GlobalPlayerService.instance.initialized) {
      return Container(color: Colors.black);
    }
    final manager = GlobalPlayerService.instance.playerManager;
    return Obx(() => manager.getVideoWidget(
          SettingsService.instance.videoFitIndex.value,
          fitList: SettingsService.instance.videofitArray.map((e) => e.fit).toList(),
          controls: controller.videoControllerPanel,
        ));
  }
}
