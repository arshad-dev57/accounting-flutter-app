// core/warehouse/products/qr/product_qr_scan_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BisonsTechs_app/core/warehouse/products/controller/product_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ProductQRScanScreen extends StatefulWidget {
  const ProductQRScanScreen({super.key});

  @override
  State<ProductQRScanScreen> createState() => _ProductQRScanScreenState();
}

class _ProductQRScanScreenState extends State<ProductQRScanScreen> {
  final ProductsController controller = Get.put(ProductsController());

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      Get.snackbar(
        'Permission Denied',
        'Camera permission is required to scan QR codes',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              controller.toggleFlash();
            },
            icon: Obx(
              () => Icon(
                controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              controller.toggleCamera();
            },
            icon: const Icon(Icons.flip_camera_ios),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller.scannerController,
              onDetect: (BarcodeCapture capture) {
                controller.onScanResult(capture);
                if (controller.scannedData.value.isNotEmpty) {
                  _handleScanResult();
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Column(
              children: [
                const Text(
                  'Align QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.scanFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleScanResult() {
    final productData = controller.selectedProductForQR.value;

    if (productData != null && productData.isNotEmpty) {
      // Return the scanned data to the previous screen
      Get.back(result: productData);
    } else {
      Get.snackbar(
        'Invalid QR',
        'This QR code does not contain product data',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.black,
      );
    }
  }
}
