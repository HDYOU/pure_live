import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/widgets/keep_alive_wrapper.dart';
import 'package:pure_live/modules/home/home_controller.dart';
import 'package:pure_live/modules/search/search_controller.dart' as pure_live;

class HomeTabletViewV2 extends GetView<HomeController> {
  const HomeTabletViewV2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraint) {
        bool showAction = Get.width > 680;
        return SafeArea(
          child: Row(
            children: [
              NavigationRail(
                groupAlignment: 0.9,
                labelType: NavigationRailLabelType.all,
                leading: showAction
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: MenuButton(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 0, bottom: 12, left: 12, right: 12),
                      child: IconButton(
                          onPressed: () {
                            Get.toNamed(RoutePath.kToolbox);
                          },
                          icon: const Icon(Icons.link)),
                    ),
                    FloatingActionButton(
                      heroTag: 'heroTag2',
                      elevation: 0,
                      onPressed: () {
                        // Get.put(pure_live.SearchController());
                        Get.toNamed(RoutePath.kSearch);
                      },
                      child: const Icon(CustomIcons.search),
                    ),
                  ],
                )
                    : Container(),
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.favorite_rounded),
                    label: Text(S.of(context).favorites_title),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(CustomIcons.popular),
                    label: Text(S.of(context).popular_title),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.area_chart_rounded),
                    label: Text(S.of(context).areas_title),
                  ),
                ],
                selectedIndex: null,
                onDestinationSelected: (int index) {
                  controller.tabController.index = index;
                  controller.tabController.animateTo(index);
                },
              ),
              const VerticalDivider(width: 1),
              Expanded(child: TabBarView(
                controller: controller.tabController,
                children:
                controller.bodys.map((e) => KeepAliveWrapper(child: e)).toList(),
              )),
            ],
          ),
        );
      }),
    );
  }
}