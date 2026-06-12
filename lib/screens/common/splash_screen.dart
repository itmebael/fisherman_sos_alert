import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/routes.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));

    _controller.forward();
  }

  bool _isNavigating = false;

  Future<void> _performNavigation() async {
    if (_isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });

    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();
    
    if (mounted) {
      // Check if user is logged in
      if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        // User is logged in, navigate based on user type
        if (authProvider.currentUser!.userType == 'coastguard') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else if (authProvider.currentUser!.userType == 'fisherman') {
          Navigator.pushReplacementNamed(context, AppRoutes.fishermanHome);
        } else {
          // Unknown user type, go to login
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        // User is not logged in, go to login screen
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 760;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (!_isNavigating) {
            _performNavigation();
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/img/bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildLogoRow(isNarrow),
                            ),
                            const SizedBox(height: 32),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                AppStrings.appName,
                                style: TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                'Fisherman Emergency Alert System',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 42),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildFeatureSection(isNarrow),
                            ),
                            const SizedBox(height: 50),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildContinueButton(isNarrow),
                            ),
                            const SizedBox(height: 18),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                'Your safety is our mission.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoRow(bool isNarrow) {
    final double logoSize = isNarrow ? 100 : 140;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: isNarrow ? 16 : 24,
      runSpacing: isNarrow ? 12 : 16,
      children: [
        _buildLogoCircle('assets/img/logo.png', size: logoSize),
        if (!isNarrow) _buildDividerLine(),
        _buildLogoCircle('assets/img/cglogo.png', size: logoSize),
      ],
    );
  }

  Widget _buildLogoCircle(String assetPath, {double size = 140}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDividerLine() {
    return Container(
      width: 1,
      height: 100,
      color: Colors.white24,
    );
  }

  Widget _buildFeatureSection(bool isNarrow) {
    final featureItems = [
      _buildFeatureItem(
        icon: Icons.notifications_active_rounded,
        title: 'Instant Alerts',
        subtitle: 'Get notified quickly',
        isNarrow: isNarrow,
      ),
      _buildFeatureItem(
        icon: Icons.location_on_rounded,
        title: 'Stay Safe',
        subtitle: 'Help when you need it',
        isNarrow: isNarrow,
      ),
      _buildFeatureItem(
        icon: Icons.group_rounded,
        title: 'Stronger Together',
        subtitle: 'A community that cares',
        isNarrow: isNarrow,
      ),
    ];

    if (isNarrow) {
      final screenWidth = MediaQuery.of(context).size.width;
      final rawItemWidth = (screenWidth - 48) / 3;
      final double itemWidth = (rawItemWidth as num).clamp(100.0, 160.0) as double;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: featureItems
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: SizedBox(width: itemWidth, child: item),
                  ))
              .toList(),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: featureItems
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: item,
              ))
          .toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isNarrow = false,
  }) {
    final double iconSize = isNarrow ? 26 : 32;
    final double circleSize = isNarrow ? 60 : 72;
    final double titleSize = isNarrow ? 13 : 15;
    final double subtitleSize = isNarrow ? 12 : 13;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: iconSize,
          ),
        ),
        SizedBox(height: isNarrow ? 10 : 14),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: isNarrow ? 4 : 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white70,
            fontSize: subtitleSize,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContinueButton(bool isNarrow) {
    final horizontal = isNarrow ? 20.0 : 32.0;
    final vertical = isNarrow ? 14.0 : 18.0;
    final fontSize = isNarrow ? 14.0 : 16.0;
    final iconSize = isNarrow ? 18.0 : 20.0;

    return GestureDetector(
      onTap: _performNavigation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3A8DFF),
              Color(0xFF1B55E3),
            ],
          ),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.26), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: iconSize,
            ),
            SizedBox(width: isNarrow ? 10 : 12),
            Text(
              'Tap to continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: isNarrow ? 10 : 14),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ],
        ),
      ),
    );
  }
}
