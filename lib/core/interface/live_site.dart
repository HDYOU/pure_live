import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/model/live_anchor_item.dart';
import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/model/live_play_quality_play_url_info.dart';
import 'package:pure_live/model/live_search_result.dart';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/model/live_category_result.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';

import 'live_site_mixin.dart';

class LiveSite with SiteAccount, SiteVideoHeaders, SiteOpen {
  /// 站点唯一ID
  String id = "";

  /// 站点名称
  String name = "";

  /// 站点名称
  LiveDanmaku getDanmaku() => LiveDanmaku();

  /// 读取网站的分类
  Future<List<LiveCategory>> getCategores(int page, int pageSize) {
    return Future.value(<LiveCategory>[]);
  }

  /// 搜索直播间
  Future<LiveSearchRoomResult> searchRooms(String keyword, {int page = 1}) {
    return Future.value(LiveSearchRoomResult(hasMore: false, items: <LiveRoom>[]));
  }

  /// 搜索直播间
  Future<LiveSearchAnchorResult> searchAnchors(String keyword, {int page = 1}) {
    return Future.value(LiveSearchAnchorResult(hasMore: false, items: <LiveAnchorItem>[]));
  }

  /// 读取类目下房间
  Future<LiveCategoryResult> getCategoryRooms(LiveArea category, {int page = 1}) {
    return Future.value(LiveCategoryResult(hasMore: false, items: <LiveRoom>[]));
  }

  /// 读取推荐的房间
  Future<LiveCategoryResult> getRecommendRooms({int page = 1, required String nick}) {
    return Future.value(LiveCategoryResult(hasMore: false, items: <LiveRoom>[]));
  }

  /// 读取房间详情
  Future<LiveRoom> getRoomDetail({
    required String roomId,
    required String platform,
    required String nick,
    required String title,
  }) {
    return Future.value(LiveRoom(
      cover: '',
      watching: '0',
      roomId: '',
      status: false,
      platform: platform,
      liveStatus: LiveStatus.offline,
      title: title,
      link: '',
      avatar: '',
      nick: nick,
      isRecord: false,
    ));
  }

  /// 读取房间清晰度
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) {
    return Future.value(<LivePlayQuality>[]);
  }

  /// 读取播放链接
  Future<List<LivePlayQualityPlayUrlInfo>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) {
    return Future.value(<LivePlayQualityPlayUrlInfo>[]);
  }

  /// 查询直播状态
  Future<bool> getLiveStatus(
      {required String nick, required String platform, required String roomId, required String title}) {
    return Future.value(false);
  }

  /// 读取指定房间的SC
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) {
    return Future.value([]);
  }

  /// 是否支持批量更新房间
  bool isSupportBatchUpdateLiveStatus() {
    return false;
  }

  /// 批量更新房间
  Future<List<LiveRoom>> getLiveRoomDetailList(
      {required List<LiveRoom> list}) {
    return Future.value(list);
  }
}
