import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/util/site_logo_widget.dart';
import 'package:pure_live/plugins/cache_network.dart';
import 'package:pure_live/plugins/extension/string_extension.dart';
import 'package:pure_live/routes/app_navigation.dart';
import 'package:remixicon/remixicon.dart';

import 'app_style.dart';

/// 预定义渐变背景，避免每次构建重新创建
const _kTopGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Colors.black87, Colors.transparent],
);

const _kBottomGradient = LinearGradient(
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
  colors: [Colors.black87, Colors.transparent],
);

/// 预定义圆角
const _kCardRadius = BorderRadius.all(Radius.circular(15.0));

// ignore: must_be_immutable
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    this.dense = false,
    this.onTap,
  });

  final LiveRoom room;

  /// 密集
  final bool dense;
  final GestureTapCallback? onTap;

  void defaultOnTap(BuildContext context) async {
    AppNavigator.toLiveRoomDetail(liveRoom: room);
  }

  void onLongPress(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(room.title!),
        content: Text(
          S.current.room_info_content(
            room.roomId!,
            room.platform!,
            room.nick!,
            room.title!,
            room.liveStatus!.name,
          ),
        ),
        actions: [FollowButton(room: room)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = room.liveStatus == LiveStatus.offline && room.cover!.isNotEmpty;
    final showFire = room.liveStatus == LiveStatus.live || room.liveStatus == LiveStatus.replay;
    final isRecord = room.isRecord == true || room.liveStatus == LiveStatus.replay;
    
    return Card(
      margin: const EdgeInsets.all(7.5),
      shape: RoundedRectangleBorder(borderRadius: _kCardRadius),
      child: InkWell(
        borderRadius: _kCardRadius,
        onTap: onTap ?? () => defaultOnTap(context),
        onLongPress: () => onLongPress(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 使用 RepaintBoundary 隔离图片区域重绘
            RepaintBoundary(
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Card(
                      margin: const EdgeInsets.all(0),
                      shape: RoundedRectangleBorder(borderRadius: _kCardRadius),
                      clipBehavior: Clip.antiAlias,
                      color: Theme.of(context).focusColor,
                      elevation: 0,
                      child: isOffline
                          ? Center(
                              child: Icon(Icons.tv_off_rounded, size: dense ? 36 : 60),
                            )
                          : CacheNetWorkUtils.getCacheImageV2(
                              room.cover!,
                              siteKey: room.platform,
                              // 增大缓存尺寸，减少解码开销
                              cacheWidth: dense ? 200 : 300,
                              cacheHeight: dense ? 112 : 169,
                            ),
                    ),
                  ),

                  // 图片顶部渐变
                  Positioned(
                    right: 0,
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: const BoxDecoration(gradient: _kTopGradient),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (room.platform.isNotNullOrEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: SiteWidget.getSiteLogeImage(room.platform!, size: 20)!,
                            ),
                          if (isRecord)
                            CountChip(
                              icon: Icons.videocam_rounded,
                              count: "",
                              dense: dense,
                              color: Theme.of(context).colorScheme.error,
                              size: 12,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 图片底部渐变
                  Positioned(
                    right: 0,
                    left: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: const BoxDecoration(gradient: _kBottomGradient),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              room.area ?? "",
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                          if (showFire)
                            Row(
                              children: [
                                const Icon(Remix.fire_fill, color: Colors.red, size: 14),
                                AppStyle.hGap4,
                                Text(
                                  readableCount(readableCountStrToNum(room.watching ?? "0").toString()),
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 底部信息区域也用 RepaintBoundary
            RepaintBoundary(
              child: ListTile(
                dense: dense,
                minLeadingWidth: dense ? 34 : null,
                contentPadding: dense ? const EdgeInsets.only(left: 8, right: 10) : null,
                horizontalTitleGap: dense ? 8 : null,
                leading: CacheNetWorkUtils.getCircleAvatar(room.avatar, radius: 17, siteKey: room.platform),
                title: Text(
                  room.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: dense ? 12.5 : 15, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  room.nick ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                trailing: dense
                    ? null
                    : Text(
                        room.platform != null ? Sites.of(room.platform!).name : '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FollowButton extends StatefulWidget {
  const FollowButton({
    super.key,
    required this.room,
  });

  final LiveRoom room;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final settings = Get.find<SettingsService>();

  late bool isFavorite = settings.isFavorite(widget.room);

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () {
        setState(() => isFavorite = !isFavorite);
        if (isFavorite) {
          settings.addRoom(widget.room);
        } else {
          settings.removeRoom(widget.room);
        }
      },
      style: ElevatedButton.styleFrom(),
      child: Text(isFavorite ? S.current.unfollow : S.current.follow),
    );
  }
}

class CountChip extends StatelessWidget {
  const CountChip({
    super.key,
    this.icon,
    required this.count,
    this.dense = false,
    this.color = Colors.black,
    this.size,
  });

  final IconData? icon;
  final String count;
  final bool dense;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    var curSize = size;
    curSize ??= Theme.of(context).textTheme.bodySmall?.fontSize;
    return Card(
      shape: const StadiumBorder(),
      color: color.withValues(alpha: 0.6),
      shadowColor: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(dense ? 4 : 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
                size: size != null ? size! * 1.2 : size,
              ),
            Text(
              count,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: size,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
