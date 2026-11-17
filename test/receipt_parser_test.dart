import 'package:flutter_test/flutter_test.dart';
import 'package:osnap/core/format.dart';
import 'package:osnap/services/receipt_parser.dart';

void main() {
  ParsedItem one(String row) {
    final r = parseReceipt([row]);
    expect(r.items, hasLength(1), reason: row);
    return r.items.single;
  }

  test('name, pcs quantity and price', () {
    final i = one('kopiko blanca 20pcs 200 pesos');
    expect(i.name, 'kopiko blanca');
    expect(i.qty, 20);
    expect(i.totalCents, 20000);
    expect(unitCentsOf(i.totalCents, i.qty), 1000);
  });

  test('name, qty, total', () {
    final i = one('KOPIKO BLANCA 40 440.00');
    expect(i.qty, 40);
    expect(i.totalCents, 44000);
    expect(unitCentsOf(i.totalCents, i.qty), 1100);
  });

  test('quantity first', () {
    final i = one('2 COKE 1.5L 130.00');
    expect(i.name, 'COKE 1.5L');
    expect(i.qty, 2);
    expect(i.totalCents, 13000);
  });

  test('qty, unit price, total', () {
    final i = one('LUCKY ME PANCIT CANTON 6 15.00 90.00');
    expect(i.qty, 6);
    expect(i.totalCents, 9000);
  });

  test('unit price then total', () {
    final i = one('SKYFLAKES 8.50 85.00');
    expect(i.qty, 10);
    expect(i.totalCents, 8500);
  });

  test('price only keeps the size in the name', () {
    final i = one('BEAR BRAND 33G ₱12.50V');
    expect(i.name, 'BEAR BRAND 33G');
    expect(i.qty, 1);
    expect(i.totalCents, 1250);
  });

  test('quantity on the following row', () {
    final r = parseReceipt(['KOPIKO BLANCA 200.00', '20 x 10.00']);
    expect(r.items, hasLength(1));
    expect(r.items.single.qty, 20);
    expect(r.items.single.totalCents, 20000);
  });

  test('name on its own row', () {
    final r = parseReceipt(['NESCAFE CLASSIC', '3 @ 25.00 75.00']);
    expect(r.items, hasLength(1));
    expect(r.items.single.name, 'NESCAFE CLASSIC');
    expect(r.items.single.qty, 3);
    expect(r.items.single.totalCents, 7500);
  });

  test('wholesale receipt: wrapped names and "N PC @ price" rows', () {
    final r = parseReceipt([
      'Sold to: 601718',
      '601718',
      'LM CHILIMANSI 80GX72 29.50',
      '2 PC @ 14.75',
      'MAXX CHEWS MINT/25SX36 75 00',
      '2 PC@ 37.5',
      'DOOWEE DONUT 104.00',
      'CHOCO 10X10',
      '1 PC @ 104',
      'LS CHEESE CAKE 12X10S 80.10',
      '1 PC @ 80.1',
      'P-CRISPS CHEESE 55.60',
      '18GX100 RL',
      '8 PC @ 695',
      'CHEEZY SPICY 22GX105 117.75',
      '15 PC @7.85',
      'PANTENE 3MM 87 60',
      'TDC 13ML(11+1',
      '1 PC @ 87.6',
      'KNORR CHICKEN 7590',
      '10G(12+2)X4',
      '1 PC @ 75.9',
    ]);
    expect(r.items.map((i) => '$i').toList(), [
      'LM CHILIMANSI 80GX72 | qty 2.0 | total 2950',
      'MAXX CHEWS MINT/25SX36 | qty 2.0 | total 7500',
      'DOOWEE DONUT CHOCO 10X10 | qty 1.0 | total 10400',
      'LS CHEESE CAKE 12X10S | qty 1.0 | total 8010',
      'P-CRISPS CHEESE 18GX100 RL | qty 8.0 | total 5560',
      'CHEEZY SPICY 22GX105 | qty 15.0 | total 11775',
      'PANTENE 3MM TDC 13ML(11+1 | qty 1.0 | total 8760',
      'KNORR CHICKEN 10G(12+2)X4 | qty 1.0 | total 7590',
    ]);
  });

  test('skips totals and reads the date', () {
    final r = parseReceipt([
      'SARI SARI STORE',
      'Date: 11/17/2026 10:32',
      'KOPIKO BLANCA 20 200.00',
      'SUBTOTAL 200.00',
      'TOTAL 200.00',
      'CASH 500.00',
      'CHANGE 300.00',
    ]);
    expect(r.items, hasLength(1));
    expect(r.date, DateTime(2026, 11, 17));
  });

  test('dates', () {
    expect(parseDate('2026-11-17'), DateTime(2026, 11, 17));
    expect(parseDate('17/11/2026'), DateTime(2026, 11, 17));
    expect(parseDate('Nov 17, 2026'), DateTime(2026, 11, 17));
    expect(parseDate('KOPIKO 200.00'), isNull);
  });

  test('money helpers', () {
    expect(parseCents('₱1,234.50'), 123450);
    expect(peso(1000), '₱10.00');
    expect(normalizeName('KOPIKO-Blanca  30g!'), 'kopiko blanca 30g');
  });
}
