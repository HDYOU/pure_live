import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/utils/color_util.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/common/web_socket_util.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:uuid/uuid.dart';

import '../cc/cc_danmaku.dart';
import 'buffer_parser.dart';

class YyDanmaku implements LiveDanmaku {
  WebScoketUtils? webScoketUtils;

  @override
  int heartbeatTime = 5 * 1000; //默认是5s

  var serverUrl = "wss://h5-sinchl.yy.com/websocket?appid=yymwebh5&version=3.2.10&uuid=f7808782-1ac8-4582-8a84-c3eab2756ade";

  @override
  Function(String msg)? onClose;

  @override
  Function(LiveMessage msg)? onMessage;

  @override
  Function()? onReady;

  @override
  void heartbeat() {
// 发送心跳包
    // 00000000: 0e00 0000 041e 0c00 c800 0000 0000
    var data = [0x0e00, 0x0000, 0x041e, 0x0c00, 0xc800, 0x0000, 0x0000];
    webScoketUtils?.sendMessage(data);
  }

  var appId = "yymwebh5";
  var appVersion = "3.2.10";
  var uuid = Uuid().v1();

  @override
  Future start(args) async {
    var headers = {
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
      // 'host': 'h5-sinchl.yy.com',
      'origin': 'https://www.yy.com',
    };
    // wss://h5-sinchl.yy.com/websocket?appid=yymwebh5&version=3.2.10&uuid=f7808782-1ac8-4582-8a84-c3eab2756ade
    webScoketUtils = WebScoketUtils(
      url: "wss://h5-sinchl.yy.com/websocket?appid=$appId&version=$appVersion&uuid=$uuid",
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

  late DanmakuArgs danmakuArgs;

  void joinRoom(dynamic args) {
    danmakuArgs = args as DanmakuArgs;
    var buildJoinChannelPacket = _buildJoinChannelPacket();
    webScoketUtils?.sendMessage(buildJoinChannelPacket);
  }

  /// 内部方法：构造加入频道协议包（YY 协议标准格式）
  Uint8List? _buildJoinChannelPacket() {
    var uid = 0;
    var topSid = danmakuArgs.topSid;
    var subSid = danmakuArgs.subSid;
    try {
      // 协议包总长度（预留足够空间，后续截取有效长度）
      final bufferSize = 256;
      final buffer = Uint8List(bufferSize);
      final byteData = ByteData.view(buffer.buffer);
      int offset = 0;

      // --------------------------
      // 填充 YY 加入频道协议固定字段
      // --------------------------
      // 1. 协议头部（4 字节，固定标识）
      byteData.setUint32(offset, 0x10000001, Endian.little);
      offset += 4;

      // 2. 指令码（4 字节，加入频道固定指令：3104100）
      byteData.setUint32(offset, 3104100, Endian.little);
      offset += 4;

      // 3. 保留字段（2 字节，填 0）
      byteData.setUint16(offset, 0, Endian.little);
      offset += 2;

      // 4. 用户 UID（4 字节）
      byteData.setUint32(offset, uid, Endian.little);
      offset += 4;

      // 5. 主频道 ID（topSid，4 字节）
      byteData.setUint32(offset, topSid, Endian.little);
      offset += 4;

      // 6. 子频道 ID（subSid，4 字节）
      byteData.setUint32(offset, subSid, Endian.little);
      offset += 4;

      // 7. 客户端类型（4 字节，Dart 端填 10（自定义，兼容服务端））
      byteData.setUint32(offset, 10, Endian.little);
      offset += 4;

      // 8. 版本号（UTF8 字符串，先填长度再填内容）
      final versionBytes = utf8.encode(appVersion);
      byteData.setUint16(offset, versionBytes.length, Endian.little);
      offset += 2;
      buffer.setAll(offset, versionBytes);
      offset += versionBytes.length;

      // 9. UUID（UTF8 字符串，先填长度再填内容）
      final uuidBytes = utf8.encode(uuid);
      byteData.setUint16(offset, uuidBytes.length, Endian.little);
      offset += 2;
      buffer.setAll(offset, uuidBytes);
      offset += uuidBytes.length;

      // 10. 保留扩展字段（4 字节，填 0）
      byteData.setUint32(offset, 0, Endian.little);
      offset += 4;

      // 截取有效数据长度
      return buffer.sublist(0, offset);
    } catch (e) {
      CoreLog.error("构造加入频道协议包异常：$e");
      return null;
    }
  }

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
    webScoketUtils?.close();
  }

  void decodeMessage(Uint8List data) {
    try {
      final parser = BufferParser(data);
      final header = parser.getUI32(); // 跳过头部
      final ruri = parser.getUI32();
      parser.getUI16(); // 跳过保留字段
      switch (ruri) {
        case 3104600: // 弹幕消息
          _parseDanmu(parser);
          break;
        // 其他服务指令处理...
      }
    } catch (e) {
      CoreLog.error(e);
    }
  }

  // 解析弹幕数据（对应 JS ge 类解析）
  void _parseDanmu(BufferParser parser) {
    var fromUid = parser.getUI32();
    var topSid = parser.getUI32();
    var subSid = parser.getUI32();
    var nick = parser.getUTF8();
    var msg = parser.getUTF8();

    final liveMsg = LiveMessage(
      type: LiveMessageType.chat,
      message: msg ?? "",
      userName: nick ?? "",
      color: Colors.white,
    );
    onMessage?.call(liveMsg);
  }
}

class DanmakuArgs {
  final int topSid;
  final int subSid;

  DanmakuArgs({required this.topSid, required this.subSid});
}
