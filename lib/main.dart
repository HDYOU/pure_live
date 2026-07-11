import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/common/services/bilibili_account_service.dart';
import 'package:pure_live/common/services/shaders_service.dart';
import 'package:pure_live/modules/home/home_controller.dart';
import 'package:pure_live/modules/search/search_controller.dart' as pure_live;
import 'package:pure_live/modules/site_account/site_account_controller.dart';
import 'package:pure_live/plugins/file_recover_utils.dart';
import 'package:pure_live/plugins/flutter_catch_error.dart';
import 'package:pure_live/plugins/route_history_observer.dart';
import 'package:pure_live/plugins/db_service.dart';
import 'package:pure_live/player/global_player_service.dart';

// 新设置控制器导入
import 'package:pure_live/common/services/settings/app_settings_controller.dart';
import 'package:pure_live/common/services/settings/theme_settings_controller.dart';
import 'package:pure_live/common/services/settings/font_settings_controller.dart';
import 'package:pure_live/common/services/settings/player_settings_controller.dart';
import 'package:pure_live/common/services/settings/danmaku_settings_controller.dart';
import 'package:pure_live/common/services/settings/volume_settings_controller.dart';
import 'package:pure_live/common/services/settings/favorite_room_controller.dart';
import 'package:pure_live/common/services/settings/history_controller.dart' as settings_history;
import 'package:pure_live/common/services/settings/web_dav_controller.dart';
import 'package:pure_live/common/services/settings/iptv_settings_controller.dart' as settings_iptv;
import 'package:pure_live/common/services/settings/cookie_settings_controller.dart';
import 'package:pure_live/common/services/settings/proxy_settings_controller.dart';
import 'package:pure_live/common/services/settings/window_size_controller.dart';
import 'package:pure_live/common/services/settings/exit_settings_controller.dart';
import 'package:pure_live/common/services/settings/startup_controller.dart';
import 'package:pure_live/common/services/settings/refresh_config_controller.dart';
import 'package:pure_live/common/services/settings/page_settings_controller.dart';
import 'package:pure_live/common/services/settings/cache_controller.dart';
import 'package:pure_live/common/services/settings/log_controller.dart';
import 'package:pure_live/common/services/settings/backup_controller.dart';

import 'modules/history/history_controller.dart';

const kWindowsScheme = 'purelive://signin';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  FlutterCatchError.run(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('zh', 'CN'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh', 'CN'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      child: const MyApp(),
    ),
    args,
  );
  // runApp(const MyApp());
}

Future<void> initService() async {
  Get.put(ShadersController());
  Get.put(SettingsService());
  await S.load(SettingsService.languages[SettingsService.instance.languageName.value]!);
  Get.put(AuthController());
  Get.put(FavoriteController());
  Get.put(PopularController());
  Get.put(AreasController());
  Get.put(BiliBiliAccountService());
  Get.put(pure_live.SearchController());
  Get.put(HomeController());
  Get.put(SiteAccountController());
  Get.put(HistoryController());
  Get.put(DbService());
  await Get.find<DbService>().init();

  // 新设置控制器（基于 Hive）
  // 注意：注册顺序很重要，被依赖的控制器要先注册
  _safePut(() => FontSettingsController());
  _safePut(() => AppSettingsController());
  _safePut(() => ThemeSettingsController());
  _safePut(() => PlayerSettingsController());
  _safePut(() => DanmakuSettingsController());
  _safePut(() => VolumeSettingsController());
  _safePut(() => FavoriteRoomController());
  _safePut(() => settings_history.HistoryController());
  _safePut(() => WebDavController());
  _safePut(() => settings_iptv.IptvSettingsController());
  _safePut(() => CookieSettingsController());
  _safePut(() => ProxySettingsController());
  _safePut(() => WindowSizeController());
  _safePut(() => ExitSettingsController());
  _safePut(() => StartupController());
  _safePut(() => RefreshConfigController());
  _safePut(() => PageSettingsController());
  _safePut(() => CacheController());
  _safePut(() => LogController());
  _safePut(() => BackupController());

  // 全局播放器服务
  _safePut(() => GlobalPlayerService.instance);
}

void _safePut<T>(T Function() builder) {
  try {
    Get.put<T>(builder());
  } catch (e, s) {
    CoreLog.e("Failed to init $T: $e", s);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  final settings = Get.find<SettingsService>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
    initShareM3uState();
  }

  String getName(String fullName) {
    return fullName.split(Platform.pathSeparator).last;
  }

  bool isDataSourceM3u(String url) => url.contains('.m3u');
  String getUUid() {
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    var randomValue = Random().nextInt(4294967295);
    var result = (currentTime % 10000000000 * 1000 + randomValue) % 4294967295;
    return result.toString();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initShareM3uState() async {
    if (Platform.isAndroid) {
      final handler = ShareHandler.instance;
      await handler.getInitialSharedMedia();
      handler.sharedMediaStream.listen((SharedMedia media) async {
        if (isDataSourceM3u(media.content!)) {
          FileRecoverUtils().recoverM3u8BackupByShare(media);
        }
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialLink();
    if (appLink != null) {
      openAppLink(appLink);
    }

    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      openAppLink(uri);
    });
  }

  void openAppLink(Uri uri) {
    final AuthController authController = Get.find<AuthController>();
    if (Platform.isWindows) {
      authController.shouldGoReset = true;
      Timer(const Duration(seconds: 2), () {
        authController.shouldGoReset = false;
        Get.offAndToNamed(RoutePath.kUpdatePassword);
      });
    }
  }

  @override
  void onWindowFocus() {
    setState(() {});
    super.onWindowFocus();
  }

  @override
  void onWindowEvent(String eventName) {
    WindowUtil.setPosition();
  }

  void _init() async {
    if (Platform.isWindows) {
      // Add this line to override the default close handler
      initDeepLinks();
      await WindowUtil.setTitle();
      await WindowUtil.setWindowsPort();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return Obx(() {
            var themeColor = HexColor(settings.themeColorSwitch.value);
            var lightTheme = MyTheme(primaryColor: themeColor).lightThemeData;
            var darkTheme = MyTheme(primaryColor: themeColor).darkThemeData;
            if (settings.enableDynamicTheme.value) {
              lightTheme = MyTheme(colorScheme: lightDynamic).lightThemeData;
              darkTheme = MyTheme(colorScheme: darkDynamic).darkThemeData;
            }
            return GetMaterialApp(
              title: '纯粹直播',
              themeMode: SettingsService.themeModes[settings.themeModeName.value]!,
              theme: lightTheme,
              darkTheme: darkTheme,
              locale: context.locale,
              navigatorObservers: [FlutterSmartDialog.observer, RouteHistoryObserver()],
              builder: FlutterSmartDialog.init(),
              supportedLocales: context.supportedLocales,
              localizationsDelegates: [
                ...context.localizationDelegates,
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: RoutePath.kInitial,
              defaultTransition: Transition.native,
              getPages: AppPages.routes,
            );
          });
        },
      ),
    );
  }
}
