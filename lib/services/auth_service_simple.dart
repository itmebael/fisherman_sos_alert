import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../data/local/shared_preferences_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Mock user for testing
  dynamic get supabaseUser => null;

  // Mock auth state changes
  Stream<dynamic> get authStateChanges => Stream.empty();

  // Register admin/coastguard - Mock implementation
  Future<bool> registerAdmin({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      // Mock registration - in real implementation, this would call Supabase
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser = UserModel(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        name: "$firstName${middleName != null && middleName.isNotEmpty ? ' $middleName' : ''} $lastName",
        email: email.trim(),
        phone: '',
        userType: 'coastguard',
        registrationDate: DateTime.now(),
        isActive: true,
        address: null,
        fishingArea: null,
        emergencyContactPerson: null,
      );

      await SharedPreferencesHelper.saveUserData(_currentUser!);
      return true;
    } catch (e) {
      throw 'Registration failed. Please check your connection.';
    }
  }

  // Login method - Mock implementation
  Future<bool> login(String email, String password) async {
    try {
      // Mock login - in real implementation, this would call Supabase
      await Future.delayed(const Duration(seconds: 1));
      
      // Hardcoded credentials for testing
      if (email.trim().toLowerCase() == "phicoastguard@gmail.com" && 
          password == "philippinecoastguard@2025") {
        _currentUser = UserModel(
          id: 'mock_admin_${DateTime.now().millisecondsSinceEpoch}',
          firstName: "Philippine",
          lastName: "Coast Guard",
          name: "Philippine Coast Guard",
          email: email.trim(),
          phone: '',
          userType: 'coastguard',
          registrationDate: DateTime.now(),
          isActive: true,
        );
        await SharedPreferencesHelper.saveUserData(_currentUser!);
        return true;
      }
      
      // Also keep the old admin@gmail.com for backward compatibility
      if (email.trim().toLowerCase() == "admin@gmail.com") {
        _currentUser = UserModel(
          id: 'mock_admin_${DateTime.now().millisecondsSinceEpoch}',
          firstName: "Admin",
          lastName: "User",
          name: "Admin User",
          email: email.trim(),
          phone: '',
          userType: 'coastguard',
          registrationDate: DateTime.now(),
          isActive: true,
        );
        await SharedPreferencesHelper.saveUserData(_currentUser!);
        return true;
      }
      
      return false;
    } catch (e) {
      throw 'An unexpected error occurred. Please check your connection.';
    }
  }

  Future<void> openWebLogin() async {
    // Mock implementation
    throw 'Web login not implemented yet';
  }

  Future<void> logout() async {
    try {
      _currentUser = null;
      await SharedPreferencesHelper.clearUserData();
    } catch (e) {
      throw 'Logout failed';
    }
  }

  // Register fisherman - Mock implementation
  Future<bool> register(UserModel user, String password) async {
    try {
      // Mock registration
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser = user;
      await SharedPreferencesHelper.saveUserData(user);
      return true;
    } catch (e) {
      throw 'Registration failed. Please check your connection.';
    }
  }

  Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;
    
    // Try to load from shared preferences
    try {
      final userData = await SharedPreferencesHelper.getUserData();
      if (userData != null) {
        _currentUser = userData;
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
    
    return false;
  }

  String _getAuthErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account';
    } else if (message.contains('User already registered')) {
      return 'An account with this email already exists';
    } else if (message.contains('Password should be at least')) {
      return 'Password is too weak (minimum 6 characters)';
    } else if (message.contains('Invalid email')) {
      return 'Please enter a valid email address';
    } else if (message.contains('Too many requests')) {
      return 'Too many failed attempts. Please try again later';
    } else {
      return 'Login failed. Please check your credentials and try again';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      // Mock implementation - simulate sending reset email
      await Future.delayed(const Duration(seconds: 1));
      
      // Validate email format
      if (email.trim().isEmpty) {
        throw 'Please enter your email address.';
      }
      
      // Check if it's a valid email format (basic check)
      if (!email.contains('@') || !email.contains('.')) {
        throw 'Please enter a valid email address.';
      }
      
      // In a real implementation, this would send an email
      // For now, we'll just simulate success
    } catch (e) {
      throw _getAuthErrorMessage(e.toString());
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
      _currentUser = user;
      await SharedPreferencesHelper.saveUserData(user);
    } catch (e) {
      throw 'Profile update failed. Please check your connection.';
    }
  }
}
