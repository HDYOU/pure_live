import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/plugins/locale_helper.dart';

class SettingsMenu<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<T, String> valueMap;
  final T value;

  final Function(T)? onChanged;
  const SettingsMenu({
    required this.title,
    required this.value,
    required this.valueMap,
    this.subtitle,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.only(left: 16).copyWith(right: 8),
      subtitle: subtitle == null ? null : Text(subtitle!, style: Get.textTheme.bodySmall!.copyWith(color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(i18n(valueMap[value]!), style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: () => openMenu(context),
    );
  }

  void openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: _RadioGroup<T>(
            groupValue: value,
            onChanged: (T? newValue) {
              if (newValue != null) {
                Navigator.of(Get.context!).pop();
                onChanged?.call(newValue);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 10, left: 16, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: valueMap.keys.map<Widget>((e) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<T>(value: e, activeColor: Theme.of(Get.context!).colorScheme.primary),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(Get.context!).pop();
                          onChanged?.call(e);
                        },
                        child: Text(i18n(valueMap[e] ?? "???"), style: Get.textTheme.bodyMedium),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget child;

  const _RadioGroup({
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
