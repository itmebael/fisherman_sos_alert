import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../admin/admin_drawer.dart';
import '../../services/database_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/csv_saver_stub.dart' if (dart.library.html) '../../utils/csv_saver_web.dart' if (dart.library.io) '../../utils/csv_saver_io.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final DatabaseService _databaseService = DatabaseService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reports = const [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _databaseService.getRescueReports();
      setState(() {
        _reports = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _buildPrintableText() {
    final buffer = StringBuffer();
    buffer.writeln('RESCUE REPORTS');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('Total Reports: ${_reports.length}');
    buffer.writeln('');
    buffer.writeln('=' * 70);
    buffer.writeln('');

    for (int i = 0; i < _reports.length; i++) {
      final r = _reports[i];
      buffer.writeln('Report #${i + 1}');
      buffer.writeln('ID: ${r['id']}');
      buffer.writeln('Full Name: ${r['fullName'] ?? '-'}');
      buffer.writeln('Status: ${r['status'] ?? '-'}');
      buffer.writeln('Distress Time: ${r['distressTime'] ?? '-'}');
      buffer.writeln('Rescue Time: ${r['rescueTime'] ?? '-'}');
      buffer.writeln('Date: ${(r['distressTime'] ?? '-').toString().split('T').first}');
      buffer.writeln('');
      buffer.writeln('-' * 70);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Future<void> _viewReport() async {
    if (_reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reports to view')),
      );
      return;
    }

    final text = _buildPrintableText();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.analytics, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            const Text('Rescue Reports'),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 600,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.homeBackground.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Reports: ${_reports.length} | Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report copied to clipboard')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrintDialog() async {
    final text = _buildPrintableText();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Print / Export'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: SelectableText(text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              }
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  String _buildCsv() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Full Name,Status,Distress Time,Rescue Time');
    for (final r in _reports) {
      final id = (r['id'] ?? '').toString().replaceAll(',', ' ');
      final name = (r['fullName'] ?? '').toString().replaceAll(',', ' ');
      final status = (r['status'] ?? '').toString().replaceAll(',', ' ');
      final distress = (r['distressTime'] ?? '').toString().replaceAll(',', ' ');
      final rescue = (r['rescueTime'] ?? '').toString().replaceAll(',', ' ');
      buffer.writeln('$id,$name,$status,$distress,$rescue');
    }
    return buffer.toString();
  }

  Future<void> _exportCsv() async {
    if (_reports.isEmpty) return;
    final csv = _buildCsv();
    final saver = getCsvSaver();
    final result = await saver.saveCsv(filename: 'rescue_reports.csv', csvContent: csv);
    if (!mounted) return;
    final msg = result.success
        ? (result.message ?? (kIsWeb ? 'Download started' : 'Saved'))
        : (result.message ?? 'Failed to save');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // BantayDagat logo
            ClipOval(
              child: Image.asset(
                'assets/img/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            // Coast Guard logo
            ClipOval(
              child: Image.asset(
                'assets/img/coastguard.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // App title
            Text(
              "Salbar_Mangirisda",
              style: const TextStyle(
                color: Color(0xFF13294B),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.homeBackground,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: _loadReports,
          ),
          if (_reports.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.visibility, color: AppColors.textPrimary),
              tooltip: 'View Report',
              onPressed: _viewReport,
            ),
            IconButton(
              icon: const Icon(Icons.download, color: AppColors.textPrimary),
              tooltip: 'Download CSV',
              onPressed: _exportCsv,
            ),
            IconButton(
              icon: const Icon(Icons.print, color: AppColors.textPrimary),
              tooltip: 'Print / Export',
              onPressed: _showPrintDialog,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.homeBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mobile Rescue And Location Tracking System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Generate Report Section
                if (_reports.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: AppColors.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Generate Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Total Reports: ${_reports.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _viewReport,
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Rescue Reports',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.dividerColor),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.search, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Search',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Reports table
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                // Table headers
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.homeBackground.withOpacity(0.3),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 2, child: Center(child: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 3, child: Center(child: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 2, child: Center(child: Text('Distress Time', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 2, child: Center(child: Text('Rescue Time', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 2, child: Center(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 2, child: Center(child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)))),
                                    ],
                                  ),
                                ),
                                
                                // Dynamic rows
                                Expanded(
                                  child: _loading
                                      ? const Center(child: CircularProgressIndicator())
                                      : _error != null
                                          ? Center(
                                              child: Text(
                                                _error!,
                                                style: const TextStyle(color: Colors.red),
                                              ),
                                            )
                                          : _reports.isEmpty
                                              ? const Center(child: Text('No reports found'))
                                              : ListView.separated(
                                                  itemCount: _reports.length,
                                                  separatorBuilder: (_, __) => Divider(color: AppColors.dividerColor.withOpacity(0.3), height: 1),
                                                  itemBuilder: (context, index) {
                                                    final r = _reports[index];
                                                    return Container(
                                                      color: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                                      child: Row(
                                                        children: [
                                                          // Profile picture
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Container(
                                                                width: 50,
                                                                height: 50,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.blue.withOpacity(0.2),
                                                                  borderRadius: BorderRadius.circular(25),
                                                                ),
                                                                child: const Icon(
                                                                  Icons.person,
                                                                  color: Colors.blue,
                                                                  size: 28,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // Full Name
                                                          Expanded(
                                                            flex: 3,
                                                            child: Center(
                                                              child: Text(
                                                                (r['fullName'] ?? '-').toString(),
                                                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 15),
                                                              ),
                                                            ),
                                                          ),
                                                          // Distress Time
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Text(
                                                                (r['distressTime'] ?? '-').toString(),
                                                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                                              ),
                                                            ),
                                                          ),
                                                          // Rescue Time
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Text(
                                                                (r['rescueTime'] ?? '-').toString(),
                                                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                                              ),
                                                            ),
                                                          ),
                                                          // Date (from distressTime date-only)
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Text(
                                                                (r['distressTime'] ?? '-').toString().split('T').first,
                                                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                                              ),
                                                            ),
                                                          ),
                                                          // Action status
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                                decoration: BoxDecoration(
                                                                  color: (r['status'] == 'resolved' ? Colors.green : Colors.red).withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(16),
                                                                  border: Border.all(color: (r['status'] == 'resolved' ? Colors.green : Colors.red).withOpacity(0.3)),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(Icons.circle, color: r['status'] == 'resolved' ? Colors.green : Colors.red, size: 10),
                                                                    const SizedBox(width: 6),
                                                                    Text(
                                                                      r['status'] == 'resolved' ? 'Rescued' : 'In Distress',
                                                                      style: TextStyle(color: r['status'] == 'resolved' ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}