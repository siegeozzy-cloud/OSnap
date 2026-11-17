import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import 'receipt_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final receipts = ref.watch(receiptsProvider);
    final entries = ref.watch(entriesProvider).value ?? const <Entry>[];

    final byReceipt = <int, List<Entry>>{};
    for (final e in entries) {
      byReceipt.putIfAbsent(e.receipt.id, () => []).add(e);
    }

    return receipts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load history: $e')),
      data: (all) {
        if (all.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No receipts yet',
            message:
                'Tap Scan to take a photo of a receipt. The app reads the '
                'items, works out the price per piece and keeps it here.',
          );
        }
        final q = _query.trim().toLowerCase();
        final list = q.isEmpty
            ? all
            : all.where((r) {
                final items = byReceipt[r.id] ?? const <Entry>[];
                return (r.title ?? '').toLowerCase().contains(q) ||
                    (r.note ?? '').toLowerCase().contains(q) ||
                    items.any(
                      (e) =>
                          e.item.rawName.toLowerCase().contains(q) ||
                          e.product.displayName.toLowerCase().contains(q),
                    );
              }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SearchBar(
                hintText: 'Search title, note or item',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Nothing matches your search.'))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) =>
                          _tile(list[i], byReceipt[list[i].id] ?? const []),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(Receipt r, List<Entry> items) {
    final hasTitle = (r.title ?? '').trim().isNotEmpty;
    final total = items.fold<int>(0, (sum, e) => sum + e.item.totalCents);
    final note = (r.note ?? '').trim();
    final lines = [
      if (hasTitle) fmtDateTime(r.capturedAt),
      if (note.isNotEmpty) note,
      '${items.length} item${items.length == 1 ? '' : 's'} · ${peso(total)}',
    ];
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          imageFilesFor(ref, r).first,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          cacheWidth: 144,
          errorBuilder: (_, _, _) => const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.receipt_long_outlined),
          ),
        ),
      ),
      title: Text(
        receiptLabel(r),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        lines.join('\n'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: lines.length > 1,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReceiptDetailScreen(receiptId: r.id)),
      ),
    );
  }
}
