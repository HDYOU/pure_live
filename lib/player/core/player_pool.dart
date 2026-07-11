import '../models/player_engine.dart';
import '../interface/unified_player_interface.dart';

/// 播放器池
/// 负责缓存和复用不同引擎的播放器实例
class PlayerPool {
  final Map<PlayerEngine, UnifiedPlayer> _cache = {};

  final Future<UnifiedPlayer> Function(PlayerEngine) factory;

  PlayerPool({required this.factory});

  /// 获取指定引擎的播放器
  /// 如果缓存中已存在则直接返回，否则通过工厂创建并初始化
  Future<UnifiedPlayer> getPlayer(PlayerEngine engine, {bool audioOnly = false}) async {
    if (_cache.containsKey(engine)) {
      return _cache[engine]!;
    }

    final player = await factory(engine);

    await player.init(audioOnly: audioOnly);

    _cache[engine] = player;

    return player;
  }

  /// 从缓存中移除并销毁指定引擎的播放器
  Future<void> removeFromCache(PlayerEngine engine) async {
    if (_cache.containsKey(engine)) {
      final player = _cache[engine]!;
      await player.hardDispose(); // 销毁原生
      _cache.remove(engine); // 从缓存删除
    }
  }

  /// 销毁所有缓存的播放器
  Future<void> disposeAll() async {
    for (final player in _cache.values) {
      await player.hardDispose();
    }

    _cache.clear();
  }
}
