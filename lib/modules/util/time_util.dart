import 'package:get/get.dart';
import 'package:pure_live/common/l10n/generated/l10n.dart';

/// 时间处理工具类
final class TimeUtil {
  static String minuteValueToStr(int allMinute) {
    int part = 60;
    var hour = allMinute ~/ part;
    var minute = allMinute % part;
    var str = "";
    if (hour > 0) {
      str = "$str$hour${S.of(Get.context!).hour}";
    }
    if (!(minute == 0 && hour > 0)) {
      str = "$str$minute${S.of(Get.context!).minute}";
    }
    return str;
  }
}