import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:extended_image_library/extended_image_library.dart';
import 'package:pure_live/core/common/core_log.dart';

/// 内存管理工具
/// 用于监控和清理内存缓存，防止内存无限增长
class MemoryManager {
  static final MemoryManager instance = MemoryManager._();
  MemoryManager._();

  /// 内存清理定时器
  Timer? _cleanupTimer;

  /// 上次清理时间
  DateTime _lastCleanup = DateTime.now();

  /// 清理间隔（默认 5 分钟）
  static const Duration cleanupInterval = Duration(minutes: 5);

  /// 启动内存监控
  void startMonitoring() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _checkAndCleanup();
    });
    CoreLog.d("MemoryManager: 开始内存监控");
  }

  /// 停止内存监控
  void stopMonitoring() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    CoreLog.d("MemoryManager: 停止内存监控");
  }

  /// 检查并清理内存
  void _checkAndCleanup() {
    final now = DateTime.now();
    if (now.difference(_lastCleanup) >= cleanupInterval) {
      clearMemoryCache();
      _lastCleanup = now;
    }
  }

  /// 清理所有图片内存缓存
  void clearMemoryCache() {
    try {
      // 清理 Flutter 图片缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // 清理 extended_image 内存缓存
      clearExtendedImageCache();
      
      CoreLog.d("MemoryManager: 图片内存缓存已清理");
    } catch (e) {
      CoreLog.error(e);
    }
  }

  /// 清理 extended_image 内存缓存
  void clearExtendedImageCache() {
    try {
      // 清理所有缓存的图片数据
      ExtendedImage.clearMemoryCache();
      // 清理所有缓存的图片文件
      ExtendedImage.clearDiskCachedImages();
    } catch (e) {
      CoreLog.error(e);
    }
  }

  /// 获取当前图片缓存信息
  Map<String, dynamic> getCacheInfo() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'pendingImages': imageCache.pendingImageCount,
      'liveImages': imageCache.liveImageCount,
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
    };
  }

  /// 设置图片缓存上限
  void setImageCacheLimits({
    int maxSize = 100, // 最大缓存图片数量
    int maxSizeBytes = 100 * 1024 * 1024, // 最大缓存字节（100MB）
  }) {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = maxSize;
    imageCache.maximumSizeBytes = maxSizeBytes;
    CoreLog.d("MemoryManager: 图片缓存上限已设置为 $maxSize 张 / ${maxSizeBytes ~/ (1024 * 1024)} MB");
  }

  /// 在页面切换时清理内存
  void onPageChange() {
    // 延迟清理，避免影响当前页面
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // 清理已完成加载但不在屏幕上的图片
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
  }
}