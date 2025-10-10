import 'dart:typed_data';
import 'dart:ui' as ui show Codec, instantiateImageCodec;
import 'dart:ui';

import 'package:flutter_avif/flutter_avif.dart';

import 'image_codec.dart';

class AvifImageCodec extends ImageCodec{
  @override
  String get key => "avif";

  @override
  Future<ui.Codec> decodeImage(Uint8List? data) async {
    if(data == null) {
      return Future<ui.Codec>.error(StateError('Failed to load.'));
    };
    try {
      Uint8List newData = data;
        // 1. avif 图片解码
        var avifFrameInfos = await decodeAvif(newData);
        // 2. 只获取第一帧
        var image2 = avifFrameInfos.first.image;
        // 3. 转成 png 格式
        var pngByteData = await image2.toByteData(format: ImageByteFormat.png);
        newData = pngByteData!.buffer.asUint8List();

      return await ui.instantiateImageCodec(newData);
    } catch(_) {
      return Future<ui.Codec>.error(StateError('Failed to load.'));
    }
  }

  @override
  bool isHandle(Uint8List? data) {
    if(data == null) return false;
    // avif 图片解码
    var avifFileType = isAvifFile(data);
    return avifFileType != AvifFileType.unknown;
  }
}