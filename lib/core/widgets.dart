import 'dart:io';

import 'package:flutter/material.dart';

import 'format.dart';

/// ▲ red when the price went up, ▼ green when it went down, grey when equal.
class PriceChange extends StatelessWidget {
  const PriceChange({
    super.key,
    required this.oldCents,
    required this.newCents,
    this.suffix,
  });
  final int oldCents;
  final int newCents;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diff = newCents - oldCents;
    final (IconData icon, Color color, String text) = switch (diff) {
      > 0 => (
        Icons.arrow_upward,
        scheme.error,
        '${signedPeso(diff)} (${percentChange(oldCents, newCents)})',
      ),
      < 0 => (
        Icons.arrow_downward,
        Colors.green.shade600,
        '${signedPeso(diff)} (${percentChange(oldCents, newCents)})',
      ),
      _ => (Icons.remove, scheme.outline, 'No change'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            suffix == null ? text : '$text $suffix',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom view of a receipt photo.
class FullImageScreen extends StatelessWidget {
  const FullImageScreen({super.key, required this.file});
  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(child: Image.file(file)),
      ),
    );
  }
}

/// Receipt photo that opens full screen when tapped.
class ReceiptImage extends StatelessWidget {
  const ReceiptImage({super.key, required this.file, this.height = 180});
  final File file;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FullImageScreen(file: file)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) => Container(
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// "Per piece / Package" chooser. Choosing Package shows a field for how many
/// pieces are inside one pack, which is what the per-piece price divides by.
class SoldAsChooser extends StatelessWidget {
  const SoldAsChooser({
    super.key,
    required this.isPack,
    required this.pieces,
    required this.onChanged,
    this.onPiecesChanged,
  });
  final bool isPack;
  final TextEditingController pieces;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String>? onPiecesChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(value: false, label: Text('Per piece')),
              ButtonSegment(value: true, label: Text('Package')),
            ],
            selected: {isPack},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
        if (isPack) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: pieces,
              keyboardType: TextInputType.number,
              onChanged: onPiecesChanged,
              decoration: const InputDecoration(
                labelText: 'Pcs per pack',
                isDense: true,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Pack size from the chooser: 1 for per piece, null when Package is chosen
/// but the piece count is missing or not a whole number above zero.
int? readPackSize({required bool isPack, required String pieces}) {
  if (!isPack) return 1;
  final n = int.tryParse(pieces.trim());
  return (n == null || n < 1) ? null : n;
}
