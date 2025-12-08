class WeatherModel {
  final String city;
  final int temperature;
  final int feelsLike;
  final int humidity;
  final int pressure;
  final String description;
  final String main;
  final String icon;
  final double windSpeed;
  final int windDirection;
  final double visibility;
  final String timestamp;
  final bool isSafeForFishing;
  final String fishingAdvice;

  WeatherModel({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.description,
    required this.main,
    required this.icon,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.timestamp,
    required this.isSafeForFishing,
    required this.fishingAdvice,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['city'] ?? '',
      temperature: json['temperature'] ?? 0,
      feelsLike: json['feelsLike'] ?? 0,
      humidity: json['humidity'] ?? 0,
      pressure: json['pressure'] ?? 0,
      description: json['description'] ?? '',
      main: json['main'] ?? '',
      icon: json['icon'] ?? '',
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      windDirection: json['windDirection'] ?? 0,
      visibility: (json['visibility'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
      isSafeForFishing: json['isSafeForFishing'] ?? false,
      fishingAdvice: json['fishingAdvice'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'pressure': pressure,
      'description': description,
      'main': main,
      'icon': icon,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'visibility': visibility,
      'timestamp': timestamp,
      'isSafeForFishing': isSafeForFishing,
      'fishingAdvice': fishingAdvice,
    };
  }

  WeatherModel copyWith({
    String? city,
    int? temperature,
    int? feelsLike,
    int? humidity,
    int? pressure,
    String? description,
    String? main,
    String? icon,
    double? windSpeed,
    int? windDirection,
    double? visibility,
    String? timestamp,
    bool? isSafeForFishing,
    String? fishingAdvice,
  }) {
    return WeatherModel(
      city: city ?? this.city,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      description: description ?? this.description,
      main: main ?? this.main,
      icon: icon ?? this.icon,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      visibility: visibility ?? this.visibility,
      timestamp: timestamp ?? this.timestamp,
      isSafeForFishing: isSafeForFishing ?? this.isSafeForFishing,
      fishingAdvice: fishingAdvice ?? this.fishingAdvice,
    );
  }

  // Helper methods
  String get temperatureDisplay => '$temperature°C';
  String get feelsLikeDisplay => 'Feels like $feelsLike°C';
  String get humidityDisplay => '$humidity%';
  String get windSpeedDisplay => '${windSpeed.toStringAsFixed(1)} m/s';
  String get visibilityDisplay => '${visibility.toStringAsFixed(1)} km';
  
  String get windDirectionText {
    if (windDirection >= 337.5 || windDirection < 22.5) return 'N';
    if (windDirection >= 22.5 && windDirection < 67.5) return 'NE';
    if (windDirection >= 67.5 && windDirection < 112.5) return 'E';
    if (windDirection >= 112.5 && windDirection < 157.5) return 'SE';
    if (windDirection >= 157.5 && windDirection < 202.5) return 'S';
    if (windDirection >= 202.5 && windDirection < 247.5) return 'SW';
    if (windDirection >= 247.5 && windDirection < 292.5) return 'W';
    if (windDirection >= 292.5 && windDirection < 337.5) return 'NW';
    return 'N';
  }

  String get weatherIconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
  
  String get safetyStatus {
    return isSafeForFishing ? 'Safe for Fishing' : 'Not Safe for Fishing';
  }
  
  String get safetyIcon {
    return isSafeForFishing ? '✅' : '⚠️';
  }
}

class WeatherForecastModel {
  final DateTime date;
  final int temperature;
  final int minTemp;
  final int maxTemp;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final bool isSafeForFishing;

  WeatherForecastModel({
    required this.date,
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.isSafeForFishing,
  });

  factory WeatherForecastModel.fromJson(Map<String, dynamic> json) {
    return WeatherForecastModel(
      date: DateTime.parse(json['date']),
      temperature: json['temperature'] ?? 0,
      minTemp: json['minTemp'] ?? 0,
      maxTemp: json['maxTemp'] ?? 0,
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      humidity: json['humidity'] ?? 0,
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      isSafeForFishing: json['isSafeForFishing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'temperature': temperature,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'description': description,
      'icon': icon,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'isSafeForFishing': isSafeForFishing,
    };
  }

  String get temperatureRange => '$minTemp°C - $maxTemp°C';
  String get weatherIconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
  String get dayName {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class WeatherAlertModel {
  final String type;
  final String title;
  final String message;
  final String severity;
  final String icon;

  WeatherAlertModel({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
  });

  factory WeatherAlertModel.fromJson(Map<String, dynamic> json) {
    return WeatherAlertModel(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'low',
      icon: json['icon'] ?? '⚠️',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'severity': severity,
      'icon': icon,
    };
  }

  bool get isHighSeverity => severity == 'high';
  bool get isMediumSeverity => severity == 'medium';
  bool get isLowSeverity => severity == 'low';
}


