import 'package:pure_live/common/models/live_room.dart';

extension LiveRoomExtension on LiveRoom {

  /// 设置 离线状态 失败
  LiveRoom getLiveRoomWithError() {
    var liveRoom = this;
    liveRoom.liveStatus = LiveStatus.offline;
    liveRoom.status = false;
    liveRoom.isRecord = false;
    return liveRoom;
  }
}