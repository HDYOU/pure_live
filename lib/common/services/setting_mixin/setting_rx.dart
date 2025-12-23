import 'package:get/get.dart';
import 'package:pure_live/common/utils/pref_util.dart';

abstract class SettingRxImpl {
  String getKey();

  dynamic getDefaultValue();

  GetListenable getRxValue();

  void fromJsonFunc(Map<String, dynamic> json) {
    getRxValue().value = json[getKey()] ?? getDefaultValue();
  }

  void toJsonFunc(Map<String, dynamic> json) {
    json[getKey()] = getRxValue().value;
  }

  void defaultConfigFunc(Map<String, dynamic> json) {
    json[getKey()] = getDefaultValue();
  }
}

class SettingRxBuild<T> extends SettingRxImpl {
  String key;
  T defaultValue;
  late Rx<T> rxValue;

  SettingRxBuild({required this.key, required this.defaultValue}) {
    var value = defaultValue;
    if (value is String) {
      rxValue = RxString((PrefUtil.getString(key) ?? value)) as Rx<T>;
      rxValue.listen((tmpValue) {
        PrefUtil.setString(key, tmpValue as String);
      });
    } else if (value is int) {
      rxValue = RxInt((PrefUtil.getInt(key) ?? value)) as Rx<T>;
      rxValue.listen((tmpValue) {
        PrefUtil.setInt(key, tmpValue as int);
      });
    } else if (value is bool) {
      rxValue = RxBool((PrefUtil.getBool(key) ?? value)) as Rx<T>;
      rxValue.listen((tmpValue) {
        PrefUtil.setBool(key, tmpValue as bool);
      });
    } else if (value is double) {
      rxValue = RxDouble((PrefUtil.getDouble(key) ?? value)) as Rx<T>;
      rxValue.listen((tmpValue) {
        PrefUtil.setDouble(key, tmpValue as double);
      });
    } else {
      throw UnimplementedError("SettingRxBuild not support! for key: $key, type: ${defaultValue.runtimeType}");
    }
  }

  @override
  dynamic getDefaultValue() => defaultValue;

  @override
  String getKey() => key;

  @override
  GetListenable<dynamic> getRxValue() => rxValue;
}

class SettingRxStringListBuild extends SettingRxImpl {
  String key;
  List<String> defaultValue;
  late RxList<String> rxValue;

  SettingRxStringListBuild({required this.key, required this.defaultValue}) {
    var sValue = (PrefUtil.getStringList(key) ?? defaultValue);
    rxValue = sValue.obs;
    rxValue.listen((tmpValue) {
      PrefUtil.setStringList(key, tmpValue);
    });
  }

  @override
  dynamic getDefaultValue() => defaultValue;

  @override
  String getKey() => key;

  @override
  GetListenable<dynamic> getRxValue() => rxValue;
}

class SettingRxMapBuild extends SettingRxImpl {
  String key;
  Map defaultValue;
  late RxMap rxValue;

  SettingRxMapBuild({required this.key, required this.defaultValue}) {
    var sValue = (PrefUtil.getMap(key) ?? defaultValue);
    rxValue = sValue.obs;
    rxValue.listen((tmpValue) {
      PrefUtil.setMap(key, tmpValue);
    });
  }

  @override
  dynamic getDefaultValue() => defaultValue;

  @override
  String getKey() => key;

  @override
  GetListenable<dynamic> getRxValue() => rxValue;
}
