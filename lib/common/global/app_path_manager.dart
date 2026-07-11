import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 应用路径管理器 - 适配上游 IPTV 系统
class AppPathManager {
  static final AppPathManager _instance = AppPathManager._internal();
  factory AppPathManager() => _instance;
  AppPathManager._internal();

  static const String dirAppData = 'AppData';
  static const String softNameDir = 'PURE_LIVE';
  static const String dirIptvCache = 'IPTV_CACHE';
  static const String iptvTable = 'pure_live_tv';
  static const String dirDownload = 'DOWNLOADS';
  static const String dirLogs = 'LOGS';
  static const String dirHiveDB = 'HIVE_DB';
  static const String dirImageCache = 'IMAGE_CACHE';
  static const String dirRecords = 'RECORDS';
  static const String dirEmojiCache = 'EMOJI_CACHE';
  static const String fontCacheDir = 'fontsDir';
  static const String iptvCategoryFile = 'categories.json';
  static const String iptvHotFile = 'hot.m3u';
  static const String iptvHotRemoteFile = 'https://raw.githubusercontent.com/YueChan/Live/main/GNTV.m3u';

  String? _basePath;

  Future<void> initialize({String instanceId = ''}) async {
    final sanitizedInstanceId = instanceId.replaceAll(RegExp(r'[\\/]'), '');

    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory supportDir = await getApplicationSupportDirectory();

    String rootPath = '';
    if (kIsWeb) {
      rootPath = softNameDir;
    } else if (Platform.isWindows) {
      final String exeDir = p.dirname(Platform.resolvedExecutable);
      final String exeDirLower = exeDir.toLowerCase();
      if (exeDirLower.contains('windowsapps') || exeDirLower.contains('program files')) {
        rootPath = p.join(supportDir.path, softNameDir);
      } else {
        final testDir = Directory(p.join(exeDir, dirAppData));
        try {
          await testDir.create(recursive: true);
          rootPath = testDir.path;
        } catch (e) {
          rootPath = p.join(supportDir.path, softNameDir);
        }
      }
    } else {
      rootPath = p.join(appDir.path, softNameDir);
    }

    if (sanitizedInstanceId.isNotEmpty) {
      rootPath = p.join(rootPath, sanitizedInstanceId);
    }

    _basePath = rootPath;
  }

  Future<Directory> getDir(String segment) async {
    final String targetPath = p.join(basePath, segment);
    final Directory directory = Directory(targetPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> get iptvCacheDir => getDir(dirIptvCache);
  Future<Directory> get downloadDir => getDir(dirDownload);
  Future<Directory> get logsDir => getDir(dirLogs);
  Future<Directory> get hiveDbDir => getDir(dirHiveDB);
  Future<Directory> get imageCacheDir => getDir(dirImageCache);
  Future<Directory> get recordsDir => getDir(dirRecords);
  Future<Directory> get emojiCacheDir => getDir(dirEmojiCache);

  String get basePath => _basePath ?? (throw StateError("AppPathManager 尚未初始化"));
}
