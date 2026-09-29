import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Core/Utils/app.colors.dart';
import '../../../Helper/image_processing_helper.dart';

class ResizeImageDialog extends StatefulWidget {
  final Uint8List originalBytes;

  const ResizeImageDialog({super.key, required this.originalBytes});

  @override
  State<ResizeImageDialog> createState() => _ResizeImageDialogState();
}

class _ResizeImageDialogState extends State<ResizeImageDialog> {
  late TextEditingController widthController;
  late TextEditingController heightController;
  bool keepRatio = true;
  double ratio = 1.0;
  int originalWidth = 0;
  int originalHeight = 0;
  bool isDecoding = true;

  @override
  void initState() {
    super.initState();
    _parseImage();
  }

  void _parseImage() {
    final decoded = ImageProcessingHelper.decodeImageSync(widget.originalBytes);
    if (decoded != null) {
      originalWidth = decoded.width;
      originalHeight = decoded.height;
      ratio = originalWidth / originalHeight;
      widthController = TextEditingController(text: originalWidth.toString());
      heightController = TextEditingController(text: originalHeight.toString());
    }
    setState(() {
      isDecoding = false;
    });
  }

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDecoding) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.photo_size_select_large, color: AppColors.primaryPurple),
          const SizedBox(width: 10),
          Text(
            "Resize Image".tr,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryPurple.withOpacity(0.15)
                    : AppColors.primaryPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryPurple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${"Original size".tr}: $originalWidth × $originalHeight px",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widthController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "Width".tr,
                suffixText: "px",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                if (!keepRatio) return;
                final int? width = int.tryParse(value);
                if (width == null || width <= 0) return;
                heightController.text = (width / ratio).round().toString();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Keep aspect ratio".tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Switch(
                  value: keepRatio,
                  activeColor: AppColors.primaryPurple,
                  onChanged: (val) => setState(() => keepRatio = val),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "Height".tr,
                suffixText: "px",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                if (!keepRatio) return;
                final int? height = int.tryParse(value);
                if (height == null || height <= 0) return;
                widthController.text = (height * ratio).round().toString();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel".tr, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check, size: 18),
          label: Text("Resize".tr),
          onPressed: () async {
            final int? width = int.tryParse(widthController.text);
            final int? height = int.tryParse(heightController.text);

            if (width == null || height == null || width <= 0 || height <= 0) {
              Get.snackbar("Error".tr, "Please enter valid dimensions".tr);
              return;
            }

            final resized = await ImageProcessingHelper.resizeImageInIsolate(
                widget.originalBytes, width, height);

            if (context.mounted) Navigator.pop(context, resized);
          },
        ),
      ],
    );
  }
}