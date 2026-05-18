import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../database/local_database.dart';

class MobileSyncResult {
  final int imported;
  final int skipped;
  final int conflicts;
  final String message;
  final String? path;

  const MobileSyncResult({
    required this.imported,
    required this.skipped,
    required this.conflicts,
    required this.message,
    this.path,
  });
}

class MobileSyncService {
  static Future<String> deviceId() async => LocalDatabase.instance.deviceId();

  static Future<String> exportPackage({String kind = 'full'}) async {
    final payload = await LocalDatabase.instance.exportPayload(kind: kind);
    final data = utf8.encode(const JsonEncoder.withIndent('  ').convert(payload));
    final archive = Archive()..addFile(ArchiveFile('sync_data.json', data.length, data));
    final zipBytes = ZipEncoder().encode(archive)!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/aldood_${kind}_sync_${DateTime.now().millisecondsSinceEpoch}.adsync');
    await file.writeAsBytes(zipBytes, flush: true);
    return file.path;
  }

  static Future<MobileSyncResult> importPackage() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['adsync', 'zip'],
      allowMultiple: false,
    );
    if (picked == null || picked.files.single.path == null) {
      return const MobileSyncResult(imported: 0, skipped: 0, conflicts: 0, message: 'لم يتم اختيار ملف.');
    }
    final path = picked.files.single.path!;
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? syncFile;
    for (final f in archive.files) {
      if (f.name == 'sync_data.json') {
        syncFile = f;
        break;
      }
    }
    if (syncFile == null) {
      return const MobileSyncResult(imported: 0, skipped: 0, conflicts: 1, message: 'الملف لا يحتوي على sync_data.json');
    }
    final payload = jsonDecode(utf8.decode(syncFile.content as List<int>)) as Map<String, dynamic>;
    final result = await LocalDatabase.instance.importPayload(payload, details: path);
    return MobileSyncResult(
      imported: result['imported'] ?? 0,
      skipped: result['skipped'] ?? 0,
      conflicts: result['conflicts'] ?? 0,
      message: 'تم استقبال ملف المزامنة.',
      path: path,
    );
  }

  static Future<Map<String, int>> stats() async => LocalDatabase.instance.syncStats();
}
