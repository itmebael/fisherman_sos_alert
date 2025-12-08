import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';
import '../models/user_model.dart';
import '../data/local/shared_preferences_helper.dart';
import '../supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  UserModel? _currentUser;

  // Hardcoded admin credentials
  static const String _adminEmail = 'phicoastguard@gmail.com';
  static const String _adminPassword = 'philippinecoastguard@2025';

  UserModel? get currentUser => _currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Initialize auth service
  Future<void> initialize() async {
    // Check if user is already logged in
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _fetchUserData(session.user.id);
    }
  }

  // Login method with hardcoded admin support
  Future<bool> login(String email, String password) async {
    try {
      // Check for hardcoded admin credentials first
      if (email.trim().toLowerCase() == _adminEmail && password == _adminPassword) {
        // Do NOT call Supabase for hardcoded admin. Proceed offline so login never fails on network.
        _currentUser = UserModel(
          id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
          firstName: "Philippine",
          lastName: "Coast Guard",
          name: "Philippine Coast Guard",
          email: email.trim(),
          phone: '',
          userType: 'coastguard',
          registrationDate: DateTime.now(),
          isActive: true,
          createdAt: DateTime.now(),
        );
        await SharedPreferencesHelper.saveUserData(_currentUser!);
        return true;
      }

      // For other users, use Supabase authentication with timeout and retry
      try {
        // Set timeout for the authentication request
        final response = await _supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw 'Connection timeout. Please check your internet connection and try again.';
          },
        );

        if (response.user != null) {
          await _fetchUserData(response.user!.id);
          return true;  
        }

        return false;
      } on TimeoutException {
        throw 'Connection timeout. Please check your internet connection and try again.';
      } on SocketException catch (e) {
        throw 'Network error. Please check your internet connection: ${e.message}';
      } on AuthException catch (e) {
        throw _getAuthErrorMessage(e.message);
      } catch (e) {
        if (e.toString().contains('ClientException') || e.toString().contains('timeout')) {
          throw 'Unable to connect to the server. Please check your internet connection and try again.';
        }
        throw 'Login failed: ${e.toString()}';
      }
    } catch (e) {
      // Surface more helpful detail in debug logs; keep user-friendly message
      print('Login error: $e');
      
      final errorMessage = e.toString();
      if (errorMessage.contains('timeout') || errorMessage.contains('ClientException')) {
        throw 'Unable to connect to the server. Please check your internet connection.';
      } else if (errorMessage.contains('Invalid login credentials')) {
        throw 'Invalid email or password.';
      } else {
        throw errorMessage;
      }
    }
  }

  // Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String userType,
    String? profileImageUrl,
    String? address,
    String? fishingArea,
    String? emergencyContactPerson,
  }) async {
    try {
      // Create user in Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        // Create user profile in database
        final userData = {
          'id': response.user!.id,
          'email': email.trim(),
          'first_name': firstName,
          'last_name': lastName,
          'name': '$firstName $lastName',
          'phone': phone,
          'user_type': userType,
          'registration_date': DateTime.now().toIso8601String(),
          'is_active': true,
          if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
          if (address != null) 'address': address,
          if (fishingArea != null) 'fishing_area': fishingArea,
          if (emergencyContactPerson != null) 'emergency_contact_person': emergencyContactPerson,
        };

        // Insert into appropriate table based on user type
        if (userType == 'fisherman') {
          await _supabase.from('fishermen').insert(userData);
        } else if (userType == 'coastguard') {
          await _supabase.from('coastguards').insert(userData);
        }

        return true;
      }

      return false;
    } on AuthException catch (e) {
      throw _getAuthErrorMessage(e.message);
    } catch (e) {
      throw 'Registration failed. Please check your connection.';
    }
  }

  // Register boat and fisherman
  Future<bool> registerBoatAndFisherman({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String boatName,
    required String boatType,
    required String boatRegistrationNumber,
    required String boatCapacity,
    String? profileImageUrl,
    String? address,
    String? fishingArea,
    String? emergencyContactPerson,
  }) async {
    try {
      // Create fisherman account
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // Create fisherman profile
        final fishermanData = {
          'id': userId,
          'email': email.trim(),
          'first_name': firstName,
          'last_name': lastName,
          'name': '$firstName $lastName',
          'phone': phone,
          'user_type': 'fisherman',
          'registration_date': DateTime.now().toIso8601String(),
          'is_active': true,
          if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
          if (address != null) 'address': address,
          if (fishingArea != null) 'fishing_area': fishingArea,
          if (emergencyContactPerson != null) 'emergency_contact_person': emergencyContactPerson,
        };

        await _supabase.from('fishermen').insert(fishermanData);

        // Create boat record
        final boatData = {
          'id': 'boat_${DateTime.now().millisecondsSinceEpoch}',
          'owner_id': userId,
          'name': boatName,
          'type': boatType,
          'registration_number': boatRegistrationNumber,
          'capacity': int.tryParse(boatCapacity) ?? 0,
          'registration_date': DateTime.now().toIso8601String(),
          'is_active': true,
        };

        await _supabase.from('boats').insert(boatData);

        return true;
      }

      return false;
    } on AuthException catch (e) {
      throw _getAuthErrorMessage(e.message);
    } catch (e) {
      throw 'Boat registration failed. Please check your connection.';
    }
  }

  // Fetch user data from database
  Future<void> _fetchUserData(String userId) async {
    try {
      // Try to fetch from fishermen table first
      final fishermanResponse = await _supabase
          .from('fishermen')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (fishermanResponse != null) {
        _currentUser = UserModel.fromMap(fishermanResponse);
        await SharedPreferencesHelper.saveUserData(_currentUser!);
        return;
      }

      // Try to fetch from coastguards table
      final coastguardResponse = await _supabase
          .from('coastguards')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (coastguardResponse != null) {
        _currentUser = UserModel.fromMap(coastguardResponse);
        await SharedPreferencesHelper.saveUserData(_currentUser!);
        return;
      }

      // If not found in either table, create a basic user object
      final authUser = _supabase.auth.currentUser;
      if (authUser != null) {
        _currentUser = UserModel(
          id: authUser.id,
          firstName: authUser.userMetadata?['first_name'] ?? 'User',
          lastName: authUser.userMetadata?['last_name'] ?? '',
          name: authUser.userMetadata?['name'] ?? 'User',
          email: authUser.email ?? '',
          phone: authUser.userMetadata?['phone'] ?? '',
          userType: 'fisherman', // Default type
          registrationDate: DateTime.now(),
          isActive: true,
          createdAt: DateTime.now(),
        );
        await SharedPreferencesHelper.saveUserData(_currentUser!);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      await SharedPreferencesHelper.clearUserData();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Get user boats (for fishermen)
  Future<List<Map<String, dynamic>>> getUserBoats(String userId) async {
    try {
      final response = await _supabase
          .from('boats')
          .select()
          .eq('owner_id', userId)
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user boats: $e');
      return [];
    }
  }

  // Get all boats (for admin)
  Future<List<Map<String, dynamic>>> getAllBoats() async {
    try {
      final response = await _supabase
          .from('boats')
          .select('*, fishermen(*)')
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all boats: $e');
      return [];
    }
  }

  // Get all fishermen
  Future<List<Map<String, dynamic>>> getAllFishermen() async {
    try {
      final response = await _supabase
          .from('fishermen')
          .select()
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching fishermen: $e');
      return [];
    }
  }

  // Get all coastguards
  Future<List<Map<String, dynamic>>> getAllCoastguards() async {
    try {
      final response = await _supabase
          .from('coastguards')
          .select()
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching coastguards: $e');
      return [];
    }
  }

  // Reset password - sends password reset email
  Future<void> resetPassword(String email) async {
    try {
      // Don't allow password reset for hardcoded admin account
      if (email.trim().toLowerCase() == _adminEmail) {
        throw 'Password reset is not available for this account. Please contact your administrator.';
      }

      // Use Supabase password reset with timeout
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw 'Connection timeout. Please check your internet connection and try again.';
        },
      );
    } on TimeoutException {
      throw 'Connection timeout. Please check your internet connection and try again.';
    } on SocketException catch (e) {
      throw 'Network error. Please check your internet connection: ${e.message}';
    } on AuthException catch (e) {
      throw _getAuthErrorMessage(e.message);
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('timeout') || errorMessage.contains('ClientException')) {
        throw 'Unable to connect to the server. Please check your internet connection.';
      } else if (errorMessage.contains('Invalid email')) {
        throw 'Please enter a valid email address.';
      } else {
        throw _getAuthErrorMessage(errorMessage);
      }
    }
  }

  // Helper method to convert auth error messages
  String _getAuthErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    } else if (message.contains('User already registered')) {
      return 'An account with this email already exists.';
    } else if (message.contains('Password should be at least')) {
      return 'Password must be at least 6 characters long.';
    } else if (message.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    } else if (message.contains('User not found') || message.contains('does not exist')) {
      return 'No account found with this email address.';
    } else {
      return message;
    }
  }

  // Web login (for future implementation)
  Future<void> openWebLogin() async {
    throw 'Web login not implemented yet';
  }
}

