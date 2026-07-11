import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/areas/areas_page.dart';
import 'package:pure_live/modules/favorite/favorite_page.dart';
import 'package:pure_live/modules/favorite/flame_ui/favorite_flame_page.dart';
import 'package:pure_live/modules/popular/flame_ui/popular_flame_page.dart';
import 'package:pure_live/modules/popular/popular_page.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  int index = 0;
  final isCustomSite = false.obs;

  HomeController() {
    final pIndex = 0;
    tabController = TabController(
      initialIndex: pIndex == -1 ? 0 : pIndex,
      length: 3,
      vsync: this,
    );
    index = pIndex == -1 ? 0 : pIndex;
  }

  /// 旧版 UI 页面列表
  final List<GetView> legacyBodys = const [
    FavoritePage(),
    PopularPage(),
    AreasPage(),
  ];

  /// 当前页面列表（响应式）
  final RxList<Widget> bodys = <Widget>[].obs;

  /// 根据设置更新页面列表
  void updateBodys() {
    final useFlameUI = SettingsService.instance.enableFlameUI.value;
    bodys.value = [
      useFlameUI ? const FavoriteFlamePage() : const FavoritePage(),
      useFlameUI ? const PopularFlamePage() : const PopularPage(),
      const AreasPage(), // 分区页暂不迁移
    ];
  }

  @override
  void onInit() async {
    for (var site in legacyBodys) {
      Get.put(site.controller);
    }
    // 初始化页面列表
    updateBodys();
    // 监听 Flame UI 设置变化
    ever(SettingsService.instance.enableFlameUI, (_) {
      updateBodys();
    });
    super.onInit();
  }
}
