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
        return 'Safe';
      case 'on_the_way':
        return 'On Way';
      case 'active':
      default:
        return 'Active';
    }
  }






  String _buildCsv() {
    final buffer = StringBuffer();
    buffer.writeln('ID,Full Name,Status,Boat Number,Distress Time,Rescue Time,Weather Condition,Temperature,Humidity,Wind Speed,Pressure,Casualties,Injured');
    for (final r in _filteredReports) {
      final id = (r['id'] ?? '').toString().replaceAll(',', ' ');
      final name = (r['fullName'] ?? r['fisherman_name'] ?? '').toString().replaceAll(',', ' ');
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
      buffer.writeln('$id,$name,$status,$boatNumber,$distress,$rescue,$condition,$temp,$humidity,$windSpeed,$pressure,$casualties,$injured');
    }
    return buffer.toString();
  }

  Future<void> _exportCsv() async {
    if (_filteredReports.isEmpty) return;
    
    // Show confirmation dialog before downloading
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Excel Report'),
        content: const Text('Are you sure you want to download the rescue reports as CSV/Excel file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
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
              // Filters and Download Section
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rescue Reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                          ),
                          icon: const Icon(Icons.download, size: 20),
                          label: const Text('Download Report'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        // Date Range Filter
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  initialDateRange: _dateRange,
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
                                  setState(() => _dateRange = picked);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 20,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date Range',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _dateRange == null
                                              ? 'All Dates'
                                              : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    if (_dateRange != null)
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                        onPressed: () => setState(() => _dateRange = null),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Clear filter',
                                      )
                                    else
                                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Status Filter
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            value: _statusFilter,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.filter_alt, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            items: ['All', 'Active', 'Safe']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
                                .toList(),
                            onChanged: (v) => setState(() => _statusFilter = v!),
                          ),
                        ),

                        // Search
                        SizedBox(
                          width: 300,
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              labelText: 'Search',
                              hintText: 'Name, Boat, or ID',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
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
                                      Expanded(flex: 2, child: Center(child: Text('Boat Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Distress Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Rescue Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 2, child: Center(child: Text('Weather', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Casualties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                                      Expanded(flex: 1, child: Center(child: Text('Injured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
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