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

  /// 监听 historyRooms 变化，自动刷新列表
  StreamSubscription? _historySubscription;

  @override
  Future<void> onInit() async {
    super.onInit();
    // 监听 SettingsService.historyRooms 变化，自动刷新
    _historySubscription = SettingsService.instance.historyRooms.listen((_) {
      _syncHistoryList();
    });
    await loadData();
  }

  @override
  void onClose() {
    _historySubscription?.cancel();
    super.onClose();
  }

  /// 同步历史记录列表
  void _syncHistoryList() {
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
