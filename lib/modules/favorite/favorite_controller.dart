import 'dart:async';

import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/core/common/core_log.dart';

import '../util/update_room_util.dart';
import 'favorite_grid_controller.dart';

class FavoriteController extends GetxController
    with GetTickerProviderStateMixin {
  late TabController tabController;
  late TabController tabSiteController;
  final tabBottomIndex = 0.obs;
  final tabSiteIndex = 0.obs;
  final tabOnlineIndex = 0.obs;
  bool isFirstLoad = true;

  static FavoriteController get instance => Get.find<FavoriteController>();

  FavoriteController() {
    tabController = TabController(length: 2, vsync: this);
    tabSiteController =
        TabController(length: Sites().availableSites().length + 1, vsync: this);
  }

  final workerList = <Worker>[];
  final listenList = <StreamSubscription>[];

  @override
  Future<void> onInit() async {
    super.onInit();
    workerList.clear();
    listenList.clear();
    // 监听settings rooms变化
    // debounce(SettingsService.instance.favoriteRooms, (rooms) => syncRooms(), time: const Duration(milliseconds: 1000));
    initFilterDataList(indexLength);
    initSiteSetList(indexLength);
    listenList.add(
        SettingsService.instance.favoriteRoomsLengthChangeFlag.listen((rooms) => syncRooms()));
    listenList.add(onlineRooms.listen((rooms) {
      CoreLog.d("onlineRooms ....");
      initSiteSet(rooms, onlineRoomsIndex);
      filterDate(onlineRoomsIndex);
    }));
    listenList.add(offlineRooms.listen((rooms) {
      CoreLog.d("offlineRooms ....");
      initSiteSet(rooms, offlineRoomsIndex);
      filterDate(offlineRoomsIndex);
    }));

    tabController.addListener(() {
      tabOnlineIndex.value = tabController.index;
    });
    tabSiteController.addListener(() {
      tabSiteIndex.value = tabSiteController.index;
    });

    // 初始化关注页
    syncRooms();

    // 更新直播间信息
    await onRefresh();

    // 定时自动刷新
    if (SettingsService.instance.autoRefreshTime.value != 0) {
      Timer.periodic(
        Duration(minutes: SettingsService.instance.autoRefreshTime.value),
        (timer) => onRefresh(),
      );
    }

    CoreLog.d("onInit");
    await initFavoriteData();
  }

  final onlineRooms = <LiveRoom>[].obs;
  final offlineRooms = <LiveRoom>[].obs;

  void syncRooms() {
    CoreLog.d("syncRooms ....");
    // CoreLog.d(StackTrace.current.toString());
    // onlineRooms.clear();
    // offlineRooms.clear();
    // onlineRooms.addAll();
    var onlineList = SettingsService.instance.favoriteRooms
        .where((room) => room.liveStatus == LiveStatus.live || room.liveStatus == LiveStatus.replay)
        .map((room) {
      room.watching =
          readableCount(readableCountStrToNum(room.watching).toString());
      return room;
    }).toList();
    onlineList.sort((a, b) => readableCountStrToNum(b.watching)
        .compareTo(readableCountStrToNum(a.watching)));
    onlineRooms.value = onlineList;

    var offlineList = SettingsService.instance.favoriteRooms
        .where((room) => room.liveStatus == LiveStatus.offline)
        .map((room) {
      room.watching =
          readableCount(readableCountStrToNum(room.watching).toString());
      return room;
    }).toList();
    offlineRooms.value = offlineList;
    // onlineRooms.sort(
    //     (a, b) => int.parse(b.watching!).compareTo(int.parse(a.watching!)));
  }

  /// 是否在更新
  var isUpdating = false;

  Future<bool> onRefresh() async {
    if (isUpdating) {
      return false;
    }
    isUpdating = true;
    // 自动刷新时间为0关闭。不是手动刷新并且不是第一次刷新
    if (isFirstLoad) {
      await const Duration(seconds: 1).delay();
    }
    bool hasError = false;
    if (SettingsService.instance.favoriteRooms.value.isEmpty) {
      return false;
    }
    var currentRooms = SettingsService.instance.favoriteRooms.value;
    if (tabSiteIndex.value != 0) {
      currentRooms = SettingsService.instance.favoriteRooms.value
          .where((element) =>
              element.platform ==
              Sites().availableSites(containsAll: true)[tabSiteIndex.value].id)
          .toList();
    }

    hasError = await UpdateRoomUtil.updateRoomList(currentRooms, SettingsService.instance);
    syncRooms();
    isFirstLoad = false;
    isUpdating = false;
    return hasError;
  }

  /// 用于过滤列表
  /// 索引
  static const int onlineRoomsIndex = 0;
  static const int offlineRoomsIndex = 1;
  static const  roomsIndexList = [onlineRoomsIndex, offlineRoomsIndex];

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
    siteSetList.clear();
    for (var i = 0; i < len; i++) {
      filterDataList.add(<LiveRoom>[].obs);
    }
  }

  void initFilterDataListDate(List<LiveRoom> list, int filterDataListIndex) {
    var dataList = filterDataList[filterDataListIndex];
    dataList.value = list;
  }

  bool filterSite(LiveRoom a, String selectedSite) =>
      selectedSite == Sites.allSite || a.platform == selectedSite;

  void filterDate(int filterDataListIndex) {
    // CoreLog.d("selectedSite ${selectedSite}");
    String siteId = selectedSiteList[filterDataListIndex];
    var allList = () {
      switch (filterDataListIndex) {
        case onlineRoomsIndex: //
          return onlineRooms.value;
        case offlineRoomsIndex:
          return offlineRooms.value;
        default:
          return <LiveRoom>[];
      }
    }();
    var list = allList.where((e) => filterSite(e, siteId)).toList();
    if(list.isEmpty) {
      list = allList;
      selectedSiteList[filterDataListIndex] = Sites.allSite;
    }
    filterDataList[filterDataListIndex].value = list;
  }

  @override
  void dispose() {
    workerList.map((w) {
      w.dispose();
    });
    workerList.clear();
    listenList.map((w) {
      w.cancel();
    });
    listenList.clear();
    super.dispose();
  }

  /// 初始化数据
  Future<void> initFavoriteData() async {
      List<Future> futures = [];
      for (var i = 0; i < roomsIndexList.length; i++) {
        var roomIndex = roomsIndexList[i];
        var tag = roomIndex.toString();
        futures.add(Future(() async {
          Get.put(FavoriteGridController(roomIndex), tag: tag);
          var controller = Get.find<FavoriteGridController>(tag: tag);
          if (controller.list.isEmpty) {
            controller.loadData();
          }
        }));
      }
      await Future.wait(futures);
    }

}
