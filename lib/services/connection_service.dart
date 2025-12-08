import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final SupabaseClient _supabase = SupabaseConfig.client;
  Timer? _connectionTimer;
  bool _isConnected = false;
  int _retryCount = 0;
  static const int maxRetries = 3;
  static const Duration timeoutDuration = Duration(seconds: 10);
  static const Duration retryDelay = Duration(seconds: 2);

  bool get isConnected => _isConnected;

  /// Test connection with timeout and retry logic
  Future<bool> testConnection() async {
    try {
      _isConnected = false;
      
      // Test with a simple query and timeout
      await _supabase
          .from('fishermen')
          .select('id')
          .limit(1)
          .timeout(timeoutDuration);
      
      _isConnected = true;
      _retryCount = 0;
      return true;
    } on TimeoutException {
      print('Connection timeout - retrying...');
      return await _retryConnection();
    } on SocketException catch (e) {
      print('Socket exception: $e');
      return await _retryConnection();
    } on PostgrestException catch (e) {
      print('Database exception: $e');
      return false;
    } catch (e) {
      print('Connection error: $e');
      return await _retryConnection();
    }
  }

  /// Retry connection with exponential backoff
  Future<bool> _retryConnection() async {
    if (_retryCount >= maxRetries) {
      print('Max retries reached. Connection failed.');
      _isConnected = false;
      return false;
    }

    _retryCount++;
    print('Retrying connection (attempt $_retryCount/$maxRetries)...');
    
    await Future.delayed(retryDelay * _retryCount);
    return await testConnection();
  }

  /// Execute query with connection retry
  Future<T> executeWithRetry<T>(
    Future<T> Function() query, {
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // Don't block on connection test - try query directly
        // Connection test might fail even if query can succeed
        
        // Execute query with timeout
        final result = await query().timeout(timeout);
        _isConnected = true;
        _retryCount = 0;
        return result;
        
      } on TimeoutException catch (e) {
        print('Query timeout (attempt ${attempts + 1}/$maxRetries): $e');
        _isConnected = false;
        attempts++;
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempts));
        }
      } on SocketException catch (e) {
        print('Socket error (attempt ${attempts + 1}/$maxRetries): $e');
        _isConnected = false;
        attempts++;
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempts));
        }
      } on PostgrestException catch (e) {
        print('Database error: ${e.message}');
        print('Error code: ${e.code}');
        print('Error details: ${e.details}');
        print('Error hint: ${e.hint}');
        // Don't retry on RLS/permission errors - these are policy issues
        if (e.code == '42501' || e.code == 'PGRST301') {
          rethrow;
        }
        // Retry on other database errors
        attempts++;
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempts));
        } else {
          rethrow;
        }
      } catch (e) {
        print('Unexpected error (attempt ${attempts + 1}/$maxRetries): $e');
        print('Error type: ${e.runtimeType}');
        _isConnected = false;
        attempts++;
        if (attempts < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempts));
        } else {
          rethrow;
        }
      }
    }
    
    throw Exception('Failed to execute query after $maxRetries attempts');
  }

  /// Get connection status
  Future<bool> getConnectionStatus() async {
    try {
      await _supabase
          .from('fishermen')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Start periodic connection monitoring
  void startConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await getConnectionStatus();
    });
  }

  /// Stop connection monitoring
  void stopConnectionMonitoring() {
    _connectionTimer?.cancel();
  }

  /// Dispose resources
  void dispose() {
    stopConnectionMonitoring();
  }
}


