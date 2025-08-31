import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  User? _firebaseUser;
  bool _isAuthenticated = false;
  String? _adminPassword;
  String? get adminPassword => _adminPassword;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isAuthenticated && _currentUser != null;
  User? get firebaseUser => _firebaseUser;
  bool get isAdmin => _currentUser?.userType == 'coastguard';
  bool get isFisherman => _currentUser?.userType == 'fisherman';

  // Initialize auth state listener (keeps app synced with Firebase login state)
  void initializeAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _fetchUserData(user.uid);
        _isAuthenticated = true;
      } else {
        _currentUser = null;
        _isAuthenticated = false;
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
        _firebaseUser = _authService.firebaseUser;
        _isAuthenticated = true;
        _adminPassword = password; // <--- STORE IT HERE
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
      _firebaseUser = null;
      _isAuthenticated = false;
      _clearError();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  // Register - Updated to use the new AuthService registerAdmin method for coastguards
  Future<bool> register(UserModel user, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _authService.register(user, password);
      if (success) {
        _currentUser = _authService.currentUser;
        _firebaseUser = _authService.firebaseUser;
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

  // Register Admin/Coastguard - New method to use the dedicated registerAdmin
  Future<bool> registerAdmin({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _authService.registerAdmin(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (success) {
        _currentUser = _authService.currentUser;
        _firebaseUser = _authService.firebaseUser;
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

  // Check auth status (useful for splash screen)
  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = _authService.currentUser;
        _firebaseUser = _authService.firebaseUser;
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

  // Fetch user data from Firestore - Updated to work with new collection structure
  Future<void> _fetchUserData(String uid) async {
    try {
      // Force AuthService to fetch fresh data from Firestore
      await _authService.isLoggedIn();
      _currentUser = _authService.currentUser;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user data: $e');
      }
    }
  }

  // Password reset
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

  // Update user profile
  Future<void> updateProfile(UserModel user) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.updateProfile(user);
      _currentUser = user;

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
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