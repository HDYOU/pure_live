import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/site/stripchat/stripchat_site.dart';
import 'package:pure_live/core/site/stripchat/stripchat_danmaku.dart';
import 'package:pure_live/modules/util/json_util.dart';

/// stripchat 直播间详情接口测试
///
/// 测试用例基于 https://zh.virtualtaboo.live/Lan-mei 实际 API 行为编写。
///
/// API 行为验证（2026-11-03）：
///   GET /api/front/users/user-ids/{username}  → 200  {"id": <uid>}
///   GET /api/front/v2/models/{uid}/cam       → 403  {"isUserExist": true}  （已废弃）
///   GET /api/front/v3/config/initial          → 200  {"initial": {"client": {...}, "common": {"hlsStreamHosts": {...}}}}
///   GET /api/front/v4/models/search/suggestion → 200  返回模型列表（无 hlsPlaylist/streamName）
///   GET https://edge-hls.{host}/hls/{uid}/master/{uid}_auto.m3u8 → 200  HLS master playlist
///   GET {apiHost}/hls/{uid}/master/{uid}_auto.m3u8              → 200 HTML（不可用）
void main() {
  const apiHost = 'https://zh.virtualtaboo.live';
  const testUsername = 'Lan-mei';

  group('stripchat getRoomDetail', () {
    late StripChatSite site;

    setUp(() {
      site = StripChatSite();
    });

    // -----------------------------------------------------------------------
    // Step 1: uid 查询
    // -----------------------------------------------------------------------
    test('step1: 通过 username 获取 uid', () async {
      final url = '$apiHost/api/front/users/user-ids/$testUsername';
      final result = await HttpClient.instance.getJson(
        url,
        header: {'Origin': apiHost, 'Referer': '$apiHost/'},
      );
      final data = JsonUtil.decode(result) as Map;
      expect(data.containsKey('id'), isTrue, reason: '响应应包含 id 字段');
      expect(data['id'], isA<int>(), reason: 'id 应为整数');
      expect(data['id'], equals(132789258), reason: 'Lan-mei 的 uid 应为 132789258');
    });

    // -----------------------------------------------------------------------
    // Step 2: config 查询
    // -----------------------------------------------------------------------
    test('step2: config/initial 返回 hlsStreamHosts 和 websocket 信息', () async {
      final url = '$apiHost/api/front/v3/config/initial';
      final result = await HttpClient.instance.getJson(
        url,
        header: {'Origin': apiHost, 'Referer': '$apiHost/'},
      );
      final data = JsonUtil.decode(result) as Map;
      expect(data.containsKey('initial'), isTrue, reason: '响应应包含 initial 字段');

      final initial = data['initial'] as Map;
      final common = initial['common'] as Map;
      final hlsStreamHosts = common['hlsStreamHosts'] as Map;

      // 验证 CDN hosts 存在
      expect(hlsStreamHosts.containsKey('A'), isTrue, reason: '应包含 CDN host A');
      expect(hlsStreamHosts['A'], equals('doppiocdn.com'),
          reason: 'CDN host A 应为 doppiocdn.com');

      // 验证 websocket 信息
      final client = initial['client'] as Map;
      final ws = client['websocket'] as Map;
      expect(ws.containsKey('url'), isTrue, reason: '应包含 websocket url');
      expect(ws['url'], startsWith('wss://'), reason: 'websocket url 应为 wss:// 协议');
      expect(ws.containsKey('token'), isTrue, reason: '应包含 websocket token');
    });

    // -----------------------------------------------------------------------
    // Step 3: cam 接口验证（已知返回 403，仅返回 isUserExist）
    // -----------------------------------------------------------------------
    test('step3: cam 接口对已知用户返回 isUserExist（非完整 cam 数据）', () async {
      final uid = '132789258';
      final url = '$apiHost/api/front/v2/models/$uid/cam';
      final result = await HttpClient.instance.getJson(
        url,
        queryParameters: {
          'timezoneOffset': '-480',
          'triggerRequest': 'loadCam',
          'withRecentShow': '1',
        },
        header: {'Origin': apiHost, 'Referer': '$apiHost/'},
      );
      final data = JsonUtil.decode(result) as Map;
      // 当前 cam 接口仅返回 isUserExist，不包含 user/cam 完整数据
      expect(data.containsKey('isUserExist'), isTrue,
          reason: 'cam 接口返回 isUserExist 而非完整用户数据');
    });

    // -----------------------------------------------------------------------
    // Step 4: HLS CDN URL 可访问性验证
    // -----------------------------------------------------------------------
    test('step4: edge-hls CDN 可正常返回 HLS master playlist', () async {
      final uid = '132789258';
      final cdnHost = 'doppiocdn.media';
      final url = 'https://edge-hls.$cdnHost/hls/$uid/master/$uid_auto.m3u8';
      final response = await HttpClient.instance.getText(
        url,
        header: {'Origin': apiHost, 'Referer': '$apiHost/'},
      );
      expect(response.isNotEmpty, isTrue, reason: 'HLS 响应不应为空');
      expect(response.contains('#EXTM3U'), isTrue, reason: '应为有效的 m3u8 文件');
      expect(response.contains('EXT-X-STREAM-INF'), isTrue,
          reason: '应包含流质量信息');
    });

    // -----------------------------------------------------------------------
    // Step 5: apiHost 直连 HLS 返回 HTML（不可用）
    // -----------------------------------------------------------------------
    test('step5: apiHost 直连 HLS URL 返回 HTML 而非 m3u8（不可用）', () async {
      final uid = '132789258';
      final url = '$apiHost/hls/$uid/master/$uid_auto.m3u8?pkey=test';
      final response = await HttpClient.instance.getText(
        url,
        header: {'Origin': apiHost, 'Referer': '$apiHost/'},
      );
      expect(response.contains('<!DOCTYPE') || response.contains('<html'), isTrue,
          reason: 'apiHost 直连返回的是 HTML 页面，非 HLS 数据，不可用作播放源');
    });

    // -----------------------------------------------------------------------
    // Step 6: 完整 getRoomDetail 流程
    // 已知限制：cam 接口 (/v2/models/{uid}/cam) 当前返回 403，
    //   仅包含 {"isUserExist": true}，不再返回 user/cam 完整数据。
    //   HttpClient.getJson 将 403 转为 CoreError，被 getRoomDetail catch 后
    //   返回 getLiveRoomWithError(detail)。
    // -----------------------------------------------------------------------
    test('getRoomDetail: Lan-mei 直播间详情（cam 接口 403 导致返回错误 LiveRoom）',
        () async {
      final detail = LiveRoom(roomId: testUsername, platform: 'stripchat');
      final liveRoom = await site.getRoomDetail(detail: detail);

      // cam 接口 403 → CoreError → getLiveRoomWithError
      // getLiveRoomWithError 保持原始 roomId/platform，userId 为空
      expect(liveRoom.roomId, equals(testUsername),
          reason: '错误处理应保留原始 roomId');
      expect(liveRoom.platform, equals('stripchat'),
          reason: '错误处理应保留 platform');
      expect(liveRoom.userId, isEmpty,
          reason: 'cam 接口失败时 userId 应为空（uid 查询已执行但未完成完整流程）');
    });

    // -----------------------------------------------------------------------
    // Step 7: 不存在的用户
    // -----------------------------------------------------------------------
    test('getRoomDetail: 不存在的用户返回错误 LiveRoom', () async {
      final detail =
          LiveRoom(roomId: 'nonexistent_user_xyz_12345', platform: 'stripchat');
      final liveRoom = await site.getRoomDetail(detail: detail);

      // uid 查询失败，应返回错误处理结果
      expect(liveRoom.roomId, equals('nonexistent_user_xyz_12345'),
          reason: 'roomId 应保持原始值');
      expect(liveRoom.userId, isEmpty,
          reason: 'uid 查询失败时 userId 应为空');
    });

    // -----------------------------------------------------------------------
    // Step 8: parseToLiveRoom 字段解析验证
    // -----------------------------------------------------------------------
    test('parseToLiveRoom: 正确解析在线主播字段', () {
      final jsonObj = {
        'username': 'TestUser',
        'id': '123456',
        'status': 'public',
        'viewersCount': '999',
        'snapshotTimestamp': '1793694360',
        'previewUrlThumbSmall':
            'https://static-proxy.strpst.com/previews/test-thumb-small',
        'topic': 'Test Topic',
      };
      final room = site.parseToLiveRoom(jsonObj);
      expect(room.roomId, equals('TestUser'));
      expect(room.userId, equals('123456'));
      expect(room.nick, equals('TestUser'));
      expect(room.title, equals('Test Topic'));
      expect(room.watching, equals('999'));
      expect(room.status, isTrue);
      expect(room.liveStatus, equals(LiveStatus.live));
      expect(room.cover, contains('i2.wp.com'),
          reason: 'cover 应替换为 wp 代理地址');
    });

    test('parseToLiveRoom: 正确解析离线主播字段', () {
      final jsonObj = {
        'username': 'OfflineUser',
        'id': '654321',
        'status': 'private',
        'viewersCount': '0',
        'snapshotTimestamp': null,
        'previewUrlThumbSmall': '',
      };
      final room = site.parseToLiveRoom(jsonObj);
      expect(room.roomId, equals('OfflineUser'));
      expect(room.status, isFalse);
      expect(room.liveStatus, equals(LiveStatus.offline));
      expect(room.cover, isEmpty, reason: '离线主播无 snapshotTimestamp 时 cover 为空');
    });

    // -----------------------------------------------------------------------
    // Step 9: getByKeyList 工具方法
    // -----------------------------------------------------------------------
    test('getByKeyList: 按优先级查找字段', () {
      final obj = {'a': 1, 'b': 2, 'c': 3};
      expect(site.getByKeyList(obj, ['x', 'y', 'z']), isNull);
      expect(site.getByKeyList(obj, ['c', 'b', 'a']), equals(3));
      expect(site.getByKeyList(obj, ['b', 'a']), equals(2));
    });
  });
}
