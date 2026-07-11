import 'dart:convert';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/tags/live_tag.dart';
import 'package:pure_live/common/utils/pref_util.dart';

class TagManagementController extends GetxController {
  static const String _storageKey = 'user_custom_tags_v5';
  static const String _roomTagsMappingKey = 'room_to_tags_mapping_v1';
  final RxMap<String, List<String>> roomTagsMap = <String, List<String>>{}.obs;
  final RxList<LiveTag> tags = <LiveTag>[].obs;
  static const Map<String, String> allTag = {'all': '全部'};
  static String get allTagKey => allTag.keys.first;
  static String get allTagLabel => allTag.values.first;
  @override
  void onInit() {
    super.onInit();
    _loadTags();
    _loadRoomTagsMapping();
  }

  void _loadTags() {
    final String? storedStr = PrefUtil.getString(_storageKey);
    if (storedStr != null && storedStr.isNotEmpty) {
      try {
        final List<dynamic> storedTags = jsonDecode(storedStr);
        final list = storedTags.map((e) => LiveTag.fromJson(Map<String, dynamic>.from(e))).toList();
        list.sort((a, b) => a.order.compareTo(b.order));
        tags.assignAll(list);
      } catch (_) {
        tags.clear();
      }
    } else {
      tags.clear();
    }
  }

  Future<void> saveTags() async {
    await PrefUtil.setString(_storageKey, jsonEncode(tags.map((e) => e.toJson()).toList()));
  }

  Future<void> saveRoomTagsMapping() async {
    PrefUtil.setMap(_roomTagsMappingKey, roomTagsMap);
  }

  void setRoomTags(String roomId, List<String> newTagIds) {
    if (newTagIds.isEmpty) {
      roomTagsMap.remove(roomId);
    } else {
      roomTagsMap[roomId] = newTagIds;
    }

    roomTagsMap.refresh();
    saveRoomTagsMapping();
  }

  void _loadRoomTagsMapping() {
    final Map<dynamic, dynamic> storedMap = PrefUtil.getMap(_roomTagsMappingKey);

    if (storedMap.isNotEmpty) {
      final convertedMap = storedMap.map((key, value) {
        return MapEntry(key.toString(), List<String>.from(value as List));
      });
      roomTagsMap.assignAll(convertedMap);
    }
  }

  List<String> getTagsForRoom(LiveRoom room) {
    final String roomId = room.roomId.toString();
    return roomTagsMap[roomId] ?? [];
  }

  bool addTag(String name, String description) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;

    final exists = tags.any((tag) => tag.name.toLowerCase() == cleanName.toLowerCase());
    if (exists) return false;

    final newTag = LiveTag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      description: description.trim(),
      order: tags.length,
    );

    tags.add(newTag);
    saveTags();
    return true;
  }

  void updateAllTags(List<LiveTag> newList) {
    tags.assignAll(newList);
    for (int i = 0; i < tags.length; i++) {
      tags[i].order = i;
    }
    tags.refresh();
    saveTags();
  }

  bool updateTag(int index, String newName, String newDescription) {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return false;

    if (tags[index].name != cleanName) {
      final exists = tags.any((tag) => tag.name.toLowerCase() == cleanName.toLowerCase());
      if (exists) return false;
    }

    tags[index].name = cleanName;
    tags[index].description = newDescription.trim();
    tags.refresh();
    saveTags();
    return true;
  }

  void pinToTop(int index) {
    if (index <= 0 || index >= tags.length) return;

    final targetTag = tags.removeAt(index);
    tags.insert(0, targetTag);

    _refreshSequentialOrders();
  }

  void togglePinStatus(int index) {
    _refreshSequentialOrders();
  }

  void deleteTag(int index) {
    tags.removeAt(index);
    _refreshSequentialOrders();
  }

  void _refreshSequentialOrders() {
    for (int i = 0; i < tags.length; i++) {
      tags[i].order = i;
    }
    tags.refresh();
    saveTags();
  }

  Map<String, dynamic> exportToJson() {
    return {'tags': tags.map((e) => e.toJson()).toList(), 'roomTagsMap': roomTagsMap};
  }

  void importFromJson(Map<String, dynamic>? json) {
    if (json == null) return;

    if (json.containsKey('tags') && json['tags'] != null) {
      final storedTags = json['tags'] as List;
      final list = storedTags.map((e) => LiveTag.fromJson(Map<String, dynamic>.from(e))).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      tags.assignAll(list);
      saveTags();
    }

    if (json.containsKey('roomTagsMap') && json['roomTagsMap'] != null) {
      final storedMap = json['roomTagsMap'] as Map;
      final convertedMap = storedMap.map((key, value) {
        return MapEntry(key.toString(), List<String>.from(value as List));
      });
      roomTagsMap.assignAll(convertedMap);
      saveRoomTagsMapping();
    }
  }
}
