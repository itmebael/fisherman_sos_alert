import 'package:flutter/material.dart';
import '../screens/common/splash_screen.dart';
import '../screens/common/login_screen.dart';
import '../screens/fisherman/fisherman_home_screen.dart';
import '../screens/fisherman/fisherman_news_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/users_page.dart';
import '../screens/admin/rescue_notifications_page.dart';
import '../screens/admin/navigation_page.dart';
import '../screens/admin/reports_page.dart';
import '../screens/admin/register_page.dart';
import '../screens/admin/users_registration_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String fishermanHome = '/fisherman-home';
  static const String fishermanNews = '/fisherman-news';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminUsers = '/admin-users';
  static const String rescueNotifications = '/rescue-notifications';
  static const String navigation = '/navigation';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String register = '/register';
  static const String usersRegistration = '/usersRegistration';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    fishermanHome: (context) => const FishermanHomeScreen(),
    fishermanNews: (context) => const FishermanNewsScreen(),
    adminDashboard: (context) => const AdminDashboard(),
    adminUsers: (context) => const UsersPage(),
    rescueNotifications: (context) => const RescueNotificationsPage(),
    navigation: (context) => const NavigationPage(),
    reports: (context) => const ReportsPage(),
    register: (context) => const RegisterPage(),
    usersRegistration: (context) => const UsersRegistrationPage(),
  };
}