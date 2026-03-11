import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  DateTimeRange? _dateRange;
  String _statusFilter = 'All'; // All, Active, Safe
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredReports {
    return _reports.where((report) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (report['fullName'] ?? '').toString().toLowerCase();
        final boatName = (report['boat_name'] ?? '').toString().toLowerCase();
        final id = (report['id'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !boatName.contains(query) && !id.contains(query)) {
          return false;
        }
      }

      // Filter by status
      if (_statusFilter != 'All') {
        final status = report['status'] ?? '';
        if (_statusFilter == 'Safe') {
          if (status != 'inactive' && status != 'rescued') return false;
        } else if (_statusFilter == 'Active') {
          if (status == 'inactive' || status == 'rescued') return false;
        }
      }

      // Filter by date range
      if (_dateRange != null) {
        final dateStr = report['distressTime']?.toString();
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null) {
            if (date.isBefore(_dateRange!.start) || date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
              return false;
            }
          }
        }
      }

      return true;
    }).toList();
  }

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
      // Enrich reports with boat information
      final enrichedData = await _enrichReportsWithBoatInfo(data);
      setState(() {
        _reports = enrichedData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _enrichReportsWithBoatInfo(List<Map<String, dynamic>> reports) async {
    final enrichedReports = <Map<String, dynamic>>[];
    
    for (var report in reports) {
      final enrichedReport = Map<String, dynamic>.from(report);
      final fishermanUid = report['fisherman_uid']?.toString();
      
      if (fishermanUid != null && fishermanUid.isNotEmpty) {
        try {
          // Fetch boat information for this fisherman
          final boats = await _databaseService.getBoatsByOwnerId(fishermanUid);
          if (boats.isNotEmpty) {
            final boat = boats.first;
            // Get boat name or registration number
            enrichedReport['boat_name'] = boat['name'] ?? 
                                         boat['registration_number'] ?? 
                                         boat['registrationNumber'] ??
                                         boat['id'] ?? 
                                         '-';
          } else {
            enrichedReport['boat_name'] = '-';
          }
        } catch (e) {
          print('Error fetching boat info for fisherman $fishermanUid: $e');
          enrichedReport['boat_name'] = '-';
        }
      } else {
        enrichedReport['boat_name'] = '-';
      }
      
      enrichedReports.add(enrichedReport);
    }
    
    return enrichedReports;
  }

  String _buildWeatherTooltip(Map<String, dynamic> report) {
    final weatherDetails = report['weatherDetails'] as Map<String, dynamic>?;
    if (weatherDetails == null || weatherDetails.isEmpty) {
      return report['weather']?.toString() ?? 'No weather data';
    }
    
    final parts = <String>[];
    if (weatherDetails['temperature'] != null) {
      parts.add('Temp: ${weatherDetails['temperature']}°C');
    }
    if (weatherDetails['description'] != null) {
      parts.add('Condition: ${weatherDetails['description']}');
    }
    if (weatherDetails['humidity'] != null) {
      parts.add('Humidity: ${weatherDetails['humidity']}%');
    }
    if (weatherDetails['windSpeed'] != null) {
      parts.add('Wind: ${weatherDetails['windSpeed']} m/s');
    }
    
    return parts.isEmpty ? (report['weather']?.toString() ?? 'No weather data') : parts.join('\n');
  }

  Widget _buildProfileImage(Map<String, dynamic> report) {
    final profileUrl = report['profile_image_url'] ?? 
                       report['fisherman_profile_picture_url'] ?? 
                       report['fisherman_profile_image_url'];
    
    if (profileUrl != null && profileUrl.toString().isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            profileUrl.toString(),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 24,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.blue,
        size: 24,
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    
    try {
      final dt = dateTime is DateTime 
          ? dateTime 
          : DateTime.tryParse(dateTime.toString());
      
      if (dt == null) return '-';
      
      return DateFormat('MMM d, y\nh:mm a').format(dt);
    } catch (e) {
      return '-';
    }
  }

  String _getStatusLabel(dynamic status) {
    if (status == null) return 'Active';
    final statusStr = status.toString().toLowerCase();
    
    switch (statusStr) {
      case 'inactive':
      case 'rescued':
      case 'resolved':
        return 'Rescued';
      case 'on_the_way':
        return 'On Way';
      case 'active':
      default:
        return 'Active';
    }
  }






  String _buildCsv() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Full Name,Gender,Age,Reason of Distress,Status,Boat Number,Distress Time,Rescue Time,Weather Condition,Temperature,Humidity,Wind Speed,Pressure,Casualties,Injured,Missing,Total Onboard');
    for (final r in _filteredReports) {
      final id = (r['id'] ?? '').toString().replaceAll(',', ' ');
      final name = (r['fullName'] ?? r['fisherman_name'] ?? '').toString().replaceAll(',', ' ');
      final gender = (r['gender'] ?? '').toString().replaceAll(',', ' ');
      final age = (r['age'] ?? '').toString().replaceAll(',', ' ');
      final reasonOfDistress = (r['reason_of_distress'] ?? '').toString().replaceAll(',', ' ');
      final status = _getStatusLabel(r['status']);
      final boatNumber = (r['boat_name'] ?? r['boat_registration_number'] ?? '-').toString().replaceAll(',', ' ');
      final distress = (r['distressTime'] ?? r['created_at'] ?? '').toString().replaceAll(',', ' ');
      final rescue = (r['rescueTime'] ?? r['resolved_at'] ?? '-').toString().replaceAll(',', ' ');
      
      // Extract weather details
      final weatherDetails = r['weatherDetails'] as Map<String, dynamic>?;
      final temp = weatherDetails?['temperature']?.toString() ?? '-';
      final condition = weatherDetails?['description']?.toString().replaceAll(',', ' ') ?? (r['weather'] ?? '-').toString().replaceAll(',', ' ');
      final humidity = weatherDetails?['humidity']?.toString() ?? '-';
      final windSpeed = weatherDetails?['windSpeed']?.toString() ?? '-';
      final pressure = weatherDetails?['pressure']?.toString() ?? '-';
      
      final casualties = (r['casualties'] ?? 0).toString();
      final injured = (r['injured'] ?? 0).toString();
      final missing = (r['missing'] ?? 0).toString();
      final totalOnboard = (r['total_onboard'] ?? 0).toString();
      buffer.writeln('$id,$name,$gender,$age,$reasonOfDistress,$status,$boatNumber,$distress,$rescue,$condition,$temp,$humidity,$windSpeed,$pressure,$casualties,$injured,$missing,$totalOnboard');
    }
    return buffer.toString();
  }

  Future<void> _exportCsv() async {
    if (_filteredReports.isEmpty) return;
    
    // Show preview dialog with data that will be exported
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Export Preview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The following ${_filteredReports.length} report(s) will be exported:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Reason of Distress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Boat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Distress Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Rescue Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Casualties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Injured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Missing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('Onboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: _filteredReports.take(50).map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                (r['id'] ?? '').toString().length > 10
                                    ? '${(r['id'] ?? '').toString().substring(0, 10)}...'
                                    : (r['id'] ?? '').toString(),
                                style: const TextStyle(fontSize: 11),
                              )),
                              DataCell(Text(
                                (r['fullName'] ?? r['fisherman_name'] ?? '-').toString(),
                                style: const TextStyle(fontSize: 11),
                              )),
                              DataCell(Text(
                                (r['gender'] ?? '-').toString(),
                                style: const TextStyle(fontSize: 11),
                              )),
                              DataCell(Text(
                                (r['age'] ?? '-').toString(),
                                style: const TextStyle(fontSize: 11),
                              )),
                              DataCell(Text(
                                (r['reason_of_distress'] ?? '-').toString(),
                                style: const TextStyle(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                              DataCell(Text(
                                _getStatusLabel(r['status']),
                                style: const TextStyle(fontSize: 11),
                              )),
                              DataCell(Text(
                                (r['boat_name'] ?? r['boat_registration_number'] ?? '-').toString(),
                                style: const TextStyle(fontSize: 11),
                              )),
                              DataCell(Text(
                                _formatDateTime(r['distressTime'] ?? r['created_at']).replaceAll('\n', ' '),
                                style: const TextStyle(fontSize: 11),
                              )),
                              DataCell(Text(
                                _formatDateTime(r['rescueTime'] ?? r['resolved_at']).replaceAll('\n', ' '),
                                style: const TextStyle(fontSize: 11),
                              )),
                              DataCell(Text(
                                (r['casualties'] ?? 0).toString(),
                                style: const TextStyle(fontSize: 11, color: Colors.red),
                              )),
                              DataCell(Text(
                                (r['injured'] ?? 0).toString(),
                                style: const TextStyle(fontSize: 11, color: Colors.orange),
                              )),
                              DataCell(Text(
                                (r['missing'] ?? 0).toString(),
                                style: const TextStyle(fontSize: 11, color: Colors.amber),
                              )),
                              DataCell(Text(
                                (r['total_onboard'] ?? 0).toString(),
                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              if (_filteredReports.length > 50)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${_filteredReports.length - 50} more report(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Export'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (confirmed != true) return;
    
    // Show exporting message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Exporting documents...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Build CSV and save
    final csv = _buildCsv();
    final saver = getCsvSaver();
    final result = await saver.saveCsv(filename: 'rescue_reports.csv', csvContent: csv);
    if (!mounted) return;
    
    // Show success or error message
    final msg = result.success
        ? (result.message ?? (kIsWeb ? 'Export started' : 'Document exported successfully'))
        : (result.message ?? 'Failed to export document');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: result.success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
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
              "Salbar Mangirisda",
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
              // Filters and Export Section
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Export Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Rescue Reports',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _exportCsv,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Export Report', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Filters Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column - Date Filters
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Start Date Filter
                              Row(
                                children: [
                                  Text(
                                    'Start Date:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime.now(),
                                              initialDate: _dateRange?.start ?? DateTime.now(),
                                              builder: (context, child) {
                                                return Theme(
                                                  data: Theme.of(context).copyWith(
                                                    colorScheme: ColorScheme.light(
                                                      primary: AppColors.primaryColor,
                                                      onPrimary: Colors.white,
                                                      surface: Colors.white,
                                                      onSurface: Colors.black,
                                                    ),
                                                    datePickerTheme: DatePickerThemeData(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                    ),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                _dateRange = DateTimeRange(
                                                  start: picked,
                                                  end: _dateRange?.end ?? picked,
                                                );
                                              });
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _dateRange == null
                                                        ? 'MM/DD/YYYY'
                                                        : DateFormat('MM/dd/yyyy').format(_dateRange!.start),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: _dateRange == null ? Colors.grey.shade400 : AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 18,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // End Date Filter
                              Row(
                                children: [
                                  Text(
                                    'End Date:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              firstDate: _dateRange?.start ?? DateTime(2020),
                                              lastDate: DateTime.now(),
                                              initialDate: _dateRange?.end ?? DateTime.now(),
                                              builder: (context, child) {
                                                return Theme(
                                                  data: Theme.of(context).copyWith(
                                                    colorScheme: ColorScheme.light(
                                                      primary: AppColors.primaryColor,
                                                      onPrimary: Colors.white,
                                                      surface: Colors.white,
                                                      onSurface: Colors.black,
                                                    ),
                                                    datePickerTheme: DatePickerThemeData(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                    ),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                _dateRange = DateTimeRange(
                                                  start: _dateRange?.start ?? picked,
                                                  end: picked,
                                                );
                                              });
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _dateRange == null
                                                        ? 'MM/DD/YYYY'
                                                        : DateFormat('MM/dd/yyyy').format(_dateRange!.end),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: _dateRange == null ? Colors.grey.shade400 : AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 18,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_dateRange != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                      onPressed: () => setState(() => _dateRange = null),
                                      tooltip: 'Clear date filter',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Column - Status and Search
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              // Status Filter
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: _statusFilter,
                                  decoration: InputDecoration(
                                    labelText: 'Status',
                                    prefixIcon: const Icon(Icons.filter_alt, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                    filled: true,
                                    fillColor: AppColors.whiteColor,
                                  ),
                                  items: ['All', 'Active', 'Safe']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                                      .toList(),
                                  onChanged: (v) => setState(() => _statusFilter = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Search
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                    filled: true,
                                    fillColor: AppColors.whiteColor,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                                      Expanded(flex: 1, child: Center(child: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Reason of Distress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Boat Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Distress Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Rescue Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Weather', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Casualties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Injured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Missing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Onboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
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
                                          : _filteredReports.isEmpty
                                              ? const Center(child: Text('No reports found matching criteria'))
                                              : ListView.separated(
                                                  itemCount: _filteredReports.length,
                                                  separatorBuilder: (_, __) => Divider(color: AppColors.dividerColor.withOpacity(0.3), height: 1),
                                                  itemBuilder: (context, index) {
                                                    final r = _filteredReports[index];
                                                    return Container(
                                                      color: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                                      child: Row(
                                                        children: [
                                                          // Profile picture
                                                          Expanded(
                                                            flex: 1,
                                                            child: Center(
                                                              child: _buildProfileImage(r),
                                                            ),
                                                          ),
                                                          // Full Name
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Text(
                                                                (r['fullName'] ?? r['fisherman_name'] ?? '-').toString(),
                                                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 12),
                                                                textAlign: TextAlign.center,
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          // Gender
                                                          Expanded(
                                                            flex: 1,
                                                            child: Center(
                                                              child: Text(
                                                                (r['gender'] ?? '-').toString(),
                                                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                                                                textAlign: TextAlign.center,
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          // Age
                                                          Expanded(
                                                            flex: 1,
                                                            child: Center(
                                                              child: Text(
                                                                (r['age'] ?? '-').toString(),
                                                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                                                                textAlign: TextAlign.center,
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                          // Reason of Distress
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Tooltip(
                                                                message: (r['reason_of_distress'] ?? '-').toString(),
                                                                child: Text(
                                                                  (r['reason_of_distress'] ?? '-').toString(),
                                                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
                                                                  textAlign: TextAlign.center,
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // Boat Number
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.blue.withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const Icon(Icons.directions_boat, size: 12, color: Colors.blue),
                                                                    const SizedBox(width: 4),
                                                                    Flexible(
                                                                      child: Text(
                                                                        (r['boat_name'] ?? r['boat_registration_number'] ?? '-').toString(),
                                                                        style: const TextStyle(
                                                                          color: AppColors.textPrimary,
                                                                          fontSize: 10,
                                                                          fontWeight: FontWeight.w500,
                                                                        ),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                        textAlign: TextAlign.center,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // Distress Time
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Tooltip(
                                                                message: r['distressTime']?.toString() ?? '-',
                                                                child: Text(
                                                                  _formatDateTime(r['distressTime'] ?? r['created_at']),
                                                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
                                                                  textAlign: TextAlign.center,
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // Rescue Time
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Tooltip(
                                                                message: r['rescueTime']?.toString() ?? r['resolved_at']?.toString() ?? '-',
                                                                child: Text(
                                                                  _formatDateTime(r['rescueTime'] ?? r['resolved_at']),
                                                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
                                                                  textAlign: TextAlign.center,
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // Weather
                                                          Expanded(
                                                            flex: 2,
                                                            child: Center(
                                                              child: Tooltip(
                                                                message: _buildWeatherTooltip(r),
                                                                child: Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.blue.withOpacity(0.1),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      const Icon(Icons.cloud, size: 12, color: Colors.blue),
                                                                      const SizedBox(width: 4),
                                                                      Flexible(
                                                                        child: Text(
                                                                          (r['weather'] ?? '-').toString(),
                                                                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                          textAlign: TextAlign.center,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // Casualties
                                                          Expanded(
                                                            flex: 1,
                                                            child: Center(
                                                              child: Text(
                                                                (r['casualties'] ?? 0).toString(),
                                                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                                              ),
                                                            ),
                                                          ),
                                                          // Injured
                                                          Expanded(
                                                            flex: 1,
                                                            child: Center(
                                                              child: Text(
                                                                (r['injured'] ?? 0).toString(),
                                                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                                              ),
                                                            ),
                                                          ),
                                                          // Missing
                                                          Expanded(
                                                            flex: 1,
                                                            child: Center(
                                                              child: Text(
                                                                (r['missing'] ?? 0).toString(),
                                                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                                                              ),
                                                            ),
                                                          ),
                                                          // Total Onboard
                                                          Expanded(
                                                            flex: 1,
                                                            child: Center(
                                                              child: Text(
                                                                (r['total_onboard'] ?? 0).toString(),
                                                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                                                              ),
                                                            ),
                                                          ),
                                                          // Status
                                                          Expanded(
                                                            flex: 1,
                                                            child: Center(
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: (r['status'] == 'inactive' || r['status'] == 'rescued' || r['status'] == 'resolved' ? Colors.green : Colors.red).withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(12),
                                                                  border: Border.all(color: (r['status'] == 'inactive' || r['status'] == 'rescued' || r['status'] == 'resolved' ? Colors.green : Colors.red).withOpacity(0.3)),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(
                                                                      (r['status'] == 'inactive' || r['status'] == 'rescued' || r['status'] == 'resolved') ? Icons.check_circle : Icons.warning,
                                                                      color: (r['status'] == 'inactive' || r['status'] == 'rescued' || r['status'] == 'resolved') ? Colors.green : Colors.red,
                                                                      size: 10,
                                                                    ),
                                                                    const SizedBox(width: 2),
                                                                    Flexible(
                                                                      child: Text(
                                                                        _getStatusLabel(r['status']),
                                                                        style: TextStyle(
                                                                          color: (r['status'] == 'inactive' || r['status'] == 'rescued' || r['status'] == 'resolved') ? Colors.green : Colors.red,
                                                                          fontSize: 9,
                                                                          fontWeight: FontWeight.w600,
                                                                        ),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
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