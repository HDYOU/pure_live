import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/widgets/refresh_grid_util.dart';
import 'package:pure_live/common/widgets/status/app_loadding_widget.dart';
import 'package:pure_live/modules/search/search_list_controller.dart';
import 'package:pure_live/plugins/cache_network.dart';
import 'package:pure_live/plugins/extension/string_extension.dart';
import 'package:pure_live/routes/app_navigation.dart';

import '../util/site_logo_widget.dart';

class SearchListView extends StatelessWidget {
  final String tag;

  const SearchListView(this.tag, {super.key});

  SearchListController get controller => Get.find<SearchListController>(tag: tag);

  @override
  Widget build(BuildContext context) {
    return RefreshGridUtil.buildRoomCard(controller, itemBuilder: (context, index) => RoomCard(room: controller.list[index], dense: true,));
  }
}

class OwnerCard extends StatefulWidget {
  const OwnerCard({super.key, required this.room});

  final LiveRoom room;

  @override
  State<OwnerCard> createState() => _OwnerCardState();
}

class _OwnerCardState extends State<OwnerCard> {
  SettingsService settings = Get.find<SettingsService>();

  void _onTap(BuildContext context) async {
    AppNavigator.toLiveRoomDetail(liveRoom: widget.room);
  }

  late bool isFavorite = settings.isFavorite(widget.room);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => _onTap(context),
        leading: CacheNetWorkUtils.getCircleAvatar(widget.room.avatar, radius: 20),
        title: Text(
          widget.room.title != null ? '${widget.room.title}' : '',
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.room.nick != null)
              Text(
                widget.room.nick!,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 12),
              ),
            if (widget.room.platform != null)
              Text(
                "${Sites.of(widget.room.platform!).name}${widget.room.area?.appendLeftTxt(" - ")}",
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w200, fontSize: 10),
              ),
          ],
        ),
        trailing: FilledButton.tonal(
          onPressed: () {
            setState(() => isFavorite = !isFavorite);
            if (isFavorite) {
              settings.addRoom(widget.room);
            } else {
              settings.removeRoom(widget.room);
            }
          },
          style: isFavorite ? null : FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
          child: Text(
            isFavorite ? S.current.unfollow : S.current.follow,
          ),
        ),
      ),
    );
  }
}
