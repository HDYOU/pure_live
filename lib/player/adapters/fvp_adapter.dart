import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../models/player_state.dart';
import '../models/player_exception.dart';
import '../models/player_error_type.dart';
import '../interface/unified_player_interface.dart';
import 'package:pure_live/common/models/live_room.dart';

/// FVP 播放器适配器
/// FVP 是基于 video_player 的硬件解码播放器
class FvpAdapter implements UnifiedPlayer {
  VideoPlayerController? _videoPlayerController;
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
  VoidCallback? _videoListener;

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

      // 创建一个空的 controller 用于初始化
      VideoPlayerOptions options = VideoPlayerOptions(allowBackgroundPlayback: true);
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(""),
        videoPlayerOptions: options,
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
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
        message: 'FVP init failed',
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

      // 销毁旧的 controller
      _removeVideoListener();
      final oldController = _videoPlayerController;
      final oldChewie = _chewieController;

      // 创建新的 controller
      VideoPlayerOptions options = VideoPlayerOptions(allowBackgroundPlayback: true);
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: options,
        httpHeaders: headers,
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: false,
        draggableProgressBar: false,
        useRootNavigator: true,
        showOptions: false,
      );

      _bindVideoListener();

      // 等待初始化
      await _videoPlayerController!.initialize();

      _stateSubject.add(PlayerState.ready);
      await setVolume(1.0);

      // 延迟销毁旧 controller
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          oldChewie?.dispose();
          oldController?.dispose();
        } catch (_) {}
      });
    } catch (e, s) {
      final exception = PlayerException(
        message: 'FVP setDataSource failed',
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
    _bindVideoListener();
  }

  void _bindVideoListener() {
    _removeVideoListener();
    if (_videoPlayerController == null) return;

    _videoListener = () {
      final value = _videoPlayerController!.value;

      // 错误
      if (value.hasError) {
        final exception = PlayerException(
          message: value.errorDescription ?? 'FVP error',
          type: _mapErrorType(value.errorDescription ?? ''),
        );
        _safeAddError(exception);
        _stateSubject.add(PlayerState.error);
        return;
      }

      // 视频尺寸
      if (value.isInitialized && value.size.width > 0) {
        final w = value.size.width.toInt();
        final h = value.size.height.toInt();
        if (_widthSubject.value != w) {
          _widthSubject.add(w);
          _heightSubject.add(h);
        }
      }

      // 播放状态
      _playingSubject.add(value.isPlaying);

      // 缓冲状态
      _loadingSubject.add(value.isBuffering);

      // 状态更新
      if (value.isPlaying && !value.isBuffering) {
        _stateSubject.add(PlayerState.playing);
      } else if (value.isBuffering) {
        _stateSubject.add(PlayerState.buffering);
      } else if (!value.isPlaying && value.isInitialized) {
        _stateSubject.add(PlayerState.paused);
      }

      // 播放完成
      if (value.isCompleted) {
        _completeSubject.add(true);
        _stateSubject.add(PlayerState.completed);
      }
    };

    _videoPlayerController!.addListener(_videoListener!);
  }

  void _removeVideoListener() {
    if (_videoListener != null && _videoPlayerController != null) {
      _videoPlayerController!.removeListener(_videoListener!);
      _videoListener = null;
    }
  }

  Future<void> _cancelAllSubscriptions() async {
    _removeVideoListener();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  void _safeAddError(PlayerException exception) {
    if (_disposed || _errorSubject.isClosed) return;
    _errorSubject.add(exception);
  }

  // =========================
  // error type mapping
  // =========================

  PlayerErrorType _mapErrorType(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('network') || lower.contains('timeout') || lower.contains('io')) {
      return PlayerErrorType.network;
    }
    if (lower.contains('codec') || lower.contains('decode')) {
      return PlayerErrorType.codec;
    }
    if (lower.contains('404') || lower.contains('source') || lower.contains('open')) {
      return PlayerErrorType.source;
    }
    if (lower.contains('surface') || lower.contains('texture')) {
      return PlayerErrorType.texture;
    }
    return PlayerErrorType.native;
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
    await _chewieController?.play();
  }

  @override
  Future<void> pause() async {
    await _chewieController?.pause();
  }

  @override
  Future<void> stop() async {
    await _videoPlayerController?.pause();
    await _videoPlayerController?.seekTo(Duration.zero);
    _stateSubject.add(PlayerState.stopped);
  }

  @override
  Future<void> softStop() async {
    await _videoPlayerController?.setVolume(0.0);
    await _videoPlayerController?.pause();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _videoPlayerController?.setVolume(volume.clamp(0.0, 1.0));
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
      _videoPlayerController?.dispose();
      _chewieController = null;
      _videoPlayerController = null;
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
