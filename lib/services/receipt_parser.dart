/// Turns OCR text rows into items. Pure Dart so it can be unit tested.
library;

import 'package:string_similarity/string_similarity.dart';

class ParsedItem {
  ParsedItem({
    required this.name,
    required this.qty,
    required this.totalCents,
    this.packSize,
  });
  String name;
  double qty;
  int totalCents;

  /// Pieces per pack read from the full printed name ("(12+2)" -> 14)
  /// before [cleanItemName] shortened it.
  int? packSize;

  @override
  String toString() => '$name | qty $qty | total $totalCents';
}

class ParsedReceipt {
  ParsedReceipt(
    this.items,
    this.date, {
    this.printedTotalCents,
    this.printedItemCount,
  });
  final List<ParsedItem> items;

  /// Date printed on the receipt, if one was found.
  final DateTime? date;

  /// "TOTAL 4,512.30" / "AMOUNT DUE ..." printed on the receipt, if found.
  final int? printedTotalCents;

  /// "No. of items: 34" / "34 ITEM(S)" printed on the receipt, if found.
  final int? printedItemCount;
}

// Words that never appear in a product row.
final _skipRow = RegExp(
  r'\b(sub\s*-?total|total|amount due|amt due|vatable|vat-?exempt|'
  r'zero rated|tendered|discount|cashier|thank you|invoice|'
  r'official receipt|accred|permit|sold to|no\.? of items?|items? sold)\b',
  caseSensitive: false,
);

// Words of summary and header rows that can also be part of a product name
// ("MAYA HOTCAKE MIX 200G", "SARDINES TIN 155G"). Such rows are only skipped
// when they carry no pack size.
final _skipRowWeak = RegExp(
  r'\b(cash|change|vat|tax|tin|balance|gcash|maya|credit|debit|tel|'
  r'telephone|contact|address|customer)\b',
  caseSensitive: false,
);
final _sizeToken = RegExp(
  r'\d\s*(kg|mg|g|ml|l|ltr|oz|s|pcs?)\b|\d\s*x\s*\d|\(',
  caseSensitive: false,
);

bool _isSkipRow(String line) =>
    _skipRow.hasMatch(line) ||
    (_skipRowWeak.hasMatch(line) && !_sizeToken.hasMatch(line));

final _totalRow = RegExp(
  r'^\W*(grand\s*total|total\s*amount(\s*due)?|total\s*due|amount\s*due|'
  r'amt\s*due|total)\b',
  caseSensitive: false,
);
final _itemCountRow = RegExp(
  r'(?:no\.?\s*of\s*items?|items?\s*(?:sold|count)|total\s*items?)'
  r'\s*[:=]?\s*(\d{1,3})\b|'
  r'\b(\d{1,3})\s*items?(?:\(s\))?(?![a-z])',
  caseSensitive: false,
);

// A row that continues a name: "(40GX10)X20", "18GX100 RL", "10G(12+2)X4".
final _sizeContinuation = RegExp(r'^[\d(]');

/// The product name up to and including its weight; what is printed after
/// the weight (case count, pack content, OCR noise) is dropped:
///   "LM CHILIMANSI 80GX72"             -> "LM CHILIMANSI 80G"
///   "LM KALAMANSI 120GŅ48"             -> "LM KALAMANSI 120G"
///   "KNORR PORK 10G(12+2)X48"          -> "KNORR PORK 10G"
///   "NESCAFE ORIG TWIN P20(40GX10)X20" -> "NESCAFE ORIG TWIN P20 40G"
/// Weights are g, kg, mg, ml and l. A name without one only loses an "X"
/// case count after a size: "MAXX CHEWS MINT/25SX36" -> "MAXX CHEWS MINT/25S".
/// Pack sizes in brackets are read before this, see [ParsedItem.packSize].
String cleanItemName(String name) {
  // The unit may be followed by anything except another plain letter
  // ("80GX72" and "120GŅ48" count, "10GRAMS" or "1 LAYER" do not).
  final weight = RegExp(
    r'\d+(?:[.,]\d+)?\s?(?:kg|mg|ml|ltr|lt|g|l)(?![a-wyz])',
    caseSensitive: false,
  ).firstMatch(name);
  if (weight != null) {
    // "P20(40G" -> "P20 40G": a bracket left open is dropped.
    final before = name
        .substring(0, weight.start)
        .replaceAll(RegExp(r'[(\[]'), ' ');
    final unit = weight[0]!.replaceAll(' ', '');
    return '$before $unit'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  return name
      .replaceAllMapped(
        RegExp(
          r'(\d\s*(?:oz|s|pcs?)|\))\s*x\s*(?:\d+(?![\d.])|$)',
          caseSensitive: false,
        ),
        (m) {
          // Keep "(4X12)": inside brackets it is the pack content.
          final before = name.substring(0, m.start + m[1]!.length);
          final open =
              '('.allMatches(before).length - ')'.allMatches(before).length;
          return open > 0 ? m[0]! : m[1]!;
        },
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// Optional prefix (x @ ₱ php p), a number, optional suffix (pcs, x, or a
// single tax-flag letter such as V/T/N/Z).
final _numToken = RegExp(
  r'^(x|@|₱|php|p)?(\d[\d,]*(?:\.\d+)?)(pcs?|x|[vtnz])?$',
  caseSensitive: false,
);

const _fillers = {
  'x',
  '@',
  'pcs',
  'pc',
  'pcs.',
  'pc.',
  'pesos',
  'peso',
  'php',
  '₱',
  'ea',
  'each',
  '=',
  '*',
  '-',
  ':',
};

// "2 PC @ 14.75" at the end of a row. OCR variants seen on real receipts:
// "1 PC O 83 4", "3 PC a 16.35", "1 PC 78.85", "5 PC @675", and stray text
// in front ("log 2 PC @1975").
final _qtyRow = RegExp(
  r'(?:^|\s)(\d{1,3})\s*pcs?\b\.?\s*[@oa©]?\s*(\d[\d., ]*)$',
  caseSensitive: false,
);

double? _looseNumber(String raw) {
  var t = raw.trim().replaceAll(',', '');
  // "83 4" is 83.4; "23. 85" is 23.85.
  t = t.contains('.') ? t.replaceAll(' ', '') : t.replaceFirst(' ', '.');
  return double.tryParse(t.replaceAll(' ', ''));
}

class _Num {
  _Num(
    this.value, {
    this.hasDecimal = false,
    this.isQty = false,
    this.isUnit = false,
  });
  final double value;
  final bool hasDecimal;
  bool isQty;
  bool isUnit;
}

_Num? _readNum(String token) {
  final m = _numToken.firstMatch(token);
  if (m == null) return null;
  final prefix = (m.group(1) ?? '').toLowerCase();
  final body = m.group(2)!;
  final suffix = (m.group(3) ?? '').toLowerCase();
  final hasDecimal = body.contains('.');
  // "30V" is not a price with a tax flag; only "30.00V" is.
  if (suffix.length == 1 && suffix != 'x' && !hasDecimal) return null;
  // "P20" in "NESCAFE ORIG TWIN P20" is part of the name (the suggested
  // retail price printed on the pack), not the price paid; prices with a
  // bare "P" carry centavos ("P199.90").
  if (prefix == 'p' && !hasDecimal) return null;
  final value = double.tryParse(body.replaceAll(',', ''));
  if (value == null) return null;
  return _Num(
    value,
    hasDecimal: hasDecimal,
    isQty: prefix == 'x' || suffix == 'x' || suffix.startsWith('pc'),
    isUnit: prefix == '@',
  );
}

bool _near(double a, double b) => (a - b).abs() < 0.011;

bool _isWhole(double v) => (v - v.roundToDouble()).abs() < 0.001;

int _letters(String s) => RegExp(r'[A-Za-z]').allMatches(s).length;

ParsedReceipt parseReceipt(List<String> rows) {
  final items = <ParsedItem>[];
  String? pendingName;
  DateTime? date;
  // True while the last item may still get a wrapped name row and a
  // "2 PC @ 14.75" row underneath it.
  var lastOpen = false;
  // Items whose printed total had no decimal point, e.g. "7590".
  final noDecimal = <ParsedItem>{};
  var withDecimal = 0;
  // Set once a "2 PC @ 14.75" row is seen: on such receipts every item has
  // one, so other rows under an open item belong to its name.
  var seenQtyRow = false;
  int? printedTotal;
  int? printedCount;

  for (final raw in rows) {
    // "77. 26" is 77.26.
    final line = raw.trim().replaceAllMapped(
      RegExp(r'(\d)\.\s+(\d{1,2})(?!\d)'),
      (m) => '${m[1]}.${m[2]}',
    );
    if (line.isEmpty) continue;
    date ??= parseDate(line);
    if (printedCount == null) {
      final c = _itemCountRow.firstMatch(line);
      if (c != null) printedCount = int.parse(c.group(1) ?? c.group(2)!);
    }

    if (_isSkipRow(line)) {
      if (printedTotal == null && _totalRow.hasMatch(line)) {
        final money = RegExp(r'(\d[\d,]*\.\d{2})(?!\d)').allMatches(line);
        if (money.isNotEmpty) {
          printedTotal =
              (double.parse(money.last.group(1)!.replaceAll(',', '')) * 100)
                  .round();
        }
      }
      pendingName = null;
      lastOpen = false;
      continue;
    }

    final qtyRow = lastOpen ? _qtyRow.firstMatch(line) : null;
    if (qtyRow != null) {
      final prev = items.last;
      final q = double.parse(qtyRow.group(1)!);
      final eachText = qtyRow.group(2)!;
      final each = _looseNumber(eachText);
      if (pendingName != null) prev.name = '${prev.name} $pendingName';
      if (q > 0) {
        prev.qty = q;
        if (each != null) {
          final printed = prev.totalCents / 100;
          final expected = q * each;
          if ((q != 1 && _near(printed, each)) ||
              _near(printed / 100, expected) ||
              // The item row's total was not a real price (no centavos)
              // and does not fit; "1 PC @ 199.90" is the better reading.
              (noDecimal.contains(prev) &&
                  RegExp(r'\d[.\s]\d').hasMatch(eachText) &&
                  !_near(printed, expected))) {
            // The item row showed the per-piece price, or its total lost
            // the decimal point ("4150" for 41.50).
            prev.totalCents = (expected * 100).round();
            noDecimal.remove(prev);
          }
        }
      }
      seenQtyRow = true;
      lastOpen = false;
      pendingName = null;
      continue;
    }

    // "PC@" and "@7.85" are read as separate tokens.
    final tokens = line.replaceAll('@', ' @ ').trim().split(RegExp(r'\s+'));
    // OCR often reads the decimal point as a space: "75 00" means 75.00.
    if (tokens.length >= 3 &&
        RegExp(r'^\d{2}$').hasMatch(tokens.last) &&
        RegExp(r'^\d{1,4}$').hasMatch(tokens[tokens.length - 2])) {
      final cents = tokens.removeLast();
      tokens[tokens.length - 1] = '${tokens.last}.$cents';
    }
    var start = 0;
    double? qty;
    var qtyFromMarker = false;

    // Quantity at the start: "2 COKE 130.00", "20x KOPIKO", "20 x 10.00".
    final lead = RegExp(
      r'^(\d{1,3})(x|pcs?)?$',
      caseSensitive: false,
    ).firstMatch(tokens.first);
    if (lead != null && tokens.length > 1 && !tokens.first.startsWith('0')) {
      final marked = lead.group(2) != null;
      final next = tokens[1].toLowerCase();
      final nextIsMarker = next == 'x' || next == '@' || next.startsWith('pc');
      if (marked || nextIsMarker || _letters(tokens[1]) > 0) {
        qty = double.parse(lead.group(1)!);
        qtyFromMarker = marked || nextIsMarker;
        start = nextIsMarker ? 2 : 1;
      }
    }

    // Numbers and filler words at the end of the row.
    final nums = <_Num>[];
    var end = tokens.length - 1;
    while (end >= start) {
      final tok = tokens[end];
      final low = tok.toLowerCase();
      final n = _readNum(tok);
      if (n != null) {
        if (end + 1 < tokens.length) {
          final after = tokens[end + 1].toLowerCase();
          if (after.startsWith('pc') || after == 'x') n.isQty = true;
        }
        if (end > start && tokens[end - 1] == '@') n.isUnit = true;
        nums.insert(0, n);
      } else if (!_fillers.contains(low)) {
        break;
      }
      end--;
    }

    var name = tokens
        .sublist(start, end + 1)
        .join(' ')
        .replaceAll(RegExp(r'[\s:\-.,]+$'), '')
        .trim();
    final hasName = _letters(name) >= 2;

    if (nums.isEmpty) {
      // A name on its own row; the numbers may be on the next row.
      // Under an open item even a mostly-numeric row such as "10X10" is
      // the rest of its name.
      final usable = hasName || (lastOpen && name.isNotEmpty);
      if (!usable || qty != null) {
        pendingName = null;
      } else if (pendingName != null &&
          ((lastOpen && seenQtyRow) || _sizeContinuation.hasMatch(name))) {
        // A long name wrapped over several rows:
        //   NESCAFE ORIG TWIN P20
        //   (40GX10)X20
        pendingName = '$pendingName $name';
      } else {
        pendingName = name;
      }
      continue;
    }

    double? unit;
    final rest = <_Num>[];
    for (final n in nums) {
      if (n.isQty && qty == null) {
        qty = n.value;
        qtyFromMarker = true;
      } else if (n.isUnit && unit == null) {
        unit = n.value;
      } else {
        rest.add(n);
      }
    }

    // "10G(12+2)X48 5": a pack-size row under the item with a stray number.
    if (seenQtyRow &&
        lastOpen &&
        hasName &&
        qty == null &&
        unit == null &&
        rest.length == 1 &&
        !rest.single.hasDecimal) {
      pendingName = pendingName == null ? name : '$pendingName $name';
      continue;
    }

    // "20 x 10.00" with nothing else: the number is the per-piece price.
    if (!hasName && qtyFromMarker && unit == null && rest.length == 1) {
      unit = rest.removeLast().value;
    }

    double total;
    if (rest.isEmpty) {
      if (unit == null) {
        pendingName = null;
        continue;
      }
      qty ??= 1;
      total = unit * qty;
    } else {
      total = rest.last.value;
      if (qty == null) {
        if (unit != null && unit > 0 && _isWhole(total / unit)) {
          qty = (total / unit).roundToDouble();
        } else if (rest.length >= 3 &&
            _near(
              rest[rest.length - 3].value * rest[rest.length - 2].value,
              total,
            )) {
          qty = rest[rest.length - 3].value; // qty, unit, total
        } else if (rest.length >= 2) {
          final a = rest[rest.length - 2];
          if (!a.hasDecimal && a.value > 0 && a.value <= 9999) {
            qty = a.value; // name, qty, total
          } else if (a.value > 0 &&
              total >= a.value &&
              _isWhole(total / a.value)) {
            qty = (total / a.value).roundToDouble(); // name, unit, total
          }
        }
      }
      qty ??= 1;
    }
    if (qty <= 0 || total <= 0) {
      pendingName = null;
      continue;
    }

    if (!hasName) {
      if (lastOpen && qtyFromMarker) {
        // Quantity row under the item:
        //   DOOWEE DONUT   104.00
        //   CHOCO 10X10            <- rest of the name
        //   1 PC @ 104             <- this row
        final prev = items.last;
        if (pendingName != null) prev.name = '${prev.name} $pendingName';
        final printed = prev.totalCents / 100;
        prev.qty = qty;
        if (unit != null && qty != 1 && _near(printed, unit)) {
          // The item row showed the per-piece price, not the total.
          prev.totalCents = (total * 100).round();
        } else if (_near(printed / 100, total) ||
            (noDecimal.contains(prev) &&
                (unit != null || rest.last.hasDecimal) &&
                !_near(printed, total))) {
          // The decimal point of the total was lost ("7590" for 75.90), or
          // the item row's number was not a price at all.
          prev.totalCents = (total * 100).round();
          noDecimal.remove(prev);
        }
        lastOpen = false;
        pendingName = null;
        continue;
      }
      if (pendingName == null) continue;
      name = pendingName;
    } else if (pendingName != null && _sizeContinuation.hasMatch(name)) {
      //   NESCAFE ORIG TWIN P20
      //   (40GX10)X20 199.90
      name = '$pendingName $name';
    }
    pendingName = null;
    lastOpen = hasName;
    final item = ParsedItem(
      name: name,
      qty: qty,
      totalCents: (total * 100).round(),
    );
    items.add(item);
    if (rest.isNotEmpty && !rest.last.hasDecimal) {
      noDecimal.add(item);
    } else {
      withDecimal++;
    }
  }
  // On a receipt that prints centavos, a large total without a decimal point
  // is a misread: "7590" was 75.90.
  if (withDecimal >= 3) {
    for (final item in noDecimal) {
      if (item.totalCents >= 100000) {
        item.totalCents = (item.totalCents / 100).round();
      }
    }
  }
  for (final item in items) {
    item.packSize = suggestedPackSize(item.name);
    item.name = cleanItemName(item.name);
  }
  return ParsedReceipt(
    items,
    date,
    printedTotalCents: printedTotal,
    printedItemCount: printedCount,
  );
}

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

DateTime? _valid(int y, int m, int d) {
  if (y < 100) y += 2000;
  if (y < 2000 || y > 2100 || m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

/// Finds a date in a row of text. Slash dates are read month-first (the usual
/// order on Philippine receipts) unless the first number is above 12.
DateTime? parseDate(String line) {
  var m = RegExp(r'\b(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\b').firstMatch(line);
  if (m != null) {
    return _valid(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }
  m = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})\b').firstMatch(line);
  if (m != null) {
    var a = int.parse(m.group(1)!);
    var b = int.parse(m.group(2)!);
    if (a > 12) {
      final t = a;
      a = b;
      b = t;
    }
    return _valid(int.parse(m.group(3)!), a, b);
  }
  m = RegExp(r'\b([A-Za-z]{3})[A-Za-z]*\.?\s+(\d{1,2}),?\s+(\d{4})\b')
      .firstMatch(line);
  if (m != null) {
    final month = _months[m.group(1)!.toLowerCase()];
    if (month != null) {
      return _valid(int.parse(m.group(3)!), month, int.parse(m.group(2)!));
    }
  }
  return null;
}

class ShotMerge {
  ShotMerge(this.toAdd, this.inserts, this.skipped, this.replaceLast);

  /// Items from the new photo that come after everything read so far.
  final List<ParsedItem> toAdd;

  /// Items the new photo shows between two already-listed neighbours (the
  /// earlier photo missed them). Key: index in the existing list to insert
  /// before.
  final Map<int, List<ParsedItem>> inserts;

  /// How many items were dropped because both photos showed them.
  final int skipped;

  /// A fuller reading of the last existing item (it was cut off at the edge
  /// of the previous photo), or null.
  final ParsedItem? replaceLast;
}

String _key(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _sameItem(ParsedItem a, ParsedItem b) {
  final x = _key(a.name);
  final y = _key(b.name);
  if (x.isEmpty || y.isEmpty) return false;
  final similarity = x.similarityTo(y);
  // Same name with a different total is a misread price, not a new item.
  if (similarity >= 0.85) return true;
  if (a.totalCents != b.totalCents) return false;
  final contains =
      (x.length >= 4 && y.contains(x)) || (y.length >= 4 && x.contains(y));
  return contains || similarity >= 0.6;
}

/// Joins a further photo of the same long receipt onto the items read so far.
///
/// Photos overlap by anything from two items to nearly the whole receipt, so
/// the two lists are aligned in order (longest common subsequence). Every
/// item of the new photo inside the overlap is dropped, including misread
/// copies; only what comes after the overlap is added. An item bought again
/// further down the receipt is outside the overlap and is kept.
ShotMerge mergeShot(List<ParsedItem> existing, List<ParsedItem> incoming) {
  final n = existing.length;
  final m = incoming.length;
  // lcs[i][j] = best number of matches using existing[i..] and incoming[j..].
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = _sameItem(existing[i], incoming[j])
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }
  final pairs = <(int, int)>[]; // (existing index, incoming index)
  for (var i = 0, j = 0; i < n && j < m;) {
    if (_sameItem(existing[i], incoming[j]) &&
        lcs[i][j] == lcs[i + 1][j + 1] + 1) {
      pairs.add((i, j));
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }

  // The overlap is the run of matches from the top of the new photo. A match
  // far below the previous one (more than 3 unmatched items apart) is an
  // item bought again, not overlap.
  final overlap = <(int, int)>[];
  for (final pair in pairs) {
    final previousJ = overlap.isEmpty ? -1 : overlap.last.$2;
    if (pair.$2 - previousJ - 1 > 3) break;
    overlap.add(pair);
  }
  if (overlap.isEmpty) {
    return ShotMerge(List.of(incoming), const {}, 0, null);
  }

  final inserts = <int, List<ParsedItem>>{};
  var skipped = overlap.length + overlap.first.$2; // half-visible top rows
  for (var k = 1; k < overlap.length; k++) {
    final (e0, j0) = overlap[k - 1];
    final (e1, j1) = overlap[k];
    final between = incoming.sublist(j0 + 1, j1);
    if (between.isEmpty) continue;
    if (e1 == e0 + 1) {
      // Neighbours in the list so far, yet the new photo shows something
      // between them: the earlier photo missed it.
      inserts[e1] = between;
    } else {
      skipped += between.length; // misread copies of items already listed
    }
  }

  final (lastE, lastJ) = overlap.last;
  ParsedItem? replaceLast;
  if (lastE == n - 1) {
    final old = existing[lastE];
    final fresh = incoming[lastJ];
    // The previous photo may have cut this item off before its second name
    // row or its quantity row.
    if (_key(fresh.name).length > _key(old.name).length ||
        (old.qty == 1 && fresh.qty != 1)) {
      replaceLast = fresh;
    }
  }
  return ShotMerge(incoming.sublist(lastJ + 1), inserts, skipped, replaceLast);
}

/// Pieces inside one pack, read from pack sizes printed in the item name:
///   "KNORR PORK 10G(12+2)"  -> 14  (12 sachets + 2 free)
///   "BB SWAK (33GX8)"       -> 8
///   "PLATI-SHURE (4X12)"    -> 12
/// The case count after the bracket ("X48") may or may not still be there.
/// Only the bracketed form is used. "25GX100" or "10X10" could be grams or a
/// case count, so those return null and the user chooses.
int? suggestedPackSize(String name) {
  final m = RegExp(r'\(([^()]*)\)').firstMatch(name);
  if (m == null) return null;
  final inner = m.group(1)!;
  final plus = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(inner);
  final int size;
  if (plus != null) {
    size = int.parse(plus.group(1)!) + int.parse(plus.group(2)!);
  } else {
    final last = RegExp(r'[xX]\s*(\d+)\s*$').firstMatch(inner);
    if (last == null) return null;
    size = int.parse(last.group(1)!);
  }
  return size > 1 && size <= 500 ? size : null;
}
