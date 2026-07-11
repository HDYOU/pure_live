import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/style/app_text_styles.dart';

/// Widget 扩展 - 适配上游 IPTV 系统
extension IptvWidgetExtensions on BuildContext {
  Widget buildGroupTitle(String text) {
    final theme = Theme.of(this);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.t12.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary.withValues(alpha: 0.65),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget buildModernCard(List<Widget> children) {
    final theme = Theme.of(this);

    return Material(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05), width: 0.5),
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          final child = children[index];
          if (index < children.length - 1) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: theme.dividerColor.withValues(alpha: 0.05),
                ),
              ],
            );
          }
          return child;
        }),
      ),
    );
  }

  Widget buildSwitchTile({
    required String title,
    required RxBool value,
    IconData? icon,
    String? subtitle,
    Color? iconColor,
    Color? subtitleColor,
    bool isLong = false,
    ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(this);
    return Obx(
      () => SwitchListTile(
        secondary: icon != null ? Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 22) : null,
        title: Text(title, style: AppTextStyles.t15.copyWith(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null && subtitle.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  style: AppTextStyles.t12.copyWith(color: subtitleColor ?? theme.hintColor.withValues(alpha: 0.75)),
                  maxLines: isLong ? null : 1,
                  overflow: isLong ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              )
            : null,
        value: value.value,
        onChanged: (val) {
          value.value = val;
          onChanged?.call(val);
        },
        contentPadding: const EdgeInsets.only(left: 16, top: 2, bottom: 2, right: 8),
      ),
    );
  }

  Widget buildTile({
    required String title,
    IconData? icon,
    Widget? iconWidget,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? subtitleColor,
    Widget? trailing,
    bool isLong = false,
  }) {
    final theme = Theme.of(this);

    Widget? leadingWidget;
    if (iconWidget != null) {
      leadingWidget = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: IconTheme(
              data: IconThemeData(color: iconColor ?? theme.colorScheme.primary, size: 22),
              child: iconWidget,
            ),
          ),
        ],
      );
    } else if (icon != null) {
      leadingWidget = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 22),
          ),
        ],
      );
    }

    return ListTile(
      horizontalTitleGap: 12,
      minLeadingWidth: 0,
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: leadingWidget,
      title: Text(title, style: AppTextStyles.t15.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null && subtitle.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: AppTextStyles.t12.copyWith(color: subtitleColor ?? theme.hintColor.withValues(alpha: 0.75)),
                maxLines: isLong ? null : 1,
                overflow: isLong ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right_rounded, color: theme.hintColor.withValues(alpha: 0.4), size: 20)
                    : null),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 间距工具
Widget spacer(double height) => SizedBox(height: height);
