import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/format.dart';
import '../data/database.dart';

class BackupService {
  BackupService(this.db, this.imagesDir);
  final AppDatabase db;
  final Directory imagesDir;

  String _stamp() => DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());

  /// Writes a .zip holding all records and receipt photos. Returns the file.
  Future<File> createBackup() async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile.string('data.json', jsonEncode(await db.exportJson())),
    );
    await for (final entity in imagesDir.list()) {
      if (entity is File) {
        archive.addFile(
          ArchiveFile.bytes(
            'images/${p.basename(entity.path)}',
            await entity.readAsBytes(),
          ),
        );
      }
    }
    final tmp = await getTemporaryDirectory();
    final file = File(p.join(tmp.path, 'osnap-backup-${_stamp()}.zip'));
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive));
    return file;
  }

  /// Replaces all current data with the contents of a backup .zip.
  Future<void> restore(File zip) async {
    final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    final dataFile = archive.findFile('data.json');
    final dataBytes = dataFile?.readBytes();
    if (dataBytes == null) {
      throw const FormatException('This file is not an Osnap backup.');
    }
    final data = jsonDecode(utf8.decode(dataBytes)) as Map<String, dynamic>;
    if (data['receipts'] is! List ||
        data['products'] is! List ||
        data['lineItems'] is! List) {
      throw const FormatException('This file is not an Osnap backup.');
    }

    // Database first: if it fails the existing photos are left untouched.
    await db.importJson(data);

    await for (final entity in imagesDir.list()) {
      if (entity is File) await entity.delete();
    }
    for (final f in archive.files) {
      if (!f.isFile || !f.name.startsWith('images/')) continue;
      // basename() keeps a crafted entry name from writing outside the folder.
      final name = p.basename(f.name);
      final bytes = f.readBytes();
      if (name.isEmpty || bytes == null) continue;
      await File(p.join(imagesDir.path, name)).writeAsBytes(bytes);
    }
  }

  Future<File> createCsv() async {
    String cell(Object? v) {
      final s = '${v ?? ''}';
      return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    String money(int? cents) => cents == null ? '' : (cents / 100).toStringAsFixed(2);

    final rows = <List<Object?>>[
      [
        'date', 'title', 'note', 'item', 'product', 'qty', 'pieces_per_pack',
        'total', 'per_piece', 'markup', 'marked_up_price',
      ],
      for (final e in await db.allEntries())
        [
          DateFormat('yyyy-MM-dd HH:mm').format(e.receipt.capturedAt),
          e.receipt.title,
          e.receipt.note,
          e.item.rawName,
          e.product.displayName,
          fmtQty(e.item.qty),
          e.item.piecesPerPack,
          money(e.item.totalCents),
          money(e.unitCents),
          money(e.item.markupCents),
          money(e.sellCents),
        ],
    ];
    final tmp = await getTemporaryDirectory();
    final file = File(p.join(tmp.path, 'osnap-${_stamp()}.csv'));
    await file.writeAsString(
      rows.map((r) => r.map(cell).join(',')).join('\n'),
    );
    return file;
  }
}
