import 'package:flutter/cupertino.dart';

class SettingVideoFit {
  final BoxFit fit;
  final double? aspectRatio;

  SettingVideoFit(this.fit,{this.aspectRatio});

  @override
  int get hashCode => fit.hashCode ^ aspectRatio.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other)
  || other is SettingVideoFit
  && runtimeType == other.runtimeType
  && (other.fit == fit && other.aspectRatio == aspectRatio);
}