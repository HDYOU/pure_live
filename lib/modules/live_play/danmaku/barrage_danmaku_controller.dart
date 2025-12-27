import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/danmaku_text.dart';
import 'package:pure_live/plugins/barrage.dart';

import 'danmaku_controller_base.dart';

class BarrageDanmakuController extends DanmakuControllerBase {
  static const String type = "Barrage";

  @override
  String getType() => type;

  /// 弹幕
  BarrageWallController danmakuController = BarrageWallController();

  ValueNotifier<DanmakuSettingOption> optionsNotifier = ValueNotifier(DanmakuSettingOption());

  @override
  void addDanmaku(IDanmakuContentItem item) {
    var options = optionsNotifier.value;
    danmakuController.send([
      Bullet(
        child: DanmakuText(
          item.text,
          fontSize: options.fontSize,
          strokeWidth: options.showStroke ? 2.0 : 0,
          color: item.color,
        ),
      ),
    ]);
  }

  @override
  void clear() {
    danmakuController.reset(0);
  }

  @override
  void pause() {
    danmakuController.disable();
  }

  @override
  void resume() {
    danmakuController.enable();
  }

  @override
  void updateOption(DanmakuSettingOption option) {
    optionsNotifier.value = option;
  }

  @override
  void dispose() {
    danmakuController.dispose();
  }

  @override
  Widget getWidget({Key? key}) {
    return DanmakuViewer(
      key: key,
      controller: this,
    );
  }
}

class DanmakuViewer extends StatelessWidget {
  const DanmakuViewer({
    super.key,
    required this.controller,
  });

  final BarrageDanmakuController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DanmakuSettingOption>(
        valueListenable: controller.optionsNotifier,
        builder: (BuildContext context, DanmakuSettingOption options, Widget? child) {
          return Opacity(
              opacity: options.opacity,
              child: (options.area == 0.0
                  ? Container()
                  : LayoutBuilder(builder: (context, constraint) {
                      final width = constraint.maxWidth;
                      final height = constraint.maxHeight;
                      return BarrageWall(
                        width: width,
                        height: height * options.area,
                        controller: controller.danmakuController,
                        speed: options.duration.toInt(),
                        maxBulletHeight: options.fontSize * 1.5,
                        massiveMode: false,
                        // disabled by default
                        child: Container(),
                      );
                    })));
        });
  }
}
