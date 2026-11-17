import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../services/settings_store.dart';
import 'database.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Folder holding the receipt photos. Set in `main()`.
final imagesDirProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('imagesDirProvider not overridden'),
);

final settingsProvider = Provider<SettingsStore>((ref) => SettingsStore());

final receiptsProvider = StreamProvider<List<Receipt>>(
  (ref) => ref.watch(dbProvider).watchReceipts(),
);

/// Every purchased item, oldest first.
final entriesProvider = StreamProvider<List<Entry>>(
  (ref) => ref.watch(dbProvider).watchEntries(),
);

File imageFileFor(WidgetRef ref, String imageName) =>
    File(p.join(ref.read(imagesDirProvider).path, imageName));

List<File> imageFilesFor(WidgetRef ref, Receipt r) => [
  for (final name in imageNamesOf(r)) imageFileFor(ref, name),
];

/// The purchase of the same product just before [entry], if any.
/// [entries] must be oldest first.
Entry? previousPurchase(List<Entry> entries, Entry entry) {
  Entry? prev;
  for (final e in entries) {
    if (e.item.id == entry.item.id) break;
    if (e.product.id == entry.product.id && e.receipt.id != entry.receipt.id) {
      prev = e;
    }
  }
  return prev;
}
