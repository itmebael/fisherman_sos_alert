import 'package:flutter/material.dart';

class AppColors {
  // Modern Ocean/Coastal Theme Colors
  static const Color primaryColor = Color(0xFF1976D2); // Standard Blue
  static const Color primaryLight = Color(0xFF42A5F5); // Light Blue
  static const Color secondaryColor = Color(0xFF03A9F4); // Light Blue
  static const Color accentColor = Color(0xFF2196F3); // Material Blue
  
  // Gradient Colors
  static const Color gradientStart = Color(0xFF1976D2);
  static const Color gradientEnd = Color(0xFF03A9F4);
  static const Color gradientSecondaryStart = Color(0xFF42A5F5);
  static const Color gradientSecondaryEnd = Color(0xFF2196F3);
  
  // Modern Background Colors
  static const Color backgroundPrimary = Color(0xFFF8FAFC); // Light Gray
  static const Color backgroundSecondary = Color(0xFFFFFFFF); // Pure White
  static const Color backgroundTertiary = Color(0xFFF1F5F9); // Slightly Gray
  
  // Drawer Colors
  static const Color drawerColor = Color(0xFF1E293B); // Dark Slate
  static const Color drawerAccent = Color(0xFF334155); // Lighter Slate
  static const Color drawerItemColor = Color(0xFF475569); // Medium Slate
  
  // Card Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0xFFE2E8F0);
  
  // Alert Colors
  static const Color sosButtonColor = Color(0xFFEF4444); // Modern Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color errorColor = Color(0xFFEF4444); // Red
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate
  static const Color textSecondary = Color(0xFF64748B); // Medium Gray
  static const Color textTertiary = Color(0xFF94A3B8); // Light Gray
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Border and Divider Colors
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color dividerColor = Color(0xFFF1F5F9);
  
  // Legacy Colors (keeping for compatibility)
  static const Color homeBackground = backgroundPrimary;
  static const Color newsBackground = backgroundSecondary;
  static const Color backgroundColor = backgroundPrimary;
  static const Color whiteColor = Color(0xFFFFFFFF);

  // Material Design Color Swatch
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF1976D2,
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );
}