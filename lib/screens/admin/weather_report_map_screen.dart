import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../constants/colors.dart';
import '../../services/weather_service.dart';
import '../admin/admin_drawer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/csv_saver_stub.dart' if (dart.library.html) '../../utils/csv_saver_web.dart' if (dart.library.io) '../../utils/csv_saver_io.dart';

class WeatherReportMapScreen extends StatefulWidget {
  const WeatherReportMapScreen({super.key});

  @override
  State<WeatherReportMapScreen> createState() => _WeatherReportMapScreenState();
}

class _WeatherReportMapScreenState extends State<WeatherReportMapScreen> {
  final WeatherService _weatherService = WeatherService();
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _weatherData = [];
  bool _isLoading = true;
  String _selectedPeriod = 'day'; // 'day', 'week', 'month'
  DateTime _selectedDate = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weatherData = await _weatherService.getMultiCityWeather();
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'day':
        return DateFormat('MMM dd, yyyy').format(_selectedDate);
      case 'week':
        final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
      case 'month':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Color _getWeatherColor(String main, double windSpeed) {
    if (main == 'Thunderstorm' || main == 'Rain') return Colors.red;
    if (windSpeed > 15) return Colors.orange;
    return Colors.green;
  }

  IconData _getWeatherIcon(String main) {
    switch (main.toLowerCase()) {
      case 'thunderstorm':
        return Icons.flash_on;
      case 'rain':
      case 'drizzle':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      case 'clouds':
        return Icons.cloud;
      case 'clear':
        return Icons.wb_sunny;
      default:
        return Icons.wb_cloudy;
    }
  }

  List<Marker> _buildWeatherMarkers() {
    return _weatherData.map((weather) {
      final coords = _weatherService.getCityCoordinates(weather['city']);
      if (coords == null) return null;

      final lat = coords['lat']!;
      final lon = coords['lon']!;
      final main = weather['main'] ?? 'Clear';
      final windSpeed = (weather['windSpeed'] ?? 0).toDouble();
      final temp = weather['temperature'] ?? 0;
      final color = _getWeatherColor(main, windSpeed);

      return Marker(
        point: latlong.LatLng(lat, lon),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showWeatherDetails(weather),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getWeatherIcon(main),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '${temp}°C',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _showWeatherDetails(Map<String, dynamic> weather) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getWeatherIcon(weather['main'] ?? 'Clear'),
              color: _getWeatherColor(weather['main'] ?? 'Clear', weather['windSpeed'] ?? 0),
            ),
            const SizedBox(width: 8),
            Text(weather['city'] ?? 'Unknown'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Temperature', '${weather['temperature']}°C'),
              _buildDetailRow('Feels Like', '${weather['feelsLike']}°C'),
              _buildDetailRow('Condition', weather['description'] ?? '-'),
              _buildDetailRow('Wind Speed', '${weather['windSpeed']} m/s'),
              _buildDetailRow('Wind Direction', '${weather['windDirection']}°'),
              _buildDetailRow('Humidity', '${weather['humidity']}%'),
              _buildDetailRow('Pressure', '${weather['pressure']} hPa'),
              _buildDetailRow('Visibility', '${weather['visibility']?.toStringAsFixed(1)} km'),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (weather['isSafeForFishing'] ?? false)
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      (weather['isSafeForFishing'] ?? false) ? Icons.check_circle : Icons.warning,
                      color: (weather['isSafeForFishing'] ?? false) ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weather['fishingAdvice'] ?? 'No advice available',
                        style: TextStyle(
                          color: (weather['isSafeForFishing'] ?? false) ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadWeatherData();
    }
  }

  String _buildReportText() {
    final buffer = StringBuffer();
    buffer.writeln('WEATHER REPORT');
    buffer.writeln('Period: ${_getPeriodLabel()}');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('=' * 60);
    buffer.writeln('');

    for (final weather in _weatherData) {
      buffer.writeln('City: ${weather['city']}');
      buffer.writeln('Temperature: ${weather['temperature']}°C');
      buffer.writeln('Feels Like: ${weather['feelsLike']}°C');
      buffer.writeln('Condition: ${weather['description']}');
      buffer.writeln('Wind Speed: ${weather['windSpeed']} m/s');
      buffer.writeln('Wind Direction: ${weather['windDirection']}°');
      buffer.writeln('Humidity: ${weather['humidity']}%');
      buffer.writeln('Pressure: ${weather['pressure']} hPa');
      buffer.writeln('Visibility: ${weather['visibility']?.toStringAsFixed(1)} km');
      buffer.writeln('Safe for Fishing: ${weather['isSafeForFishing'] ? 'Yes' : 'No'}');
      buffer.writeln('Advice: ${weather['fishingAdvice']}');
      buffer.writeln('');
      buffer.writeln('-' * 60);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _buildReportCsv() {
    final buffer = StringBuffer();
    buffer.writeln('City,Temperature,Feels Like,Condition,Wind Speed,Wind Direction,Humidity,Pressure,Visibility,Safe for Fishing,Advice');
    
    for (final weather in _weatherData) {
      final city = (weather['city'] ?? '').toString().replaceAll(',', ' ');
      final temp = (weather['temperature'] ?? '').toString();
      final feelsLike = (weather['feelsLike'] ?? '').toString();
      final condition = (weather['description'] ?? '').toString().replaceAll(',', ' ');
      final windSpeed = (weather['windSpeed'] ?? '').toString();
      final windDir = (weather['windDirection'] ?? '').toString();
      final humidity = (weather['humidity'] ?? '').toString();
      final pressure = (weather['pressure'] ?? '').toString();
      final visibility = (weather['visibility']?.toStringAsFixed(1) ?? '').toString();
      final safe = (weather['isSafeForFishing'] ?? false) ? 'Yes' : 'No';
      final advice = (weather['fishingAdvice'] ?? '').toString().replaceAll(',', ' ').replaceAll('\n', ' ');
      
      buffer.writeln('$city,$temp,$feelsLike,$condition,$windSpeed,$windDir,$humidity,$pressure,$visibility,$safe,"$advice"');
    }
    
    return buffer.toString();
  }

  Future<void> _viewReport() async {
    final report = _buildReportText();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Text('Weather Report - ${_getPeriodLabel()}'),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 500,
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
                        'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
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
                    report,
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
              await Clipboard.setData(ClipboardData(text: report));
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

  Future<void> _downloadReport() async {
    if (_weatherData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No weather data to download')),
      );
      return;
    }

    final periodLabel = _getPeriodLabel().replaceAll(' ', '_').replaceAll(',', '');
    final filename = 'weather_report_${periodLabel}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final csv = _buildReportCsv();
    
    final saver = getCsvSaver();
    final result = await saver.saveCsv(filename: filename, csvContent: csv);
    
    if (!mounted) return;
    
    final msg = result.success
        ? (result.message ?? (kIsWeb ? 'Download started' : 'File saved'))
        : (result.message ?? 'Failed to download');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: result.success ? Colors.green : Colors.red,
        action: result.success && result.filePath != null
            ? SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () {
                  // Could open file location here if needed
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/img/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            ClipOval(
              child: Image.asset(
                'assets/img/coastguard.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              "Salbar Mangirisda",
              style: TextStyle(
                color: Color(0xFF13294B),
                fontWeight: FontWeight.bold,
                fontSize: 22,
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
            onPressed: _loadWeatherData,
          ),
          if (_weatherData.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.visibility, color: AppColors.textPrimary),
              tooltip: 'View Report',
              onPressed: _viewReport,
            ),
            IconButton(
              icon: const Icon(Icons.download, color: AppColors.textPrimary),
              tooltip: 'Download Report',
              onPressed: _downloadReport,
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart.withOpacity(0.1),
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Period selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'day', label: Text('Day')),
                          ButtonSegment(value: 'week', label: Text('Week')),
                          ButtonSegment(value: 'month', label: Text('Month')),
                        ],
                        selected: {_selectedPeriod},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedPeriod = newSelection.first;
                          });
                          _loadWeatherData();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_getPeriodLabel()),
                    ),
                  ],
                ),
              ),
              // Generate Report Section
              if (_weatherData.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      const Expanded(
                        child: Text(
                          'Generate Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
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
                        onPressed: _downloadReport,
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
              // Map
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(_error!),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadWeatherData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: const latlong.LatLng(11.7753, 124.8861), // Samar center
                                  initialZoom: 10.0,
                                  minZoom: 8.0,
                                  maxZoom: 18.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                    userAgentPackageName: 'com.example.fisherman_sos_alert',
                                    maxZoom: 19,
                                  ),
                                  MarkerLayer(markers: _buildWeatherMarkers()),
                                ],
                              ),
                            ),
                          ),
              ),
              // Legend
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.green, 'Safe'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.orange, 'Caution'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.red, 'Dangerous'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

