import 'dart:typed_data';
import 'dart:ui' as ui show Codec;

import 'package:pure_live/plugins/image/image_codec_avif.dart';

class ImageCodecFactory {
  static Map<String, ImageCodec> factory = {};

  static void addImageCodec(ImageCodec imageCodec) {
    if (!factory.containsKey(imageCodec.key)) {
      factory[imageCodec.key] = imageCodec;
    }
  }

  static Iterable<ImageCodec> getImageCodecList() {
    return factory.values;
  }

  /// 初始化编解码
  static void initImageCodecList(){
    addImageCodec(AvifImageCodec());
  }
}

abstract class ImageCodec {
  String get key;

  bool isHandle(Uint8List? data);

  Future<ui.Codec> decodeImage(Uint8List? data);
}
