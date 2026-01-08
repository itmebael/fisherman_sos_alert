import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../widgets/fisherman/cool_weather_widget.dart';
import '../../widgets/fisherman/weather_forecast_widget.dart';
import '../../widgets/fisherman/weather_alerts_widget.dart';
import '../../services/weather_service.dart';
import '../../models/weather_model.dart';
import 'fisherman_drawer.dart';

class FishermanNewsScreen extends StatefulWidget {
  const FishermanNewsScreen({super.key});

  @override
  State<FishermanNewsScreen> createState() => _FishermanNewsScreenState();
}

class _FishermanNewsScreenState extends State<FishermanNewsScreen> {
  final WeatherService _weatherService = WeatherService();
  WeatherModel? _currentWeather;
  List<WeatherForecastModel> _forecast = [];
  List<WeatherAlertModel> _alerts = [];
  bool _isLoadingWeather = true;
  String _selectedCity = 'Catbalogan';

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      // Load current weather
      final weatherData = await _weatherService.getCurrentWeather(_selectedCity);
      if (weatherData != null) {
        setState(() {
          _currentWeather = WeatherModel.fromJson(weatherData);
        });
      }

      // Load forecast
      final forecastData = await _weatherService.getWeatherForecast(_selectedCity);
      setState(() {
        _forecast = forecastData.map((data) => WeatherForecastModel.fromJson(data)).toList();
      });

      // Load alerts
      final alertsData = await _weatherService.getWeatherAlerts();
      setState(() {
        _alerts = alertsData.map((data) => WeatherAlertModel.fromJson(data)).toList();
      });
    } catch (e) {
      print('Error loading weather data: $e');
    } finally {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Samar Municipality',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ..._weatherService.getAvailableCities().map((city) {
                return ListTile(
                  title: Text(city),
                  trailing: _selectedCity == city ? const Icon(Icons.check) : null,
                  onTap: () {
                    setState(() {
                      _selectedCity = city;
                    });
                    Navigator.pop(context);
                    _loadWeatherData();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Samar Weather & News',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 20,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.whiteColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.location_city, color: AppColors.whiteColor, size: isMobile ? 20 : 24),
            onPressed: _showCitySelector,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.whiteColor, size: isMobile ? 20 : 24),
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      drawer: const FishermanDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadWeatherData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Weather Section
                if (_isLoadingWeather)
                  _buildLoadingWidget()
                else ...[
                  // Current Weather Widget
                  if (_currentWeather != null)
                    CoolWeatherWidget(
                      weather: _currentWeather!,
                      onTap: _showWeatherDetails,
                    ),
                  
                  // Weather Forecast Widget
                  if (_forecast.isNotEmpty)
                    WeatherForecastWidget(
                      forecast: _forecast,
                      city: _selectedCity,
                    ),
                  
                  // Weather Alerts Widget
                  if (_alerts.isNotEmpty)
                    WeatherAlertsWidget(
                      alerts: _alerts,
                    ),
                ],
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF87CEEB),
            Color(0xFF4682B4),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading Weather Data...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeatherDetails() {
    if (_currentWeather == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Detailed Weather Information',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDetailRow('Temperature', '${_currentWeather!.temperature}°C'),
                      _buildDetailRow('Feels Like', '${_currentWeather!.feelsLike}°C'),
                      _buildDetailRow('Humidity', '${_currentWeather!.humidity}%'),
                      _buildDetailRow('Pressure', '${_currentWeather!.pressure} hPa'),
                      _buildDetailRow('Wind Speed', '${_currentWeather!.windSpeed} m/s'),
                      _buildDetailRow('Wind Direction', _currentWeather!.windDirectionText),
                      _buildDetailRow('Visibility', '${_currentWeather!.visibility} km'),
                      _buildDetailRow('Weather', _currentWeather!.description),
                      _buildDetailRow('Fishing Safety', _currentWeather!.safetyStatus),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fishing Advice',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentWeather!.fishingAdvice,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}