import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/sos_provider.dart';
import 'providers/admin_provider_simple.dart';
import 'supabase_config.dart';
import 'services/connection_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Initialize connection service
  final connectionService = ConnectionService();
  await connectionService.testConnection();
  connectionService.startConnectionMonitoring();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initializeAuthListener()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => SOSProvider()),
        ChangeNotifierProvider(create: (_) => AdminProviderSimple()),
      ],
      child: const BantayDagatApp(),
    ),
  );
}