import 'dart:io';

import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/core/common/core_log.dart';

class ShadersController extends GetxController {
  static ShadersController get instance => Get.find<ShadersController>();

  late Directory shadersDirectory;

  Future<void> copyShadersToExternalDirectory() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = assetManifest.listAssets();
    final directory = await getApplicationSupportDirectory();
    shadersDirectory = Directory(path.join(directory.path, 'anime_shaders'));

    if (!await shadersDirectory.exists()) {
      await shadersDirectory.create(recursive: true);
      CoreLog.i('ShaderManager: Create GLSL Shader: ${shadersDirectory.path}');
    }

    final shaderFiles = assets.where((String asset) => asset.startsWith('assets/shaders/') && asset.endsWith('.glsl'));

    int copiedFilesCount = 0;

    for (var filePath in shaderFiles) {
      final fileName = filePath.split('/').last;
      final targetFile = File(path.join(shadersDirectory.path, fileName));
      if (await targetFile.exists()) {
        CoreLog.i('ShaderManager: GLSL Shader exists, skip: ${targetFile.path}');
        continue;
      }

      try {
        final data = await rootBundle.load(filePath);
        final List<int> bytes = data.buffer.asUint8List();
        await targetFile.writeAsBytes(bytes);
        copiedFilesCount++;
        CoreLog.i('ShaderManager: Copy: ${targetFile.path}');
      } catch (e) {
        if (e is StackTrace) {
          CoreLog.e('ShaderManager: Copy: ($filePath)', e);
        } else {
          CoreLog.error('ShaderManager: Copy: ($filePath)');
        }
      }
    }

    CoreLog.i('ShaderManager: $copiedFilesCount GLSL files copied to ${shadersDirectory.path}');
  }
}
