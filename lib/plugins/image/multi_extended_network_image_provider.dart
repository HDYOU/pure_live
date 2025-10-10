import 'dart:async';
import 'dart:ui' as ui show Codec;

import 'package:extended_image_library/src/platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';

import 'extended_network_image_provider.dart';
import 'image_codec.dart';

class MultiExtendedNetworkImageProvider extends ExtendedNetworkImageProvider {
  MultiExtendedNetworkImageProvider(
    super.url, {
    super.scale = 1.0,
    super.headers,
    super.cache = false,
    super.retries = 3,
    super.timeLimit,
    super.timeRetry = const Duration(milliseconds: 100),
    super.cacheKey,
    super.printError = true,
    super.cacheRawData = false,
    super.cancelToken,
    super.imageCacheName,
    super.cacheMaxAge,
  });

  @override
  Future<ui.Codec> loadAsync(
    ExtendedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);
    final String md5Key = cacheKey ?? keyToMd5(key.url);
    ui.Codec? result;
    if (cache) {
      try {
        final Uint8List? data = await loadCache(
          key,
          chunkEvents,
          md5Key,
        );
        if (data != null) {
          result = await decodeImage(data, decode);
        }
      } catch (e) {
        if (printError) {
          print(e);
        }
      }
    }

    if (result == null) {
      try {
        final Uint8List? data = await loadNetwork(
          key,
          chunkEvents,
        );
        if (data != null) {
          result = await decodeImage(data, decode);
        }
      } catch (e) {
        if (printError) {
          print(e);
        }
      }
    }

    //Failed to load
    if (result == null) {
      //result = await ui.instantiateImageCodec(kTransparentImage);
      return Future<ui.Codec>.error(StateError('Failed to load $url.'));
    }

    return result;
  }

  /////////////////////////////////
  Future<ui.Codec> decodeImage(Uint8List? data, ImageDecoderCallback decode) async {
    if (data == null) {
      return Future<ui.Codec>.error(StateError('Failed to load $url.'));
    }
    try {
      Uint8List newData = data;

      for (var imageCodec in ImageCodecFactory.getImageCodecList()) {
        if (imageCodec.isHandle(data)) {
          return imageCodec.decodeImage(data);
        }
      }

      return await instantiateImageCodec(newData, decode);
    } catch (_) {
      return Future<ui.Codec>.error(StateError('Failed to load $url.'));
    }
  }
}
