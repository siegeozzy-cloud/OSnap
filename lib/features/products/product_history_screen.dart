import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../history/receipt_detail_screen.dart';

/// One product across all receipts, oldest at the top, with the price change
/// between each pair of purchases.
class ProductHistoryScreen extends ConsumerWidget {
  const ProductHistoryScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(entriesProvider).value ?? const <Entry>[];
    final entries = all.where((e) => e.product.id == productId).toList();
    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No receipts for this item.')),
      );
    }
    final product = entries.last.product;
    final theme = Theme.of(context);
    final first = entries.first;
    final latest = entries.last;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.displayName),
        actions: [
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(context, ref, product),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '${peso(latest.unitCents)} per piece',
            style: theme.textTheme.headlineSmall,
          ),
          if (latest.sellCents != null)
            Text(
              'Marked up price ${peso(latest.sellCents!)}',
              style: theme.textTheme.titleMedium,
            ),
          if (entries.length > 1) ...[
            const SizedBox(height: 4),
            PriceChange(
              oldCents: first.unitCents,
              newCents: latest.unitCents,
              suffix: 'since ${fmtDate(first.receipt.capturedAt)}',
            ),
            const SizedBox(height: 20),
            SizedBox(height: 180, child: _chart(context, entries)),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.south,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PriceChange(
                        oldCents: entries[i - 1].unitCents,
                        newCents: entries[i].unitCents,
                        suffix: 'per piece',
                      ),
                    ),
                  ],
                ),
              ),
            _purchaseCard(context, entries[i]),
          ],
        ],
      ),
    );
  }

  Widget _purchaseCard(BuildContext context, Entry e) {
    final theme = Theme.of(context);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
    final hasTitle = (e.receipt.title ?? '').trim().isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptDetailScreen(receiptId: e.receipt.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receiptLabel(e.receipt), style: theme.textTheme.titleMedium),
              if (hasTitle)
                Text(
                  fmtDateTime(e.receipt.capturedAt),
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 4),
              row('Qty', e.qtyLabel),
              row('Total price', peso(e.item.totalCents)),
              if (e.isPack) row('Per pack', peso(e.packCents)),
              row('Per piece', peso(e.unitCents)),
              if (e.sellCents != null)
                row('Marked up price', peso(e.sellCents!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chart(BuildContext context, List<Entry> entries) {
    final scheme = Theme.of(context).colorScheme;
    final values = [for (final e in entries) e.unitCents / 100];
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final pad = hi == lo ? (hi == 0 ? 1.0 : hi * 0.1) : (hi - lo) * 0.2;
    const none = AxisTitles(sideTitles: SideTitles(showTitles: false));
    return LineChart(
      LineChartData(
        minY: lo - pad,
        maxY: hi + pad,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: none,
          rightTitles: none,
          bottomTitles: none,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 48),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${peso((s.y * 100).round())}\n'
                  '${fmtDate(entries[s.x.toInt()].receipt.capturedAt)}',
                  TextStyle(color: scheme.onInverseSurface),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            color: scheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Product p) async {
    final name = TextEditingController(text: p.displayName);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename item'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
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
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final renamed = await ref.read(dbProvider).renameProduct(p.id, name.text);
    if (!renamed && context.mounted) {
      showMessage(
        context,
        'Another item already has that name. To combine them, open a receipt, '
        'tap the item and choose "Link to a different product".',
      );
    }
  }
}
