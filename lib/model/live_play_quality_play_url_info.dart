import 'dart:convert';

class LivePlayQualityPlayUrlInfo {
  /// 播放链接
  String playUrl;

  ///  额外信息
  String info = "";

  LivePlayQualityPlayUrlInfo({
    required this.playUrl,
    this.info = "",
  });

  Map<String, dynamic> toJson() {
    return {
      "playUrl": playUrl,
      "info": info.toString(),
    };
  }

  @override
  String toString() {
    return json.encode({
      "playUrl": playUrl,
      "info": info.toString(),
    });
  }

  @override
  int get hashCode => playUrl.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other)
          || other is LivePlayQualityPlayUrlInfo
          && runtimeType == other.runtimeType
          && (other.playUrl == playUrl);
}
