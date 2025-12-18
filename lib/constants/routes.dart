import 'package:flutter/material.dart';
import '../screens/common/splash_screen.dart';
import '../screens/common/login_screen.dart';
import '../screens/fisherman/fisherman_home_screen.dart';
import '../screens/fisherman/fisherman_profile_screen.dart';
import '../screens/fisherman/fisherman_edit_profile_screen.dart';
import '../screens/fisherman/fisherman_news_screen.dart';
import '../screens/fisherman/fisherman_notifications_screen.dart';
import '../screens/fisherman/fisherman_map_screen.dart';
import '../screens/fisherman/fisherman_account_creation_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/users_page_simple.dart';
import '../screens/admin/user_management_page.dart';
import '../screens/admin/rescue_notifications_page.dart';
import '../screens/admin/navigation_page.dart';
import '../screens/admin/admin_map.dart';
import '../screens/admin/reports_page.dart';
import '../screens/admin/register_page.dart';
import '../screens/admin/users_registration_page_simple.dart';
import '../screens/admin/boat_registration_page_simple.dart';
import '../screens/admin/device_management_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String fishermanHome = '/fisherman-home';
  static const String fishermanNews = '/fisherman-news';
  static const String fishermanNotifications = '/fisherman-notifications';
  static const String fishermanMap = '/fisherman-map';
  static const String fishermanProfile = '/fisherman-profile';
  static const String fishermanEditProfile = '/fisherman-edit-profile';
  static const String fishermanAccountCreation = '/fisherman-account-creation';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminUsers = '/admin-users';
  static const String userManagement = '/user-management';
  static const String rescueNotifications = '/rescue-notifications';
  static const String navigation = '/navigation';
  static const String adminMap = '/admin-map';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String register = '/register';
  static const String usersRegistration = '/usersRegistration';
  static const String boatRegistration = '/boatRegistration';
  static const String deviceManagement = '/device-management';
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    fishermanHome: (context) => const FishermanHomeScreen(),
    fishermanNews: (context) => const FishermanNewsScreen(),
    fishermanNotifications: (context) => const FishermanNotificationsScreen(),
    fishermanMap: (context) => const FishermanMapScreen(),
    fishermanProfile: (context) => const FishermanProfileScreen(),
    fishermanEditProfile: (context) => const FishermanEditProfileScreen(),
    fishermanAccountCreation: (context) => const FishermanAccountCreationScreen(),
    adminDashboard: (context) => const AdminDashboard(),
    adminUsers: (context) => const UsersPageSimple(),
    userManagement: (context) => const UserManagementPage(),
    rescueNotifications: (context) => const RescueNotificationsPage(),
    navigation: (context) => const NavigationPage(),
    adminMap: (context) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AdminMapScreen.fromRouteArguments(arguments);
    },
    reports: (context) => const ReportsPage(),
    register: (context) => const RegisterPage(),
    usersRegistration: (context) => const UsersRegistrationPageSimple(),
    boatRegistration: (context) => const BoatRegistrationPageSimple(),
    deviceManagement: (context) => const DeviceManagementPage(),
  };
}