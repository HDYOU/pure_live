import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/base/base_controller.dart';
import 'package:pure_live/common/flame_ui/flame_list_game.dart';
import 'package:pure_live/common/flame_ui/flame_room_card.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/routes/app_navigation.dart';

/// Flame 网格列表 Widget
/// 封装 Flame Game 为标准 Flutter Widget，可直接替代原网格列表
class FlameGridList extends StatefulWidget {
  final BasePageController<LiveRoom> controller;
  final bool dense;
  final Widget? emptyView;

  const FlameGridList({
    super.key,
    required this.controller,
    this.dense = false,
    this.emptyView,
  });

  @override
  State<FlameGridList> createState() => _FlameGridListState();
}

class _FlameGridListState extends State<FlameGridList> {
  late _RoomGridGame _game;

  @override
  void initState() {
    super.initState();
    _game = _RoomGridGame(
      controller: widget.controller,
      dense: widget.dense,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 空状态
      if (widget.controller.list.isEmpty && !widget.controller.loadding.value) {
        return widget.emptyView ??
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.live_tv_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无数据',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
      }

      return Stack(
        children: [
          GameWidget(game: _game),
          // 加载中遮罩
          if (widget.controller.loadding.value)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// 直播间网格游戏实现
class _RoomGridGame extends FlameListGame {
  final BasePageController<LiveRoom> controller;
  final bool dense;

  _RoomGridGame({
    required this.controller,
    this.dense = false,
  }) : super(
          onRefresh: () => controller.refreshData(),
          onLoadMore: () => controller.loadData(),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 监听数据变化
    ever(controller.list, (_) {
      refreshList();
    });
    refreshList();
  }

  @override
  int getItemCount() {
    return controller.list.length;
  }

  @override
  PositionComponent buildItem(int index, Vector2 position, double width) {
    final room = controller.list[index];
    final cardHeight = width * 9 / 16 + (dense ? 50 : 65);
    return FlameRoomCard(
      room: room,
      dense: dense,
      size: Vector2(width, cardHeight),
      position: position,
      onTap: () {
        // 跳转到直播间
        AppNavigator.toLiveRoomDetail(liveRoom: room);
      },
    );
  }
}
