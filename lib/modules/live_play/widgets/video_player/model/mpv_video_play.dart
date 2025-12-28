import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:pure_live/common/services/settings_service.dart';
import 'package:pure_live/common/services/shaders_service.dart';
import 'package:pure_live/common/widgets/settings/settings_list_item.dart';
import 'package:pure_live/core/common/core_log.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller.dart' as video_player;
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller_panel.dart';
import 'package:pure_live/modules/util/listen_list_util.dart';
import 'package:pure_live/modules/util/rx_util.dart';

import '../../../../../common/services/setting_mixin/setting_video_fit.dart';
import '../../../../../common/widgets/utils.dart';
import 'video_play_impl.dart';

class MpvVideoPlay extends VideoPlayerInterFace {
  // Video player status
  // A [GlobalKey<VideoState>] is required to access the programmatic fullscreen interface.
  late GlobalKey<media_kit_video.VideoState> key = GlobalKey<media_kit_video.VideoState>();

  // Create a [Player] to control playback.
  late media_kit.Player player;

  // CeoController] to handle video output from [Player].
  late media_kit_video.VideoController mediaPlayerController;

  /// 存储 Stream 流监听
  /// 默认视频 MPV 视频监听流
  final defaultVideoStreamSubscriptionList = <StreamSubscription>[];

  @override
  final String playerName;

  MpvVideoPlay({
    required this.playerName,
  });

  late video_player.VideoController controller;

  @override
  void init({required video_player.VideoController controller}) {
    this.controller = controller;
    ListenListUtil.clearStreamSubscriptionList(defaultVideoStreamSubscriptionList);
    player = media_kit.Player(
      configuration: media_kit.PlayerConfiguration(
        title: "Simple Live Player",
        logLevel: media_kit.MPVLogLevel.warn,
      ),
    );
    if (player.platform is media_kit.NativePlayer) {
      (player.platform as dynamic).setProperty('cache', 'no'); // --cache=<yes|no|auto>
      (player.platform as dynamic).setProperty('cache-secs', '0'); // --cache-secs=<seconds> with cache but why not.
      (player.platform as dynamic).setProperty('demuxer-donate-buffer', 'no'); // --demuxer-donate-buffer==<yes|no>
    }
    var conf = media_kit_video.VideoControllerConfiguration(
      enableHardwareAcceleration: SettingsService.instance.enableCodec.value,
    );
    if (Platform.isAndroid || Platform.isIOS) {
      conf = media_kit_video.VideoControllerConfiguration(
        vo: 'mediacodec_embed',
        hwdec: 'mediacodec',
        enableHardwareAcceleration: SettingsService.instance.enableCodec.value,
      );
    }
    mediaPlayerController = media_kit_video.VideoController(player, configuration: conf);
    defaultVideoStreamSubscriptionList.add(mediaPlayerController.player.stream.playing.listen((bool playing) {
      isPlaying.updateValueNotEquate(playing);
    }));
    defaultVideoStreamSubscriptionList.add(mediaPlayerController.player.stream.error.listen((event) {
      CoreLog.d("mpv error: ${event}");
      if (event.toString().contains('Failed to open')) {
        hasError.updateValueNotEquate(true);
        isBuffering.updateValueNotEquate(false);
        isPlaying.updateValueNotEquate(false);
      }
    }));
    defaultVideoStreamSubscriptionList.add(mediaPlayerController.player.stream.buffering.listen((e) {
      isBuffering.updateValueNotEquate(e);
      CoreLog.d("isBuffering : $isBuffering  hashcode: ${isBuffering.hashCode}");
    }));

    defaultVideoStreamSubscriptionList.add(player.stream.width.listen((event) {
      CoreLog.d('Video width:$event  W:${(player.state.width)}  H:${(player.state.height)}');
      isVertical.updateValueNotEquate((player.state.height ?? 9) > (player.state.width ?? 16));
    }));
    defaultVideoStreamSubscriptionList.add(player.stream.height.listen((event) {
      CoreLog.d('height:$event  W:${(player.state.width)}  H:${(player.state.height)}');
      isVertical.updateValueNotEquate((player.state.height ?? 9) > (player.state.width ?? 16));
    }));
  }

  @override
  void dispose() {
    ListenListUtil.clearStreamSubscriptionList(defaultVideoStreamSubscriptionList);
    if (key.currentState?.isFullscreen() ?? false) {
      key.currentState?.exitFullscreen();
    }
    player.dispose();
  }

  @override
  Future<void> enterFullscreen() async {
    await key.currentState?.enterFullscreen();
    // CoreLog.d("isVertical: $isVertical");
    // if (isVertical.value) {
    //   // 竖屏
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    //   SystemChrome.setPreferredOrientations([
    //     DeviceOrientation.portraitUp,
    //     DeviceOrientation.portraitDown,
    //   ]);
    // }
  }

  @override
  Future<void> exitFullScreen() async {
    await key.currentState?.exitFullscreen();
  }

  @override
  Future<void> toggleFullScreen() async {
    isFullscreen.toggle();
    if (key.currentState?.isFullscreen() == true) {
      return exitFullScreen();
    }
    return enterFullscreen();
  }

  @override
  Future<Uint8List?> snapshot() async {
    try {
      return await player.screenshot();
    } catch (e) {
      CoreLog.error(e);
      return null;
    }
  }

  @override
  Future<void> openVideo(String datasource, Map<String, String> headers) async {
    CoreLog.d("play url: $datasource");
    // fix datasource empty error
    if (datasource.isEmpty) {
      hasError.value = true;
      return;
    } else {
      hasError.value = false;
    }
    isBuffering.updateValueNotEquate(true);
    isPlaying.updateValueNotEquate(false);
    return player.open(media_kit.Media(datasource, httpHeaders: headers));
  }

  @override
  Future<void> pause() async {
    return player.pause();
  }

  @override
  Future<void> togglePlayPause() async {
    mediaPlayerController.player.playOrPause();
  }

  @override
  Future<void> play() {
    return player.play();
  }

  @override
  void setVideoFit(SettingVideoFit fit) {
    key.currentState?.update(fit: fit.fit, aspectRatio: fit.aspectRatio);
  }

  @override
  bool get supportPip => true;

  @override
  List<String> get supportPlatformList => ["linux", "macos", "windows", "android", "ios"];

  @override
  Widget getVideoPlayerWidget() {
    try {
      return Obx(() => media_kit_video.Video(
            key: controller.playerKey,
            controller: mediaPlayerController,
            pauseUponEnteringBackgroundMode: !SettingsService.instance.enableBackgroundPlay.value,
            // 进入背景模式时暂停
            resumeUponEnteringForegroundMode: true,
            // 进入前景模式后恢复
            fit: SettingsService.instance.videofitArray[SettingsService.instance.videoFitIndex.value].fit,
            aspectRatio: SettingsService.instance.videofitArray[SettingsService.instance.videoFitIndex.value].aspectRatio,
            controls: "" == Sites.iptvSite
                ? media_kit_video.MaterialVideoControls
                : (state) => controller.videoControllerPanel,
            onEnterFullscreen: enterNativeFullscreen,
          ));
    } catch (e) {
      CoreLog.error(e);
      return Container();
    }
  }

  @override
  Widget getDesktopFullscreenWidget() {
    return Material(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Obx(() => media_kit_video.Video(
                  key: controller.playerKey,
                  controller: mediaPlayerController,
                  fit: SettingsService.instance.videofitArray[controller.videoFitIndex.value].fit,
                  pauseUponEnteringBackgroundMode: !SettingsService.instance.enableBackgroundPlay.value,
                  // 进入背景模式时暂停
                  resumeUponEnteringForegroundMode: true,
                  // 进入前景模式后恢复
                  controls: (state) => VideoControllerPanel(controller: controller),
                  onEnterFullscreen: enterNativeFullscreen,
                ))
          ],
        ),
      ),
    );
  }

  /// copy from media-kit media_kit_video-1.2.5\lib\src\video\video_texture.dart
  Future<void> enterNativeFullscreen() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (isVertical.value) {
          // 竖屏
          await Future.wait(
            [
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
              // SystemChrome.setEnabledSystemUIMode(
              //   SystemUiMode.immersiveSticky,
              //   overlays: [],
              // ),
              SystemChrome.setPreferredOrientations(
                [
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ],
              ),
            ],
          );
        } else {
          await Future.wait(
            [
              SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.immersiveSticky,
                overlays: [],
              ),
              SystemChrome.setPreferredOrientations(
                [
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ],
              ),
            ],
          );
        }
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await media_kit_video.defaultEnterNativeFullscreen();
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      // if (player == null) return;
      final normalized = volume.clamp(0.0, 1.0);
      player.setVolume(normalized);
    } catch (e) {
      CoreLog.error(e);
    }
  }

  /// 超分辨率滤镜
  static const List<String> mpvAnime4KShaders = [
    'Anime4K_Clamp_Highlights.glsl',
    'Anime4K_Restore_CNN_VL.glsl',
    'Anime4K_Upscale_CNN_x2_VL.glsl',
    'Anime4K_AutoDownscalePre_x2.glsl',
    'Anime4K_AutoDownscalePre_x4.glsl',
    'Anime4K_Upscale_CNN_x2_M.glsl'
  ];

  /// 超分辨率滤镜 (轻量)
  static const List<String> mpvAnime4KShadersLite = [
    'Anime4K_Clamp_Highlights.glsl',
    'Anime4K_Restore_CNN_M.glsl',
    'Anime4K_Restore_CNN_S.glsl',
    'Anime4K_Upscale_CNN_x2_M.glsl',
    'Anime4K_AutoDownscalePre_x2.glsl',
    'Anime4K_AutoDownscalePre_x4.glsl',
    'Anime4K_Upscale_CNN_x2_S.glsl'
  ];

  static const Map<String, List<String>?> superResolutionMap = {
    "关闭": null,
    "效率": mpvAnime4KShadersLite,
    "质量": mpvAnime4KShaders,
  };

  static final List<String> superResolutionList = superResolutionMap.keys.toList();
  static final List<List<String>?> superResolutionValueList = superResolutionMap.values.toList();

  var superResolutionType = 0;

  Future<void> setShader(int type, {bool synchronized = true}) async {
    var pp = player.platform as media_kit.NativePlayer;
    await pp.waitForPlayerInitialization;
    await pp.waitForVideoControllerInitializationIfAttached;
    superResolutionType = type;

    var superResolutionKey = superResolutionList[superResolutionType];
    var superResolutionPathList = superResolutionMap[superResolutionKey];
    CoreLog.d("shadersDirectory: ${ShadersController.instance.shadersDirectory.path}");
    if (superResolutionPathList == null) {
      await pp.command(['change-list', 'glsl-shaders', 'clr', '']);
    } else {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(ShadersController.instance.shadersDirectory.path, superResolutionPathList),
      ]);
    }
  }

  @override
  Future<List<Widget>> playerOtherWidgets() async {
    return [
      SettingsListItem(
        title: Text("超分辨率"),
        subtitle: Text("超分辨率,放大视频"),
        onTap: showSuperResolutionSelectorDialog,
      ),
    ];
  }

  void showSuperResolutionSelectorDialog() {
    var context = Get.context!;
    Utils.showRightOrBottomSheet(
      title: "超分辨率",
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: superResolutionList.length,
        itemBuilder: (_, i) {
          var item = superResolutionList[i];
          return ListTile(
            selected: superResolutionType == i,
            title: Text(item, style: const TextStyle(fontSize: 14)),
            minLeadingWidth: 16,
            onTap: () {
              setShader(i);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}

class DesktopFullscreen extends StatelessWidget {
  const DesktopFullscreen({super.key, required this.controller, required this.mediaPlayerController});

  final video_player.VideoController controller;
  final media_kit_video.VideoController mediaPlayerController;

  SettingsService get settings => Get.find<SettingsService>();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Obx(() => media_kit_video.Video(
                  key: controller.playerKey,
                  controller: mediaPlayerController,
                  fit: SettingsService.instance.videofitArray[controller.videoFitIndex.value].fit,
                  pauseUponEnteringBackgroundMode: !SettingsService.instance.enableBackgroundPlay.value,
                  // 进入背景模式时暂停
                  resumeUponEnteringForegroundMode: true,
                  // 进入前景模式后恢复
                  controls: (state) => VideoControllerPanel(controller: controller),
                ))
          ],
        ),
      ),
    );
  }
}
