import 'dart:math';

import '../../model/live_play_quality.dart';
import '../../model/live_play_quality_play_url_info.dart';

final class M3u8FileUtil {
  static List<LivePlayQuality> parseM3u8File(String txt, String info) {
    List<LivePlayQuality> list = [];
    var split = txt.split(RegExp(r'[\n\r]+'));
    // BANDWIDTH=3080664,RESOLUTION=1280x720,CODECS="avc1.64001F,mp4a.40.2"
    final bandwidthPattern = RegExp(r'BANDWIDTH=(\d+)');
    final resolutionPattern = RegExp(r'RESOLUTION=\d+x(\d+)');
    final codecsPattern = RegExp("CODECS=[\"']+([\da-zA-Z]+)");
    for (var i = 0; i < split.length; i++) {
      var line = split[i];
      var bandwidth = bandwidthPattern.firstMatch(line)?.group(1) ?? "";
      if (bandwidth.isEmpty) {
        continue;
      }
      var resolution = resolutionPattern.firstMatch(line)?.group(1) ?? "";
      if (resolution.isEmpty) {
        continue;
      }
      var codec = codecsPattern.firstMatch(line)?.group(1) ?? "";
      if (codec.isEmpty) {
        continue;
      }
      var bandwidthNum = int.parse(bandwidth);
      var resolutionNum = int.parse(resolution);
      i++;
      var nextLine = split[i];
      var url = nextLine.trim();
      if (!(url.startsWith("https://") || url.startsWith("http://"))) {
        continue;
      }
      var livePlayQuality = LivePlayQuality(quality: resolutionToQualityName(resolutionNum), sort: bandwidthNum, bitRate: resolutionToBitRate(resolutionNum), data: null);
      livePlayQuality.playUrlList.add(LivePlayQualityPlayUrlInfo(playUrl: url, info: "($info $codec)"));
      list.add(livePlayQuality);
    }
    return list;
  }

  static String resolutionToQualityName(int resolutionNum) {
    if (resolutionNum <= 1080) return "${resolutionNum}p";
    return "${(resolutionNum / 1000).toInt()}K";
  }

  /// 清晰度转码率
  static int resolutionToBitRate(int resolutionNum) {
    var resolutionToBitRateMap = {
      16000: 160000,
      8000: 80000,
      4000: 40000,
      2000: 20000,
      1080: 10000,
      720: 2000,
      480: 1000,
      360: 500,
      160: 250,
    };
    var num = resolutionNum;
    var minVal = 160;
    num = max(num, minVal);
    var bitRate = resolutionToBitRateMap[num];
    if (bitRate != null) return bitRate;
    var tmpNum = 1000;
    if (num > tmpNum) return num * 10;
    var keys = resolutionToBitRateMap.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      if (key > tmpNum) continue;
      if (num > key) return resolutionToBitRateMap[key] ?? 0;
    }
    return 0;
  }
}
