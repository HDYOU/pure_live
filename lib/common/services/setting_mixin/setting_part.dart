class SettingPartList {
  List<Function> fromJsonList = [];
  List<Function> toJsonList = [];
  List<Function> defaultConfigList = [];
}

typedef FromJson = void Function(Map<String, dynamic> json);
typedef ToJson = void Function(Map<String, dynamic> json);
typedef DefaultConfig = void Function(Map<String, dynamic> json);

class SettingPartBean {
  final FromJson fromJsonFunc;
  final ToJson toJsonFunc;
  final DefaultConfig defaultConfigFunc;

  SettingPartBean({required this.fromJsonFunc, required this.toJsonFunc, required this.defaultConfigFunc});
}
