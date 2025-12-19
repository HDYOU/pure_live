import 'package:flutter/services.dart';
import 'package:dart_quickjs/dart_quickjs.dart';

class JsEngine {
  static JsRuntime? _jsRuntime;
  static JsRuntime get jsRuntime => _jsRuntime!;

  static Future<void> init() async {
    if(_jsRuntime == null) {
      _jsRuntime = JsRuntime();
      // jsRuntime.enableHandlePromises();
      await JsEngine.loadDouyinSdk();
      await JsEngine.loadCryptoJsSdk();
    }
  }

  static Future<void> loadDouyinSdk() async {
    final webmssdkjs = await rootBundle.loadString('assets/js/webmssdk.js');
    jsRuntime.eval(webmssdkjs);
  }

  static Future<void> loadDouyinExEcutorSdk() async {
    final douyinsdkjs = await rootBundle.loadString('assets/js/douyin.js');
    jsRuntime.eval(douyinsdkjs);
  }



  static dynamic evaluate(String code) {
    return jsRuntime.eval(code);
  }

  static Future<dynamic> evaluateAsync(String code) {
    return jsRuntime.eval(code);
  }

  static dynamic onMessage(String channelName, dynamic Function(dynamic) fn) {
    // return jsRuntime.onMessage(channelName, (args) => null);
    return jsRuntime.eval("$channelName()");
  }

  static dynamic sendMessage({
    required String channelName,
    required List<String> args,
    String? uuid,
  }) {
    // return jsRuntime.sendMessage(channelName: channelName, args: args);
    var argsTxt = args.map((i) => "'$i'").join(",");
    return jsRuntime.eval("$channelName($argsTxt)");
    // 创建可调用的函数
    final add = jsRuntime.evalFunction('((a, b) => a + b)');
    print(add.call([1, 2]));  // 3
    print(add.call([10, 20])); // 30
  }

  static Future<void> loadCryptoJsSdk() async {
    final coreJS = await rootBundle.loadString('assets/js/crypto-js-core.js');
    final md5JS = await rootBundle.loadString('assets/js/crypto-js-md5.js');
    jsRuntime.eval(coreJS);
    jsRuntime.eval(md5JS);
  }

}
