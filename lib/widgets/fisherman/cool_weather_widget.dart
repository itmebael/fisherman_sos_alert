import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/weather_model.dart';

class CoolWeatherWidget extends StatefulWidget {
  final WeatherModel weather;
  final VoidCallback? onTap;

  const CoolWeatherWidget({
    super.key,
    required this.weather,
    this.onTap,
  });

  @override
  State<CoolWeatherWidget> createState() => _CoolWeatherWidgetState();
}

class _CoolWeatherWidgetState extends State<CoolWeatherWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: _getWeatherGradient(),
                  boxShadow: [
                    BoxShadow(
                      color: _getWeatherColor().withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Animated background particles
                      _buildAnimatedBackground(),
                      
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildTemperatureSection(),
                            const SizedBox(height: 16),
                            _buildDetailsSection(),
                            const SizedBox(height: 16),
                            _buildFishingSafetySection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: WeatherParticlesPainter(
              animation: _pulseAnimation.value,
              weatherType: widget.weather.main,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.weather.city,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.weather.description.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Image.network(
            widget.weather.weatherIconUrl,
            width: 50,
            height: 50,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                _getWeatherIcon(),
                size: 50,
                color: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.weather.temperatureDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                widget.weather.feelsLikeDisplay,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                widget.weather.humidityDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            Icons.air,
            'Wind',
            widget.weather.windSpeedDisplay,
            widget.weather.windDirectionText,
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            Icons.visibility,
            'Visibility',
            widget.weather.visibilityDisplay,
            'km',
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            Icons.compress,
            'Pressure',
            '${widget.weather.pressure}',
            'hPa',
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishingSafetySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.weather.isSafeForFishing 
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.weather.isSafeForFishing 
              ? Colors.green.withOpacity(0.5)
              : Colors.red.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.weather.isSafeForFishing ? _pulseAnimation.value : 1.0,
                child: Icon(
                  widget.weather.isSafeForFishing ? Icons.check_circle : Icons.warning,
                  color: widget.weather.isSafeForFishing ? Colors.green : Colors.red,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.weather.safetyStatus,
                  style: TextStyle(
                    color: widget.weather.isSafeForFishing ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.weather.fishingAdvice,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getWeatherGradient() {
    switch (widget.weather.main.toLowerCase()) {
      case 'clear':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF87CEEB), // Sky blue
            Color(0xFF4682B4), // Steel blue
          ],
        );
      case 'clouds':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF708090), // Slate gray
            Color(0xFF2F4F4F), // Dark slate gray
          ],
        );
      case 'rain':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4169E1), // Royal blue
            Color(0xFF191970), // Midnight blue
          ],
        );
      case 'thunderstorm':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4B0082), // Indigo
            Color(0xFF000080), // Navy
          ],
        );
      case 'snow':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0F8FF), // Alice blue
            Color(0xFFB0C4DE), // Light steel blue
          ],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF87CEEB),
            Color(0xFF4682B4),
          ],
        );
    }
  }

  Color _getWeatherColor() {
    switch (widget.weather.main.toLowerCase()) {
      case 'clear':
        return const Color(0xFF87CEEB);
      case 'clouds':
        return const Color(0xFF708090);
      case 'rain':
        return const Color(0xFF4169E1);
      case 'thunderstorm':
        return const Color(0xFF4B0082);
      case 'snow':
        return const Color(0xFFF0F8FF);
      default:
        return const Color(0xFF87CEEB);
    }
  }

  IconData _getWeatherIcon() {
    switch (widget.weather.main.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_sunny;
    }
  }
}

class WeatherParticlesPainter extends CustomPainter {
  final double animation;
  final String weatherType;

  WeatherParticlesPainter({
    required this.animation,
    required this.weatherType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw animated particles based on weather type
    switch (weatherType.toLowerCase()) {
      case 'rain':
        _drawRainParticles(canvas, size, paint);
        break;
      case 'snow':
        _drawSnowParticles(canvas, size, paint);
        break;
      case 'clear':
        _drawSunParticles(canvas, size, paint);
        break;
      case 'clouds':
        _drawCloudParticles(canvas, size, paint);
        break;
      default:
        _drawDefaultParticles(canvas, size, paint);
    }
  }

  void _drawRainParticles(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 20; i++) {
      final x = (i * 20.0) % size.width;
      final y = (animation * 100 + i * 10) % size.height;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 2, y + 8),
        paint..strokeWidth = 1,
      );
    }
  }

  void _drawSnowParticles(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 15; i++) {
      final x = (i * 30.0) % size.width;
      final y = (animation * 80 + i * 15) % size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        2,
        paint,
      );
    }
  }

  void _drawSunParticles(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 10; i++) {
      final angle = (i * 36.0) * (math.pi / 180);
      final radius = 30 + animation * 10;
      final x = size.width / 2 + math.cos(angle) * radius;
      final y = size.height / 2 + math.sin(angle) * radius;
      
      canvas.drawCircle(
        Offset(x, y),
        3,
        paint,
      );
    }
  }

  void _drawCloudParticles(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 8; i++) {
      final x = (i * 50.0) % size.width;
      final y = (animation * 20 + i * 20) % size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        8,
        paint,
      );
    }
  }

  void _drawDefaultParticles(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 12; i++) {
      final x = (i * 40.0) % size.width;
      final y = (animation * 60 + i * 25) % size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WeatherParticlesPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.weatherType != weatherType;
  }
}


