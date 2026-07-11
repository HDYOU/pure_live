import 'dart:developer';
import '../models/player_engine.dart';
import '../models/player_exception.dart';
import '../models/player_error_type.dart';

/// 引擎降级管理器
/// 当某个播放器引擎播放失败时，自动降级到下一个可用引擎
class EngineFallbackManager {
  EngineFallbackManager({
    required this.defaultEngine,
    this.maxRetryCount = 2,
    required this.supportedEngines,
  });

  /// 支持的引擎列表
  final List<PlayerEngine> supportedEngines;

  /// 默认引擎
  final PlayerEngine defaultEngine;

  /// 最大重试次数（达到后才降级）
  final int maxRetryCount;

  /// 各引擎的重试次数记录
  final Map<PlayerEngine, int> _retryMap = {};

  /// 永久失败的引擎集合
  final Set<PlayerEngine> _permanentlyFailed = {};

  /// 优先级列表（默认引擎优先）
  late final List<PlayerEngine> _priority = [
    defaultEngine,
    ...PlayerEngine.values,
  ].where((e) => supportedEngines.contains(e)).toList();

  /// 判断是否需要降级
  bool shouldFallback(PlayerException error) {
    switch (error.type) {
      case PlayerErrorType.codec:
      case PlayerErrorType.native:
      case PlayerErrorType.texture:
      case PlayerErrorType.initialization:
      case PlayerErrorType.source:
        return true;
      default:
        return false;
    }
  }

  /// 执行降级，返回下一个可用引擎
  /// [current] 当前失败的引擎
  /// [error] 导致降级的错误
  Future<PlayerEngine> fallback(PlayerEngine current, PlayerException error) async {
    if (supportedEngines.length <= 1) {
      return defaultEngine;
    }

    final currentRetry = _retryMap[current] ?? 0;
    final nextRetry = currentRetry + 1;
    _retryMap[current] = nextRetry;

    // 未达到最大重试次数，继续使用当前引擎
    if (nextRetry < maxRetryCount) {
      return current;
    }

    // 标记为永久失败，尝试下一个引擎
    _permanentlyFailed.add(current);
    for (final engine in _priority) {
      if (!_permanentlyFailed.contains(engine)) {
        log("Engine fallback: $current -> $engine", name: "EngineFallbackManager");
        _retryMap[engine] = 0;
        return engine;
      }
    }

    // 所有引擎都失败了，重置并重试
    resetAll();
    throw error;
  }

  /// 重置指定引擎的失败状态
  void reset(PlayerEngine engine) {
    _retryMap[engine] = 0;
    _permanentlyFailed.remove(engine);
  }

  /// 重置所有引擎的失败状态
  void resetAll() {
    _retryMap.clear();
    _permanentlyFailed.clear();
  }
}
