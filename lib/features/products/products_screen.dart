import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import 'product_history_screen.dart';

/// Every product with its latest per-piece price and how it changed.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    return entries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load prices: $e')),
      data: (all) {
        if (all.isEmpty) {
          return const EmptyState(
            icon: Icons.sell_outlined,
            title: 'No prices yet',
            message:
                'Items from your receipts appear here. Scan the same item '
                'again later to see if its price went up or down.',
          );
        }
        // Oldest first, so the last entry of each list is the latest price.
        final byProduct = <int, List<Entry>>{};
        for (final e in all) {
          byProduct.putIfAbsent(e.product.id, () => []).add(e);
        }
        final q = _query.trim().toLowerCase();
        final groups =
            byProduct.values
                .where(
                  (g) =>
                      q.isEmpty ||
                      g.last.product.displayName.toLowerCase().contains(q),
                )
                .toList()
              ..sort(
                (a, b) => a.last.product.displayName.toLowerCase().compareTo(
                  b.last.product.displayName.toLowerCase(),
                ),
              );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SearchBar(
                hintText: 'Search items',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: groups.isEmpty
                  ? const Center(child: Text('Nothing matches your search.'))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) => _tile(groups[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(List<Entry> group) {
    final latest = group.last;
    final prev = group.length > 1 ? group[group.length - 2] : null;
    return ListTile(
      title: Text(latest.product.displayName),
      subtitle: prev == null
          ? const Text('1 receipt')
          : PriceChange(
              oldCents: prev.unitCents,
              newCents: latest.unitCents,
              suffix: '· ${group.length} receipts',
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${peso(latest.unitCents)}/pc',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (latest.sellCents != null) Text('Sell ${peso(latest.sellCents!)}'),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductHistoryScreen(productId: latest.product.id),
        ),
      ),
    );
  }
}
