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
import 'scan_flow.dart';

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
  )..printedPack = i.packSize;

  /// Pieces per pack printed on the receipt ("(12+2)" -> 14), read before
  /// the name was shortened to name + weight.
  int? printedPack;

  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController total;
  final TextEditingController markup;

  /// Sold as a package; [pack] holds the pieces inside one pack.
  bool isPack = false;
  final TextEditingController pack = TextEditingController();

  /// The user chose Per piece / Package by hand; automatic guesses stop.
  bool packTouched = false;

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
  const ReviewScreen({super.key, required this.first});

  /// The first photo. More photos of the same receipt are added on this
  /// screen.
  final Shot first;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  late List<_Draft> _drafts;

  /// Photos of this receipt, top to bottom.
  late List<String> _imageNames;
  late String _rawText;

  /// Date printed on the receipt, if the scanner found one.
  DateTime? _receiptDate;

  /// Total and item count printed on the receipt, to check the scan against.
  int? _printedTotal;
  int? _printedCount;
  late DateTime _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _imageNames = [widget.first.imageName];
    _rawText = widget.first.rows.join('\n');
    _receiptDate = widget.first.parsed.date;
    _printedTotal = widget.first.parsed.printedTotalCents;
    _printedCount = widget.first.parsed.printedItemCount;
    _drafts = widget.first.parsed.items.map(_Draft.from).toList();
    _date = widget.first.capturedAt;
    _prefillPacks();
  }

  /// Starts an item as a package when its size is known: from the last time
  /// the same item was saved, otherwise from a pack size printed in its name
  /// such as "(12+2)X48". The user can still switch it back.
  Future<void> _prefillPacks() async {
    final known = await ref.read(dbProvider).lastPackSizes();
    if (!mounted) return;
    setState(() {
      for (final d in _drafts) {
        if (d.packTouched) continue;
        final size =
            known[normalizeName(d.name.text)] ??
            d.printedPack ??
            suggestedPackSize(d.name.text);
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
    for (final name in _imageNames) {
      final file = imageFileFor(ref, name);
      if (await file.exists()) await file.delete();
    }
    if (mounted) Navigator.of(context).pop();
  }

  ParsedItem? _toParsed(_Draft d) {
    final qty = parseQty(d.qty.text);
    final total = parseCents(d.total.text);
    if (qty == null || total == null) return null;
    return ParsedItem(name: d.name.text, qty: qty, totalCents: total);
  }

  /// Another photo of the same receipt, for receipts too long for one shot.
  Future<void> _addPhoto() async {
    final shot = await captureShot(context, ref);
    if (shot == null || !mounted) return;

    // Rows without a usable price stand in as items that match nothing.
    final existing = [
      for (final d in _drafts)
        _toParsed(d) ?? ParsedItem(name: '', qty: 1, totalCents: -1),
    ];
    final merge = mergeShot(existing, shot.parsed.items);
    setState(() {
      _imageNames.add(shot.imageName);
      _rawText = '$_rawText\n${shot.rows.join('\n')}';
      _receiptDate ??= shot.parsed.date;
      _printedTotal ??= shot.parsed.printedTotalCents;
      _printedCount ??= shot.parsed.printedItemCount;
      final fuller = merge.replaceLast;
      if (fuller != null && _drafts.isNotEmpty) {
        _drafts.last.name.text = fuller.name;
        _drafts.last.qty.text = fmtQty(fuller.qty);
        _drafts.last.printedPack ??= fuller.packSize;
      }
      // Highest index first so earlier positions stay valid.
      for (final at in merge.inserts.keys.toList()..sort((a, b) => b - a)) {
        _drafts.insertAll(at, merge.inserts[at]!.map(_Draft.from));
      }
      _drafts.addAll(merge.toAdd.map(_Draft.from));
    });
    _prefillPacks();
    final added =
        merge.toAdd.length +
        merge.inserts.values.fold<int>(0, (sum, list) => sum + list.length);
    showMessage(
      context,
      'Photo ${_imageNames.length} added: $added new item${added == 1 ? '' : 's'}'
      '${merge.skipped > 0 ? ', ${merge.skipped} already listed and skipped' : ''}.',
    );
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
        ocrText: _rawText,
        images: [for (final n in _imageNames) imageFileFor(ref, n)],
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
      showMessage(
        context,
        'Items replaced with the AI result. Please check them.',
      );
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
          showMessage(
            context,
            'Item ${i + 1} needs a name, quantity and total price.',
          );
        }
        return;
      }
      final packSize = readPackSize(isPack: d.isPack, pieces: d.pack.text);
      if (packSize == null) {
        if (mounted) {
          showMessage(
            context,
            'Item ${i + 1}: enter how many pieces are in one pack.',
          );
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
        imageName: _imageNames.join('|'),
        capturedAt: _date,
        title: _title.text,
        note: _note.text,
        rawOcrText: _rawText,
        items: items,
        defaultMarkupCents: await ref
            .read(settingsProvider)
            .defaultMarkupCents(),
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
          child: ScrollJump(
            builder: (scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
              children: [
                if (_busy) const LinearProgressIndicator(),
                ReceiptImages(
                  files: [for (final n in _imageNames) imageFileFor(ref, n)],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add photo (long receipt)'),
                  ),
                ),
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
                ?_scanCheck(),
                for (final d in _drafts) _itemCard(d),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _runningTotal(),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _dateHint() {
    final printed = _receiptDate;
    if (printed == null) return const Text('When the photo was taken');
    final usingPrinted = DateUtils.isSameDay(_date, printed);
    if (usingPrinted) return const Text('Date printed on the receipt');
    if (DateUtils.isSameDay(printed, widget.first.capturedAt)) {
      return const Text('When the photo was taken');
    }
    return InkWell(
      onTap: () => setState(() => _date = _withDay(printed)),
      child: Text('Receipt says ${fmtDate(printed)}. Tap to use it.'),
    );
  }

  /// Sum of the items as they are now, always shown above Save so it can be
  /// checked against the total printed on the photo while editing.
  Widget _runningTotal() {
    final theme = Theme.of(context);
    var sum = 0;
    var missing = 0;
    for (final d in _drafts) {
      final t = parseCents(d.total.text);
      if (t == null) {
        if (d.total.text.trim().isNotEmpty || d.name.text.trim().isNotEmpty) {
          missing++;
        }
      } else {
        sum += t;
      }
    }
    final printed = _printedTotal;
    final matches = printed != null && printed == sum;
    final color = printed == null
        ? theme.colorScheme.onSurface
        : matches
        ? Colors.green.shade700
        : theme.colorScheme.error;
    final count = _drafts.length;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count item${count == 1 ? '' : 's'}'
                '${missing > 0 ? ' · $missing without a price' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (printed != null)
                Text(
                  matches
                      ? 'Matches receipt total'
                      : 'Receipt total ${peso(printed)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
            ],
          ),
        ),
        Text('Total ', style: theme.textTheme.titleMedium),
        Text(
          peso(sum),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Compares the items with the total and item count printed on the
  /// receipt, so a missed item or a wrong price shows up before saving.
  Widget? _scanCheck() {
    final printedTotal = _printedTotal;
    final printedCount = _printedCount;
    if (printedTotal == null && printedCount == null) return null;
    var sum = 0;
    var pieces = 0.0;
    for (final d in _drafts) {
      sum += parseCents(d.total.text) ?? 0;
      pieces += parseQty(d.qty.text) ?? 0;
    }
    final problems = <String>[];
    if (printedTotal != null && sum != printedTotal) {
      problems.add(
        'Items add up to ${peso(sum)}, the receipt total is '
        '${peso(printedTotal)} (${sum > printedTotal ? '+' : '-'}'
        '${peso((sum - printedTotal).abs())}).',
      );
    }
    // Some stores count rows, others count pieces.
    if (printedCount != null &&
        printedCount != _drafts.length &&
        (pieces - printedCount).abs() > 0.001) {
      problems.add(
        'The receipt lists $printedCount items, ${_drafts.length} were found.',
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final ok = problems.isEmpty;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: ok ? scheme.secondaryContainer : scheme.errorContainer,
      child: ListTile(
        leading: Icon(
          ok ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          color: ok ? scheme.onSecondaryContainer : scheme.onErrorContainer,
        ),
        title: Text(
          ok ? 'Matches the receipt' : 'Check the items',
          style: TextStyle(
            color: ok ? scheme.onSecondaryContainer : scheme.onErrorContainer,
          ),
        ),
        subtitle: Text(
          ok
              ? [
                  if (printedTotal != null) 'Total ${peso(printedTotal)}',
                  if (printedCount != null) '$printedCount items',
                ].join(' · ')
              : problems.join('\n'),
          style: TextStyle(
            color: ok ? scheme.onSecondaryContainer : scheme.onErrorContainer,
          ),
        ),
      ),
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
                onChanged: (v) => setState(() {
                  d.isPack = v;
                  d.packTouched = true;
                }),
                onPiecesChanged: (v) => setState(() => d.packTouched = true),
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
