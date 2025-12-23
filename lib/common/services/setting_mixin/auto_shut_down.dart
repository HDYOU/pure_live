import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/services/setting_mixin/setting_part.dart';
import 'package:pure_live/common/services/setting_mixin/setting_rx.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

/// 自动关闭
mixin AutoShutDownMixin {
  /// 自动关闭时间
  final autoShutDownTimeBuild = SettingRxBuild(key: "autoShutDownTime", defaultValue: 120);
  late final autoShutDownTime = autoShutDownTimeBuild.rxValue;

  /// 是否允许自动关闭
  final enableAutoShutDownTimeBuild = SettingRxBuild(key: "enableAutoShutDownTime", defaultValue: false);
  late final enableAutoShutDownTime = enableAutoShutDownTimeBuild.rxValue;

  StopWatchTimer _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countDown); // Create instance.
  StopWatchTimer get stopWatchTimer => _stopWatchTimer;

  void handleWatchTimer(){
    if (enableAutoShutDownTime.isTrue) {
      _stopWatchTimer.onStopTimer();
      _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countDown, refreshTime: autoShutDownTime.value * 60);
      _stopWatchTimer.setPresetMinuteTime(autoShutDownTime.value, add: false);
      _stopWatchTimer.onStartTimer();
    } else {
      _stopWatchTimer.onStopTimer();
    }
  }

  void initAutoShutDown(SettingPartList settingPartList) {
    autoShutDownTime.listen((value) {
      handleWatchTimer();
    });

    enableAutoShutDownTime.listen((value) {
      handleWatchTimer();
    });

    _stopWatchTimer.fetchEnded.listen((value) {
      FlutterExitApp.exitApp();
    });
    handleWatchTimer();

    var list = [autoShutDownTimeBuild, enableAutoShutDownTimeBuild];
    for (var value in list) {
      settingPartList.fromJsonList.add(value.fromJsonFunc);
      settingPartList.toJsonList.add(value.toJsonFunc);
      settingPartList.defaultConfigList.add(value.defaultConfigFunc);
    }

  }

  void onInitShutDown() {
    handleWatchTimer();
  }

  void changeShutDownConfig(int minutes, bool isAutoShutDown) {
    autoShutDownTime.value = minutes;
    enableAutoShutDownTime.value = isAutoShutDown;
    onInitShutDown();
  }

}
