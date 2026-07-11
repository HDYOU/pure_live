import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/widgets/iptv_widget_extensions.dart';
import 'package:pure_live/plugins/locale_helper.dart';
import 'package:pure_live/common/services/settings/proxy_settings_controller.dart';

class NetworkProxySettingsPage extends StatelessWidget {
  const NetworkProxySettingsPage({super.key});

  ProxySettingsController get _proxy => Get.find<ProxySettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(i18n("custom_network_proxy"))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          context.buildGroupTitle(i18n("app_proxy")),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n("enable_app_proxy"),
              subtitle: i18n("enable_app_proxy_subtitle"),
              value: _proxy.enableAppProxy,
              icon: Remix.global_line,
            ),
            Obx(
              () => Visibility(
                visible: _proxy.enableAppProxy.v,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Remix.server_line),
                      title: Text(i18n("proxy_host")),
                      subtitle: Text(_proxy.appProxyHost.v),
                      onTap: () => _showHostDialog(context, isAppProxy: true),
                    ),
                    ListTile(
                      leading: const Icon(Remix.hashtag),
                      title: Text(i18n("proxy_port")),
                      subtitle: Text("${_proxy.appProxyPort.v}"),
                      onTap: () => _showPortDialog(context, isAppProxy: true),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          context.buildGroupTitle(i18n("video_proxy")),
          context.buildModernCard([
            context.buildSwitchTile(
              title: i18n("enable_proxy"),
              subtitle: i18n("enable_proxy_subtitle"),
              value: _proxy.enableProxy,
              icon: Remix.video_upload_line,
            ),
            Obx(
              () => Visibility(
                visible: _proxy.enableProxy.v,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Remix.server_line),
                      title: Text(i18n("proxy_host")),
                      subtitle: Text(_proxy.proxyHost.v),
                      onTap: () => _showHostDialog(context, isAppProxy: false),
                    ),
                    ListTile(
                      leading: const Icon(Remix.hashtag),
                      title: Text(i18n("proxy_port")),
                      subtitle: Text("${_proxy.proxyPort.v}"),
                      onTap: () => _showPortDialog(context, isAppProxy: false),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showHostDialog(BuildContext context, {required bool isAppProxy}) {
    final controller = TextEditingController(
      text: isAppProxy ? _proxy.appProxyHost.v : _proxy.proxyHost.v,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n("proxy_host")),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '127.0.0.1',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(i18n("cancel"))),
          TextButton(
            onPressed: () {
              if (isAppProxy) {
                _proxy.appProxyHost.v = controller.text;
              } else {
                _proxy.proxyHost.v = controller.text;
              }
              Navigator.pop(context);
            },
            child: Text(i18n("confirm")),
          ),
        ],
      ),
    );
  }

  void _showPortDialog(BuildContext context, {required bool isAppProxy}) {
    final controller = TextEditingController(
      text: isAppProxy ? "${_proxy.appProxyPort.v}" : "${_proxy.proxyPort.v}",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n("proxy_port")),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '7897',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(i18n("cancel"))),
          TextButton(
            onPressed: () {
              final port = int.tryParse(controller.text) ?? 7897;
              if (isAppProxy) {
                _proxy.appProxyPort.v = port;
              } else {
                _proxy.proxyPort.v = port;
              }
              Navigator.pop(context);
            },
            child: Text(i18n("confirm")),
          ),
        ],
      ),
    );
  }
}
