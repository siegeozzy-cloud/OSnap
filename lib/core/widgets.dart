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
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => FullImageScreen(file: file))),
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

/// One photo full width, or a side-scrolling strip when a long receipt was
/// shot in several photos. Each opens full screen when tapped.
class ReceiptImages extends StatelessWidget {
  const ReceiptImages({super.key, required this.files, this.height = 180});
  final List<File> files;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (files.length == 1) {
      return ReceiptImage(file: files.single, height: height);
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => SizedBox(
          width: height * 0.9,
          child: Stack(
            children: [
              ReceiptImage(file: files[i], height: height),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${i + 1} of ${files.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a long scrolling page with a jump button:
///  - in the top half, "Go to bottom" slides up from the bottom edge;
///  - in the bottom half, "Back to top" slides down from the top edge.
/// [builder] gets the controller to give to the page's scroll view.
class ScrollJump extends StatefulWidget {
  const ScrollJump({super.key, required this.builder, this.bottomInset = 16});

  final Widget Function(ScrollController controller) builder;

  /// Space under the bottom button, e.g. to clear a floating action button.
  final double bottomInset;

  @override
  State<ScrollJump> createState() => _ScrollJumpState();
}

class _ScrollJumpState extends State<ScrollJump> {
  final _controller = ScrollController();

  /// null = page too short for a button, true = top half, false = bottom half.
  bool? _inTopHalf;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final p = _controller.position;
    final bool? next;
    // Worth a button only when the page is more than a screen and a half.
    if (p.maxScrollExtent < p.viewportDimension * 0.5) {
      next = null;
    } else {
      next = p.pixels < p.maxScrollExtent / 2;
    }
    if (next != _inTopHalf) setState(() => _inTopHalf = next);
  }

  Future<void> _jump({required bool down}) async {
    if (!_controller.hasClients) return;
    const duration = Duration(milliseconds: 450);
    if (!down) {
      await _controller.animateTo(
        0,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    // Lazily built lists only know their real length once scrolled, so
    // keep going until the end stops moving.
    for (var i = 0; i < 5 && _controller.hasClients; i++) {
      final max = _controller.position.maxScrollExtent;
      if (_controller.position.pixels >= max - 1) break;
      await _controller.animateTo(
        max,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _inTopHalf;
    // The controller can belong to a newly built scroll view after the page
    // changes length; re-check once that frame is laid out.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _update());
        return false;
      },
      child: Stack(
        children: [
          widget.builder(_controller),
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.bottomInset,
            child: _JumpButton(
              visible: state == true,
              hiddenOffset: const Offset(0, 2),
              icon: Icons.arrow_downward,
              label: 'Go to bottom',
              onPressed: () => _jump(down: true),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 12,
            child: _JumpButton(
              visible: state == false,
              hiddenOffset: const Offset(0, -2),
              icon: Icons.arrow_upward,
              label: 'Back to top',
              onPressed: () => _jump(down: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _JumpButton extends StatelessWidget {
  const _JumpButton({
    required this.visible,
    required this.hiddenOffset,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool visible;
  final Offset hiddenOffset;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : hiddenOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                elevation: 3,
                shadowColor: scheme.shadow,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
