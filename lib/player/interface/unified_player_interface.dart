import '../models/player_state.dart';
import 'package:flutter/material.dart';
import '../models/player_exception.dart';
import 'package:pure_live/common/models/live_room.dart';

/// 统一播放器接口
/// 所有播放器适配器都需要实现此接口
abstract class UnifiedPlayer {
  /// 初始化播放器
  /// [audioOnly] 是否为纯音频模式
  Future<void> init({bool audioOnly = false});

  /// 设置数据源
  /// [url] 当前播放地址
  /// [playUrls] 备用地址列表（用于线路降级）
  /// [headers] HTTP 请求头
  /// [room] 直播间信息
  /// [audioOnly] 是否纯音频播放
  Future<void> setDataSource(
    String url,
    List<String> playUrls,
    Map<String, String> headers, {
    LiveRoom? room,
    bool audioOnly = false,
  });

  /// 开始播放
  Future<void> play();

  /// 暂停播放
  Future<void> pause();

  /// 停止播放（保留播放器实例）
  Future<void> stop();

  /// 软停止（不销毁播放器，仅停止播放）
  Future<void> softStop();

  /// 硬销毁（释放原生播放器资源）
  Future<void> hardDispose();

  /// 设置音量
  /// [volume] 0.0 ~ 1.0
  Future<void> setVolume(double volume);

  /// 获取视频渲染组件
  Widget getVideoWidget();

  /// 是否已初始化
  bool get isInitialized;

  /// 当前是否在播放
  bool get isPlayingNow;

  /// 是否可复用
  bool get isReusable;

  // --- 状态流 ---

  /// 播放器状态变化流
  Stream<PlayerState> get onStateChanged;

  /// 播放状态变化流
  Stream<bool> get onPlaying;

  /// 错误流
  Stream<PlayerException> get onError;

  /// 缓冲/加载状态流
  Stream<bool> get onLoading;

  /// 播放完成流
  Stream<bool> get onComplete;

  /// 视频宽度流
  Stream<int?> get width;

  /// 视频高度流
  Stream<int?> get height;
}
