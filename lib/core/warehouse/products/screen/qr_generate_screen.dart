// core/warehouse/products/qr/qr_generate_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LedgerPro_app/core/warehouse/products/controller/product_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGenerateScreen extends StatelessWidget {
  const QRGenerateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              if (controller.qrData.value.isNotEmpty) {
                controller.saveQRCode();
              }
            },
            icon: const Icon(Icons.save),
          ),
          IconButton(
            onPressed: () {
              if (controller.qrData.value.isNotEmpty) {
                controller.shareQRCode();
              }
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code Display
            Obx(() => controller.qrData.value.isNotEmpty
                ? Center(
                    child: Container(
                      key: controller.qrKey,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: controller.qrData.value,
                        size: controller.qrSize.value,
                        backgroundColor: controller.qrBackgroundColor.value,
                      ),
                    ),
                  )
                : Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code, size: 60, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Generate QR Code',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 20),

            // QR Type Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select QR Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Wrap(
                    spacing: 8,
                    children: controller.qrTypes.map((type) {
                      final isSelected = controller.selectedQRType.value == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (_) {
                          controller.selectedQRType.value = type;
                        },
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input Fields
            Obx(() {
              switch (controller.selectedQRType.value) {
                case 'Product QR':
                  return _buildProductQRInput(controller);
                case 'URL':
                  return _buildURLInput(controller);
                case 'Text':
                  return _buildTextInput(controller);
                case 'Custom Data':
                  return _buildCustomDataInput(controller);
                default:
                  return const SizedBox.shrink();
              }
            }),
            const SizedBox(height: 20),

            // QR Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Options',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Size:', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(() => Slider(
                          value: controller.qrSize.value,
                          min: 100,
                          max: 400,
                          divisions: 30,
                          onChanged: (v) => controller.qrSize.value = v,
                          activeColor: Colors.blue,
                        )),
                      ),
                      Obx(() => Text(
                        '${controller.qrSize.value.toInt()}px',
                        style: const TextStyle(fontSize: 13),
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorPicker(
                          label: 'Foreground',
                          color: controller.qrForegroundColor.value,
                          onChanged: (c) => controller.qrForegroundColor.value = c,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildColorPicker(
                          label: 'Background',
                          color: controller.qrBackgroundColor.value,
                          onChanged: (c) => controller.qrBackgroundColor.value = c,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isGeneratingQR.value 
                  ? null 
                  : controller.generateQRCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isGeneratingQR.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Generate QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductQRInput(ProductsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.productIdController,
          decoration: InputDecoration(
            hintText: 'Enter Product ID or SKU',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.inventory_2),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Quantity',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.numbers),
          ),
        ),
      ],
    );
  }

  Widget _buildURLInput(ProductsController controller) {
    return TextField(
      controller: controller.urlController,
      decoration: InputDecoration(
        hintText: 'Enter URL (e.g., https://example.com)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.link),
      ),
    );
  }

  Widget _buildTextInput(ProductsController controller) {
    return TextField(
      controller: controller.textController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Enter text to encode in QR code',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.text_fields),
      ),
    );
  }

  Widget _buildCustomDataInput(ProductsController controller) {
    return TextField(
      controller: controller.customDataController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Enter custom data',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.data_array),
      ),
    );
  }

  Widget _buildColorPicker({
    required String label,
    required Color color,
    required void Function(Color) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showColorPicker(Get.context!);
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Color Picker Dialog ──────────────────────────────────────
Future<Color?> showColorPicker(BuildContext context) async {
  return showDialog<Color>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.black,
                Colors.white,
              ].map((color) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}