import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/widgets/utils.dart';

import '../util/update_room_util.dart';

class HistoryPage extends GetView {
  HistoryPage({super.key});

  final refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  Future onRefresh() async {
    final SettingsService settings = Get.find<SettingsService>();
    bool result = await UpdateRoomUtil.updateRoomList(settings.historyRooms, settings);
    if (result) {
      refreshController.finishRefresh(IndicatorResult.success);
      refreshController.resetFooter();
    } else {
      refreshController.finishRefresh(IndicatorResult.fail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: Text(S.current.history),
        actions: [
          IconButton(
            tooltip: S.current.clear_history,
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () async {
              var result = await Utils.showAlertDialog(S.current.clear_history_confirm, title: S.current.clear_history);
              if (result) {
                final SettingsService settings = Get.find<SettingsService>();
                settings.clearHistory();
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        final SettingsService settings = Get.find<SettingsService>();
        const dense = true;
        final rooms = settings.historyRooms.toList();
        return LayoutBuilder(builder: (context, constraint) {
          final width = constraint.maxWidth;
          int crossAxisCount = width > 1280 ? 4 : (width > 960 ? 3 : (width > 640 ? 2 : 1));
          if (dense) {
            crossAxisCount = width > 1280 ? 5 : (width > 960 ? 4 : (width > 640 ? 3 : 2));
          }
          return EasyRefresh(
            controller: refreshController,
            onRefresh: onRefresh,
            onLoad: () {
              refreshController.finishLoad(IndicatorResult.noMore);
            },
            child: rooms.isEmpty
                ? EmptyView(
                    icon: Icons.history_rounded,
                    title: S.current.empty_history,
                    subtitle: '',
                    boxConstraints: constraint,
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.all(5),
                    controller: ScrollController(),
                    crossAxisCount: crossAxisCount,
                    itemCount: rooms.length,
                    itemBuilder: (context, index) => RoomCard(
                      room: rooms[rooms.length - 1 - index],
                      dense: dense,
                    ),
                  ),
          );
        });
      }),
    );
  }
}
