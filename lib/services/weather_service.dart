import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '4e9b091fda97fe35ed8292bfd4c1fbcb';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Samar province cities and municipalities for weather data
  static const Map<String, Map<String, double>> _philippineCities = {
    'Catbalogan': {'lat': 11.7753, 'lon': 124.8861}, // Capital of Samar
    'Calbayog': {'lat': 12.0667, 'lon': 124.6000},
    'Basey': {'lat': 11.2833, 'lon': 125.0667},
    'Marabut': {'lat': 11.1167, 'lon': 125.2167},
    'Tarangnan': {'lat': 11.9000, 'lon': 124.7500},
    'Villareal': {'lat': 11.5667, 'lon': 124.9167},
    'Pinabacdao': {'lat': 11.6167, 'lon': 125.0167},
    'Jiabong': {'lat': 11.7500, 'lon': 125.0167},
    'Motiong': {'lat': 11.7833, 'lon': 125.0000},
    'Paranas': {'lat': 11.7167, 'lon': 125.1167},
    'San Jorge': {'lat': 11.9833, 'lon': 124.8167},
    'Pagsanghan': {'lat': 11.9667, 'lon': 124.7500},
    'Gandara': {'lat': 12.0167, 'lon': 124.8167},
    'San Sebastian': {'lat': 11.7000, 'lon': 125.0000},
    'Hinabangan': {'lat': 11.7000, 'lon': 125.0667},
  };

  /// Get current weather for a specific Philippine city
  Future<Map<String, dynamic>?> getCurrentWeather(String cityName) async {
    try {
      final city = _philippineCities[cityName];
      if (city == null) {
        throw Exception('City not found in Philippine cities list');
      }

      final url = '$_baseUrl/weather?lat=${city['lat']}&lon=${city['lon']}&appid=$_apiKey&units=metric';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatWeatherData(data, cityName);
      } else {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('Weather API Error: $e');
      return null;
    }
  }

  /// Get weather forecast for a specific Philippine city
  Future<List<Map<String, dynamic>>> getWeatherForecast(String cityName, {int days = 5}) async {
    try {
      final city = _philippineCities[cityName];
      if (city == null) {
        throw Exception('City not found in Philippine cities list');
      }

      final url = '$_baseUrl/forecast?lat=${city['lat']}&lon=${city['lon']}&appid=$_apiKey&units=metric';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatForecastData(data['list'], days);
      } else {
        throw Exception('Failed to fetch forecast data: ${response.statusCode}');
      }
    } catch (e) {
      print('Weather Forecast API Error: $e');
      return [];
    }
  }

  /// Get weather for multiple Philippine cities
  Future<List<Map<String, dynamic>>> getMultiCityWeather() async {
    List<Map<String, dynamic>> weatherData = [];
    
    for (String city in _philippineCities.keys) {
      try {
        final weather = await getCurrentWeather(city);
        if (weather != null) {
          weatherData.add(weather);
        }
        // Add small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Error fetching weather for $city: $e');
      }
    }
    
    return weatherData;
  }

  /// Get weather alerts/warnings for Samar
  Future<List<Map<String, dynamic>>> getWeatherAlerts() async {
    try {
      // Using Catbalogan (Samar capital) as reference point for Samar alerts
      final url = '$_baseUrl/weather?lat=11.7753&lon=124.8861&appid=$_apiKey&units=metric';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _generateWeatherAlerts(data);
      } else {
        throw Exception('Failed to fetch weather alerts: ${response.statusCode}');
      }
    } catch (e) {
      print('Weather Alerts API Error: $e');
      return [];
    }
  }

  /// Format weather data for consistent structure
  Map<String, dynamic> _formatWeatherData(Map<String, dynamic> data, String cityName) {
    final main = data['main'];
    final weather = data['weather'][0];
    final wind = data['wind'];
    
    return {
      'city': cityName,
      'temperature': main['temp'].round(),
      'feelsLike': main['feels_like'].round(),
      'humidity': main['humidity'],
      'pressure': main['pressure'],
      'description': weather['description'],
      'main': weather['main'],
      'icon': weather['icon'],
      'windSpeed': wind['speed'],
      'windDirection': wind['deg'],
      'visibility': data['visibility'] / 1000, // Convert to km
      'timestamp': DateTime.now().toIso8601String(),
      'isSafeForFishing': _isSafeForFishing(main['temp'], wind['speed'], weather['main']),
      'fishingAdvice': _getFishingAdvice(main['temp'], wind['speed'], weather['main']),
    };
  }

  /// Format forecast data
  List<Map<String, dynamic>> _formatForecastData(List<dynamic> forecastList, int days) {
    List<Map<String, dynamic>> formattedForecast = [];
    
    for (int i = 0; i < forecastList.length && i < days * 8; i += 8) {
      final item = forecastList[i];
      final main = item['main'];
      final weather = item['weather'][0];
      
      formattedForecast.add({
        'date': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000).toIso8601String(),
        'temperature': main['temp'].round(),
        'minTemp': main['temp_min'].round(),
        'maxTemp': main['temp_max'].round(),
        'description': weather['description'],
        'icon': weather['icon'],
        'humidity': main['humidity'],
        'windSpeed': item['wind']['speed'],
        'isSafeForFishing': _isSafeForFishing(main['temp'], item['wind']['speed'], weather['main']),
      });
    }
    
    return formattedForecast;
  }

  /// Generate weather alerts based on current conditions
  List<Map<String, dynamic>> _generateWeatherAlerts(Map<String, dynamic> data) {
    List<Map<String, dynamic>> alerts = [];
    final main = data['main'];
    final weather = data['weather'][0];
    final wind = data['wind'];
    
    // Temperature alerts
    if (main['temp'] > 35) {
      alerts.add({
        'type': 'heat_warning',
        'title': 'Heat Warning',
        'message': 'High temperatures detected. Stay hydrated and avoid prolonged sun exposure.',
        'severity': 'high',
        'icon': '🌡️',
      });
    }
    
    // Wind alerts
    if (wind['speed'] > 15) {
      alerts.add({
        'type': 'wind_warning',
        'title': 'Strong Wind Warning',
        'message': 'Strong winds detected. Exercise caution when fishing.',
        'severity': 'medium',
        'icon': '💨',
      });
    }
    
    // Storm alerts
    if (weather['main'] == 'Thunderstorm' || weather['main'] == 'Rain') {
      alerts.add({
        'type': 'storm_warning',
        'title': 'Storm Warning',
        'message': 'Storm conditions detected. Avoid fishing until conditions improve.',
        'severity': 'high',
        'icon': '⛈️',
      });
    }
    
    // Fishing safety alerts
    if (!_isSafeForFishing(main['temp'], wind['speed'], weather['main'])) {
      alerts.add({
        'type': 'fishing_warning',
        'title': 'Fishing Safety Warning',
        'message': 'Current weather conditions are not safe for fishing. Please stay ashore.',
        'severity': 'high',
        'icon': '⚠️',
      });
    }
    
    return alerts;
  }

  /// Check if weather conditions are safe for fishing
  bool _isSafeForFishing(double temperature, double windSpeed, String weatherMain) {
    // Unsafe conditions
    if (weatherMain == 'Thunderstorm' || weatherMain == 'Rain') return false;
    if (windSpeed > 20) return false; // Strong winds
    if (temperature < 15 || temperature > 40) return false; // Extreme temperatures
    
    return true;
  }

  /// Get fishing advice based on weather conditions for Samar waters
  String _getFishingAdvice(double temperature, double windSpeed, String weatherMain) {
    if (weatherMain == 'Thunderstorm' || weatherMain == 'Rain') {
      return 'Avoid fishing in Samar waters due to storm conditions. Stay safe on shore.';
    }
    
    if (windSpeed > 15) {
      return 'Strong winds detected in Samar. Consider fishing in sheltered areas like Basey or Marabut bays only.';
    }
    
    if (temperature > 35) {
      return 'Hot weather in Samar. Stay hydrated and fish during cooler hours (early morning or late afternoon).';
    }
    
    if (temperature < 20) {
      return 'Cool weather in Samar. Dress warmly and check your fishing equipment before heading out.';
    }
    
    return 'Good weather conditions for fishing in Samar waters. Enjoy your time on the water!';
  }

  /// Get list of available Philippine cities
  List<String> getAvailableCities() {
    return _philippineCities.keys.toList();
  }

  /// Get city coordinates
  Map<String, double>? getCityCoordinates(String cityName) {
    return _philippineCities[cityName];
  }
}
