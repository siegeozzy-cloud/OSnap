import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../services/ai_service.dart';
import '../../services/product_matcher.dart';
import '../../services/receipt_parser.dart';
import '../history/receipt_detail_screen.dart';

class _Draft {
  _Draft({String name = '', String qty = '1', String total = ''})
    : name = TextEditingController(text: name),
      qty = TextEditingController(text: qty),
      total = TextEditingController(text: total),
      markup = TextEditingController();

  factory _Draft.from(ParsedItem i) => _Draft(
    name: i.name,
    qty: fmtQty(i.qty),
    total: centsToInput(i.totalCents),
  );

  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController total;
  final TextEditingController markup;

  /// Sold as a package; [pack] holds the pieces inside one pack.
  bool isPack = false;
  final TextEditingController pack = TextEditingController();

  void dispose() {
    pack.dispose();
    name.dispose();
    qty.dispose();
    total.dispose();
    markup.dispose();
  }
}

/// Shown after every scan so the user can fix what the OCR got wrong, add an
/// optional title and note, and set markups before saving.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    super.key,
    required this.imageName,
    required this.capturedAt,
    required this.rawText,
    required this.items,
    this.receiptDate,
  });
  final String imageName;
  final DateTime capturedAt;

  /// Date printed on the receipt, if the scanner found one.
  final DateTime? receiptDate;
  final String rawText;
  final List<ParsedItem> items;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  late List<_Draft> _drafts;
  late DateTime _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.items.map(_Draft.from).toList();
    _date = widget.capturedAt;
    _prefillPacks();
  }

  /// Items bought before as a package start as a package of the same size.
  Future<void> _prefillPacks() async {
    final known = await ref.read(dbProvider).lastPackSizes();
    if (!mounted) return;
    setState(() {
      for (final d in _drafts) {
        final size = known[normalizeName(d.name.text)];
        if (size != null && size > 1 && !d.isPack && d.pack.text.isEmpty) {
          d.isPack = true;
          d.pack.text = '$size';
        }
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  DateTime _withDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, _date.hour, _date.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = _withDay(picked));
  }

  Future<void> _discard() async {
    final ok = await confirm(
      context,
      title: 'Discard this scan?',
      message: 'The photo and the items on this screen will be removed.',
      action: 'Discard',
    );
    if (!ok || !mounted) return;
    final file = imageFileFor(ref, widget.imageName);
    if (await file.exists()) await file.delete();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _improveWithAi() async {
    final settings = await ref.read(settingsProvider).ai();
    if (!mounted) return;
    if (settings.apiKey.isEmpty &&
        settings.baseUrl.contains('models.github.ai')) {
      _aiError(
        'No GitHub token is saved yet.\n\nOpen Settings > AI clean-up, paste '
        'a GitHub token that has the "Models: read" permission, then tap '
        '"Save AI settings".',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await AiService().extract(
        settings: settings,
        ocrText: widget.rawText,
        image: imageFileFor(ref, widget.imageName),
      );
      if (!mounted) return;
      if (result.items.isEmpty) {
        showMessage(context, 'The AI did not find any items.');
        return;
      }
      setState(() {
        for (final d in _drafts) {
          d.dispose();
        }
        _drafts = result.items.map(_Draft.from).toList();
        if (result.date != null) _date = _withDay(result.date!);
      });
      _prefillPacks();
      showMessage(context, 'Items replaced with the AI result. Please check them.');
    } on AiException catch (e) {
      if (mounted) _aiError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A dialog, not a snackbar, so the full error can be read and copied.
  void _aiError(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI clean-up did not work'),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// true = same product, false = different, null = cancelled.
  Future<bool?> _askSame(String name, Product candidate) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Same product?'),
        content: Text(
          'Is "$name" the same product as "${candidate.displayName}"?\n\n'
          'If yes, its price is compared with your earlier receipts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, it is new'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, same'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final db = ref.read(dbProvider);
    final products = await db.allProducts();
    final items = <NewItem>[];

    for (var i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      final name = d.name.text.trim();
      if (name.isEmpty && d.total.text.trim().isEmpty) continue; // blank row
      final qty = parseQty(d.qty.text);
      final total = parseCents(d.total.text);
      if (name.isEmpty || qty == null || qty <= 0 || total == null) {
        if (mounted) {
          showMessage(context, 'Item ${i + 1} needs a name, quantity and total price.');
        }
        return;
      }
      final packSize = readPackSize(isPack: d.isPack, pieces: d.pack.text);
      if (packSize == null) {
        if (mounted) {
          showMessage(context, 'Item ${i + 1}: enter how many pieces are in one pack.');
        }
        return;
      }
      final match = matchProduct(name, products);
      var productId = match.exact?.id;
      if (productId == null && match.similar != null) {
        if (!mounted) return;
        final same = await _askSame(name, match.similar!);
        if (same == null) return;
        if (same) productId = match.similar!.id;
      }
      items.add(
        NewItem(
          name: name,
          qty: qty,
          totalCents: total,
          markupCents: parseCents(d.markup.text),
          productId: productId,
          piecesPerPack: packSize,
        ),
      );
    }

    setState(() => _busy = true);
    try {
      // Last known per-piece price of each product, before this receipt.
      final lastUnit = <int, int>{};
      for (final e in await db.allEntries()) {
        if (!e.receipt.capturedAt.isAfter(_date)) {
          lastUnit[e.product.id] = e.unitCents;
        }
      }

      final receiptId = await db.saveReceipt(
        imageName: widget.imageName,
        capturedAt: _date,
        title: _title.text,
        note: _note.text,
        rawOcrText: widget.rawText,
        items: items,
        defaultMarkupCents: await ref.read(settingsProvider).defaultMarkupCents(),
      );

      var changed = 0;
      for (final e in await db.allEntries()) {
        if (e.receipt.id != receiptId) continue;
        final before = lastUnit[e.product.id];
        if (before != null && before != e.unitCents) changed++;
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReceiptDetailScreen(receiptId: receiptId),
        ),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            changed == 0
                ? 'Saved.'
                : 'Saved. $changed item${changed == 1 ? '' : 's'} changed price since last time.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, 'Could not save: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review scan'),
          actions: [
            TextButton.icon(
              onPressed: _busy ? null : _improveWithAi,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Fix with AI'),
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_busy) const LinearProgressIndicator(),
              ReceiptImage(file: imageFileFor(ref, widget.imageName)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(fmtDateTime(_date)),
                subtitle: _dateHint(),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Items (${_drafts.length})',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _drafts.add(_Draft())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ],
              ),
              if (_drafts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No items were detected. Add them by hand, or try '
                    '"Fix with AI".',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final d in _drafts) _itemCard(d),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _dateHint() {
    final printed = widget.receiptDate;
    if (printed == null) return const Text('When the photo was taken');
    final usingPrinted = DateUtils.isSameDay(_date, printed);
    if (usingPrinted) return const Text('Date printed on the receipt');
    if (DateUtils.isSameDay(printed, widget.capturedAt)) {
      return const Text('When the photo was taken');
    }
    return InkWell(
      onTap: () => setState(() => _date = _withDay(printed)),
      child: Text('Receipt says ${fmtDate(printed)}. Tap to use it.'),
    );
  }

  Widget _itemCard(_Draft d) {
    final theme = Theme.of(context);
    final qty = parseQty(d.qty.text);
    final total = parseCents(d.total.text);
    final markup = parseCents(d.markup.text);
    String summary = '';
    final packSize = readPackSize(isPack: d.isPack, pieces: d.pack.text);
    if (qty != null && qty > 0 && total != null && packSize != null) {
      final unit = unitCentsOf(total, qty * packSize);
      summary = d.isPack
          ? 'Per pack: ${peso(unitCentsOf(total, qty))}   '
                'Per piece: ${peso(unit)}'
          : 'Per piece: ${peso(unit)}';
      if (markup != null) summary += '   Marked up: ${peso(unit + markup)}';
    } else if (d.isPack && packSize == null) {
      summary = 'Enter the pieces per pack to get the per-piece price.';
    }
    const number = TextInputType.numberWithOptions(decimal: true);
    void refresh(String _) => setState(() {});

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: d.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Item name'),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _drafts.remove(d);
                    d.dispose();
                  }),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: d.qty,
                      keyboardType: number,
                      onChanged: refresh,
                      decoration: const InputDecoration(labelText: 'Qty'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: d.total,
                      keyboardType: number,
                      onChanged: refresh,
                      decoration: const InputDecoration(
                        labelText: 'Total price',
                        prefixText: '₱',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: d.markup,
                      keyboardType: number,
                      onChanged: refresh,
                      decoration: const InputDecoration(
                        labelText: 'Markup / pc',
                        prefixText: '+₱',
                        hintText: 'auto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 8),
              child: SoldAsChooser(
                isPack: d.isPack,
                pieces: d.pack,
                onChanged: (v) => setState(() => d.isPack = v),
                onPiecesChanged: refresh,
              ),
            ),
            if (summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
