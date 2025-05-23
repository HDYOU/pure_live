import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/widgets/keep_alive_wrapper.dart';
import 'package:pure_live/common/widgets/status/app_loadding_widget.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/modules/areas/areas_list_controller.dart';

import 'widgets/area_card.dart';

class AreaGridView extends StatefulWidget {
  final String tag;

  const AreaGridView(this.tag, {super.key});

  AreasListController get controller => Get.find<AreasListController>(tag: tag);

  @override
  State<AreaGridView> createState() => _AreaGridViewState();
}

class _AreaGridViewState extends State<AreaGridView> with SingleTickerProviderStateMixin {
  late TabController tabController = TabController(length: widget.controller.list.length, vsync: this);

  @override
  void initState() {
    widget.controller.tabIndex.addListener(() {
      tabController.animateTo(widget.controller.tabIndex.value);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => widget.controller.list.isNotEmpty
        ? Column(
            children: [
              TabBar(
                controller: tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: widget.controller.list.map<Widget>((e) => Tab(text: e.name)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: widget.controller.list.map<Widget>((e) => KeepAliveWrapper(child: buildAreasView(e))).toList(),
                ),
              ),
            ],
          )
        : Container());
  }

  Widget buildAreasView(LiveCategory category) {
    return LayoutBuilder(builder: (context, constraint) {
      final width = constraint.maxWidth;
      final crossAxisCount = width > 1280 ? 9 : (width > 960 ? 7 : (width > 640 ? 5 : 3));
      return Stack(children: [
        widget.controller.list.isNotEmpty
            ? MasonryGridView.count(
                cacheExtent: 3500,
                padding: const EdgeInsets.all(5),
                controller: ScrollController(),
                crossAxisCount: crossAxisCount,
                itemCount: category.children.length,
                itemBuilder: (context, index) => AreaCard(category: category.children[index]),
              )
            : EmptyView(
                icon: Icons.area_chart_outlined,
                title: S.current.empty_areas_title,
                subtitle: S.current.empty_areas_subtitle,
                boxConstraints: constraint,
              ),
        Visibility(
          visible: (widget.controller.loadding.value),
          child: const AppLoaddingWidget(),
        ),
      ]);
    });
  }
}
