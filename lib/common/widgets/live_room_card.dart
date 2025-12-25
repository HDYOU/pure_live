import 'package:flutter/material.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/widgets/utils.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/routes/app_navigation.dart';
import 'package:remixicon/remixicon.dart';
import '../utils/text_util.dart';
import 'app_style.dart';
import 'net_image.dart';
import 'shadow_card.dart';

class LiveRoomCard extends StatelessWidget {
  final Site site;
  final LiveRoom item;
  const LiveRoomCard(this.site, this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: () {
        AppNavigator.toLiveRoomDetail(liveRoom: item);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: NetImage(
                  item.cover ?? "",
                  fit: BoxFit.cover,
                  height: 110,
                  width: double.infinity,
                ),
              ),
              Positioned(
                right: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Text(
                          item.area ?? "",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Remix.fire_fill,
                            color: Colors.white,
                            size: 14,
                          ),
                          AppStyle.hGap4,
                          Text(
                            readableCount(readableCountStrToNum(item.watching).toString()),
                            // Utils.onlineToString(item.watching??""),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: AppStyle.edgeInsetsA8.copyWith(bottom: 4),
            child: Text(
              item.title ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: AppStyle.edgeInsetsH8.copyWith(bottom: 8),
            child: Text(
              item.nick ?? "",
              maxLines: 1,
              style: const TextStyle(
                height: 1.4,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
