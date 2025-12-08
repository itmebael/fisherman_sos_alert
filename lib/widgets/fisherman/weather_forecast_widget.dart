import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class WeatherForecastWidget extends StatelessWidget {
  final List<WeatherForecastModel> forecast;
  final String city;

  const WeatherForecastWidget({
    super.key,
    required this.forecast,
    required this.city,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '5-Day Forecast for $city, Samar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...forecast.map((day) => _buildForecastDay(day)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastDay(WeatherForecastModel day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 60,
            child: Text(
              day.dayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Weather icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.network(
              day.weatherIconUrl,
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  _getWeatherIcon(day.description),
                  color: Colors.white,
                  size: 20,
                );
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Temperature range
          Expanded(
            child: Text(
              day.temperatureRange,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Description
          Expanded(
            child: Text(
              day.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Safety indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: day.isSafeForFishing ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String description) {
    if (description.toLowerCase().contains('rain')) {
      return Icons.grain;
    } else if (description.toLowerCase().contains('cloud')) {
      return Icons.cloud;
    } else if (description.toLowerCase().contains('clear') || description.toLowerCase().contains('sun')) {
      return Icons.wb_sunny;
    } else if (description.toLowerCase().contains('storm')) {
      return Icons.flash_on;
    } else if (description.toLowerCase().contains('snow')) {
      return Icons.ac_unit;
    }
    return Icons.wb_sunny;
  }
}
