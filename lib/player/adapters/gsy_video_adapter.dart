import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:gsy_video_player/gsy_video_player.dart';
import 'package:chewie/chewie.dart';

import '../models/player_state.dart';
import '../models/player_exception.dart';
import '../models/player_error_type.dart';
import '../interface/unified_player_interface.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/services/settings_service.dart';

/// GSY Video Player 适配器
/// 支持 ExoPlayer 和 IJKPlayer 两种内核
class GsyVideoAdapter implements UnifiedPlayer {
  late final GsyVideoPlayerController _controller;
  final GsyVideoPlayerType playerType;

  ChewieController? _chewieController;

  bool _initialized = false;
  bool _disposed = false;
  bool _isAudioOnly = false;
  String? _currentUrl;

  // =========================
  // subjects
  // =========================

  final _stateSubject = BehaviorSubject<PlayerState>.seeded(PlayerState.idle);
  final _playingSubject = BehaviorSubject<bool>.seeded(false);
  final _loadingSubject = BehaviorSubject<bool>.seeded(false);
  final _errorSubject = PublishSubject<PlayerException>();
  final _completeSubject = BehaviorSubject<bool>.seeded(false);
  final _widthSubject = BehaviorSubject<int?>.seeded(null);
  final _heightSubject = BehaviorSubject<int?>.seeded(null);

  // =========================
  // subscriptions
  // =========================

  final List<StreamSubscription> _subscriptions = [];
  StreamSubscription? _eventSubscription;

  GsyVideoAdapter({this.playerType = GsyVideoPlayerType.exo});

  // =========================
  // init
  // =========================

  @override
  Future<void> init({bool audioOnly = false}) async {
    if (_initialized) return;
    _isAudioOnly = audioOnly;
    _disposed = false;
    _currentUrl = null;

    try {
      _stateSubject.add(PlayerState.initializing);

      _controller = GsyVideoPlayerController(
        allowBackgroundPlayback: SettingsService.instance.enableBackgroundPlay.value,
        player: playerType,
      );

      // 设置渲染类型和超时
      _controller.setRenderType(GsyVideoPlayerRenderType.surfaceView);
      _controller.setTimeOut(4000);
      _controller.setMediaCodec(SettingsService.instance.enableCodec.value);
      _controller.setMediaCodecTexture(SettingsService.instance.enableCodec.value);

      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: false,
        looping: false,
        showControls: false,
        draggableProgressBar: false,
        useRootNavigator: true,
        showOptions: false,
      );

      _bindListeners();

      _initialized = true;
      _stateSubject.add(PlayerState.initialized);
    } catch (e, s) {
      final exception = PlayerException(
        message: 'GSY Video init failed',
        type: PlayerErrorType.initialization,
        error: e,
        stackTrace: s,
      );
      _safeAddError(exception);
      throw exception;
    }
  }

  // =========================
  // datasource
  // =========================

  @override
  Future<void> setDataSource(
    String url,
    List<String> playUrls,
    Map<String, String> headers, {
    LiveRoom? room,
    bool audioOnly = false,
  }) async {
    if (_disposed) return;

    if (_currentUrl == url && isPlayingNow) {
      return;
    }
    _isAudioOnly = audioOnly;
    _currentUrl = url;

    try {
      _loadingSubject.add(true);
      _stateSubject.add(PlayerState.preparing);
      _completeSubject.add(false);
      _widthSubject.add(null);
      _heightSubject.add(null);

      // 设置数据源
      _controller.setDataSourceBuilder(
        url,
        mapHeadData: headers,
        cacheWithPlay: false,
        useDefaultIjkOptions: true,
      );

      await _controller.prepare();
      await _controller.resume();

      _stateSubject.add(PlayerState.ready);
      await setVolume(1.0);
    } catch (e, s) {
      final exception = PlayerException(
        message: 'GSY Video setDataSource failed',
        type: PlayerErrorType.source,
        error: e,
        stackTrace: s,
      );
      _safeAddError(exception);
      _stateSubject.add(PlayerState.error);
      throw exception;
    } finally {
      if (!_disposed) {
        _loadingSubject.add(false);
      }
    }
  }

  // =========================
  // listeners
  // =========================

  void _bindListeners() {
    _cancelAllSubscriptions();

    // 视频事件流
    _eventSubscription = _controller.videoEventStreamController.stream.listen((event) {
      if (_disposed) return;

      // 视频尺寸
      if (event.size != null && event.size!.width > 0) {
        final w = event.size!.width.toInt();
        final h = event.size!.height.toInt();
        if (_widthSubject.value != w) {
          _widthSubject.add(w);
          _heightSubject.add(h);
        }
      }

      // 缓冲状态
      if (event.isBuffering != null) {
        _loadingSubject.add(event.isBuffering!);
        if (event.isBuffering!) {
          _stateSubject.add(PlayerState.buffering);
        } else if (_playingSubject.value) {
          _stateSubject.add(PlayerState.playing);
        } else {
          _stateSubject.add(PlayerState.paused);
        }
      }
    });

    // 事件监听
    _controller.addEventsListener((event) {
      if (_disposed) return;

      switch (event) {
        case VideoEventType.onError:
          final exception = PlayerException(
            message: 'GSY Video playback error',
            type: PlayerErrorType.native,
          );
          _safeAddError(exception);
          _stateSubject.add(PlayerState.error);
          break;
        case VideoEventType.onPrepared:
          _playingSubject.add(true);
          _stateSubject.add(PlayerState.playing);
          break;
        case VideoEventType.onPause:
          _playingSubject.add(false);
          _stateSubject.add(PlayerState.paused);
          break;
        case VideoEventType.onCompletion:
          _completeSubject.add(true);
          _playingSubject.add(false);
          _stateSubject.add(PlayerState.completed);
          break;
        case VideoEventType.onInfo:
        case VideoEventType.onSeekComplete:
        case VideoEventType.onVideoSizeChanged:
          // 这些事件已通过 stream 处理
          break;
        default:
          break;
      }
    });

    _subscriptions.add(_eventSubscription!);
  }

  Future<void> _cancelAllSubscriptions() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _eventSubscription = null;
  }

  void _safeAddError(PlayerException exception) {
    if (_disposed || _errorSubject.isClosed) return;
    _errorSubject.add(exception);
  }

  // =========================
  // widget
  // =========================

  @override
  Widget getVideoWidget() {
    if (_isAudioOnly || _chewieController == null) {
      return const SizedBox.shrink();
    }
    return Chewie(controller: _chewieController!);
  }

  // =========================
  // play controls
  // =========================

  @override
  Future<void> play() async {
    await _controller.resume();
  }

  @override
  Future<void> pause() async {
    await _controller.pause();
  }

  @override
  Future<void> stop() async {
    await _controller.pause();
    _stateSubject.add(PlayerState.stopped);
  }

  @override
  Future<void> softStop() async {
    await _controller.setVolume(0.0);
    await _controller.pause();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _controller.setVolume(volume.clamp(0.0, 1.0));
  }

  // =========================
  // dispose
  // =========================

  @override
  Future<void> hardDispose() async {
    if (_disposed) return;
    _disposed = true;
    _initialized = false;

    await _cancelAllSubscriptions();

    try {
      _chewieController?.dispose();
      _controller.dispose();
      _chewieController = null;
    } catch (_) {}

    await Future.wait([
      _stateSubject.close(),
      _playingSubject.close(),
      _loadingSubject.close(),
      _errorSubject.close(),
      _completeSubject.close(),
      _widthSubject.close(),
      _heightSubject.close(),
    ]);
  }

  // =========================
  // getters
  // =========================

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isPlayingNow => _playingSubject.value;

  @override
  bool get isReusable => true;

  @override
  Stream<PlayerState> get onStateChanged => _stateSubject.stream;

  @override
  Stream<bool> get onPlaying => _playingSubject.stream;

  @override
  Stream<PlayerException> get onError => _errorSubject.stream;

  @override
  Stream<bool> get onLoading => _loadingSubject.stream;

  @override
  Stream<bool> get onComplete => _completeSubject.stream;

  @override
  Stream<int?> get width => _widthSubject.stream;

  @override
  Stream<int?> get height => _heightSubject.stream;
}
