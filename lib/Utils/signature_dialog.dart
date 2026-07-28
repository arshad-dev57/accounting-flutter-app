import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:LedgerPro_app/Utils/colors.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({Key? key}) : super(key: key);

  @override
  _SignatureDialogState createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      Get.back(result: null);
      return;
    }

    try {
      final Uint8List? data = await _signatureController.toPngBytes();
      if (data != null) {
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath = tempDir.path;
        final String fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = File('$tempPath/$fileName');
        await file.writeAsBytes(data);
        Get.back(result: file.path);
      } else {
        Get.back(result: null);
      }
    } catch (e) {
      print("Error saving signature: $e");
      Get.back(result: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Draw Signature',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(result: null),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: _signatureController,
                  height: 200,
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _signatureController.clear(),
                  icon: const Icon(Icons.clear, color: Colors.red),
                  label: const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton.icon(
                  onPressed: _saveSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> showSignatureDialog(BuildContext context) async {
  return await showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const SignatureDialog(),
  );
}
