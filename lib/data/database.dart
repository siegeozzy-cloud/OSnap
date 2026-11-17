import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../core/format.dart';
import '../services/receipt_parser.dart' show cleanItemName;

part 'database.g.dart';

class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Photo file name(s). A long receipt shot in several photos stores them
  /// top to bottom, joined with "|" (see [imageNamesOf]). Files live in the
  /// app's `receipts/` folder; the absolute path is not stored because iOS
  /// changes it between installs.
  TextColumn get imageName => text()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get rawOcrText => text().withDefault(const Constant(''))();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text()();
  TextColumn get normalizedName => text().unique()();
}

class LineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get receiptId =>
      integer().references(Receipts, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get rawName => text()();
  RealColumn get qty => real()();
  IntColumn get totalCents => integer()();

  /// Pesos added per piece, in centavos. Null means no markup set.
  IntColumn get markupCents => integer().nullable()();

  /// Pieces inside one bought unit. 1 = sold per piece; 10 = a pack of 10,
  /// so the per-piece price is total / (qty * 10).
  IntColumn get piecesPerPack => integer().withDefault(const Constant(1))();
}

/// One purchased item together with its receipt and product.
class Entry {
  Entry(this.item, this.receipt, this.product);
  final LineItem item;
  final Receipt receipt;
  final Product product;

  bool get isPack => item.piecesPerPack > 1;

  /// Price of one piece.
  int get unitCents =>
      unitCentsOf(item.totalCents, item.qty * item.piecesPerPack);

  /// Price of one pack (same as [unitCents] when sold per piece).
  int get packCents => unitCentsOf(item.totalCents, item.qty);

  /// "2" or "2 packs × 10 pcs".
  String get qtyLabel {
    final q = fmtQty(item.qty);
    if (!isPack) return q;
    return '$q pack${item.qty == 1 ? '' : 's'} × ${item.piecesPerPack} pcs';
  }

  int? get sellCents =>
      item.markupCents == null ? null : unitCents + item.markupCents!;
}

class NewItem {
  NewItem({
    required this.name,
    required this.qty,
    required this.totalCents,
    this.markupCents,
    this.productId,
    this.piecesPerPack = 1,
  });
  final int piecesPerPack;
  final String name;
  final double qty;
  final int totalCents;
  final int? markupCents;

  /// Existing product to link to. Null creates or reuses one by name.
  final int? productId;
}

/// The photos of a receipt, top to bottom.
List<String> imageNamesOf(Receipt r) => r.imageName.split('|');

String receiptLabel(Receipt r) {
  final t = r.title?.trim() ?? '';
  return t.isNotEmpty ? t : fmtDateTime(r.capturedAt);
}

@DriftDatabase(tables: [Receipts, Products, LineItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'osnap'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(lineItems, lineItems.piecesPerPack);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      final before = details.versionBefore;
      if (before != null && before < 3) await shortenProductNames();
    },
  );

  Stream<List<Receipt>> watchReceipts() {
    return (select(receipts)..orderBy([
          (r) => OrderingTerm.desc(r.capturedAt),
          (r) => OrderingTerm.desc(r.id),
        ]))
        .watch();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _entriesQuery() {
    return select(lineItems).join([
      innerJoin(receipts, receipts.id.equalsExp(lineItems.receiptId)),
      innerJoin(products, products.id.equalsExp(lineItems.productId)),
    ])..orderBy([
      OrderingTerm.asc(receipts.capturedAt),
      OrderingTerm.asc(lineItems.id),
    ]);
  }

  Entry _toEntry(TypedResult r) => Entry(
    r.readTable(lineItems),
    r.readTable(receipts),
    r.readTable(products),
  );

  /// Every item, oldest first.
  Stream<List<Entry>> watchEntries() =>
      _entriesQuery().watch().map((rows) => rows.map(_toEntry).toList());

  Future<List<Entry>> allEntries() async =>
      (await _entriesQuery().get()).map(_toEntry).toList();

  Future<List<Product>> allProducts() => (select(
    products,
  )..orderBy([(p) => OrderingTerm.asc(p.displayName)])).get();

  /// Pack size last used for each product, keyed by normalised name, so a
  /// repeat scan of the same item starts with the same choice.
  Future<Map<String, int>> lastPackSizes() async {
    return {
      for (final e in await allEntries())
        e.product.normalizedName: e.item.piecesPerPack,
    };
  }

  Future<int> findOrCreateProduct(String name) async {
    final display = name.trim();
    final norm = normalizeName(display);
    final existing = await (select(
      products,
    )..where((p) => p.normalizedName.equals(norm))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(products).insert(
      ProductsCompanion.insert(displayName: display, normalizedName: norm),
    );
  }

  Future<int?> _lastMarkupFor(int productId) async {
    final q =
        select(lineItems).join([
            innerJoin(receipts, receipts.id.equalsExp(lineItems.receiptId)),
          ])
          ..where(
            lineItems.productId.equals(productId) &
                lineItems.markupCents.isNotNull(),
          )
          ..orderBy([
            OrderingTerm.desc(receipts.capturedAt),
            OrderingTerm.desc(lineItems.id),
          ])
          ..limit(1);
    final row = await q.getSingleOrNull();
    return row?.readTable(lineItems).markupCents;
  }

  /// Saves a receipt and its items. An item without a markup inherits the
  /// last markup used for the same product, then [defaultMarkupCents].
  Future<int> saveReceipt({
    required String imageName,
    required DateTime capturedAt,
    String? title,
    String? note,
    String rawOcrText = '',
    required List<NewItem> items,
    int? defaultMarkupCents,
  }) {
    return transaction(() async {
      final receiptId = await into(receipts).insert(
        ReceiptsCompanion.insert(
          imageName: imageName,
          capturedAt: capturedAt,
          title: Value(_blankToNull(title)),
          note: Value(_blankToNull(note)),
          rawOcrText: Value(rawOcrText),
        ),
      );
      for (final item in items) {
        final productId =
            item.productId ?? await findOrCreateProduct(item.name);
        final markup =
            item.markupCents ??
            await _lastMarkupFor(productId) ??
            defaultMarkupCents;
        await into(lineItems).insert(
          LineItemsCompanion.insert(
            receiptId: receiptId,
            productId: productId,
            rawName: item.name.trim(),
            qty: item.qty,
            totalCents: item.totalCents,
            markupCents: Value(markup),
            piecesPerPack: Value(item.piecesPerPack),
          ),
        );
      }
      return receiptId;
    });
  }

  Future<void> updateReceiptMeta(
    int id, {
    String? title,
    String? note,
    required DateTime capturedAt,
  }) {
    return (update(receipts)..where((r) => r.id.equals(id))).write(
      ReceiptsCompanion(
        title: Value(_blankToNull(title)),
        note: Value(_blankToNull(note)),
        capturedAt: Value(capturedAt),
      ),
    );
  }

  Future<void> addItem(int receiptId, NewItem item) async {
    final productId = item.productId ?? await findOrCreateProduct(item.name);
    await into(lineItems).insert(
      LineItemsCompanion.insert(
        receiptId: receiptId,
        productId: productId,
        rawName: item.name.trim(),
        qty: item.qty,
        totalCents: item.totalCents,
        markupCents: Value(item.markupCents),
        piecesPerPack: Value(item.piecesPerPack),
      ),
    );
  }

  Future<void> updateItem(
    int id, {
    required double qty,
    required int totalCents,
    required int? markupCents,
    required int piecesPerPack,
  }) {
    return (update(lineItems)..where((i) => i.id.equals(id))).write(
      LineItemsCompanion(
        qty: Value(qty),
        totalCents: Value(totalCents),
        markupCents: Value(markupCents),
        piecesPerPack: Value(piecesPerPack),
      ),
    );
  }

  Future<void> moveItemToProduct(int itemId, int productId) async {
    await (update(lineItems)..where((i) => i.id.equals(itemId))).write(
      LineItemsCompanion(productId: Value(productId)),
    );
    await _deleteOrphanProducts();
  }

  Future<void> deleteItem(int id) async {
    await (delete(lineItems)..where((i) => i.id.equals(id))).go();
    await _deleteOrphanProducts();
  }

  Future<void> deleteReceipt(int id) async {
    await (delete(receipts)..where((r) => r.id.equals(id))).go();
    await _deleteOrphanProducts();
  }

  /// Returns false when another product already uses that name.
  Future<bool> renameProduct(int id, String name) async {
    final display = name.trim();
    final norm = normalizeName(display);
    final clash =
        await (select(products)..where(
              (p) => p.normalizedName.equals(norm) & p.id.isNotValue(id),
            ))
            .getSingleOrNull();
    if (clash != null) return false;
    await (update(products)..where((p) => p.id.equals(id))).write(
      ProductsCompanion(
        displayName: Value(display),
        normalizedName: Value(norm),
      ),
    );
    return true;
  }

  /// Renames products saved before names were cut at the weight
  /// ("LM CHILIMANSI 80GX72" -> "LM CHILIMANSI 80G"). Products that end up
  /// with the same name are merged, keeping all their price history.
  Future<void> shortenProductNames() => transaction(() async {
    final all = await (select(
      products,
    )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();
    final keepByNorm = <String, int>{
      for (final p in all) p.normalizedName: p.id,
    };
    for (final p in all) {
      final display = cleanItemName(p.displayName);
      final norm = normalizeName(display);
      if (norm.isEmpty || norm == p.normalizedName) continue;
      final keep = keepByNorm[norm];
      if (keep != null && keep != p.id) {
        await (update(lineItems)..where((i) => i.productId.equals(p.id))).write(
          LineItemsCompanion(productId: Value(keep)),
        );
        await (delete(products)..where((x) => x.id.equals(p.id))).go();
      } else {
        await (update(products)..where((x) => x.id.equals(p.id))).write(
          ProductsCompanion(
            displayName: Value(display),
            normalizedName: Value(norm),
          ),
        );
        keepByNorm[norm] = p.id;
      }
      keepByNorm.remove(p.normalizedName);
    }
  });

  Future<void> _deleteOrphanProducts() => customUpdate(
    'DELETE FROM products WHERE id NOT IN '
    '(SELECT product_id FROM line_items)',
    updates: {products},
  );

  // ---- Backup ----

  Future<Map<String, dynamic>> exportJson() async {
    return {
      'version': 1,
      'receipts': [for (final r in await select(receipts).get()) r.toJson()],
      'products': [for (final p in await select(products).get()) p.toJson()],
      'lineItems': [for (final i in await select(lineItems).get()) i.toJson()],
    };
  }

  /// Replaces everything in the database with [data].
  Future<void> importJson(Map<String, dynamic> data) {
    List<Map<String, dynamic>> rows(String key) =>
        (data[key] as List).cast<Map<String, dynamic>>();
    final newReceipts = rows('receipts').map(Receipt.fromJson).toList();
    final newProducts = rows('products').map(Product.fromJson).toList();
    // Backups made before pack sizes existed have no piecesPerPack.
    final newItems = rows('lineItems')
        .map((j) => LineItem.fromJson({'piecesPerPack': 1, ...j}))
        .toList();
    return transaction(() async {
      await delete(lineItems).go();
      await delete(receipts).go();
      await delete(products).go();
      await batch((b) {
        b.insertAll(receipts, newReceipts);
        b.insertAll(products, newProducts);
        b.insertAll(lineItems, newItems);
      });
    });
  }
}

String? _blankToNull(String? s) {
  final t = s?.trim() ?? '';
  return t.isEmpty ? null : t;
}
