import 'package:pure_live/common/index.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:pure_live/plugins/file_recover_utils.dart';

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  bool hasFound = false;
  bool syncResult = false;
  bool isSuccess = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController qrController) {
    controller = qrController;
    // 监听扫码数据
    qrController.scannedDataStream.listen((scanData) async {
      final code = scanData.code;
      if (code != null && FileRecoverUtils.isHostUrl(code)) {
        setState(() {
          hasFound = true;
          syncResult = true;
        });
        final result = await FileRecoverUtils().recoverSettingsBackup(code);
        SmartDialog.showToast(result ? '同步成功' : "同步失败");
        setState(() {
          isSuccess = result;
          syncResult = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
        actions: [
          if (!hasFound)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => controller?.toggleFlash(),
            ),
          if (!hasFound)
            IconButton(
              icon: const Icon(Icons.camera_rear),
              onPressed: () => controller?.flipCamera(),
            ),
        ],
      ),
      body: hasFound
          ? Center(
              child: syncResult
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          "正在同步...",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSuccess ? '同步成功' : "同步失败",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              hasFound = false;
                              syncResult = false;
                              isSuccess = false;
                            });
                          },
                          child: const Text("重新扫描"),
                        ),
                      ],
                    ),
            )
          : QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
    );
  }
}
