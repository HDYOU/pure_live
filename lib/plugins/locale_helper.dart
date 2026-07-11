import 'package:easy_localization/easy_localization.dart';

/// 国际化辅助函数 - 桥接到 easy_localization 系统
///
/// 统一使用 easy_localization 的 JSON 翻译文件 (assets/translations/)
/// 支持动态 key 查询和参数替换
String i18n(String key, {Map<String, String>? args}) {
  try {
    // 使用 easy_localization 的 tr() 方法获取翻译
    // 如果 key 不存在，easy_localization 默认返回 key 本身
    final result = key.tr(namedArgs: args ?? {});
    return result;
  } catch (e) {
    // 如果 easy_localization 尚未初始化或出错，返回 key 作为降级
    return key;
  }
}
