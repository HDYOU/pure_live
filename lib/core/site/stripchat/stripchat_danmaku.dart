import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pure_live/common/index.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/web_socket_util.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';

class StripChatDanmaku implements LiveDanmaku {
  WebScoketUtils? webScoketUtils;

  @override
  int heartbeatTime = 60 * 1000; //默认是60s

  var serverUrl = "wss://chat-ws.neolive.kr/connection/websocket";

  static final _msgRegex = RegExp(r'"message":"(.+?)"');
  static final _senderRegex = RegExp(r'"nk":"(.+?)"');
  static final _createTimeRegex = RegExp(r'"created_at":(\d+)');
  static final _idxRegex = RegExp(r'"idx":"(\d+)"');

  // 正则匹配直播间URL
  static final _urlRegex = RegExp(r'https?://[^/]+/([^/?]+)');

  @override
  Function(String msg)? onClose;

  @override
  Function(LiveMessage msg)? onMessage;

  @override
  Function()? onReady;

  @override
  void heartbeat() {
    // 发送心跳包
    final heartbeatPacket = jsonEncode({
      'method': '7',
      'id': '${_sendId++}',
    });
    webScoketUtils?.sendMessage(heartbeatPacket);
  }

  @override
  Future start(args) async {
    var headers = {
      'Origin': 'https://www.pandalive.co.kr',
    };
    webScoketUtils = WebScoketUtils(
      url: serverUrl,
      heartBeatTime: heartbeatTime,
      headers: headers,
      onMessage: (e) {
        decodeMessage(e);
      },
      onReady: () {
        onReady?.call();
        joinRoom(args);
      },
      onHeartBeat: () {
        heartbeat();
      },
      onReconnect: () {
        onClose?.call("与服务器断开连接，正在尝试重连");
      },
      onClose: (e) {
        onClose?.call("服务器连接失败$e");
      },
    );
    webScoketUtils?.connect();
  }

  int _sendId = 1;

  Future<void> joinRoom(args) async {
    args = args as StripChatDanmakuArgs;

    // 认证数据包
    final authPacket = jsonEncode({
      'id': _sendId++,
      'params': {
        'token': args.token,
        'name': 'js',
      }
    });

    // 加入频道数据包
    final joinChannelPacket = jsonEncode({
      'method': 1,
      'params': {'channel': args.userId},
      'id': _sendId++,
    });

    webScoketUtils?.sendMessage(authPacket);
    await Future.delayed(const Duration(milliseconds: 100)); // 避免消息发送过快
    webScoketUtils?..sendMessage(joinChannelPacket);
  }

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
    webScoketUtils?.close();
  }

  void decodeMessage(dynamic data) {
    try {
      String msg;
      if (data is Uint8List) {
        msg = utf8.decode(data);
      } else if (data is String) {
        msg = data;
      } else {
        CoreLog.w('未知消息类型: ${data.runtimeType}');
        return;
      }

      // 解析弹幕
      final danmuList = _decodeDanmu(msg);
      if (danmuList.isNotEmpty) {
        for (var item in danmuList) {
          onMessage?.call(item);
        }
      }
    } catch (e) {
      CoreLog.error('处理消息失败: $e');
    }
  }

  /// 解析弹幕消息
  List<LiveMessage> _decodeDanmu(String msg) {
    final supportedTypes = ['chatter', 'manager'];

    CoreLog.d("pandatv msg: ${msg}");
    // 检查是否是支持的弹幕类型
    if (!supportedTypes.any((type) => msg.contains('"type":"$type"'))) {
      return [];
    }

    // 提取弹幕内容
    final msgMatch = _msgRegex.firstMatch(msg);
    if (msgMatch == null) return [];
    var message = msgMatch.group(1)!;

    // 提取发送者
    final senderMatch = _senderRegex.firstMatch(msg);
    final sender = senderMatch?.group(1) ?? '';

    // 提取创建时间
    final timeMatch = _createTimeRegex.firstMatch(msg);
    final createTime = timeMatch != null ? int.tryParse(timeMatch.group(1)!) ?? 0 : 0;

    // 提取用户ID
    final idxMatch = _idxRegex.firstMatch(msg);
    final idx = idxMatch != null ? int.tryParse(idxMatch.group(1)!) ?? 0 : 0;

    message = message.replaceAll("\\n", "\n");
    return [
      LiveMessage(
        type: LiveMessageType.chat,
        userName: sender,
        message: message,
        // userLevel: ,
        // fansName: ,
        // fansLevel: ,
        color: Colors.white,
      )
    ];
  }
}

class StripChatDanmakuArgs {
  final String roomId;
  final String userId;
  final String token;

  StripChatDanmakuArgs({required this.roomId, required this.token, required this.userId});
}
