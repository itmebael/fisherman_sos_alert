// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'csv_saver_stub.dart';

class CsvSaverWeb implements CsvSaver {
  @override
  Future<CsvSaverResult> saveCsv({required String filename, required String csvContent}) async {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return const CsvSaverResult(success: true);
  }
}

CsvSaver getCsvSaver() => CsvSaverWeb();


