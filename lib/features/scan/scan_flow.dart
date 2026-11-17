import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';
import 'review_screen.dart';

/// Camera or gallery -> save the photo -> read the text -> review screen.
Future<void> startScan(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return;

  final XFile? picked;
  try {
    picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2200,
      imageQuality: 88,
    );
  } catch (e) {
    if (context.mounted) showMessage(context, 'Could not open the camera: $e');
    return;
  }
  if (picked == null || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final capturedAt = DateTime.now();
  final imageName = 'receipt_${capturedAt.millisecondsSinceEpoch}.jpg';
  final file = File(p.join(ref.read(imagesDirProvider).path, imageName));
  await File(picked.path).copy(file.path);

  if (source == ImageSource.camera &&
      await ref.read(settingsProvider).saveToGallery()) {
    try {
      await Gal.putImage(file.path, album: 'Osnap');
    } catch (_) {
      // Gallery access denied; the app keeps its own copy anyway.
    }
  }

  var rows = <String>[];
  String? ocrError;
  try {
    rows = (await OcrService().recognize(file.path)).rows;
  } catch (e) {
    ocrError = '$e';
  }
  final parsed = parseReceipt(rows);

  if (!context.mounted) return;
  Navigator.of(context).pop(); // progress dialog
  if (ocrError != null) {
    showMessage(context, 'Could not read text from the photo. Add items by hand.');
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ReviewScreen(
        imageName: imageName,
        capturedAt: capturedAt,
        receiptDate: parsed.date,
        rawText: rows.join('\n'),
        items: parsed.items,
      ),
    ),
  );
}
