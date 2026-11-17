/// Turns OCR text rows into items. Pure Dart so it can be unit tested.
library;

class ParsedItem {
  ParsedItem({required this.name, required this.qty, required this.totalCents});
  String name;
  double qty;
  int totalCents;

  @override
  String toString() => '$name | qty $qty | total $totalCents';
}

class ParsedReceipt {
  ParsedReceipt(this.items, this.date);
  final List<ParsedItem> items;

  /// Date printed on the receipt, if one was found.
  final DateTime? date;
}

final _skipRow = RegExp(
  r'\b(sub\s*-?total|total|amount due|amt due|cash|change|vat|vatable|'
  r'vat-?exempt|zero rated|tax|tin|tendered|discount|balance|cashier|'
  r'thank you|gcash|maya|credit|debit|invoice|official receipt|'
  r'tel|telephone|contact|accred|permit|sold to|address|customer)\b',
  caseSensitive: false,
);

// Optional prefix (x @ ₱ php p), a number, optional suffix (pcs, x, or a
// single tax-flag letter such as V/T/N/Z).
final _numToken = RegExp(
  r'^(x|@|₱|php|p)?(\d[\d,]*(?:\.\d+)?)(pcs?|x|[vtnz])?$',
  caseSensitive: false,
);

const _fillers = {
  'x', '@', 'pcs', 'pc', 'pcs.', 'pc.', 'pesos', 'peso', 'php', '₱', 'ea',
  'each', '=', '*', '-', ':',
};

class _Num {
  _Num(this.value, {this.hasDecimal = false, this.isQty = false, this.isUnit = false});
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

  for (final raw in rows) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    date ??= parseDate(line);

    if (_skipRow.hasMatch(line)) {
      pendingName = null;
      continue;
    }

    // "PC@" and "@7.85" are read as separate tokens.
    final tokens = line
        .replaceAll('@', ' @ ')
        .trim()
        .split(RegExp(r'\s+'));
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
    final lead = RegExp(r'^(\d{1,3})(x|pcs?)?$', caseSensitive: false)
        .firstMatch(tokens.first);
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
      pendingName = hasName && qty == null ? name : null;
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
            _near(rest[rest.length - 3].value * rest[rest.length - 2].value,
                total)) {
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
        } else if (_near(printed / 100, total)) {
          // The decimal point of the total was lost ("7590" for 75.90).
          prev.totalCents = (total * 100).round();
          noDecimal.remove(prev);
        }
        lastOpen = false;
        pendingName = null;
        continue;
      }
      if (pendingName == null) continue;
      name = pendingName;
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
  return ParsedReceipt(items, date);
}

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
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
  m = RegExp(
    r'\b([A-Za-z]{3})[A-Za-z]*\.?\s+(\d{1,2}),?\s+(\d{4})\b',
  ).firstMatch(line);
  if (m != null) {
    final month = _months[m.group(1)!.toLowerCase()];
    if (month != null) {
      return _valid(int.parse(m.group(3)!), month, int.parse(m.group(2)!));
    }
  }
  return null;
}
