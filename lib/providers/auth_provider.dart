import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  User? _supabaseUser;
  bool _isAuthenticated = false;
  String? _adminPassword;
  String? get adminPassword => _adminPassword;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isAuthenticated && _currentUser != null;
  User? get supabaseUser => _supabaseUser;
  bool get isAdmin => _currentUser?.userType == 'coastguard';
  bool get isFisherman => _currentUser?.userType == 'fisherman';

  // Initialize auth state listener (keeps app synced with auth state)
  void initializeAuthListener() {
    _authService.authStateChanges.listen((data) async {
      if (data.session != null) {
        _isAuthenticated = true;
        _currentUser = _authService.currentUser;
        _supabaseUser = data.session!.user;
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        _supabaseUser = null;
      }
      notifyListeners();
    });
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _authService.login(email, password);
      if (success) {
        _currentUser = _authService.currentUser;
        // _supabaseUser will be set by the auth state listener
        _isAuthenticated = true;
        _adminPassword = password; // Store it here
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      _isAuthenticated = false;
      return false;
    }
  }

  // Web login (for fisherman accounts, if needed)
  Future<void> openWebLogin() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.openWebLogin();
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);

      await _authService.logout();
      _currentUser = null;
      _supabaseUser = null;
      _isAuthenticated = false;
      _clearError();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  // Register - Updated to use the new AuthService register method
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String userType,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        userType: userType,
      );
      
      if (success) {
        _currentUser = _authService.currentUser;
        _isAuthenticated = true;
      } else {
        _setError('Registration failed');
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }


  // Reset password - sends password reset email
  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.resetPassword(email);
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      rethrow;
    }
  }

  // Check auth status (useful for splash screen)
  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = _authService.isLoggedIn;
      if (isLoggedIn) {
        _currentUser = _authService.currentUser;
        _isAuthenticated = true;
      } else {
        _currentUser = null;
        _isAuthenticated = false;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Auth status check error: $e');
      }
      _isAuthenticated = false;
      notifyListeners();
    }
  }


  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}