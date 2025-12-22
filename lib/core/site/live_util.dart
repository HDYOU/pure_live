import '../../model/live_play_quality.dart';

final class LiveUtil {

  static List<LivePlayQuality> combineLivePlayQuality(List<LivePlayQuality> list) {
    Map<int, LivePlayQuality> map = {};
    var qualities = <LivePlayQuality>[];
    for (var item in list) {
      var bitRate = item.bitRate;
      if (map.containsKey(bitRate)) {
        map[bitRate]?.playUrlList.addAll(item.playUrlList);
      } else {
        map[bitRate] = item;
      }
    }
    var keys = map.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    for (var key in keys) {
      var value = map[key]!;
      value.playUrlList = value.playUrlList.toSet().toList();
      qualities.add(value);
    }
    return qualities;
  }
}
