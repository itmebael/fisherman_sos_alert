import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/routes.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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

    _controller.forward();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor,
              AppColors.drawerColor,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return MediaQuery.of(context).size.width < 600
                  ? _buildMobileLayout()
                  : _buildWebLayout();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/img/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // App name
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Subtitle
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              'Fisherman Emergency Alert System',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.whiteColor,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Loading indicator
          FadeTransition(
            opacity: _fadeAnimation,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.whiteColor,
              ),
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/img/logo.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // App name
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteColor,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Subtitle
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Fisherman Emergency Alert System',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Loading indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.whiteColor,
                ),
                strokeWidth: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}