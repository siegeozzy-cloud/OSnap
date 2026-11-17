// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageNameMeta = const VerificationMeta(
    'imageName',
  );
  @override
  late final GeneratedColumn<String> imageName = GeneratedColumn<String>(
    'image_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawOcrTextMeta = const VerificationMeta(
    'rawOcrText',
  );
  @override
  late final GeneratedColumn<String> rawOcrText = GeneratedColumn<String>(
    'raw_ocr_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    note,
    imageName,
    capturedAt,
    rawOcrText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Receipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('image_name')) {
      context.handle(
        _imageNameMeta,
        imageName.isAcceptableOrUnknown(data['image_name']!, _imageNameMeta),
      );
    } else if (isInserting) {
      context.missing(_imageNameMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('raw_ocr_text')) {
      context.handle(
        _rawOcrTextMeta,
        rawOcrText.isAcceptableOrUnknown(
          data['raw_ocr_text']!,
          _rawOcrTextMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      imageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_name'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      rawOcrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_ocr_text'],
      )!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final int id;
  final String? title;
  final String? note;

  /// File name only. The file lives in the app's `receipts/` folder; the
  /// absolute path is not stored because iOS changes it between installs.
  final String imageName;
  final DateTime capturedAt;
  final String rawOcrText;
  const Receipt({
    required this.id,
    this.title,
    this.note,
    required this.imageName,
    required this.capturedAt,
    required this.rawOcrText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['image_name'] = Variable<String>(imageName);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['raw_ocr_text'] = Variable<String>(rawOcrText);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      imageName: Value(imageName),
      capturedAt: Value(capturedAt),
      rawOcrText: Value(rawOcrText),
    );
  }

  factory Receipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      imageName: serializer.fromJson<String>(json['imageName']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      rawOcrText: serializer.fromJson<String>(json['rawOcrText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'note': serializer.toJson<String?>(note),
      'imageName': serializer.toJson<String>(imageName),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'rawOcrText': serializer.toJson<String>(rawOcrText),
    };
  }

  Receipt copyWith({
    int? id,
    Value<String?> title = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? imageName,
    DateTime? capturedAt,
    String? rawOcrText,
  }) => Receipt(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    note: note.present ? note.value : this.note,
    imageName: imageName ?? this.imageName,
    capturedAt: capturedAt ?? this.capturedAt,
    rawOcrText: rawOcrText ?? this.rawOcrText,
  );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      imageName: data.imageName.present ? data.imageName.value : this.imageName,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      rawOcrText: data.rawOcrText.present
          ? data.rawOcrText.value
          : this.rawOcrText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('imageName: $imageName, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rawOcrText: $rawOcrText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, note, imageName, capturedAt, rawOcrText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.imageName == this.imageName &&
          other.capturedAt == this.capturedAt &&
          other.rawOcrText == this.rawOcrText);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String?> note;
  final Value<String> imageName;
  final Value<DateTime> capturedAt;
  final Value<String> rawOcrText;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.imageName = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rawOcrText = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    required String imageName,
    required DateTime capturedAt,
    this.rawOcrText = const Value.absent(),
  }) : imageName = Value(imageName),
       capturedAt = Value(capturedAt);
  static Insertable<Receipt> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? imageName,
    Expression<DateTime>? capturedAt,
    Expression<String>? rawOcrText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (imageName != null) 'image_name': imageName,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rawOcrText != null) 'raw_ocr_text': rawOcrText,
    });
  }

  ReceiptsCompanion copyWith({
    Value<int>? id,
    Value<String?>? title,
    Value<String?>? note,
    Value<String>? imageName,
    Value<DateTime>? capturedAt,
    Value<String>? rawOcrText,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      imageName: imageName ?? this.imageName,
      capturedAt: capturedAt ?? this.capturedAt,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (imageName.present) {
      map['image_name'] = Variable<String>(imageName.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (rawOcrText.present) {
      map['raw_ocr_text'] = Variable<String>(rawOcrText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('imageName: $imageName, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rawOcrText: $rawOcrText')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, displayName, normalizedName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String displayName;
  final String normalizedName;
  const Product({
    required this.id,
    required this.displayName,
    required this.normalizedName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['normalized_name'] = Variable<String>(normalizedName);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      normalizedName: Value(normalizedName),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'normalizedName': serializer.toJson<String>(normalizedName),
    };
  }

  Product copyWith({int? id, String? displayName, String? normalizedName}) =>
      Product(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        normalizedName: normalizedName ?? this.normalizedName,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('normalizedName: $normalizedName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, normalizedName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.normalizedName == this.normalizedName);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String> normalizedName;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.normalizedName = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    required String normalizedName,
  }) : displayName = Value(displayName),
       normalizedName = Value(normalizedName);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? normalizedName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (normalizedName != null) 'normalized_name': normalizedName,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String>? normalizedName,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      normalizedName: normalizedName ?? this.normalizedName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('normalizedName: $normalizedName')
          ..write(')'))
        .toString();
  }
}

class $LineItemsTable extends LineItems
    with TableInfo<$LineItemsTable, LineItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<int> receiptId = GeneratedColumn<int>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _rawNameMeta = const VerificationMeta(
    'rawName',
  );
  @override
  late final GeneratedColumn<String> rawName = GeneratedColumn<String>(
    'raw_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCentsMeta = const VerificationMeta(
    'totalCents',
  );
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
    'total_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _markupCentsMeta = const VerificationMeta(
    'markupCents',
  );
  @override
  late final GeneratedColumn<int> markupCents = GeneratedColumn<int>(
    'markup_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _piecesPerPackMeta = const VerificationMeta(
    'piecesPerPack',
  );
  @override
  late final GeneratedColumn<int> piecesPerPack = GeneratedColumn<int>(
    'pieces_per_pack',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    productId,
    rawName,
    qty,
    totalCents,
    markupCents,
    piecesPerPack,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'line_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LineItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('raw_name')) {
      context.handle(
        _rawNameMeta,
        rawName.isAcceptableOrUnknown(data['raw_name']!, _rawNameMeta),
      );
    } else if (isInserting) {
      context.missing(_rawNameMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('total_cents')) {
      context.handle(
        _totalCentsMeta,
        totalCents.isAcceptableOrUnknown(data['total_cents']!, _totalCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalCentsMeta);
    }
    if (data.containsKey('markup_cents')) {
      context.handle(
        _markupCentsMeta,
        markupCents.isAcceptableOrUnknown(
          data['markup_cents']!,
          _markupCentsMeta,
        ),
      );
    }
    if (data.containsKey('pieces_per_pack')) {
      context.handle(
        _piecesPerPackMeta,
        piecesPerPack.isAcceptableOrUnknown(
          data['pieces_per_pack']!,
          _piecesPerPackMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LineItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      rawName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_name'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      )!,
      totalCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cents'],
      )!,
      markupCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}markup_cents'],
      ),
      piecesPerPack: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pieces_per_pack'],
      )!,
    );
  }

  @override
  $LineItemsTable createAlias(String alias) {
    return $LineItemsTable(attachedDatabase, alias);
  }
}

class LineItem extends DataClass implements Insertable<LineItem> {
  final int id;
  final int receiptId;
  final int productId;
  final String rawName;
  final double qty;
  final int totalCents;

  /// Pesos added per piece, in centavos. Null means no markup set.
  final int? markupCents;

  /// Pieces inside one bought unit. 1 = sold per piece; 10 = a pack of 10,
  /// so the per-piece price is total / (qty * 10).
  final int piecesPerPack;
  const LineItem({
    required this.id,
    required this.receiptId,
    required this.productId,
    required this.rawName,
    required this.qty,
    required this.totalCents,
    this.markupCents,
    required this.piecesPerPack,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['receipt_id'] = Variable<int>(receiptId);
    map['product_id'] = Variable<int>(productId);
    map['raw_name'] = Variable<String>(rawName);
    map['qty'] = Variable<double>(qty);
    map['total_cents'] = Variable<int>(totalCents);
    if (!nullToAbsent || markupCents != null) {
      map['markup_cents'] = Variable<int>(markupCents);
    }
    map['pieces_per_pack'] = Variable<int>(piecesPerPack);
    return map;
  }

  LineItemsCompanion toCompanion(bool nullToAbsent) {
    return LineItemsCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      productId: Value(productId),
      rawName: Value(rawName),
      qty: Value(qty),
      totalCents: Value(totalCents),
      markupCents: markupCents == null && nullToAbsent
          ? const Value.absent()
          : Value(markupCents),
      piecesPerPack: Value(piecesPerPack),
    );
  }

  factory LineItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LineItem(
      id: serializer.fromJson<int>(json['id']),
      receiptId: serializer.fromJson<int>(json['receiptId']),
      productId: serializer.fromJson<int>(json['productId']),
      rawName: serializer.fromJson<String>(json['rawName']),
      qty: serializer.fromJson<double>(json['qty']),
      totalCents: serializer.fromJson<int>(json['totalCents']),
      markupCents: serializer.fromJson<int?>(json['markupCents']),
      piecesPerPack: serializer.fromJson<int>(json['piecesPerPack']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'receiptId': serializer.toJson<int>(receiptId),
      'productId': serializer.toJson<int>(productId),
      'rawName': serializer.toJson<String>(rawName),
      'qty': serializer.toJson<double>(qty),
      'totalCents': serializer.toJson<int>(totalCents),
      'markupCents': serializer.toJson<int?>(markupCents),
      'piecesPerPack': serializer.toJson<int>(piecesPerPack),
    };
  }

  LineItem copyWith({
    int? id,
    int? receiptId,
    int? productId,
    String? rawName,
    double? qty,
    int? totalCents,
    Value<int?> markupCents = const Value.absent(),
    int? piecesPerPack,
  }) => LineItem(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    productId: productId ?? this.productId,
    rawName: rawName ?? this.rawName,
    qty: qty ?? this.qty,
    totalCents: totalCents ?? this.totalCents,
    markupCents: markupCents.present ? markupCents.value : this.markupCents,
    piecesPerPack: piecesPerPack ?? this.piecesPerPack,
  );
  LineItem copyWithCompanion(LineItemsCompanion data) {
    return LineItem(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      productId: data.productId.present ? data.productId.value : this.productId,
      rawName: data.rawName.present ? data.rawName.value : this.rawName,
      qty: data.qty.present ? data.qty.value : this.qty,
      totalCents: data.totalCents.present
          ? data.totalCents.value
          : this.totalCents,
      markupCents: data.markupCents.present
          ? data.markupCents.value
          : this.markupCents,
      piecesPerPack: data.piecesPerPack.present
          ? data.piecesPerPack.value
          : this.piecesPerPack,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LineItem(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('productId: $productId, ')
          ..write('rawName: $rawName, ')
          ..write('qty: $qty, ')
          ..write('totalCents: $totalCents, ')
          ..write('markupCents: $markupCents, ')
          ..write('piecesPerPack: $piecesPerPack')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    receiptId,
    productId,
    rawName,
    qty,
    totalCents,
    markupCents,
    piecesPerPack,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LineItem &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.productId == this.productId &&
          other.rawName == this.rawName &&
          other.qty == this.qty &&
          other.totalCents == this.totalCents &&
          other.markupCents == this.markupCents &&
          other.piecesPerPack == this.piecesPerPack);
}

class LineItemsCompanion extends UpdateCompanion<LineItem> {
  final Value<int> id;
  final Value<int> receiptId;
  final Value<int> productId;
  final Value<String> rawName;
  final Value<double> qty;
  final Value<int> totalCents;
  final Value<int?> markupCents;
  final Value<int> piecesPerPack;
  const LineItemsCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.productId = const Value.absent(),
    this.rawName = const Value.absent(),
    this.qty = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.markupCents = const Value.absent(),
    this.piecesPerPack = const Value.absent(),
  });
  LineItemsCompanion.insert({
    this.id = const Value.absent(),
    required int receiptId,
    required int productId,
    required String rawName,
    required double qty,
    required int totalCents,
    this.markupCents = const Value.absent(),
    this.piecesPerPack = const Value.absent(),
  }) : receiptId = Value(receiptId),
       productId = Value(productId),
       rawName = Value(rawName),
       qty = Value(qty),
       totalCents = Value(totalCents);
  static Insertable<LineItem> custom({
    Expression<int>? id,
    Expression<int>? receiptId,
    Expression<int>? productId,
    Expression<String>? rawName,
    Expression<double>? qty,
    Expression<int>? totalCents,
    Expression<int>? markupCents,
    Expression<int>? piecesPerPack,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (productId != null) 'product_id': productId,
      if (rawName != null) 'raw_name': rawName,
      if (qty != null) 'qty': qty,
      if (totalCents != null) 'total_cents': totalCents,
      if (markupCents != null) 'markup_cents': markupCents,
      if (piecesPerPack != null) 'pieces_per_pack': piecesPerPack,
    });
  }

  LineItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? receiptId,
    Value<int>? productId,
    Value<String>? rawName,
    Value<double>? qty,
    Value<int>? totalCents,
    Value<int?>? markupCents,
    Value<int>? piecesPerPack,
  }) {
    return LineItemsCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      productId: productId ?? this.productId,
      rawName: rawName ?? this.rawName,
      qty: qty ?? this.qty,
      totalCents: totalCents ?? this.totalCents,
      markupCents: markupCents ?? this.markupCents,
      piecesPerPack: piecesPerPack ?? this.piecesPerPack,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<int>(receiptId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (rawName.present) {
      map['raw_name'] = Variable<String>(rawName.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (markupCents.present) {
      map['markup_cents'] = Variable<int>(markupCents.value);
    }
    if (piecesPerPack.present) {
      map['pieces_per_pack'] = Variable<int>(piecesPerPack.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LineItemsCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('productId: $productId, ')
          ..write('rawName: $rawName, ')
          ..write('qty: $qty, ')
          ..write('totalCents: $totalCents, ')
          ..write('markupCents: $markupCents, ')
          ..write('piecesPerPack: $piecesPerPack')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $LineItemsTable lineItems = $LineItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    receipts,
    products,
    lineItems,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'receipts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('line_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<String?> note,
  required String imageName,
  required DateTime capturedAt,
  Value<String> rawOcrText,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<String?> note,
  Value<String> imageName,
  Value<DateTime> capturedAt,
  Value<String> rawOcrText,
});

final class $$ReceiptsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LineItemsTable, List<LineItem>>
  _lineItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lineItems,
    aliasName: 'receipts__id__line_items__receipt_id',
  );

  $$LineItemsTableProcessedTableManager get lineItemsRefs {
    final manager = $$LineItemsTableTableManager(
      $_db,
      $_db.lineItems,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lineItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageName => $composableBuilder(
    column: $table.imageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> lineItemsRefs(
    Expression<bool> Function($$LineItemsTableFilterComposer f) f,
  ) {
    final $$LineItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lineItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LineItemsTableFilterComposer(
            $db: $db,
            $table: $db.lineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageName => $composableBuilder(
    column: $table.imageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get imageName =>
      $composableBuilder(column: $table.imageName, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawOcrText => $composableBuilder(
    column: $table.rawOcrText,
    builder: (column) => column,
  );

  Expression<T> lineItemsRefs<T extends Object>(
    Expression<T> Function($$LineItemsTableAnnotationComposer a) f,
  ) {
    final $$LineItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lineItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LineItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.lineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTable,
          Receipt,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (Receipt, $$ReceiptsTableReferences),
          Receipt,
          PrefetchHooks Function({bool lineItemsRefs})
        > {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> imageName = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String> rawOcrText = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                title: title,
                note: note,
                imageName: imageName,
                capturedAt: capturedAt,
                rawOcrText: rawOcrText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String imageName,
                required DateTime capturedAt,
                Value<String> rawOcrText = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                id: id,
                title: title,
                note: note,
                imageName: imageName,
                capturedAt: capturedAt,
                rawOcrText: rawOcrText,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptsTable, Receipt>(table),
                  $$ReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lineItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lineItemsRefs) db.lineItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lineItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      Receipt,
                      $ReceiptsTable,
                      LineItem,
                      $LineItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ReceiptsTableReferences
                          ._lineItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ReceiptsTableReferences(
                        db,
                        table,
                        p0,
                      ).lineItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'receipt_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTable,
      Receipt,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (Receipt, $$ReceiptsTableReferences),
      Receipt,
      PrefetchHooks Function({bool lineItemsRefs})
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  required String displayName,
  required String normalizedName,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> displayName,
  Value<String> normalizedName,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LineItemsTable, List<LineItem>>
  _lineItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lineItems,
    aliasName: 'products__id__line_items__product_id',
  );

  $$LineItemsTableProcessedTableManager get lineItemsRefs {
    final manager = $$LineItemsTableTableManager(
      $_db,
      $_db.lineItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lineItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> lineItemsRefs(
    Expression<bool> Function($$LineItemsTableFilterComposer f) f,
  ) {
    final $$LineItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lineItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LineItemsTableFilterComposer(
            $db: $db,
            $table: $db.lineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  Expression<T> lineItemsRefs<T extends Object>(
    Expression<T> Function($$LineItemsTableAnnotationComposer a) f,
  ) {
    final $$LineItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lineItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LineItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.lineItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool lineItemsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                displayName: displayName,
                normalizedName: normalizedName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                required String normalizedName,
              }) => ProductsCompanion.insert(
                id: id,
                displayName: displayName,
                normalizedName: normalizedName,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, Product>(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lineItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lineItemsRefs) db.lineItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lineItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      Product,
                      $ProductsTable,
                      LineItem,
                      $LineItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableReferences
                          ._lineItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProductsTableReferences(
                        db,
                        table,
                        p0,
                      ).lineItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'product_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool lineItemsRefs})
    >;
typedef $$LineItemsTableCreateCompanionBuilder = LineItemsCompanion Function({
  Value<int> id,
  required int receiptId,
  required int productId,
  required String rawName,
  required double qty,
  required int totalCents,
  Value<int?> markupCents,
  Value<int> piecesPerPack,
});
typedef $$LineItemsTableUpdateCompanionBuilder = LineItemsCompanion Function({
  Value<int> id,
  Value<int> receiptId,
  Value<int> productId,
  Value<String> rawName,
  Value<double> qty,
  Value<int> totalCents,
  Value<int?> markupCents,
  Value<int> piecesPerPack,
});

final class $$LineItemsTableReferences
    extends BaseReferences<_$AppDatabase, $LineItemsTable, LineItem> {
  $$LineItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias('line_items__receipt_id__receipts__id');

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<int>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('line_items__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LineItemsTable> {
  $$LineItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get markupCents => $composableBuilder(
    column: $table.markupCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get piecesPerPack => $composableBuilder(
    column: $table.piecesPerPack,
    builder: (column) => ColumnFilters(column),
  );

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LineItemsTable> {
  $$LineItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get markupCents => $composableBuilder(
    column: $table.markupCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get piecesPerPack => $composableBuilder(
    column: $table.piecesPerPack,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LineItemsTable> {
  $$LineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawName =>
      $composableBuilder(column: $table.rawName, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get markupCents => $composableBuilder(
    column: $table.markupCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get piecesPerPack => $composableBuilder(
    column: $table.piecesPerPack,
    builder: (column) => column,
  );

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LineItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LineItemsTable,
          LineItem,
          $$LineItemsTableFilterComposer,
          $$LineItemsTableOrderingComposer,
          $$LineItemsTableAnnotationComposer,
          $$LineItemsTableCreateCompanionBuilder,
          $$LineItemsTableUpdateCompanionBuilder,
          (LineItem, $$LineItemsTableReferences),
          LineItem,
          PrefetchHooks Function({bool receiptId, bool productId})
        > {
  $$LineItemsTableTableManager(_$AppDatabase db, $LineItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LineItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LineItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> receiptId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> rawName = const Value.absent(),
                Value<double> qty = const Value.absent(),
                Value<int> totalCents = const Value.absent(),
                Value<int?> markupCents = const Value.absent(),
                Value<int> piecesPerPack = const Value.absent(),
              }) => LineItemsCompanion(
                id: id,
                receiptId: receiptId,
                productId: productId,
                rawName: rawName,
                qty: qty,
                totalCents: totalCents,
                markupCents: markupCents,
                piecesPerPack: piecesPerPack,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int receiptId,
                required int productId,
                required String rawName,
                required double qty,
                required int totalCents,
                Value<int?> markupCents = const Value.absent(),
                Value<int> piecesPerPack = const Value.absent(),
              }) => LineItemsCompanion.insert(
                id: id,
                receiptId: receiptId,
                productId: productId,
                rawName: rawName,
                qty: qty,
                totalCents: totalCents,
                markupCents: markupCents,
                piecesPerPack: piecesPerPack,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LineItemsTable, LineItem>(table),
                  $$LineItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.receiptId,
                        referencedTable: $$LineItemsTableReferences
                            ._receiptIdTable(db),
                        referencedColumn: $$LineItemsTableReferences
                            ._receiptIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$LineItemsTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$LineItemsTableReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LineItemsTable,
      LineItem,
      $$LineItemsTableFilterComposer,
      $$LineItemsTableOrderingComposer,
      $$LineItemsTableAnnotationComposer,
      $$LineItemsTableCreateCompanionBuilder,
      $$LineItemsTableUpdateCompanionBuilder,
      (LineItem, $$LineItemsTableReferences),
      LineItem,
      PrefetchHooks Function({bool receiptId, bool productId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$LineItemsTableTableManager get lineItems =>
      $$LineItemsTableTableManager(_db, _db.lineItems);
}
