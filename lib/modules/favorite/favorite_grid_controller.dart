import 'dart:async';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/base/base_controller.dart';
import 'package:pure_live/core/common/core_log.dart';

class FavoriteGridController extends BasePageController<LiveRoom> {
  final int index;

  /// 监听器：同步 FavoriteController 的 filterDataList 变化
  Worker? _filterDataListener;

  FavoriteGridController(this.index);

  @override
  void onInit() {
    super.onInit();
    // 监听 filterDataList 变化，自动同步到本控制器的 list
    _setupFilterDataListener();
  }

  /// 设置 filterDataList 监听器
  void _setupFilterDataListener() {
    _filterDataListener?.dispose();
    final favoriteController = FavoriteController.instance;
    if (index >= 0 && index < favoriteController.filterDataList.length) {
      final sourceList = favoriteController.filterDataList[index];
      // 使用 ever Worker 监听源列表变化，同步到本地 list
      _filterDataListener = ever(sourceList, (List<LiveRoom> data) {
        if (isClosed) return;
        list.value = List<LiveRoom>.from(data);
      });
    }
  }

  @override
  Future refreshData() async {
    EasyThrottle.throttle('refresh-favorite', const Duration(milliseconds: 200),
        () async {
      if (isClosed) return;
      await FavoriteController.instance.onRefresh();
      if (!isClosed) {
        await super.refreshData();
      }
    });
  }

  @override
  Future<List<LiveRoom>> getData(int page, int pageSize) async {
    if (page > 1) {
      return [];
    }
    final favoriteController = FavoriteController.instance;
    if (index >= 0 && index < favoriteController.filterDataList.length) {
      final sourceList = favoriteController.filterDataList[index];
      // 返回数据的副本，避免直接引用导致的并发修改问题
      return List<LiveRoom>.from(sourceList.value);
    }
    return [];
  }

  @override
  void onClose() {
    _filterDataListener?.dispose();
    _filterDataListener = null;
    super.onClose();
  }
}
