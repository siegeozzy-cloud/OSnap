import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../products/product_history_screen.dart';

const _number = TextInputType.numberWithOptions(decimal: true);

class ReceiptDetailScreen extends ConsumerWidget {
  const ReceiptDetailScreen({super.key, required this.receiptId});
  final int receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptsProvider).value ?? const <Receipt>[];
    final entries = ref.watch(entriesProvider).value ?? const <Entry>[];
    final receipt = receipts.where((r) => r.id == receiptId).firstOrNull;
    if (receipt == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final items = entries.where((e) => e.receipt.id == receiptId).toList();
    final total = items.fold<int>(0, (sum, e) => sum + e.item.totalCents);
    final theme = Theme.of(context);
    final note = (receipt.note ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(receiptLabel(receipt)),
        actions: [
          IconButton(
            tooltip: 'Edit title, note and date',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editMeta(context, ref, receipt),
          ),
          IconButton(
            tooltip: 'Delete receipt',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref, receipt),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: ScrollJump(
        // Clear the "Add item" button.
        bottomInset: 88,
        builder: (scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            ReceiptImages(files: imageFilesFor(ref, receipt)),
            const SizedBox(height: 12),
            Text(
              fmtDateTime(receipt.capturedAt),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Items (${items.length})',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Total ${peso(total)}',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No items on this receipt.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            for (final e in items) _ItemCard(entry: e, all: entries),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Receipt r) async {
    final ok = await confirm(
      context,
      title: 'Delete this receipt?',
      message:
          'The photo, note and items will be removed. This cannot be undone.',
      action: 'Delete',
    );
    if (!ok) return;
    final files = imageFilesFor(ref, r);
    await ref.read(dbProvider).deleteReceipt(r.id);
    for (final file in files) {
      if (await file.exists()) await file.delete();
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _editMeta(BuildContext context, WidgetRef ref, Receipt r) async {
    final title = TextEditingController(text: r.title ?? '');
    final note = TextEditingController(text: r.note ?? '');
    var date = r.capturedAt;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit receipt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                  ),
                ),
                TextField(
                  controller: note,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(fmtDate(date)),
                  trailing: const Text('Change'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(
                        () => date = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          date.hour,
                          date.minute,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (save == true) {
      await ref
          .read(dbProvider)
          .updateReceiptMeta(
            r.id,
            title: title.text,
            note: note.text,
            capturedAt: date,
          );
    }
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final qty = TextEditingController(text: '1');
    final total = TextEditingController();
    final markup = TextEditingController();
    final pack = TextEditingController();
    var isPack = false;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Item name'),
              ),
              TextField(
                controller: qty,
                keyboardType: _number,
                decoration: const InputDecoration(labelText: 'Qty'),
              ),
              TextField(
                controller: total,
                keyboardType: _number,
                decoration: const InputDecoration(
                  labelText: 'Total price',
                  prefixText: '₱',
                ),
              ),
              TextField(
                controller: markup,
                keyboardType: _number,
                decoration: const InputDecoration(
                  labelText: 'Markup per piece (optional)',
                  prefixText: '+₱',
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (ctx, setState) => SoldAsChooser(
                  isPack: isPack,
                  pieces: pack,
                  onChanged: (v) => setState(() => isPack = v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (save != true) return;
    final q = parseQty(qty.text);
    final t = parseCents(total.text);
    final packSize = readPackSize(isPack: isPack, pieces: pack.text);
    if (name.text.trim().isEmpty || q == null || q <= 0 || t == null) {
      if (context.mounted) {
        showMessage(context, 'An item needs a name, quantity and total price.');
      }
      return;
    }
    if (packSize == null) {
      if (context.mounted) {
        showMessage(context, 'Enter how many pieces are in one pack.');
      }
      return;
    }
    await ref
        .read(dbProvider)
        .addItem(
          receiptId,
          NewItem(
            name: name.text,
            qty: q,
            totalCents: t,
            markupCents: parseCents(markup.text),
            piecesPerPack: packSize,
          ),
        );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.entry, required this.all});
  final Entry entry;
  final List<Entry> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prev = previousPurchase(all, entry);
    final item = entry.item;
    final linkedName = entry.product.displayName;
    final showLinked = normalizeName(linkedName) != normalizeName(item.rawName);

    Widget row(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: strong ? FontWeight.w700 : null),
          ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _edit(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.rawName, style: theme.textTheme.titleMedium),
                        if (showLinked)
                          Text(
                            'Tracked as $linkedName',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Price history',
                    icon: const Icon(Icons.show_chart),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductHistoryScreen(productId: entry.product.id),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    row('Qty', entry.qtyLabel),
                    row('Total price', peso(item.totalCents)),
                    if (entry.isPack) row('Per pack', peso(entry.packCents)),
                    row('Per piece', peso(entry.unitCents), strong: true),
                    if (entry.sellCents != null)
                      row(
                        'Marked up price (${signedPeso(item.markupCents!)})',
                        peso(entry.sellCents!),
                        strong: true,
                      )
                    else
                      row('Marked up price', 'Tap to set'),
                    const SizedBox(height: 8),
                    if (prev == null)
                      Text(
                        'First time you bought this',
                        style: TextStyle(color: theme.colorScheme.outline),
                      )
                    else
                      PriceChange(
                        oldCents: prev.unitCents,
                        newCents: entry.unitCents,
                        suffix:
                            'per piece vs ${receiptLabel(prev.receipt)} '
                            '(${peso(prev.unitCents)})',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final item = entry.item;
    final qty = TextEditingController(text: fmtQty(item.qty));
    final total = TextEditingController(text: centsToInput(item.totalCents));
    final markup = TextEditingController(
      text: item.markupCents == null ? '' : centsToInput(item.markupCents!),
    );
    final pack = TextEditingController(
      text: entry.isPack ? '${item.piecesPerPack}' : '',
    );
    var isPack = entry.isPack;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.rawName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: qty,
                keyboardType: _number,
                decoration: const InputDecoration(labelText: 'Qty'),
              ),
              TextField(
                controller: total,
                keyboardType: _number,
                decoration: const InputDecoration(
                  labelText: 'Total price',
                  prefixText: '₱',
                ),
              ),
              TextField(
                controller: markup,
                keyboardType: _number,
                decoration: const InputDecoration(
                  labelText: 'Markup per piece',
                  prefixText: '+₱',
                  helperText: 'Leave empty for no markup',
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (ctx, setState) => SoldAsChooser(
                  isPack: isPack,
                  pieces: pack,
                  onChanged: (v) => setState(() => isPack = v),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx, 'move'),
                icon: const Icon(Icons.link),
                label: const Text('Link to a different product'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove this item'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final db = ref.read(dbProvider);
    switch (action) {
      case 'save':
        final q = parseQty(qty.text);
        final t = parseCents(total.text);
        if (q == null || q <= 0 || t == null) {
          if (context.mounted) {
            showMessage(context, 'Quantity and total price must be numbers.');
          }
          return;
        }
        final packSize = readPackSize(isPack: isPack, pieces: pack.text);
        if (packSize == null) {
          if (context.mounted) {
            showMessage(context, 'Enter how many pieces are in one pack.');
          }
          return;
        }
        await db.updateItem(
          item.id,
          qty: q,
          totalCents: t,
          markupCents: parseCents(markup.text),
          piecesPerPack: packSize,
        );
      case 'delete':
        await db.deleteItem(item.id);
      case 'move':
        if (context.mounted) await _move(context, ref);
    }
  }

  /// Fixes a wrong match by linking the item to another product.
  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final products = await db.allProducts();
    if (!context.mounted) return;
    // -1 means "make a separate product from this item's own name".
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Which product is this?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, -1),
            child: Text('New product: "${entry.item.rawName}"'),
          ),
          const Divider(),
          for (final p in products)
            if (p.id != entry.product.id)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, p.id),
                child: Text(p.displayName),
              ),
        ],
      ),
    );
    if (choice == null) return;
    final target = choice == -1
        ? await db.findOrCreateProduct(entry.item.rawName)
        : choice;
    await db.moveItemToProduct(entry.item.id, target);
  }
}
