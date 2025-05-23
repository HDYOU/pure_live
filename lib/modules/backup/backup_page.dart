import 'dart:io';

import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/auth/utils/constants.dart';
import 'package:pure_live/modules/backup/scan_page.dart';
import 'package:pure_live/plugins/file_recover_utils.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final settings = Get.find<SettingsService>();
  late String backupDirectory = settings.backupDirectory.value;
  late String m3uDirectory = settings.m3uDirectory.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          SectionTitle(title: S.current.backup_recover),
          ListTile(
            title: Text(S.current.network),
            subtitle: Text(S.current.import_live_streaming_source),
            onTap: () => showImportSetDialog(),
          ),
          if (Platform.isAndroid || Platform.isIOS)
            ListTile(
              title: Text(S.current.synchronize_tv_data),
              subtitle: Text(S.current.synchronize_tv_data_info),
              onTap: () async {
                Get.to(() => const ScanCodePage());
              },
            ),
          ListTile(
            title: Text(S.current.create_backup),
            subtitle: Text(S.current.create_backup_subtitle),
            onTap: () async {
              final selectedDirectory = await FileRecoverUtils().createBackup(backupDirectory);
              if (selectedDirectory != null) {
                setState(() {
                  backupDirectory = selectedDirectory;
                });
              }
            },
          ),
          ListTile(
            title: Text(S.current.recover_backup),
            subtitle: Text(S.current.recover_backup_subtitle),
            onTap: () => FileRecoverUtils().recoverBackup(),
          ),
          SectionTitle(title: S.current.auto_backup),
          ListTile(
            title: Text(S.current.backup_directory),
            subtitle: Text(backupDirectory),
            onTap: () async {
              final selectedDirectory = await FileRecoverUtils().selectBackupDirectory(backupDirectory);
              if (selectedDirectory != null) {
                setState(() {
                  backupDirectory = selectedDirectory;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void showImportSetDialog() {
    List<String> list = [S.current.local_import, S.current.network_import];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(S.current.import_live_streaming_source),
          children: list.map<Widget>((name) {
            return RadioListTile<String>(
              activeColor: Theme.of(context).colorScheme.primary,
              groupValue: '',
              value: name,
              title: Text(name),
              onChanged: (value) {
                importFile(value!);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<String?> showEditTextDialog() async {
    final TextEditingController urlEditingController = TextEditingController();
    final TextEditingController textEditingController = TextEditingController();
    var result = await Get.dialog(
        AlertDialog(
          title: Text(S.current.download_address_enter),
          content: SizedBox(
            width: 400.0,
            height: 300.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  TextField(
                    controller: urlEditingController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      //prefixText: title,
                      contentPadding: EdgeInsets.all(12),
                      hintText: S.current.download_address,
                    ),
                    autofocus: true,
                  ),
                  spacer(12.0),
                  TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      //prefixText: title,
                      contentPadding: EdgeInsets.all(12),
                      hintText: S.current.file_name,
                    ),
                    autofocus: false,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(Get.context!).pop();
              },
              child: Text(S.current.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (urlEditingController.text.isEmpty) {
                  SmartDialog.showToast(S.current.download_address_enter);
                  return;
                }
                bool validate = FileRecoverUtils.isUrl(urlEditingController.text);
                if (!validate) {
                  SmartDialog.showToast(S.current.download_address_enter_check);
                  return;
                }
                if (textEditingController.text.isEmpty) {
                  SmartDialog.showToast(S.current.file_name_input);
                  return;
                }
                await FileRecoverUtils().recoverNetworkM3u8Backup(urlEditingController.text, textEditingController.text);
                Navigator.of(Get.context!).pop();
              },
              child: Text(S.current.confirm),
            ),
          ],
        ),
        barrierDismissible: false);
    return result;
  }

  importFile(String value) {
    if (value == S.current.local_import) {
      FileRecoverUtils().recoverM3u8Backup();
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop(false);
      showEditTextDialog();
    }
  }
}
