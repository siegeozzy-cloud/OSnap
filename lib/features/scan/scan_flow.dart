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

/// One photo of a receipt (or of one part of a long receipt) and what the
/// scanner read from it.
class Shot {
  Shot({
    required this.imageName,
    required this.capturedAt,
    required this.rows,
    required this.parsed,
  });
  final String imageName;
  final DateTime capturedAt;
  final List<String> rows;
  final ParsedReceipt parsed;
}

/// Camera or gallery -> save the photo in the app folder -> read the text.
/// Returns null if the user cancels.
Future<Shot?> captureShot(BuildContext context, WidgetRef ref) async {
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
  if (source == null) return null;

  final XFile? picked;
  try {
    picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2200,
      imageQuality: 88,
    );
  } catch (e) {
    if (context.mounted) showMessage(context, 'Could not open the camera: $e');
    return null;
  }
  if (picked == null || !context.mounted) return null;

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
  var ocrFailed = false;
  try {
    rows = (await OcrService().recognize(file.path)).rows;
  } catch (_) {
    ocrFailed = true;
  }

  if (!context.mounted) return null;
  Navigator.of(context).pop(); // progress dialog
  if (ocrFailed) {
    showMessage(
      context,
      'Could not read text from the photo. Add items by hand.',
    );
  }
  return Shot(
    imageName: imageName,
    capturedAt: capturedAt,
    rows: rows,
    parsed: parseReceipt(rows),
  );
}

/// First photo of a new receipt, then the review screen. More photos of the
/// same receipt can be added there.
Future<void> startScan(BuildContext context, WidgetRef ref) async {
  final shot = await captureShot(context, ref);
  if (shot == null || !context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ReviewScreen(first: shot)));
}
