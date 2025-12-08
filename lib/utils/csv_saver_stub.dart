class CsvSaverResult {
  final bool success;
  final String? message;
  final String? filePath;

  const CsvSaverResult({required this.success, this.message, this.filePath});
}

abstract class CsvSaver {
  Future<CsvSaverResult> saveCsv({required String filename, required String csvContent});
}

class CsvSaverStub implements CsvSaver {
  @override
  Future<CsvSaverResult> saveCsv({required String filename, required String csvContent}) async {
    return const CsvSaverResult(success: false, message: 'CSV download not supported on this platform');
  }
}

CsvSaver getCsvSaver() => CsvSaverStub();


