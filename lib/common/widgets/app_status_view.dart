import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/style/app_text_styles.dart';

enum AppStatusType { loading, empty, error }

/// 状态视图 - 适配上游 IPTV 系统（简化版）
class AppStatusView extends StatelessWidget {
  final AppStatusType type;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool isMini;
  final Color? iconColor;
  final Color? titleColor;
  final Color? subtitleColor;

  const AppStatusView({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.icon,
    this.buttonText,
    this.onButtonPressed,
    this.isMini = false,
    this.iconColor,
    this.titleColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    if (type == AppStatusType.loading) {
      return Center(
        child: SpinKitCircle(
          color: effectiveIconColor,
          size: isMini ? 24 : 40,
        ),
      );
    }

    final String finalTitle =
        title ?? (type == AppStatusType.error ? i18n('status_error_title') : i18n('status_empty_title'));
    final String finalSubtitle =
        subtitle ??
            (type == AppStatusType.error ? i18n('status_error_subtitle') : i18n('status_empty_subtitle'));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isMini ? 8 : 22),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? (type == AppStatusType.error ? Icons.wifi_off_rounded : Icons.live_tv_rounded),
              size: isMini ? 16 : 42,
              color: iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
          if (!isMini || finalTitle.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              finalTitle,
              style: AppTextStyles.t15.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor ?? theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
          if (!isMini || finalSubtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              finalSubtitle,
              style: AppTextStyles.t13.copyWith(color: subtitleColor ?? theme.hintColor),
            ),
          ],
          if (!isMini && onButtonPressed != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(buttonText ?? i18n('status_retry_button')),
            ),
          ],
        ],
      ),
    );
  }
}
