import 'dart:developer';
import 'dart:io';

import 'core/player_pool.dart';
import 'core/player_manager.dart';
import 'models/player_engine.dart';
import 'adapters/gsy_video_adapter.dart';
import 'adapters/media_kit_adapter.dart';
import 'core/line_fallback_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'core/preload_player_manager.dart';
import 'core/engine_fallback_manager.dart';
import 'adapters/fvp_adapter.dart';
import 'adapters/system_video_adapter.dart';
import 'package:gsy_video_player/gsy_video_player.dart' show GsyVideoPlayerType;

/// 全局播放器服务
/// 单例模式，提供统一的播放器管理入口
///
/// 核心功能：
/// - 播放器池 (PlayerPool)：缓存和复用不同引擎的播放器实例
/// - 预加载 (PreloadPlayerManager)：提前预加载视频源，实现无缝切换
/// - 引擎降级 (EngineFallbackManager)：播放失败时自动切换到备用引擎
/// - 线路降级 (LineFallbackManager)：播放失败时自动切换到备用线路
/// - PIP 画中画：桌面端通过窗口管理器实现
/// - Texture 保活 (TextureKeeper)：避免不必要的 Texture 重建
class GlobalPlayerService {
  GlobalPlayerService._();

  static final GlobalPlayerService instance = GlobalPlayerService._();

  late final PlayerManager playerManager;

  bool _initialized = false;

  bool get initialized => _initialized;

  /// 初始化全局播放器服务
  /// [defaultEngine] 默认使用的播放器引擎
  Future<void> initialize({PlayerEngine defaultEngine = PlayerEngine.mediaKit}) async {
    if (_initialized) return;

    // 初始化 MediaKit（MPV 引擎需要）
    MediaKit.ensureInitialized();

    // 1. 设置播放器池（工厂方法创建各引擎适配器）
    final playerPool = PlayerPool(
      factory: (engine) async {
        switch (engine) {
          case PlayerEngine.mediaKit:
            return MediaKitAdapter();
          case PlayerEngine.gsyExo:
            return GsyVideoAdapter(playerType: GsyVideoPlayerType.exo);
          case PlayerEngine.gsyIjk:
            return GsyVideoAdapter(playerType: GsyVideoPlayerType.ijk);
          case PlayerEngine.fvp:
            return FvpAdapter();
          case PlayerEngine.systemVideo:
            return SystemVideoAdapter();
        }
      },
    );

    // 2. 获取当前平台支持的引擎列表
    final supportedEngines = _getSupportedEngines();

    // 3. 创建播放器管理器（包含所有子管理器）
    playerManager = PlayerManager(
      playerPool: playerPool,
      fallbackManager: EngineFallbackManager(
        defaultEngine: defaultEngine,
        supportedEngines: supportedEngines,
      ),
      preloadManager: PreloadPlayerManager(),
      lineManager: LineFallbackManager(),
    );

    // 4. 执行基础初始化（预热默认引擎）
    try {
      await playerManager.initialize(engine: defaultEngine);
      _initialized = true;
      log("GlobalPlayerService: Initialized successfully with engine: ${defaultEngine.name}",
          name: "GlobalPlayerService");
    } catch (e) {
      log("GlobalPlayerService: Failed to initialize: $e", name: "GlobalPlayerService", error: e);
    }
  }

  /// 获取当前平台支持的引擎列表
  List<PlayerEngine> _getSupportedEngines() {
    // 桌面端支持所有引擎
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return [
        PlayerEngine.mediaKit,
        PlayerEngine.fvp,
        PlayerEngine.systemVideo,
      ];
    }
    // 移动端支持更多引擎
    if (Platform.isAndroid || Platform.isIOS) {
      return [
        PlayerEngine.mediaKit,
        PlayerEngine.gsyExo,
        PlayerEngine.gsyIjk,
        PlayerEngine.fvp,
        PlayerEngine.systemVideo,
      ];
    }
    // 默认只返回 mediaKit
    return [PlayerEngine.mediaKit];
  }

  /// 全局销毁 - 仅在应用退出时调用
  Future<void> dispose() async {
    if (!_initialized) return;
    await playerManager.dispose();
    _initialized = false;
    log("GlobalPlayerService: Disposed.", name: "GlobalPlayerService");
  }
}
