import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pure_live/common/services/settings/backup_controller.dart';

class LocalConfigPreviewPage extends StatelessWidget {
  const LocalConfigPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final backupController = Get.find<BackupController>();
    final config = backupController.exportAllSettings();

    return Scaffold(
      appBar: AppBar(title: const Text("Config Preview")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(const JsonEncoder.withIndent('  ').convert(config)),
        ),
      ),
    );
  }
}
