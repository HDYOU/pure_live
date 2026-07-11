import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/common/core_log.dart';

/// Flame 列表游戏基类
/// 提供通用的滚动、下拉刷新、列表渲染能力
abstract class FlameListGame extends FlameGame
    with HasKeyboardHandlerComponents, ScrollDetector, PanDetector {
  /// 滚动偏移量
  double scrollOffset = 0;

  /// 最大滚动距离
  double maxScrollExtent = 0;

  /// 是否正在刷新
  bool isRefreshing = false;

  /// 是否正在加载更多
  bool isLoadingMore = false;

  /// 下拉刷新阈值
  static const double _refreshThreshold = 80;

  /// 当前下拉距离
  double _pullDistance = 0;

  /// 是否正在拖拽
  bool _isDragging = false;

  /// 是否发生了滚动（用于区分点击和滚动）
  bool hasMovedDuringDrag = false;

  /// 惯性滚动速度（像素/秒）
  double _velocity = 0;

  /// 上一帧时间
  double _lastDeltaY = 0;
  double _lastUpdateTime = 0;

  /// 刷新回调
  final Future<void> Function()? onRefresh;

  /// 加载更多回调
  final Future<void> Function()? onLoadMore;

  /// 列数
  int crossAxisCount = 2;

  /// 间距
  double spacing = 8;

  /// 卡片宽高比（封面部分）
  double cardAspectRatio = 16 / 9;

  /// 卡片底部信息区域高度
  double get cardInfoHeight => 60;

  /// 视口尺寸变化流
  final _viewportResizeController = StreamController<Vector2>.broadcast();
  Stream<Vector2> get onViewportResize => _viewportResizeController.stream;

  FlameListGame({
    this.onRefresh,
    this.onLoadMore,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _viewportResizeController.add(size);
    _updateCrossAxisCount(size.x);
    refreshList();
  }

  /// 根据宽度计算列数
  void _updateCrossAxisCount(double width) {
    if (width > 1280) {
      crossAxisCount = 5;
    } else if (width > 960) {
      crossAxisCount = 4;
    } else if (width > 640) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }
  }

  /// 计算卡片宽度
  double get cardWidth {
    final totalSpacing = spacing * (crossAxisCount + 1);
    return (size.x - totalSpacing) / crossAxisCount;
  }

  /// 计算卡片总高度（封面 + 底部信息区）
  double get cardHeight {
    return cardWidth / cardAspectRatio + cardInfoHeight;
  }

  /// 计算列表总高度
  double get listHeight {
    final itemCount = getItemCount();
    final rows = (itemCount / crossAxisCount).ceil();
    return rows * cardHeight + (rows + 1) * spacing;
  }

  /// 获取列表项数量（子类实现）
  int getItemCount();

  /// 构建列表项组件（子类实现）
  PositionComponent buildItem(int index, Vector2 position, double width);

  /// 刷新列表内容
  void refreshList() {
    // 移除旧的列表项
    final itemsToRemove = children.whereType<FlameListItem>().toList();
    for (var item in itemsToRemove) {
      item.removeFromParent();
    }
    // 重新构建
    _buildListItems();
    maxScrollExtent = listHeight - size.y;
    if (maxScrollExtent < 0) maxScrollExtent = 0;
    if (scrollOffset > maxScrollExtent) {
      scrollOffset = maxScrollExtent;
    }
  }

  /// 构建所有列表项
  void _buildListItems() {
    final count = getItemCount();
    for (var i = 0; i < count; i++) {
      final row = i ~/ crossAxisCount;
      final col = i % crossAxisCount;
      final x = spacing + col * (cardWidth + spacing);
      final y = spacing + row * (cardHeight + spacing) - scrollOffset;
      final item = buildItem(i, Vector2(x, y), cardWidth);
      if (item is FlameListItem) {
        item.index = i;
      }
      add(item);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 惯性滚动
    if (!_isDragging && _velocity.abs() > 1) {
      scrollOffset += _velocity * dt;
      _velocity *= 0.92; // 阻尼

      // 边界检查
      if (scrollOffset < 0) {
        scrollOffset = 0;
        _velocity = 0;
      }
      if (scrollOffset > maxScrollExtent) {
        scrollOffset = maxScrollExtent;
        _velocity = 0;
        _triggerLoadMore();
      }
    }

    // 更新所有列表项的位置
    var i = 0;
    for (final child in children.whereType<FlameListItem>()) {
      final row = i ~/ crossAxisCount;
      final col = i % crossAxisCount;
      final x = spacing + col * (cardWidth + spacing);
      final y = spacing + row * (cardHeight + spacing) - scrollOffset;
      child.position = Vector2(x, y);
      i++;
    }
  }

  // === 鼠标滚轮滚动 ===

  @override
  void onScroll(PointerScrollInfo info) {
    if (isRefreshing) return;
    super.onScroll(info);

    final delta = info.scrollDelta.global.y;
    _updateScrollOffset(scrollOffset + delta, false);
    _velocity = 0; // 滚轮滚动时停止惯性
  }

  // === 触摸/拖拽滚动 ===

  @override
  void onPanStart(DragStartInfo info) {
    super.onPanStart(info);
    _isDragging = true;
    hasMovedDuringDrag = false;
    _velocity = 0;
    _lastDeltaY = 0;
    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    super.onPanUpdate(info);
    if (isRefreshing) return;

    // EventDelta 有 global 和 local 两个 Vector2
    final deltaY = info.delta.global.y;
    if (deltaY.abs() > 2) {
      hasMovedDuringDrag = true;
    }

    if (hasMovedDuringDrag) {
      _updateScrollOffset(scrollOffset - deltaY, true);

      // 计算速度
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      final dt = (now - _lastUpdateTime) / 1000;
      if (dt > 0) {
        _velocity = -deltaY / dt;
      }
      _lastUpdateTime = now;
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    super.onPanEnd(info);
    _isDragging = false;

    // velocity 是 EventVector2 类型，使用 global 获取世界坐标
    // info.velocity.global.y 单位是像素/秒
    _velocity = -info.velocity.global.y;

    // 限制最大速度
    if (_velocity.abs() > 3000) {
      _velocity = _velocity > 0 ? 3000 : -3000;
    }

    // 下拉刷新检测
    if (_pullDistance >= _refreshThreshold && !isRefreshing) {
      _triggerRefresh();
    } else if (_pullDistance > 0) {
      _animateScrollTo(0);
    }
  }

  @override
  void onPanCancel() {
    super.onPanCancel();
    _isDragging = false;
    _velocity = 0;
    if (_pullDistance > 0 && !isRefreshing) {
      _animateScrollTo(0);
    }
  }

  /// 更新滚动偏移量
  void _updateScrollOffset(double newOffset, bool isDrag) {
    scrollOffset = newOffset;

    // 边界检查 - 顶部
    if (scrollOffset < 0) {
      if (isDrag) {
        // 拖拽下拉，增加阻尼效果
        _pullDistance = -scrollOffset;
        scrollOffset = -_pullDistance * 0.5;
      } else {
        // 滚轮直接回弹
        scrollOffset = 0;
        _pullDistance = 0;
      }
    } else {
      _pullDistance = 0;
    }

    // 边界检查 - 底部
    if (scrollOffset > maxScrollExtent) {
      scrollOffset = maxScrollExtent;
      _triggerLoadMore();
    }
  }

  /// 动画滚动到目标位置
  Future<void> _animateScrollTo(double target) async {
    final start = scrollOffset;
    final duration = 300; // ms
    final startTime = DateTime.now().millisecondsSinceEpoch;

    while (_isDragging) {
      await Future.delayed(const Duration(milliseconds: 16));
    }

    while (true) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      if (elapsed >= duration || _isDragging) {
        scrollOffset = target;
        break;
      }
      final t = elapsed / duration;
      // easeOutCubic
      final eased = 1 - (1 - t) * (1 - t) * (1 - t);
      scrollOffset = start + (target - start) * eased;
      await Future.delayed(const Duration(milliseconds: 16));
    }
    scrollOffset = target;
  }

  /// 触发刷新
  Future<void> _triggerRefresh() async {
    if (isRefreshing || onRefresh == null) return;
    isRefreshing = true;

    try {
      await onRefresh!();
      refreshList();
    } catch (e) {
      CoreLog.error(e);
    } finally {
      isRefreshing = false;
      _pullDistance = 0;
      _animateScrollTo(0);
    }
  }

  /// 触发加载更多
  Future<void> _triggerLoadMore() async {
    if (isLoadingMore || onLoadMore == null) return;
    isLoadingMore = true;
    try {
      await onLoadMore!();
      refreshList();
    } catch (e) {
      CoreLog.error(e);
    } finally {
      isLoadingMore = false;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 绘制下拉刷新指示器
    if (isRefreshing || _pullDistance > 0) {
      _drawRefreshIndicator(canvas);
    }

    // 绘制加载更多指示器
    if (isLoadingMore) {
      _drawLoadMoreIndicator(canvas);
    }
  }

  /// 绘制下拉刷新指示器
  void _drawRefreshIndicator(Canvas canvas) {
    final centerX = size.x / 2;
    final y = 20 + _pullDistance * 0.3;

    // 绘制背景圆
    final bgPaint = Paint()..color = Colors.grey.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(centerX, y), 18, bgPaint);

    // 绘制旋转的圆弧
    final arcPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rect = Rect.fromCircle(center: Offset(centerX, y), radius: 14);
    final rotation = DateTime.now().millisecondsSinceEpoch / 300;
    canvas.drawArc(
      rect,
      rotation,
      1.5 * 3.14159,
      false,
      arcPaint,
    );

    // 刷新文字
    if (_pullDistance > _refreshThreshold * 0.5) {
      final text = isRefreshing ? '刷新中...' : '下拉刷新';
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, y + 24),
      );
    }
  }

  /// 绘制加载更多指示器
  void _drawLoadMoreIndicator(Canvas canvas) {
    final centerX = size.x / 2;
    final y = size.y - 30;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '加载中...',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, y));
  }

  @override
  void onRemove() {
    _viewportResizeController.close();
    super.onRemove();
  }
}

/// Flame 列表项组件基类
abstract class FlameListItem extends PositionComponent {
  int index = 0;
}
