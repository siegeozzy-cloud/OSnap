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
      'LM CHILIMANSI 80G | qty 2.0 | total 2950',
      'MAXX CHEWS MINT/25S | qty 2.0 | total 7500',
      'DOOWEE DONUT CHOCO 10X10 | qty 1.0 | total 10400',
      'LS CHEESE CAKE 12X10S | qty 1.0 | total 8010',
      'P-CRISPS CHEESE 18G | qty 8.0 | total 5560',
      'CHEEZY SPICY 22G | qty 15.0 | total 11775',
      'PANTENE 3MM TDC 13ML | qty 1.0 | total 8760',
      'KNORR CHICKEN 10G | qty 1.0 | total 7590',
    ]);
  });

  test('second photo of a long receipt: overlap is not added twice', () {
    final first = parseReceipt([
      'PIATTOS BBQ 40GX80 49.05',
      '3 PC @ 16.35',
      'ARIEL SUNRISE 91.00',
      '66G(6+1)X30',
      '1 PC @ 91',
      'KNORR CHICKEN 75.90', // cut off: no second name row, no quantity row
    ]).items;
    final second = parseReceipt([
      '66G(6+1)X30', // half-visible item at the top of the new photo
      '1 PC @ 91',
      'KNORR CHICKEN 75.90',
      '10G(12+2)X4',
      '2 PC @ 37.95',
      'PIATTOS BBQ 40GX80 49.05', // bought again further down: kept
      '3 PC @ 16.35',
      'SKYFLAKES 85.00',
      '1 PC @ 85',
    ]).items;
    final m = mergeShot(first, second);
    expect(m.skipped, 2);
    expect('${m.replaceLast}', 'KNORR CHICKEN 10G | qty 2.0 | total 7590');
    expect(m.toAdd.map((i) => i.name).toList(), [
      'PIATTOS BBQ 40G',
      'SKYFLAKES',
    ]);
  });

  test('second photo overlapping most of the first, with misreads', () {
    ParsedItem it(String name, int cents, [double qty = 1]) =>
        ParsedItem(name: name, qty: qty, totalCents: cents);
    final first = [
      for (var i = 0; i < 20; i++) it('ITEM NUMBER $i', 1000 + i),
      it('RICHOCO WAFER 48GX60', 6275, 5),
      it('MUCHO COOKIE WHITE 30X10', 7885),
      it('PIATTOS BBQ 40GX80', 4905, 3),
      it('BB SWAK', 8950),
    ];
    final second = [
      it('RICHOCO WAFER 48GX60', 8275, 5), // price misread
      it('MUCHO COOKIE 78 WHITE 30X10', 8500), // name and price misread
      it('PIATTOS BBQ 40GX8o', 4905, 3),
      it('BB SWAK (33GX8)X24', 8950),
      it('CRISPY FRY ORIG 62GX182', 4150, 2),
      it('HAPPY COTTON 10GX100', 2550, 5),
    ];
    final m = mergeShot(first, second);
    expect(m.skipped, 4);
    expect(m.inserts, isEmpty);
    expect(m.replaceLast?.name, 'BB SWAK (33GX8)X24');
    expect(m.toAdd.map((i) => i.name).toList(), [
      'CRISPY FRY ORIG 62GX182',
      'HAPPY COTTON 10GX100',
    ]);
  });

  test('misread quantity rows and pack-size rows', () {
    final r = parseReceipt([
      'LM CHILIMANSI 80GX72 29.50',
      '2 PC @ 14.75',
      'TOPPS SARAP CHOCO 10X10 83 40',
      '1 PC O 83 4',
      'MUCHO COOKIE 78. 85',
      'WHITE 30X10',
      '1 PC 78.85',
      'KNORR PORK 77. 25',
      '10G(12+2)X48 5',
      '1 PC @ 77.25',
      'SUGAR WASHED 1/4KL 39 50',
      'log 2 PC @1975',
      'CRISPY FRY ORIG 62GX182 4150',
      '2 PC @ 20.75',
      'HAPPY COTTON 25 50',
      '10GX100 2010',
      '5 PC @ 5.1',
    ]);
    expect(r.items.map((i) => '$i').toList(), [
      'LM CHILIMANSI 80G | qty 2.0 | total 2950',
      'TOPPS SARAP CHOCO 10X10 | qty 1.0 | total 8340',
      'MUCHO COOKIE WHITE 30X10 | qty 1.0 | total 7885',
      'KNORR PORK 10G | qty 1.0 | total 7725',
      'SUGAR WASHED 1/4KL | qty 2.0 | total 3950',
      'CRISPY FRY ORIG 62G | qty 2.0 | total 4150',
      'HAPPY COTTON 10G | qty 5.0 | total 2550',
    ]);
  });

  test('name keeps only name and weight', () {
    expect(cleanItemName('Kopiko blanca 45gX25'), 'Kopiko blanca 45g');
    expect(cleanItemName('LM CHILIMANSI 80GX72'), 'LM CHILIMANSI 80G');
    expect(cleanItemName('LM KALAMANSI 120GŅ48'), 'LM KALAMANSI 120G');
    expect(cleanItemName('KNORR PORK 10G(12+2)X48'), 'KNORR PORK 10G');
    expect(
      cleanItemName('NESCAFE ORIG TWIN P20(40GX10)X20'),
      'NESCAFE ORIG TWIN P20 40G',
    );
    expect(cleanItemName('BB SWAK (33GX8)X24'), 'BB SWAK 33G');
    expect(cleanItemName('DOWNY SUNRISE 75ML(6+1)X25'), 'DOWNY SUNRISE 75ML');
    expect(cleanItemName('CRACKLING 25GX100 L'), 'CRACKLING 25G');
    expect(cleanItemName('COKE 1.5L'), 'COKE 1.5L');
    expect(cleanItemName('BEAR BRAND 33G'), 'BEAR BRAND 33G');
    expect(cleanItemName('MAXX CHEWS MINT/25SX36'), 'MAXX CHEWS MINT/25S');
    expect(cleanItemName('PLATI-SHURE (4X12)X200'), 'PLATI-SHURE (4X12)');
    expect(
      cleanItemName('DOOWEE DONUT CHOCO 10X10'),
      'DOOWEE DONUT CHOCO 10X10',
    );
    expect(cleanItemName('SUGAR WASHED 1/4KL'), 'SUGAR WASHED 1/4KL');
    expect(one('Kopiko blanca 45gX25 112.50').name, 'Kopiko blanca 45g');
  });

  test('pack size is read before the name is shortened', () {
    final r = parseReceipt([
      'KNORR PORK 77.25',
      '10G(12+2)X48',
      '1 PC @ 77.25',
    ]);
    expect(r.items.single.name, 'KNORR PORK 10G');
    expect(r.items.single.packSize, 14);
  });

  group('long Nescafe name with "P20"', () {
    const before = ['LM CHILIMANSI 80GX72 29.50', '2 PC @ 14.75'];
    const after = ['SKYFLAKES 85.00', '1 PC @ 85'];
    const want = [
      'LM CHILIMANSI 80G | qty 2.0 | total 2950',
      'NESCAFE ORIG TWIN P20 40G | qty 1.0 | total 19990',
      'SKYFLAKES | qty 1.0 | total 8500',
    ];
    List<String> run(List<String> rows) =>
        parseReceipt([...before, ...rows, ...after]).items
            .map((i) => '$i')
            .toList();

    test('price on the first row', () {
      expect(
        run(['NESCAFE ORIG TWIN 199.90', 'P20(40GX10)X20', '1 PC @ 199.9']),
        [want[0], 'NESCAFE ORIG TWIN P20 40G | qty 1.0 | total 19990', want[2]],
      );
    });
    test('name ends in P20 and the price is lost', () {
      final r = run(['NESCAFE ORIG TWIN P20', '(40GX10)X20', '1 PC @ 199.9']);
      expect(r, hasLength(3));
      expect(r[1], 'NESCAFE ORIG TWIN P20 40G | qty 1.0 | total 19990');
    });
    test('price on the wrapped row', () {
      final r = run([
        'NESCAFE ORIG TWIN P20',
        '(40GX10)X20 199.90',
        '1 PC @ 199.9',
      ]);
      expect(r, [
        want[0],
        'NESCAFE ORIG TWIN P20 40G | qty 1.0 | total 19990',
        want[2],
      ]);
    });
    test('P20 and price on one row', () {
      final r = run([
        'NESCAFE ORIG TWIN P20 199.90',
        '(40GX10)X20',
        '1 PC @ 199.9',
      ]);
      expect(r, [
        want[0],
        'NESCAFE ORIG TWIN P20 40G | qty 1.0 | total 19990',
        want[2],
      ]);
    });
  });

  test('product names that contain summary words are kept', () {
    final r = parseReceipt([
      'MAYA HOTCAKE MIX 200G 45.50',
      '1 PC @ 45.5',
      'SARDINES TIN 155G 22.00',
      '1 PC @ 22',
      'SUBTOTAL 67.50',
      'TOTAL 67.50',
      'CASH 100.00',
      'CHANGE 32.50',
      'No. of items: 2',
    ]);
    expect(r.items.map((i) => i.name).toList(), [
      'MAYA HOTCAKE MIX 200G',
      'SARDINES TIN 155G',
    ]);
    expect(r.printedTotalCents, 6750);
    expect(r.printedItemCount, 2);
  });

  test('a summary row closes the last item', () {
    final r = parseReceipt([
      'KOPIKO BLANCA 30GX24 112.50',
      'TOTAL 112.50',
      '1 PC @ 9999.99',
    ]);
    expect(r.items.single.totalCents, 11250);
  });

  test('pack size printed in the name', () {
    expect(suggestedPackSize('KNORR PORK 10G(12+2)X48'), 14);
    expect(suggestedPackSize('MAGIC 8G(17+1)X60'), 18);
    expect(suggestedPackSize('DOWNY SUNRISE 75ML(6+1)X25'), 7);
    expect(suggestedPackSize('BB SWAK (33GX8)X24'), 8);
    expect(suggestedPackSize('NESCAFE ORIG TWIN P20(40GX10)X20'), 10);
    expect(suggestedPackSize('PLATI-SHURE (4X12)X200'), 12);
    expect(suggestedPackSize('CRACKLING 25GX100 L'), isNull);
    expect(suggestedPackSize('DOOWEE DONUT CHOCO 10X10'), isNull);
    expect(suggestedPackSize('KOPIKO BLANCA'), isNull);
    expect(suggestedPackSize('KNORR PORK 10G(12+2)'), 14);
    expect(suggestedPackSize('BB SWAK (33GX8)'), 8);
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
