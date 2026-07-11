import 'package:collection/collection.dart';
import 'package:pure_live/common/index.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:pure_live/modules/web_dav/webdav_config.dart';
import 'package:pure_live/modules/web_dav/webdav_service.dart';
import 'package:pure_live/common/utils/snackbar_util.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/web_dav_controller.dart' show WebDavController;

class WebDavPageController extends GetxController {
  final RxList<WebDAVConfig> configs = <WebDAVConfig>[].obs;
  final Rx<WebDAVConfig?> currentConfig = Rx<WebDAVConfig?>(null);
  final RxList<webdav.File> files = <webdav.File>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString dirPath = '/'.obs;
  final RxList<String> breadcrumbParts = <String>[].obs;
  final RxBool isFromBreadcrumb = false.obs;

  late WebDAVService _webdavService;
  final WebDavController _webDavController = Get.find<WebDavController>();

  @override
  void onInit() {
    super.onInit();
    // 从 WebDavController (Hive 存储) 加载配置列表
    configs.assignAll(_webDavController.webDavConfigs.v);
    // 从 SettingsService 读取当前 WebDAV 配置作为默认配置
    final settings = SettingsService.instance;
    if (settings.webdavUrl.value.isNotEmpty) {
      final currentName = _webDavController.currentWebDavConfig.value;
      if (currentName.isNotEmpty) {
        final existing = configs.firstWhereOrNull((c) => c.name == currentName);
        if (existing != null) {
          currentConfig.value = existing;
        } else {
          final defaultConfig = WebDAVConfig(
            name: currentName,
            address: settings.webdavUrl.value,
            username: settings.webdavUser.value,
            password: settings.webdavPwd.value,
          );
          configs.add(defaultConfig);
          currentConfig.value = defaultConfig;
        }
      } else {
        final defaultConfig = WebDAVConfig(
          name: '默认配置',
          address: settings.webdavUrl.value,
          username: settings.webdavUser.value,
          password: settings.webdavPwd.value,
        );
        configs.add(defaultConfig);
        currentConfig.value = defaultConfig;
      }
      initializeWebDAV();
    }
  }

  void initializeWebDAV() {
    if (currentConfig.value != null) {
      _webdavService = WebDAVService(
        url: currentConfig.value!.fullUrl,
        username: currentConfig.value!.username,
        password: currentConfig.value!.password,
      );
      loadFiles();
    }
  }

  Future<void> saveCurrentConfig(String configName) async {
    if (currentConfig.value != null) {
      // 同步到 SettingsService (SettingWebdavMixin)
      final settings = SettingsService.instance;
      settings.webdavUrl.value = currentConfig.value!.address;
      settings.webdavUser.value = currentConfig.value!.username;
      settings.webdavPwd.value = currentConfig.value!.password;
      // 同步到 WebDavController (Hive 存储)
      _webDavController.currentWebDavConfig.value = configName;
      _webDavController.addWebDavConfig(currentConfig.value!);
    }
  }

  Future<void> loadFiles() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final loadedFiles = await _webdavService.readDirectory(dirPath.value);
      files.assignAll(loadedFiles);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = '${i18n("webdav_load_dir_failed")}: $e';
      Get.showSnackbar(
        GetSnackBar(
          message: '${i18n("webdav_load_failed")}: $e',
          duration: const Duration(seconds: 2),
          backgroundColor: Get.theme.colorScheme.error,
        ),
      );
    }
  }

  String buildPath(String fileName) {
    final cleanPath = dirPath.value.replaceAll(RegExp(r'/+'), '/');
    return cleanPath.endsWith('/') ? '$cleanPath$fileName/' : '$cleanPath/$fileName/';
  }

  void goToParentDirectory() {
    if (dirPath.value != '/') {
      final cleanPath = dirPath.value.endsWith('/')
          ? dirPath.value.substring(0, dirPath.value.length - 1)
          : dirPath.value;
      final newPath = cleanPath.substring(0, cleanPath.lastIndexOf('/') + 1);
      dirPath.value = newPath.isEmpty ? '/' : newPath;
      isFromBreadcrumb.value = true;
      triggerBreadcrumbScroll();
      loadFiles();
    } else {
      Navigator.pop(Get.context!);
    }
  }

  void deleteConfig(WebDAVConfig config) {
    configs.removeWhere((c) => c.name == config.name);
    // 同步到 WebDavController (Hive 存储)
    _webDavController.removeWebDavConfig(config);
    if (currentConfig.value?.name == config.name) {
      currentConfig.value = null;
      dirPath.value = '/';
      _webDavController.currentWebDavConfig.value = '';
      // 清除 SettingsService 中的 webdav 配置
      final settings = SettingsService.instance;
      settings.webdavUrl.value = '';
      settings.webdavUser.value = '';
      settings.webdavPwd.value = '';
      initializeWebDAV();
    }
    Navigator.pop(Get.context!);
  }

  void rebuildBreadcrumb() {
    final cleanPath = dirPath.value.replaceAll(RegExp(r'/+'), '/').replaceAll(RegExp(r'^/|/$'), '');
    breadcrumbParts.assignAll(cleanPath.split('/'));
    if (dirPath.value == '/' || cleanPath.isEmpty) breadcrumbParts.clear();
  }

  void updateBreadcrumbParts() {
    if (!isFromBreadcrumb.value) {
      String path = dirPath.value;
      if (path.startsWith('/')) path = path.substring(1);
      if (path.endsWith('/')) path = path.substring(0, path.length - 1);
      breadcrumbParts.assignAll(path.isEmpty ? [] : path.split('/'));
    }
  }

  void triggerBreadcrumbScroll() {}

  void onConfigSelected(WebDAVConfig config) {
    currentConfig.value = config;
    dirPath.value = '/';
    breadcrumbParts.clear();
    saveCurrentConfig(config.name);
    initializeWebDAV();
    rebuildBreadcrumb();
    Navigator.pop(Get.context!);
  }

  void onFileTap(webdav.File file) {
    if (file.isDir ?? false) {
      final newPath = buildPath(file.name!);
      dirPath.value = newPath;
      isFromBreadcrumb.value = false;
      updateBreadcrumbParts();
      triggerBreadcrumbScroll();
      loadFiles();
    }
  }

  /// 上传配置到 WebDAV
  void uploadConfigSettings() async {
    try {
      final settings = SettingsService.instance;
      final success = await settings.uploadData();
      if (success) {
        SnackBarUtil.success(i18n("webdav_upload_success"));
        loadFiles();
      } else {
        SnackBarUtil.error(i18n("webdav_upload_failed"));
      }
    } catch (e) {
      SnackBarUtil.error('${i18n("webdav_upload_failed")}: $e');
    }
  }

  void deleteFile(webdav.File file) async {
    final result = await _showConfirmDialog(i18n("webdav_confirm_delete"), title: i18n("webdav_delete"));
    if (result) {
      try {
        await _webdavService.client.remove(file.path!);
        loadFiles();
        SnackBarUtil.success(i18n("webdav_delete_success"));
      } catch (e) {
        SnackBarUtil.error('${i18n("webdav_delete_failed")}: $e');
      }
    }
  }

  Future<bool> _showConfirmDialog(String content, {String title = ''}) async {
    final result = await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(i18n("cancel")),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(i18n("webdav_delete"), style: TextStyle(color: Get.theme.colorScheme.error)),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// 下载并恢复配置
  void downloadFile(webdav.File file) async {
    try {
      final settings = SettingsService.instance;
      final success = await settings.downloadData();
      if (success) {
        SnackBarUtil.success(i18n("webdav_sync_success"));
      } else {
        SnackBarUtil.error(i18n("webdav_download_failed"));
      }
    } catch (e) {
      SnackBarUtil.error('${i18n("webdav_download_failed")}: $e');
    }
  }
}
