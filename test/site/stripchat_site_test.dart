import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/core/site/stripchat/stripchat_site.dart';
import 'package:pure_live/core/site/stripchat/stripchat_danmaku.dart';
import 'package:pure_live/modules/util/json_util.dart';

/// stripchat 直播间单元测试
///
/// 测试目标：验证 stripchat 站点核心逻辑，不依赖 HttpClient 单例
/// （该单例在测试环境需要初始化 Rust native 库）。
///
/// API 行为参考（2026-11-03 实测）：
///   GET https://zh.virtualtaboo.live/api/front/users/user-ids/Lan-mei
///     → 200 {"id": 132789258}
///   GET https://zh.virtualtaboo.live/api/front/v2/models/132789258/cam?triggerRequest=loadCam
///     → 200 {user: {...}, cam: {...}}（需 X-Requested-With header）
///   GET https://zh.virtualtaboo.live/api/front/v3/config/initial
///     → 200 {initial: {client: {websocket: {...}}, common: {hlsStreamHosts: {...}}}}
///   GET https://edge-hls.doppiocdn.media/hls/{uid}/master/{uid}_auto.m3u8
///     → 200 #EXTM3U master playlist（含 source/480p/240p）
void main() {
  const apiHost = 'https://zh.virtualtaboo.live';
  const testUsername = 'Lan-mei';
  const testUid = '132789258';

  final dio = Dio(BaseOptions(
    headers: {
      'Origin': apiHost,
      'Referer': '$apiHost/',
      'X-Requested-With': 'XMLHttpRequest',
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    },
  ));

  group('stripchat getRoomDetail', () {
    late StripChatSite site;

    setUp(() {
      site = StripChatSite();
    });

    // -----------------------------------------------------------------------
    // Step 1: uid 查询（直接 HTTP）
    // -----------------------------------------------------------------------
    test('step1: 通过 username 获取 uid', () async {
      final url = '$apiHost/api/front/users/user-ids/$testUsername';
      final response = await dio.get(url);
      expect(response.statusCode, equals(200));
      final data = JsonUtil.decode(response.data) as Map;
      expect(data.containsKey('id'), isTrue, reason: '响应应包含 id 字段');
      expect(data['id'], isA<int>(), reason: 'id 应为整数');
      expect(data['id'], equals(132789258),
          reason: 'Lan-mei 的 uid 应为 132789258');
    });

    // -----------------------------------------------------------------------
    // Step 2: config 查询（直接 HTTP）
    // -----------------------------------------------------------------------
    test(
        'step2: config/initial 返回 hlsStreamHosts 和 websocket 信息',
        () async {
      final url = '$apiHost/api/front/v3/config/initial';
      final response = await dio.get(url);
      expect(response.statusCode, equals(200));
      final data = JsonUtil.decode(response.data) as Map;
      expect(data.containsKey('initial'), isTrue,
          reason: '响应应包含 initial 字段');

      final initial = data['initial'] as Map;
      final common = initial['common'] as Map;
      final hlsStreamHosts = common['hlsStreamHosts'] as Map;

      // 验证 CDN hosts 存在
      expect(hlsStreamHosts.containsKey('A'), isTrue,
          reason: '应包含 CDN host A');
      expect(hlsStreamHosts['A'], equals('doppiocdn.com'),
          reason: 'CDN host A 应为 doppiocdn.com');

      // 验证 websocket 信息
      final client = initial['client'] as Map;
      final ws = client['websocket'] as Map;
      expect(ws.containsKey('url'), isTrue, reason: '应包含 websocket url');
      expect(ws['url'], startsWith('wss://'),
          reason: 'websocket url 应为 wss:// 协议');
      expect(ws.containsKey('token'), isTrue, reason: '应包含 websocket token');
    });

    // -----------------------------------------------------------------------
    // Step 3: cam 接口验证（带正确 headers 返回 200）
    // -----------------------------------------------------------------------
    test('step3: cam 接口返回完整 user/cam 数据（非 isUserExist）', () async {
      final url = '$apiHost/api/front/v2/models/$testUid/cam';
      final response = await dio.get(
        url,
        queryParameters: {
          'timezoneOffset': '-480',
          'triggerRequest': 'loadCam',
          'withRecentShow': '1',
        },
      );
      expect(response.statusCode, equals(200),
          reason: '带 X-Requested-With header 时 cam 接口返回 200');
      final data = JsonUtil.decode(response.data) as Map;
      // 正确的 cam 响应应包含 user 和 cam 字段
      expect(data.containsKey('user'), isTrue,
          reason: 'cam 接口应返回 user 字段');
      expect(data.containsKey('cam'), isTrue, reason: 'cam 接口应返回 cam 字段');
      final userObj = data['user']['user'] as Map;
      expect(userObj['id'], equals(132789258),
          reason: 'user.id 应为 132789258');
      expect(userObj['username'], equals('Lan-mei'),
          reason: 'user.username 应为 Lan-mei');
      expect(userObj['status'], anyOf(equals('public'), equals('groupShow')),
          reason: 'user.status 应为 public 或 groupShow');
    });

    // -----------------------------------------------------------------------
    // Step 4: HLS CDN URL 可访问性验证
    // -----------------------------------------------------------------------
    test('step4: edge-hls CDN 可正常返回 HLS master playlist', () async {
      final cdnHost = 'doppiocdn.media';
      final url =
          'https://edge-hls.$cdnHost/hls/$testUid/master/${testUid}_auto.m3u8';
      final response = await dio.get(url);
      expect(response.statusCode, equals(200),
          reason: 'edge-hls CDN 应返回 200');
      final body = response.data as String;
      expect(body.isNotEmpty, isTrue, reason: 'HLS 响应不应为空');
      expect(body.contains('#EXTM3U'), isTrue,
          reason: '应为有效的 m3u8 文件');
      expect(body.contains('EXT-X-STREAM-INF'), isTrue,
          reason: '应包含流质量信息');
    });

    // -----------------------------------------------------------------------
    // Step 5: apiHost 直连 HLS（无 X-Requested-With 时 406）
    // -----------------------------------------------------------------------
    test(
        'step5: apiHost 直连 HLS 需要 X-Requested-With header（否则返回非 200）',
        () async {
      // 不带 X-Requested-With
      final dioNoXhr = Dio(BaseOptions(
        headers: {
          'Origin': apiHost,
          'Referer': '$apiHost/',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ));
      final url =
          '$apiHost/hls/$testUid/master/${testUid}_auto.m3u8?pkey=test';
      try {
        await dioNoXhr.get(url);
        fail('应抛出异常（非 200 状态码）');
      } catch (e) {
        expect(e, isA<DioException>(), reason: '应为 DioException');
        final dioEx = e as DioException;
        // 无 X-Requested-With 时服务端返回 406 或 404（非 200 即可）
        final statusCode = dioEx.response?.statusCode;
        expect(statusCode != null && statusCode! != 200, isTrue,
            reason: '缺少 X-Requested-With 时应返回非 200 状态码');
      }
    });

    // -----------------------------------------------------------------------
    // Step 6: getRoomDetail 模拟数据测试（不依赖 HttpClient 单例）
    // -----------------------------------------------------------------------
    test(
        'getRoomDetail: 模拟 Lan-mei 数据验证解析逻辑',
        () async {
      // 模拟 cam API 响应
      final camData = {
        'user': {
          'user': {
            'id': testUid,
            'username': testUsername,
            'status': 'public',
            'isLive': true,
            'viewersCount': 479,
            'snapshotTimestamp': '1793696400',
            'previewUrlThumbSmall':
                'https://static-proxy.strpst.com/previews/test-thumb-small',
          }
        },
        'cam': {
          'streamName': testUid,
          'topic': '主播话题测试',
          'isCamActive': true,
        }
      };

      // 模拟 config 响应
      final configData = {
        'initial': {
          'client': {
            'websocket': {
              'url': 'wss://test.websocket.com/connection/websocket',
              'token': 'test_jwt_token_abc123',
            }
          },
          'common': {
            'hlsStreamHosts': {
              'A': 'doppiocdn.com',
              'B': 'doppiocdn1.com',
              'C': 'doppiocdn.media',
            }
          }
        }
      };

      // 构造 detail（模拟从列表接口获取的数据）
      final hlsHosts = <String>[];
      final hostsMap =
          (configData['initial'] as Map?)?['common'] as Map? ?? {};
      final streamHosts = hostsMap['hlsStreamHosts'] as Map? ?? {};
      for (var entry in streamHosts.entries) {
        hlsHosts.add(entry.value.toString());
      }

      final detail = LiveRoom(
        roomId: testUsername,
        platform: 'stripchat',
        data: {
          'username': testUsername,
          'id': testUid,
          'status': 'public',
          'streamName': testUid,
          'viewersCount': '479',
          'snapshotTimestamp': '1793696400',
          'hlsHosts': hlsHosts,
        },
      );

      // parseToLiveRoom 验证
      final userObj = (camData['user'] as Map?)?['user'] as Map? ?? {};
      final camObj = camData['cam'] as Map? ?? {};
      final room = site.parseToLiveRoom(userObj, camObj: camObj);

      expect(room.roomId, equals(testUsername));
      expect(room.userId, equals(testUid));
      expect(room.nick, equals(testUsername));
      expect(room.title, equals('主播话题测试'));
      expect(room.watching, equals('479'));
      expect(room.status, isTrue);
      expect(room.liveStatus, equals(LiveStatus.live));
      expect(room.cover, contains('i2.wp.com'));
    });

    // -----------------------------------------------------------------------
    // Step 7: 不存在的用户
    // -----------------------------------------------------------------------
    test('getRoomDetail: 不存在的用户接口返回 404', () async {
      final url =
          '$apiHost/api/front/users/user-ids/nonexistent_user_xyz_12345';
      try {
        await dio.get(url);
        fail('应抛出异常');
      } catch (e) {
        expect(e, isA<DioException>());
        final dioEx = e as DioException;
        expect(dioEx.response?.statusCode, equals(404),
            reason: '不存在的用户应返回 404');
      }
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
      expect(room.cover, isEmpty,
          reason: '离线主播无 snapshotTimestamp 时 cover 为空');
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
