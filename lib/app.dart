import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'constants/colors.dart';
import 'constants/routes.dart';
import 'providers/auth_provider.dart';

class BantayDagatApp extends StatelessWidget {
  const BantayDagatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salbar Mangirisda',
      theme: ThemeData(
        primarySwatch: AppColors.primarySwatch,
        textTheme: GoogleFonts.poppinsTextTheme(
          const TextTheme(
            displayLarge: TextStyle(fontSize: 57),
            displayMedium: TextStyle(fontSize: 45),
            displaySmall: TextStyle(fontSize: 36),
            headlineLarge: TextStyle(fontSize: 32),
            headlineMedium: TextStyle(fontSize: 28),
            headlineSmall: TextStyle(fontSize: 24),
            titleLarge: TextStyle(fontSize: 22),
            titleMedium: TextStyle(fontSize: 16),
            titleSmall: TextStyle(fontSize: 14),
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14),
            bodySmall: TextStyle(fontSize: 12),
            labelLarge: TextStyle(fontSize: 14),
            labelMedium: TextStyle(fontSize: 12),
            labelSmall: TextStyle(fontSize: 11),
          ),
        ).apply(
          fontSizeFactor: 1.5,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Initialize auth listener when app starts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.initializeAuthListener();
        });
        return child!;
      },
    );
  }
}