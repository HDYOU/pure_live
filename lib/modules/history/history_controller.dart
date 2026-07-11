import 'dart:async';

import 'package:get/get.dart';
import 'package:pure_live/common/base/base_controller.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/modules/util/rx_util.dart';

import '../util/update_room_util.dart';

class HistoryController extends BasePageController<LiveRoom> {
  HistoryController();

  static HistoryController get instance => Get.find<HistoryController>();

  /// 使用 GetX Worker 替代直接 listen，自动在 Controller 销毁时清理
  Worker? _historyWorker;

  @override
  Future<void> onInit() async {
    super.onInit();
    // 使用 ever Worker 监听 historyRooms 变化，自动管理生命周期
    _historyWorker = ever(SettingsService.instance.historyRooms, (_) {
      _syncHistoryList();
    });
    await loadData();
  }

  @override
  void onClose() {
    _historyWorker?.dispose();
    super.onClose();
  }

  /// 同步历史记录列表
  void _syncHistoryList() {
    // 检查 Controller 是否已关闭，避免在销毁后操作
    if (isClosed) return;
    final rooms = SettingsService.instance.historyRooms.toList().reversed.toList();
    list.updateValueNotEquate(rooms);
    canLoadMore.value = false;
    pageEmpty.value = rooms.isEmpty;
  }

  @override
  Future refreshData() async {
    CoreLog.d("HistoryController refreshData");
    final SettingsService settings = SettingsService.instance;
    await UpdateRoomUtil.updateRoomList(settings.historyRooms, settings);
    _syncHistoryList();
    return;
  }

  @override
  Future<List<LiveRoom>> getData(int page, int pageSize) async {
    CoreLog.d("HistoryController getData(int page = $page, int pageSize = $pageSize)");
    if (page > 1) {
      canLoadMore.updateValueNotEquate(false);
      return [];
    }
    final SettingsService settings = SettingsService.instance;
    final rooms = settings.historyRooms.toList().reversed.toList();
    canLoadMore.updateValueNotEquate(false);
    return rooms;
  }
}
