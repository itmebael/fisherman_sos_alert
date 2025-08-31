import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../data/local/shared_preferences_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  User? get firebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register admin/coastguard - updated to use subcollection
  Future<bool> registerAdmin({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = userCredential.user!.uid;

      final coastguardData = {
        'id': uid,
        'firstName': firstName,
        'middleName': middleName?.isEmpty == true ? null : middleName,
        'lastName': lastName,
        'email': email.trim(),
        'isActive': true,
        'registrationDate': Timestamp.now(),
      };

      // Save to subcollection
      await _firestore
        .collection('users')
        .doc(uid)
        .collection('coastguards')
        .doc(uid)
        .set(coastguardData);

      _currentUser = UserModel(
        id: uid,
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
        boatId: null,
      );

      await SharedPreferencesHelper.saveUserData(_currentUser!);
      return true;
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Registration failed. Please check your connection.';
    }
  }

  // Login method - updated to check both subcollections
  Future<bool> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        await _fetchUserData(uid);

        // --- BEGIN: Hardcoded fallback for admin@gmail.com ---
        if (_currentUser == null && email.trim().toLowerCase() == "admin@gmail.com") {
          _currentUser = UserModel(
            id: uid,
            firstName: "Admin",
            lastName: "User",
            name: "Admin User",
            email: email.trim(),
            phone: '',
            userType: 'coastguard', // treat as admin
            registrationDate: DateTime.now(),
            isActive: true,
          );
          await SharedPreferencesHelper.saveUserData(_currentUser!);
          return true;
        }
        // --- END: Hardcoded fallback for admin@gmail.com ---

        return _currentUser != null;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'An unexpected error occurred. Please check your connection.';
    }
  }

  Future<void> openWebLogin() async {
    final url = Uri.parse('https://sos-alert-b187f.web.app/login');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open web login page';
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      await SharedPreferencesHelper.clearUserData();
    } catch (e) {
      throw 'Logout failed';
    }
  }

  // Register fisherman - updated to use subcollection
  Future<bool> register(UserModel user, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        
        if (user.userType == 'fisherman') {
          final fishermenData = {
            'id': uid,
            'firstName': user.firstName ?? '',
            'middleName': user.middleName,
            'lastName': user.lastName ?? '',
            'email': user.email,
            'phone': user.phone,
            'address': user.address ?? '',
            'fishingArea': user.fishingArea ?? '',
            'emergencyContactPerson': user.emergencyContactPerson ?? '',
            'isActive': true,
            'registrationDate': Timestamp.now(),
          };
          
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('fishermen')
              .doc(uid)
              .set(fishermenData);
        } else if (user.userType == 'coastguard') {
          final coastguardData = {
            'id': uid,
            'firstName': user.firstName ?? '',
            'middleName': user.middleName,
            'lastName': user.lastName ?? '',
            'email': user.email,
            'isActive': true,
            'registrationDate': Timestamp.now(),
          };
          
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('coastguards')
              .doc(uid)
              .set(coastguardData);
        }
        
        await _fetchUserData(uid);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    } catch (e) {
      throw 'Registration failed. Please check your connection.';
    }
  }

  Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;
    if (_auth.currentUser != null) {
      await _fetchUserData(_auth.currentUser!.uid);
      return _currentUser != null;
    }
    return false;
  }

  // Updated to fetch from correct subcollection based on user type
  Future<void> _fetchUserData(String uid) async {
    try {
      // Try to fetch from coastguards subcollection first
      DocumentSnapshot coastguardDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('coastguards')
          .doc(uid)
          .get();

      if (coastguardDoc.exists && coastguardDoc.data() != null) {
        final data = coastguardDoc.data() as Map<String, dynamic>;
        _currentUser = UserModel(
          id: data['id'],
          firstName: data['firstName'],
          middleName: data['middleName'],
          lastName: data['lastName'],
          name: "${data['firstName']}${data['middleName'] != null && data['middleName'].toString().isNotEmpty ? ' ${data['middleName']}' : ''} ${data['lastName']}",
          email: data['email'],
          phone: '',
          userType: 'coastguard',
          registrationDate: (data['registrationDate'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
        );
        await SharedPreferencesHelper.saveUserData(_currentUser!);
        return;
      }

      // Try to fetch from fishermen subcollection
      DocumentSnapshot fishermenDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('fishermen')
          .doc(uid)
          .get();

      if (fishermenDoc.exists && fishermenDoc.data() != null) {
        final data = fishermenDoc.data() as Map<String, dynamic>;
        _currentUser = UserModel(
          id: data['id'],
          firstName: data['firstName'],
          middleName: data['middleName'],
          lastName: data['lastName'],
          name: "${data['firstName']}${data['middleName'] != null && data['middleName'].toString().isNotEmpty ? ' ${data['middleName']}' : ''} ${data['lastName']}",
          email: data['email'],
          phone: data['phone'] ?? '',
          userType: 'fisherman',
          registrationDate: (data['registrationDate'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          address: data['address'],
          fishingArea: data['fishingArea'],
          emergencyContactPerson: data['emergencyContactPerson'],
        );
        await SharedPreferencesHelper.saveUserData(_currentUser!);
        return;
      }

      // If user not found in either subcollection, create a basic user model
      final user = _auth.currentUser;
      if (user != null) {
        _currentUser = UserModel(
          id: uid,
          name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          email: user.email ?? '',
          phone: '',
          userType: 'fisherman', // Default to fisherman
          registrationDate: DateTime.now(),
          isActive: true,
        );
      }
    } catch (e) {
      try {
        final userData = await SharedPreferencesHelper.getUserData();
        if (userData != null && userData.id == uid) {
          _currentUser = userData;
        }
      } catch (_) {
        if (kDebugMode) {
          print('Error fetching user data: $e');
        }
      }
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email address';
      case 'wrong-password': return 'Incorrect password';
      case 'invalid-credential': return 'Invalid email or password';
      case 'email-already-in-use': return 'An account with this email already exists';
      case 'weak-password': return 'Password is too weak (minimum 6 characters)';
      case 'invalid-email': return 'Please enter a valid email address';
      case 'user-disabled': return 'This account has been disabled';
      case 'too-many-requests': return 'Too many failed attempts. Please try again later';
      case 'network-request-failed': return 'Network error. Please check your internet connection';
      default: return 'Login failed. Please check your credentials and try again';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e.code);
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      // Determine which subcollection to update based on user type
      String subcollection = user.userType == 'coastguard' ? 'coastguards' : 'fishermen';
      
      Map<String, dynamic> updateData;
      
      if (user.userType == 'coastguard') {
        updateData = {
          'id': user.id,
          'firstName': user.firstName,
          'middleName': user.middleName,
          'lastName': user.lastName,
          'email': user.email,
          'isActive': user.isActive,
          'registrationDate': Timestamp.fromDate(user.registrationDate),
        };
      } else {
        updateData = {
          'id': user.id,
          'firstName': user.firstName,
          'middleName': user.middleName,
          'lastName': user.lastName,
          'email': user.email,
          'phone': user.phone,
          'address': user.address,
          'fishingArea': user.fishingArea,
          'emergencyContactPerson': user.emergencyContactPerson,
          'isActive': user.isActive,
          'registrationDate': Timestamp.fromDate(user.registrationDate),
        };
      }
      
      await _firestore
        .collection('users')
        .doc(user.id)
        .collection(subcollection)
        .doc(user.id)
        .update(updateData);
      _currentUser = user;
      await SharedPreferencesHelper.saveUserData(user);
    } catch (e) {
      throw 'Profile update failed. Please check your connection.';
    }
  }
}