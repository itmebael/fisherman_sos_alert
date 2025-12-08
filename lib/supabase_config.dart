import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Your Supabase project credentials
  static const String supabaseUrl = 'https://khptgibwfuvsrcjgqgsf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtocHRnaWJ3ZnV2c3JjamdxZ3NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyMzU3OTIsImV4cCI6MjA3MzgxMTc5Mn0.iZYGU2SkUyDsZfbvYqdsBjZbz_wY7HcZGi0GX64gPEc';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

