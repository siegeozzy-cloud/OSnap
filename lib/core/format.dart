import 'package:intl/intl.dart';

/// Money is always stored as integer centavos (₱10.50 == 1050).

final _peso = NumberFormat.currency(
  locale: 'en_US',
  symbol: '₱',
  decimalDigits: 2,
);

String peso(int cents) => _peso.format(cents / 100);

/// "+₱1.00", "−₱0.50" or "₱0.00".
String signedPeso(int cents) {
  final sign = cents > 0 ? '+' : (cents < 0 ? '−' : '');
  return '$sign${peso(cents.abs())}';
}

/// Plain number for text fields, e.g. 1050 -> "10.50", 1000 -> "10".
String centsToInput(int cents) {
  final v = cents / 100;
  return cents % 100 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

/// Parses "₱1,234.50" / "1234.5" / "200" into centavos. Null if not a number.
int? parseCents(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  final v = double.tryParse(cleaned);
  if (v == null) return null;
  return (v * 100).round();
}

double? parseQty(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

String fmtQty(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
}

String fmtDate(DateTime d) => DateFormat('MMM d, y').format(d);

String fmtDateTime(DateTime d) => DateFormat('MMM d, y • h:mm a').format(d);

/// Per-piece price in centavos.
int unitCentsOf(int totalCents, double qty) =>
    qty <= 0 ? totalCents : (totalCents / qty).round();

/// Key used to recognise the same product across receipts.
String normalizeName(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String percentChange(int oldCents, int newCents) {
  if (oldCents == 0) return '';
  final pct = (newCents - oldCents) / oldCents * 100;
  final sign = pct > 0 ? '+' : (pct < 0 ? '−' : '');
  return '$sign${pct.abs().toStringAsFixed(1)}%';
}
