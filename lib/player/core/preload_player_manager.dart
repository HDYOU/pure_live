import '../interface/unified_player_interface.dart';

/// 预加载播放器管理器
/// 支持提前预加载下一个视频源，实现无缝切换
class PreloadPlayerManager {
  /// 当前主播放器
  UnifiedPlayer? current;

  /// 备用预加载播放器
  UnifiedPlayer? standby;

  /// 预加载视频源
  /// [player] 用于预加载的播放器实例
  /// [url] 视频地址
  /// [playUrls] 备用地址列表
  /// [headers] 请求头
  Future<void> preload(
    UnifiedPlayer player,
    String url,
    List<String> playUrls,
    Map<String, String> headers,
  ) async {
    standby = player;

    await standby!.setDataSource(url, playUrls, headers);

    await standby!.pause();
  }

  /// 切换到预加载的备用播放器
  Future<void> switchToStandby() async {
    if (standby == null) return;

    current = standby;

    standby = null;

    await current?.play();
  }
}
