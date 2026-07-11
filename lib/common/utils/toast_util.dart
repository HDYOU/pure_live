import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// Toast 工具类 - 适配上游 IPTV 系统
class ToastUtil {
  static DateTime? _lastShowTime;
  static String? _lastMsg;

  static void show(String? msg) {
    if (msg == null || msg.isEmpty) return;
    final now = DateTime.now();
    if (msg == _lastMsg &&
        _lastShowTime != null &&
        now.difference(_lastShowTime!) < const Duration(milliseconds: 3000)) {
      return;
    }
    _lastShowTime = now;
    _lastMsg = msg;
    SmartDialog.showToast(msg);
  }
}
