import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/core/common/core_log.dart';

import '../util/update_room_util.dart';
import 'favorite_grid_controller.dart';

class FavoriteController extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController tabController;
  late TabController tabSiteController;
  final tabBottomIndex = 0.obs;
  final tabSiteIndex = 0.obs;
  final tabOnlineIndex = 0.obs;
  bool isFirstLoad = true;

  static FavoriteController get instance => Get.find<FavoriteController>();

  /// 定时刷新 Timer
  Timer? _autoRefreshTimer;

  /// App 是否在前台
  final _isAppResumed = true.obs;

  FavoriteController();

  final workerList = <Worker>[];
  final listenList = <StreamSubscription>[];

  @override
  Future<void> onInit() async {
    super.onInit();

    // 初始化 TabController（移到 onInit 中，确保 vsync 正确初始化）
    tabController = TabController(length: 2, vsync: this);
    tabSiteController =
        TabController(length: Sites().availableSites().length + 1, vsync: this);

    workerList.clear();
    listenList.clear();

    initFilterDataList(indexLength);
    initSiteSetList(indexLength);

    // 监听设置中收藏房间变化，添加 isClosed 防护
    listenList.add(
        SettingsService.instance.favoriteRoomsLengthChangeFlag.listen((_) {
      if (isClosed) return;
      syncRooms();
    }));

    // 监听在线房间变化，添加 isClosed 防护
    listenList.add(onlineRooms.listen((rooms) {
      if (isClosed) return;
      CoreLog.d("onlineRooms ....");
      initSiteSet(rooms, onlineRoomsIndex);
      filterDate(onlineRoomsIndex);
    }));

    // 监听离线房间变化，添加 isClosed 防护
    listenList.add(offlineRooms.listen((rooms) {
      if (isClosed) return;
      CoreLog.d("offlineRooms ....");
      initSiteSet(rooms, offlineRoomsIndex);
      filterDate(offlineRoomsIndex);
    }));

    tabController.addListener(() {
      if (isClosed) return;
      tabOnlineIndex.value = tabController.index;
    });
    tabSiteController.addListener(() {
      if (isClosed) return;
      tabSiteIndex.value = tabSiteController.index;
    });

    // 监听 App 生命周期
    WidgetsBinding.instance.addObserver(this);

    // 初始化关注页
    syncRooms();

    // 更新直播间信息
    await onRefresh();

    // 定时自动刷新
    _startAutoRefreshTimer();

    CoreLog.d("FavoriteController onInit");
    await initFavoriteData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppResumed.value = true;
        CoreLog.d("FavoriteController: App resumed, restarting auto refresh timer");
        _startAutoRefreshTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _isAppResumed.value = false;
        CoreLog.d("FavoriteController: App paused, canceling auto refresh timer");
        _autoRefreshTimer?.cancel();
        _autoRefreshTimer = null;
        break;
    }
  }

  /// 启动自动刷新定时器
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (SettingsService.instance.autoRefreshTime.value != 0) {
      _autoRefreshTimer = Timer.periodic(
        Duration(minutes: SettingsService.instance.autoRefreshTime.value),
        (timer) {
          // 仅在 App 前台时刷新
          if (_isAppResumed.value && !isClosed) {
            onRefresh();
          }
        },
      );
    }
  }

  final onlineRooms = <LiveRoom>[].obs;
  final offlineRooms = <LiveRoom>[].obs;

  void syncRooms() {
    if (isClosed) return;
    CoreLog.d("syncRooms ....");

    // 在线列表：创建副本，避免修改原对象
    var onlineList = SettingsService.instance.favoriteRooms
        .where((room) =>
            room.liveStatus == LiveStatus.live ||
            room.liveStatus == LiveStatus.replay)
        .map((room) {
      // 创建新对象，不修改原对象
      var newRoom = LiveRoom.fromJson(room.toJson());
      newRoom.watching =
          readableCount(readableCountStrToNum(room.watching).toString());
      return newRoom;
    }).toList();
    onlineList.sort((a, b) => readableCountStrToNum(b.watching)
        .compareTo(readableCountStrToNum(a.watching)));
    onlineRooms.value = onlineList;

    // 离线列表：创建副本，避免修改原对象
    var offlineList = SettingsService.instance.favoriteRooms
        .where((room) => room.liveStatus == LiveStatus.offline)
        .map((room) {
      // 创建新对象，不修改原对象
      var newRoom = LiveRoom.fromJson(room.toJson());
      newRoom.watching =
          readableCount(readableCountStrToNum(room.watching).toString());
      return newRoom;
    }).toList();
    offlineRooms.value = offlineList;
  }

  /// 是否在更新
  var isUpdating = false;

  Future<bool> onRefresh() async {
    if (isClosed) return false;
    if (isUpdating) {
      return false;
    }
    isUpdating = true;
    bool hasError = false;
    try {
      // 自动刷新时间为0关闭。不是手动刷新并且不是第一次刷新
      if (isFirstLoad) {
        await const Duration(seconds: 1).delay();
      }
      if (SettingsService.instance.favoriteRooms.value.isEmpty) {
        return false;
      }
      var currentRooms = SettingsService.instance.favoriteRooms.value;
      if (tabSiteIndex.value != 0) {
        var sites = Sites().availableSites(containsAll: true);
        if (tabSiteIndex.value < sites.length) {
          currentRooms = SettingsService.instance.favoriteRooms.value
              .where((element) =>
                  element.platform == sites[tabSiteIndex.value].id)
              .toList();
        }
      }

      hasError = await UpdateRoomUtil.updateRoomList(
          currentRooms, SettingsService.instance);
      if (!isClosed) {
        syncRooms();
      }
      isFirstLoad = false;
    } catch (e) {
      CoreLog.error(e);
      hasError = true;
    } finally {
      // 确保 isUpdating 始终被重置
      isUpdating = false;
    }
    return hasError;
  }

  /// 用于过滤列表
  /// 索引
  static const int onlineRoomsIndex = 0;
  static const int offlineRoomsIndex = 1;
  static const roomsIndexList = [onlineRoomsIndex, offlineRoomsIndex];

  /// 索引长度
  final int indexLength = 2;

  /// 存储已有的站点
  final List<Set<String>> siteSetList = [];
  final List<String> selectedSiteList = [];

  /// 初始化 存储已有的站点 列表长度
  void initSiteSetList(int len) {
    siteSetList.clear();
    selectedSiteList.clear();
    for (var i = 0; i < len; i++) {
      siteSetList.add(<String>{});
      selectedSiteList.add(Sites.allSite);
    }
  }

  /// 设置 存储已有的站点， 根据 直播间
  void initSiteSet(List<LiveRoom> list, int siteSetListIndex) {
    if (isClosed) return;
    if (siteSetListIndex < 0 || siteSetListIndex >= siteSetList.length) return;
    var siteSet = siteSetList[siteSetListIndex];
    siteSet.clear();
    siteSet.add(Sites.allSite);
    for (var room in list) {
      if (room.platform != null) {
        siteSet.add(room.platform!);
      }
    }
  }

  /// 用于过滤的列表
  final RxList<LiveRoom> dataList = <LiveRoom>[].obs;
  final List<RxList<LiveRoom>> filterDataList = [];

  void initFilterDataList(int len) {
    filterDataList.clear();
    for (var i = 0; i < len; i++) {
      filterDataList.add(<LiveRoom>[].obs);
    }
  }

  void initFilterDataListDate(List<LiveRoom> list, int filterDataListIndex) {
    if (isClosed) return;
    if (filterDataListIndex < 0 ||
        filterDataListIndex >= filterDataList.length) return;
    var dataList = filterDataList[filterDataListIndex];
    dataList.value = list;
  }

  bool filterSite(LiveRoom a, String selectedSite) =>
      selectedSite == Sites.allSite || a.platform == selectedSite;

  void filterDate(int filterDataListIndex) {
    if (isClosed) return;
    if (filterDataListIndex < 0 ||
        filterDataListIndex >= selectedSiteList.length) return;
    String siteId = selectedSiteList[filterDataListIndex];
    var allList = () {
      switch (filterDataListIndex) {
        case onlineRoomsIndex:
          return onlineRooms.value;
        case offlineRoomsIndex:
          return offlineRooms.value;
        default:
          return <LiveRoom>[];
      }
    }();
    var list = allList.where((e) => filterSite(e, siteId)).toList();
    if (list.isEmpty) {
      list = allList;
      selectedSiteList[filterDataListIndex] = Sites.allSite;
    }
    if (filterDataListIndex < filterDataList.length) {
      filterDataList[filterDataListIndex].value = list;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    for (var w in workerList) {
      w.dispose();
    }
    workerList.clear();
    for (var w in listenList) {
      w.cancel();
    }
    listenList.clear();
    try {
      tabController.dispose();
    } catch (e) {
      CoreLog.error(e);
    }
    try {
      tabSiteController.dispose();
    } catch (e) {
      CoreLog.error(e);
    }
    super.onClose();
  }

  /// 初始化数据
  Future<void> initFavoriteData() async {
    if (isClosed) return;
    List<Future> futures = [];
    for (var i = 0; i < roomsIndexList.length; i++) {
      var roomIndex = roomsIndexList[i];
      var tag = roomIndex.toString();
      futures.add(Future(() async {
        // 先检查是否已存在，避免重复创建
        if (!Get.isRegistered<FavoriteGridController>(tag: tag)) {
          Get.put(FavoriteGridController(roomIndex), tag: tag);
        }
        var controller = Get.find<FavoriteGridController>(tag: tag);
        if (controller.list.isEmpty) {
          controller.loadData();
        }
      }));
    }
    await Future.wait(futures);
  }
}
