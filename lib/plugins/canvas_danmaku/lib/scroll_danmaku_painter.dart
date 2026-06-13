import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'models/danmaku_item.dart';
import './utils/utils.dart';

// 通用简易对象池（复用 PictureRecorder）
class _ObjectPool<T> {
  final List<T> _cache = [];
  final T Function() _creator;
  final int _maxCache;

  _ObjectPool(this._creator, {int maxCache = 5}) : _maxCache = maxCache;

  T get() {
    return _cache.isNotEmpty ? _cache.removeLast() : _creator();
  }

  void recycle(T obj) {
    if (_cache.length < _maxCache) {
      _cache.add(obj);
    }
  }

  void clear() => _cache.clear();
}

// 全局复用绘制临时对象（CustomPainter 内常驻，不重复创建）
class _DanmakuDrawHelper {
  // 固定复用：Offset / Rect / Size 绘制临时对象
  static final Offset _tempOffset = Offset.zero;
  static final Rect _tempRect = Rect.zero;
  static final Size _tempSize = Size.zero;
  // Picture 离屏绘制对象池，限制最大缓存数
  static final _ObjectPool<ui.PictureRecorder> _recorderPool =
      _ObjectPool(() => ui.PictureRecorder(), maxCache: 3);
}

class ScrollDanmakuPainter extends CustomPainter {
  // 外部传入参数
  final double progress;
  final List<DanmakuItem> scrollDanmakuItems;
  final int danmakuDurationInSeconds;
  final double fontSize;
  final int fontWeight;
  final bool showStroke;
  final double danmakuHeight;
  final bool running;
  final int tick;
  final int batchThreshold;

  // 预计算常量（构造只算一次，循环不再重复计算）
  final double totalDuration;
  // 复用画笔（全局唯一，不重复创建）
  final Paint selfSendStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.green;

  ScrollDanmakuPainter(
    this.progress,
    this.scrollDanmakuItems,
    this.danmakuDurationInSeconds,
    this.fontSize,
    this.fontWeight,
    this.showStroke,
    this.danmakuHeight,
    this.running,
    this.tick, {
    this.batchThreshold = 10,
  }) : totalDuration = danmakuDurationInSeconds * 1000,
       super(repaint: AlwaysStoppedAnimation(0));

  /// 核心：抽取公共绘制逻辑，消除代码冗余
  void _drawDanmakuItem(Canvas canvas, Size size, DanmakuItem item) {
    // 缓存高频访问字段，减少重复寻址
    final double itemWidth = item.width;
    final double itemHeight = item.height;
    final double itemY = item.yPosition;

    // 初始化上一帧tick
    item.lastDrawTick ??= item.creationTime;

    // 预计算固定值（循环内只算一次）
    final double startPos = size.width;
    final double endPos = -itemWidth;
    final double distance = startPos - endPos;

    // 更新X坐标
    item.xPosition += ((item.lastDrawTick! - tick) / totalDuration) * distance;

    // 超出可视区域，直接跳过
    final double currentX = item.xPosition;
    if (currentX < -itemWidth || currentX > size.width) {
      return;
    }

    // 生成文本 Paragraph（惰性初始化，原有逻辑保留）
    item.paragraph ??= Utils.generateParagraph(
      item.content,
      size.width,
      fontSize,
      fontWeight,
    );

    // 绘制描边文本
    if (showStroke && item.strokeParagraph != null) {
      canvas.drawParagraph(item.strokeParagraph!, _DanmakuDrawHelper._tempOffset..setValues(currentX, itemY));
    } else if (showStroke) {
      item.strokeParagraph ??= Utils.generateStrokeParagraph(
        item.content,
        size.width,
        fontSize,
        fontWeight,
      );
      canvas.drawParagraph(item.strokeParagraph!, _DanmakuDrawHelper._tempOffset..setValues(currentX, itemY));
    }

    // 绘制自己发送弹幕的边框
    if (item.content.selfSend) {
      // 复用全局临时 Rect，不新建对象
      _DanmakuDrawHelper._tempOffset.setValues(currentX - 2, itemY + 2);
      _DanmakuDrawHelper._tempSize.setValues(itemWidth + 4, itemHeight);
      _DanmakuDrawHelper._tempRect.fromOffsetSize(
        _DanmakuDrawHelper._tempOffset,
        _DanmakuDrawHelper._tempSize,
      );
      canvas.drawRect(_DanmakuDrawHelper._tempRect, selfSendStrokePaint);
    }

    // 绘制主体文本
    canvas.drawParagraph(item.paragraph!, _DanmakuDrawHelper._tempOffset..setValues(currentX, itemY));

    // 更新最后绘制tick
    item.lastDrawTick = tick;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 非运行状态直接返回，跳过绘制
    if (!running) return;

    final int itemCount = scrollDanmakuItems.length;
    if (itemCount == 0) return;

    // 分支1：数量多，使用离屏批量绘制（复用 PictureRecorder）
    if (itemCount > batchThreshold) {
      // 从对象池取出复用对象，不新建
      final recorder = _DanmakuDrawHelper._recorderPool.get();
      final offCanvas = ui.Canvas(recorder);

      for (final item in scrollDanmakuItems) {
        _drawDanmakuItem(offCanvas, size, item);
      }

      // 结束离屏录制，绘制到主画布
      final picture = recorder.endRecording();
      canvas.drawPicture(picture);

      // 归还对象到池，复用
      _DanmakuDrawHelper._recorderPool.recycle(recorder);
    }
    // 分支2：数量少，直接绘制
    else {
      for (final item in scrollDanmakuItems) {
        _drawDanmakuItem(canvas, size, item);
      }
    }
  }

  /// 精准重绘判断：对比新旧实例关键参数，减少无效重绘
  @override
  bool shouldRepaint(covariant ScrollDanmakuPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        tick != oldDelegate.tick ||
        running != oldDelegate.running ||
        showStroke != oldDelegate.showStroke ||
        scrollDanmakuItems != oldDelegate.scrollDanmakuItems;
  }

  /// 销毁时清空对象池（防止内存泄漏）
  @override
  void dispose() {
    _DanmakuDrawHelper._recorderPool.clear();
    super.dispose();
  }
}
