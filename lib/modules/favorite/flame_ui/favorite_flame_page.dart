import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/flame_ui/flame_grid_list.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/widgets/keep_alive_wrapper.dart';
import 'package:pure_live/common/widgets/settings/settings_list_item.dart';
import 'package:pure_live/modules/favorite/favorite_controller.dart';
import 'package:pure_live/modules/favorite/favorite_grid_controller.dart';
import 'package:pure_live/modules/util/site_logo_widget.dart';

/// Flame UI 版本的收藏页
/// 新 UI 放在这里，旧的 favorite_page.dart 保持不变
class FavoriteFlamePage extends GetView<FavoriteController> {
  const FavoriteFlamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(child: LayoutBuilder(builder: (context, constraint) {
      bool showAction = constraint.maxWidth <= 680;
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          scrolledUnderElevation: 0,
          leading: showAction ? const MenuButton() : null,
          actions: showAction
              ? [
                  PopupMenuButton(
                    tooltip: S.current.search,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    offset: const Offset(12, 0),
                    position: PopupMenuPosition.under,
                    icon: const Icon(Icons.read_more_sharp),
                    onSelected: (int index) {
                      if (index == 0) {
                        Get.toNamed(RoutePath.kSearch);
                      } else {
                        Get.toNamed(RoutePath.kToolbox);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem(
                          value: 0,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: MenuListTile(
                            leading: Icon(CustomIcons.search),
                            text: S.current.live_room_search,
                          ),
                        ),
                        PopupMenuItem(
                          value: 1,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: MenuListTile(
                            leading: Icon(Icons.link),
                            text: S.current.live_room_link_access,
                          ),
                        ),
                      ];
                    },
                  )
                ]
              : null,
          title: TabBar(
            controller: controller.tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: S.current.online_room_title),
              Tab(text: S.current.offline_room_title),
            ],
          ),
        ),
        body: TabBarView(
          controller: controller.tabController,
          children: [
            KeepAliveWrapper(
              child: _RoomFlameGridView(FavoriteController.onlineRoomsIndex),
            ),
            KeepAliveWrapper(child: _RoomFlameGridView(FavoriteController.offlineRoomsIndex)),
          ],
        ),
      );
    }));
  }
}

/// Flame UI 版本的房间网格视图
class _RoomFlameGridView extends StatefulWidget {
  final int selectIndex;

  const _RoomFlameGridView(this.selectIndex);

  @override
  State<_RoomFlameGridView> createState() => _RoomFlameGridViewState();
}

class _RoomFlameGridViewState extends State<_RoomFlameGridView> {
  late FavoriteGridController _gridController;
  final FavoriteController _favoriteController = FavoriteController.instance;
  final dense = Get.find<SettingsService>().enableDenseFavorites.value;

  @override
  void initState() {
    super.initState();
    final tag = widget.selectIndex.toString();
    if (!Get.isRegistered<FavoriteGridController>(tag: tag)) {
      Get.put(FavoriteGridController(widget.selectIndex), tag: tag);
    }
    _gridController = Get.find<FavoriteGridController>(tag: tag);
    if (_gridController.list.isEmpty) {
      _gridController.loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FlameGridList(
          controller: _gridController,
          dense: dense,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
            key: UniqueKey(),
            heroTag: UniqueKey(),
            onPressed: () {
              showFilter();
            },
            child: const Icon(Icons.local_offer)));
  }

  void showFilter({BuildContext? context}) {
    var curContext = context ?? Get.context!;
    showModalBottomSheet(
      context: curContext,
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._favoriteController.siteSetList[widget.selectIndex].map((siteId) {
              var site = Sites.allLiveSite;
              if (siteId != Sites.allSite) {
                site = Sites.of(siteId);
              }
              return SettingsListItem(
                leading: SiteWidget.getSiteLogeImage(site.id),
                title: Text(Sites.getSiteName(site.id)),
                onTap: () {
                  var curSiteId = _favoriteController.selectedSiteList[widget.selectIndex];
                  if (curSiteId != site.id) {
                    _favoriteController.selectedSiteList[widget.selectIndex] = site.id;
                    _favoriteController.filterDate(widget.selectIndex);
                  }
                  Navigator.pop(curContext);
                },
                selected: site.id == _favoriteController.selectedSiteList[widget.selectIndex],
              );
            }),
          ],
        ),
      ),
    );
  }
}
