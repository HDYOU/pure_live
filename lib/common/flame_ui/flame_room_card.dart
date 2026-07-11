import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/common/flame_ui/flame_list_game.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/core/common/core_log.dart';

/// Flame 版本的直播间卡片组件
class FlameRoomCard extends FlameListItem with TapCallbacks {
  final LiveRoom room;
  final bool dense;
  final VoidCallback? onTap;

  /// 封面图 Sprite（异步加载）
  Sprite? _coverSprite;
  bool _coverLoading = false;

  /// 圆角半径
  final double _cornerRadius = 12;

  FlameRoomCard({
    required this.room,
    this.dense = false,
    this.onTap,
    Vector2? size,
    Vector2? position,
  }) : super(size: size, position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadCoverImage();
  }

  /// 加载封面图
  Future<void> _loadCoverImage() async {
    if (_coverLoading || room.cover == null || room.cover!.isEmpty) return;
    _coverLoading = true;

    try {
      // 从网络加载图片
      final uri = Uri.parse(room.cover!);
      // 优先使用缓存
      final cacheManager = _CacheManager.instance;
      final image = await cacheManager.loadImage(uri.toString());
      _coverSprite = Sprite(image);
    } catch (e) {
      // 网络图片加载失败是正常的，忽略
      CoreLog.d('FlameRoomCard 封面加载失败: ${room.cover}');
    } finally {
      _coverLoading = false;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cardRect = Rect.fromLTWH(0, 0, width, height);
    final rrect = RRect.fromRectAndRadius(
      cardRect,
      Radius.circular(_cornerRadius),
    );

    // 绘制卡片背景
    final bgPaint = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawRRect(rrect, bgPaint);

    // 裁剪圆角区域
    canvas.save();
    canvas.clipRRect(rrect);

    // 计算封面区域（16:9）
    final coverHeight = width * 9 / 16;
    final coverRect = Rect.fromLTWH(0, 0, width, coverHeight);

    // 绘制封面图
    if (_coverSprite != null) {
      _drawCoverImage(canvas, coverRect);
    } else {
      // 绘制占位背景
      final placeholderPaint = Paint()..color = Colors.grey[800]!;
      canvas.drawRect(coverRect, placeholderPaint);
      // 绘制占位图标
      _drawPlaceholderIcon(canvas, coverRect);
    }

    // 绘制顶部渐变遮罩
    _drawTopGradient(canvas, coverRect);

    // 绘制底部渐变遮罩
    _drawBottomGradient(canvas, coverRect);

    // 绘制平台图标
    _drawPlatformBadge(canvas, coverRect);

    // 绘制人气/状态
    _drawViewCount(canvas, coverRect);

    // 绘制底部信息区
    _drawBottomInfo(canvas, coverHeight);

    // 绘制离线遮罩
    if (room.liveStatus == LiveStatus.offline) {
      final offlinePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6);
      canvas.drawRect(coverRect, offlinePaint);

      // 绘制离线图标
      final iconPainter = TextPainter(
        text: TextSpan(
          text: '📺',
          style: TextStyle(fontSize: dense ? 24 : 40),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          coverRect.center.dx - iconPainter.width / 2,
          coverRect.center.dy - iconPainter.height / 2,
        ),
      );
    }

    canvas.restore();
  }

  /// 绘制封面图
  void _drawCoverImage(Canvas canvas, Rect coverRect) {
    if (_coverSprite == null) return;
    _coverSprite!.render(
      canvas,
      position: Vector2(coverRect.left, coverRect.top),
      size: Vector2(coverRect.width, coverRect.height),
    );
  }

  /// 绘制占位图标
  void _drawPlaceholderIcon(Canvas canvas, Rect coverRect) {
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '🖼️',
        style: TextStyle(fontSize: dense ? 20 : 32),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        coverRect.center.dx - iconPainter.width / 2,
        coverRect.center.dy - iconPainter.height / 2,
      ),
    );
  }

  /// 绘制顶部渐变
  void _drawTopGradient(Canvas canvas, Rect coverRect) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.7),
        Colors.transparent,
      ],
    );
    final gradientHeight = coverRect.height * 0.3;
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(coverRect.left, coverRect.top, coverRect.width, gradientHeight),
      );
    canvas.drawRect(
      Rect.fromLTWH(coverRect.left, coverRect.top, coverRect.width, gradientHeight),
      paint,
    );
  }

  /// 绘制底部渐变
  void _drawBottomGradient(Canvas canvas, Rect coverRect) {
    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.black.withValues(alpha: 0.7),
        Colors.transparent,
      ],
    );
    final gradientHeight = coverRect.height * 0.3;
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(coverRect.left, coverRect.bottom - gradientHeight, coverRect.width, gradientHeight),
      );
    canvas.drawRect(
      Rect.fromLTWH(coverRect.left, coverRect.bottom - gradientHeight, coverRect.width, gradientHeight),
      paint,
    );
  }

  /// 绘制平台标签
  void _drawPlatformBadge(Canvas canvas, Rect coverRect) {
    if (room.platform == null) return;

    final badgeText = room.platform!;
    final textPainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: TextStyle(
          color: Colors.white,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 背景圆角矩形
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);
    final padding = dense ? 4.0 : 6.0;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        6,
        6,
        textPainter.width + padding * 2,
        textPainter.height + 2,
      ),
      Radius.circular(dense ? 8 : 10),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 文字
    textPainter.paint(canvas, Offset(6 + padding, 7));
  }

  /// 绘制人气/观看人数
  void _drawViewCount(Canvas canvas, Rect coverRect) {
    final isLive = room.liveStatus == LiveStatus.live || room.liveStatus == LiveStatus.replay;
    if (!isLive) return;

    final watching = room.watching ?? '0';
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🔥 $watching',
        style: TextStyle(
          color: Colors.white,
          fontSize: dense ? 10 : 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final x = coverRect.width - textPainter.width - 8;
    final y = coverRect.bottom - textPainter.height - 6;
    textPainter.paint(canvas, Offset(x, y));
  }

  /// 绘制底部信息（标题、主播名）
  void _drawBottomInfo(Canvas canvas, double coverHeight) {
    final infoTop = coverHeight + 8;

    // 标题
    final title = room.title ?? '';
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Colors.white,
          fontSize: dense ? 11 : 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: width - 16);
    titlePainter.paint(canvas, Offset(8, infoTop));

    // 主播名
    final nick = room.nick ?? '';
    final nickPainter = TextPainter(
      text: TextSpan(
        text: nick,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: dense ? 10 : 12,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: width - 16);
    nickPainter.paint(canvas, Offset(8, infoTop + titlePainter.height + 4));

    // 分区名
    final area = room.area ?? '';
    if (area.isNotEmpty) {
      final areaPainter = TextPainter(
        text: TextSpan(
          text: area,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: dense ? 9 : 11,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: width - 16);
      areaPainter.paint(
        canvas,
        Offset(8, infoTop + titlePainter.height + nickPainter.height + 8),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // 按下效果（轻微缩放）
    scale = Vector2.all(0.98);
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    onTap?.call();
    super.onTapUp(event);
  }

  @override
  void onTapCancel() {
    scale = Vector2.all(1.0);
    super.onTapCancel();
  }
}

/// 简单的图片缓存管理器
class _CacheManager {
  static final _CacheManager instance = _CacheManager._internal();
  factory _CacheManager() => instance;
  _CacheManager._internal();

  final Map<String, ui.Image> _cache = {};
  final Map<String, Future<ui.Image>> _loading = {};

  Future<ui.Image> loadImage(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }
    if (_loading.containsKey(url)) {
      return _loading[url]!;
    }
    final future = _loadNetworkImage(url);
    _loading[url] = future;
    try {
      final image = await future;
      _cache[url] = image;
      return image;
    } finally {
      _loading.remove(url);
    }
  }

  Future<ui.Image> _loadNetworkImage(String url) async {
    final completer = Completer<ui.Image>();
    final networkImage = NetworkImage(url);
    final stream = networkImage.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    completer.future.then((_) {
      stream.removeListener(listener);
    }).catchError((_) {
      stream.removeListener(listener);
    });
    return completer.future;
  }
}
