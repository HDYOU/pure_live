import 'package:flame_barrage/flame_barrage.dart';
import 'package:flutter/material.dart';

import 'danmaku_controller_base.dart';

class FlameBarrageDanmakuController extends DanmakuControllerBase {
  static const String type = "FlameBarrage";

  @override
  String getType() => type;

  final BarrageController barrageController = BarrageController();

  BarrageConfig _barrageConfig = const BarrageConfig(
    fontSize: 16,
    baseSpeed: 120,
    trackHeight: 36,
    showStroke: true,
    safeArea: true,
    opacity: 1.0,
  );

  @override
  void addDanmaku(IDanmakuContentItem item) {
    BarrageType barrageType;
    switch (item.type) {
      case IDanmakuItemType.scroll:
        barrageType = BarrageType.scroll;
      case IDanmakuItemType.top:
        barrageType = BarrageType.topFixed;
      case IDanmakuItemType.bottom:
        barrageType = BarrageType.bottomFixed;
    }

    barrageController.send(
      BarrageItem(
        content: item.text,
        type: barrageType,
        textColor: item.color,
      ),
    );
  }

  @override
  void clear() {
    barrageController.clear();
  }

  @override
  void pause() {
    barrageController.pause();
  }

  @override
  void resume() {
    barrageController.resume();
  }

  @override
  void updateOption(DanmakuSettingOption option) {
    _barrageConfig = _barrageConfig.copyWith(
      fontSize: option.fontSize,
      showStroke: option.showStroke,
      opacity: option.opacity,
      area: option.area,
      safeArea: option.safeArea,
      hideTop: option.hideTop,
      hideBottom: option.hideBottom,
      hideScroll: option.hideScroll,
    );
    barrageController.updateConfig(_barrageConfig);
  }

  @override
  void dispose() {
    barrageController.clear();
    barrageController.detach();
  }

  @override
  Widget getWidget({Key? key}) {
    return FlameBarrageWidget(
      key: key,
      controller: barrageController,
      config: _barrageConfig,
      emojiAtlas: EmojiAtlas.instance,
    );
  }
}
