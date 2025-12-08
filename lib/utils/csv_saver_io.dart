import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'csv_saver_stub.dart';

class CsvSaverIo implements CsvSaver {
  @override
  Future<CsvSaverResult> saveCsv({required String filename, required String csvContent}) async {
    try {
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csvContent);
      return CsvSaverResult(success: true, filePath: file.path, message: 'Saved to ${file.path}');
    } catch (e) {
      return CsvSaverResult(success: false, message: e.toString());
    }
  }
}

CsvSaver getCsvSaver() => CsvSaverIo();


