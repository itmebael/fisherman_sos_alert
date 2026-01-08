import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';
import '../models/user_model.dart';
import '../data/local/shared_preferences_helper.dart';
import '../supabase_config.dart';
import 'connection_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final ConnectionService _connectionService = ConnectionService();
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
    // First, try to restore from Supabase session (for regular users)
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _fetchUserData(session.user.id);
      return;
    }
    
    // If no Supabase session, check SharedPreferences (for hardcoded admin or saved sessions)
    final savedUser = await SharedPreferencesHelper.getUserData();
    final isLoggedIn = await SharedPreferencesHelper.isUserLoggedIn();
    
    if (savedUser != null && isLoggedIn) {
      _currentUser = savedUser;
      print('Restored user session from SharedPreferences: ${savedUser.email}');
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

  // Helper function to check if account exists (by ID or email)
  Future<bool> _checkAccountExists(String userId, String email, String userType) async {
    try {
      // First try by ID (faster)
      final userById = await _connectionService.executeWithRetry(
        () async {
          if (userType == 'fisherman') {
            return await _supabase.from('fishermen').select('id').eq('id', userId).maybeSingle();
          } else {
            return await _supabase.from('coastguards').select('id').eq('id', userId).maybeSingle();
          }
        },
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );
      
      if (userById != null) {
        return true;
      }
      
      // Also check by email (in case ID check fails but account exists)
      final userByEmail = await _connectionService.executeWithRetry(
        () async {
          if (userType == 'fisherman') {
            return await _supabase.from('fishermen').select('id').eq('email', email).maybeSingle();
          } else {
            return await _supabase.from('coastguards').select('id').eq('email', email).maybeSingle();
          }
        },
        maxRetries: 2,
        timeout: const Duration(seconds: 10),
      );
      
      return userByEmail != null;
    } catch (e) {
      print('Error checking account existence: $e');
      return false;
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
    String? userId;
    
    try {
      // Create user in Supabase Auth with timeout and retry
      final response = await _connectionService.executeWithRetry(
        () async {
          return await _supabase.auth.signUp(
            email: email.trim(),
            password: password,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Registration timeout. Please check your internet connection and try again.');
            },
          );
        },
        maxRetries: 3,
        timeout: const Duration(seconds: 25),
      );

      if (response.user != null) {
        userId = response.user!.id;
        
        // Create user profile in database
        final userData = {
          'id': userId,
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

        // Insert into appropriate table with retry logic
        bool insertSucceeded = false;
        try {
          await _connectionService.executeWithRetry(
            () async {
              if (userType == 'fisherman') {
                await _supabase.from('fishermen').insert(userData).timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    throw TimeoutException('Database insert timeout. Please try again.');
                  },
                );
              } else if (userType == 'coastguard') {
                await _supabase.from('coastguards').insert(userData).timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    throw TimeoutException('Database insert timeout. Please try again.');
                  },
                );
              }
            },
            maxRetries: 3,
            timeout: const Duration(seconds: 20),
          );
          insertSucceeded = true;
        } catch (insertError) {
          // If insert fails, ALWAYS check if account was actually created
          // (insert might succeed but response might fail due to network)
          print('Insert error occurred, checking if account exists: $insertError');
          
          final accountExists = await _checkAccountExists(userId!, email.trim(), userType);
          if (accountExists) {
            print('Account exists despite insert error - registration succeeded');
            return true;
          }
          
          // If account doesn't exist, check if email is already registered
          try {
            final existingByEmail = await _connectionService.executeWithRetry(
              () async {
                if (userType == 'fisherman') {
                  return await _supabase.from('fishermen').select('id').eq('email', email.trim()).maybeSingle();
                } else {
                  return await _supabase.from('coastguards').select('id').eq('email', email.trim()).maybeSingle();
                }
              },
              maxRetries: 2,
              timeout: const Duration(seconds: 10),
            );
            
            if (existingByEmail != null) {
              throw 'An account with this email already exists. Please sign in instead.';
            }
          } catch (emailCheckError) {
            // If it's already the "already exists" message, re-throw it
            if (emailCheckError.toString().contains('already exists')) {
              throw emailCheckError;
            }
            // Otherwise, continue to throw original insert error
          }
          
          // Re-throw original error if account doesn't exist
          throw insertError;
        }

        // Verify account was created successfully (even if insert seemed to succeed)
        if (insertSucceeded) {
          try {
            final accountExists = await _checkAccountExists(userId!, email.trim(), userType);
            if (accountExists) {
              // Auto-login after successful registration
              try {
                await _autoLoginAfterRegistration(email.trim(), password);
              } catch (loginError) {
                print('Auto-login failed after registration: $loginError');
                // Don't fail registration if auto-login fails - user can login manually
              }
              return true;
            }
          } catch (e) {
            // If verification fails but insert succeeded, assume success
            // The account was inserted, verification is just a safety check
            print('Verification check failed but insert succeeded - assuming success: $e');
            // Try auto-login anyway
            try {
              await _autoLoginAfterRegistration(email.trim(), password);
            } catch (loginError) {
              print('Auto-login failed after registration: $loginError');
            }
            return true;
          }
        }

        // Auto-login after successful registration
        try {
          await _autoLoginAfterRegistration(email.trim(), password);
        } catch (loginError) {
          print('Auto-login failed after registration: $loginError');
        }
        return true;
      }

      return false;
    } on TimeoutException {
      // ALWAYS check if account was created despite timeout
      if (userId != null) {
        try {
          final accountExists = await _checkAccountExists(userId, email.trim(), userType);
          if (accountExists) {
            return true; // Account exists, treat as success
          }
          
          // Also check by email
          final existingByEmail = await _connectionService.executeWithRetry(
            () async {
              if (userType == 'fisherman') {
                return await _supabase.from('fishermen').select('id').eq('email', email.trim()).maybeSingle();
              } else {
                return await _supabase.from('coastguards').select('id').eq('email', email.trim()).maybeSingle();
              }
            },
            maxRetries: 2,
            timeout: const Duration(seconds: 10),
          );
          
          if (existingByEmail != null) {
            throw 'An account with this email already exists. Please sign in instead.';
          }
        } catch (e) {
          // If it's the "already exists" message, re-throw it
          if (e.toString().contains('already exists')) {
            rethrow;
          }
          // Otherwise, continue with timeout error
        }
      }
      throw 'Connection timeout. Please check your internet connection and try again.';
    } on SocketException catch (e) {
      // ALWAYS check if account was created despite network error
      if (userId != null) {
        try {
          final accountExists = await _checkAccountExists(userId, email.trim(), userType);
          if (accountExists) {
            return true; // Account exists, treat as success
          }
          
          // Also check by email
          final existingByEmail = await _connectionService.executeWithRetry(
            () async {
              if (userType == 'fisherman') {
                return await _supabase.from('fishermen').select('id').eq('email', email.trim()).maybeSingle();
              } else {
                return await _supabase.from('coastguards').select('id').eq('email', email.trim()).maybeSingle();
              }
            },
            maxRetries: 2,
            timeout: const Duration(seconds: 10),
          );
          
          if (existingByEmail != null) {
            throw 'An account with this email already exists. Please sign in instead.';
          }
        } catch (checkError) {
          // If it's the "already exists" message, re-throw it
          if (checkError.toString().contains('already exists')) {
            rethrow;
          }
          // Otherwise, continue with network error
        }
      }
      throw 'Network error. Please check your internet connection: ${e.message}';
    } on AuthException catch (e) {
      // Check if account was created despite auth exception
      if (userId != null) {
        try {
          final accountExists = await _checkAccountExists(userId, email.trim(), userType);
          if (accountExists) {
            return true; // Account exists, treat as success
          }
        } catch (checkError) {
          // Ignore check errors
        }
      }
      throw _getAuthErrorMessage(e.message);
    } catch (e) {
      // ALWAYS check if account was created despite any exception
      if (userId != null) {
        try {
          final accountExists = await _checkAccountExists(userId, email.trim(), userType);
          if (accountExists) {
            return true; // Account exists, treat as success
          }
          
          // Also check by email to catch "already exists" cases
          final existingByEmail = await _connectionService.executeWithRetry(
            () async {
              if (userType == 'fisherman') {
                return await _supabase.from('fishermen').select('id').eq('email', email.trim()).maybeSingle();
              } else {
                return await _supabase.from('coastguards').select('id').eq('email', email.trim()).maybeSingle();
              }
            },
            maxRetries: 2,
            timeout: const Duration(seconds: 10),
          );
          
          if (existingByEmail != null) {
            throw 'An account with this email already exists. Please sign in instead.';
          }
        } catch (checkError) {
          // If it's the "already exists" message, re-throw it
          if (checkError.toString().contains('already exists')) {
            rethrow;
          }
          // Otherwise, continue with original error
        }
      }
      
      // Provide more specific error messages
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('timeout') || errorMessage.contains('connection')) {
        throw 'Connection timeout. Please check your internet connection and try again.';
      } else if (errorMessage.contains('socket') || errorMessage.contains('network')) {
        throw 'Network error. Please check your internet connection and try again.';
      } else if (errorMessage.contains('already exists') || errorMessage.contains('duplicate')) {
        throw 'An account with this email already exists. Please sign in instead.';
      } else {
        throw 'Registration failed: ${e.toString()}. Please check your connection and try again.';
      }
    }
  }

  // Register boat and fisherman
  Future<bool> registerBoatAndFisherman({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? middleName,
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
    String? userId;
    String? boatId;
    
    try {
      // Create fisherman account with timeout and retry
      final response = await _connectionService.executeWithRetry(
        () async {
          return await _supabase.auth.signUp(
            email: email.trim(),
            password: password,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Registration timeout. Please check your internet connection and try again.');
            },
          );
        },
        maxRetries: 3,
        timeout: const Duration(seconds: 25),
      );

      if (response.user != null) {
        userId = response.user!.id;

        // Build full name from first, middle, and last name
        final fullName = [
          firstName,
          if (middleName != null && middleName.isNotEmpty) middleName,
          lastName,
        ].where((part) => part.isNotEmpty).join(' ');

        // Create boat record first to get boat ID
        boatId = 'boat_${DateTime.now().millisecondsSinceEpoch}';
        final boatData = {
          'id': boatId,
          'owner_id': userId,
          'name': boatName.isNotEmpty ? boatName : 'Boat-$boatId',
          'type': boatType,
          'registration_number': boatRegistrationNumber,
          'capacity': int.tryParse(boatCapacity) ?? 0,
          'registration_date': DateTime.now().toIso8601String(),
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Insert boat with retry logic
        try {
          await _connectionService.executeWithRetry(
            () async {
              await _supabase.from('boats').insert(boatData).timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw TimeoutException('Boat insert timeout. Please try again.');
                },
              );
            },
            maxRetries: 3,
            timeout: const Duration(seconds: 20),
          );
        } catch (boatError) {
          print('Boat insert error, but continuing with fisherman creation: $boatError');
          // Continue even if boat insert fails - fisherman can be created without boat
        }

        // Create fisherman profile with all fields from schema including boat information (denormalized)
        final fishermanData = {
          'id': userId,
          'email': email.trim(),
          'first_name': firstName,
          if (middleName != null && middleName.isNotEmpty) 'middle_name': middleName,
          'last_name': lastName,
          'name': fullName,
          'phone': phone,
          'user_type': 'fisherman',
          'registration_date': DateTime.now().toIso8601String(),
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'last_active': DateTime.now().toIso8601String(),
          // Profile image URL - ensure it's saved
          if (profileImageUrl != null && profileImageUrl.isNotEmpty) 'profile_image_url': profileImageUrl,
          if (address != null && address.isNotEmpty) 'address': address,
          if (fishingArea != null && fishingArea.isNotEmpty) 'fishing_area': fishingArea,
          if (emergencyContactPerson != null && emergencyContactPerson.isNotEmpty) 'emergency_contact_person': emergencyContactPerson,
          // Boat information (denormalized)
          'boat_id': boatId,
          'boat_name': boatName.isNotEmpty ? boatName : 'Boat-$boatId',
          'boat_type': boatType.isNotEmpty ? boatType : null,
          'boat_registration_number': boatRegistrationNumber.isNotEmpty ? boatRegistrationNumber : null,
          'boat_capacity': int.tryParse(boatCapacity) ?? null,
        };

        // Insert fisherman with retry logic
        bool insertSucceeded = false;
        try {
          await _connectionService.executeWithRetry(
            () async {
              await _supabase.from('fishermen').insert(fishermanData).timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw TimeoutException('Fisherman insert timeout. Please try again.');
                },
              );
            },
            maxRetries: 3,
            timeout: const Duration(seconds: 20),
          );
          insertSucceeded = true;
        } catch (insertError) {
          // If insert fails, ALWAYS check if account was actually created
          print('Fisherman insert error occurred, checking if account exists: $insertError');
          
          final accountExists = await _checkAccountExists(userId!, email.trim(), 'fisherman');
          if (accountExists) {
            print('Account exists despite insert error - registration succeeded');
            return true;
          }
          
          // If account doesn't exist, check if email is already registered
          try {
            final existingByEmail = await _connectionService.executeWithRetry(
              () async {
                return await _supabase.from('fishermen').select('id').eq('email', email.trim()).maybeSingle();
              },
              maxRetries: 2,
              timeout: const Duration(seconds: 10),
            );
            
            if (existingByEmail != null) {
              throw 'An account with this email already exists. Please sign in instead.';
            }
          } catch (emailCheckError) {
            if (emailCheckError.toString().contains('already exists')) {
              throw emailCheckError;
            }
          }
          
          throw insertError;
        }

        // Verify account was created successfully
        if (insertSucceeded) {
          try {
            final accountExists = await _checkAccountExists(userId!, email.trim(), 'fisherman');
            if (accountExists) {
              return true;
            }
          } catch (e) {
            // If verification fails but insert succeeded, assume success
            print('Verification check failed but insert succeeded - assuming success: $e');
            return true;
          }
        }

        return true;
      }

      return false;
    } on TimeoutException {
      // ALWAYS check if account was created despite timeout
      if (userId != null) {
        try {
          final accountExists = await _checkAccountExists(userId, email.trim(), 'fisherman');
          if (accountExists) {
            return true;
          }
          
          final existingByEmail = await _connectionService.executeWithRetry(
            () async {
              return await _supabase.from('fishermen').select('id').eq('email', email.trim()).maybeSingle();
            },
            maxRetries: 2,
            timeout: const Duration(seconds: 10),
          );
          
          if (existingByEmail != null) {
            throw 'An account with this email already exists. Please sign in instead.';
          }
        } catch (e) {
          if (e.toString().contains('already exists')) {
            rethrow;
          }
        }
      }
      throw 'Connection timeout. Please check your internet connection and try again.';
    } on SocketException catch (e) {
      // ALWAYS check if account was created despite network error
      if (userId != null) {
        try {
          final accountExists = await _checkAccountExists(userId, email.trim(), 'fisherman');
          if (accountExists) {
            return true;
          }
          
          final existingByEmail = await _connectionService.executeWithRetry(
            () async {
              return await _supabase.from('fishermen').select('id').eq('email', email.trim()).maybeSingle();
            },
            maxRetries: 2,
            timeout: const Duration(seconds: 10),
          );
          
          if (existingByEmail != null) {
            throw 'An account with this email already exists. Please sign in instead.';
          }
        } catch (checkError) {
          if (checkError.toString().contains('already exists')) {
            rethrow;
          }
        }
      }
      throw 'Network error. Please check your internet connection: ${e.message}';
    } on AuthException catch (e) {
      // Check if account was created despite auth exception
      if (userId != null) {
        try {
          final accountExists = await _checkAccountExists(userId, email.trim(), 'fisherman');
          if (accountExists) {
            return true;
          }
        } catch (checkError) {
          // Ignore check errors
        }
      }
      throw _getAuthErrorMessage(e.message);
    } catch (e) {
      // ALWAYS check if account was created despite any exception
      if (userId != null) {
        try {
          final accountExists = await _checkAccountExists(userId, email.trim(), 'fisherman');
          if (accountExists) {
            return true;
          }
          
          final existingByEmail = await _connectionService.executeWithRetry(
            () async {
              return await _supabase.from('fishermen').select('id').eq('email', email.trim()).maybeSingle();
            },
            maxRetries: 2,
            timeout: const Duration(seconds: 10),
          );
          
          if (existingByEmail != null) {
            throw 'An account with this email already exists. Please sign in instead.';
          }
        } catch (checkError) {
          if (checkError.toString().contains('already exists')) {
            rethrow;
          }
        }
      }
      
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('timeout') || errorMessage.contains('connection')) {
        throw 'Connection timeout. Please check your internet connection and try again.';
      } else if (errorMessage.contains('socket') || errorMessage.contains('network')) {
        throw 'Network error. Please check your internet connection and try again.';
      } else if (errorMessage.contains('already exists') || errorMessage.contains('duplicate')) {
        throw 'An account with this email already exists. Please sign in instead.';
      } else {
        throw 'Boat registration failed: ${e.toString()}. Please check your connection and try again.';
      }
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
      print('Starting logout process...');
      
      // Sign out from Supabase (if logged in via Supabase)
      try {
        await _supabase.auth.signOut().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Supabase sign out timeout - continuing with local cleanup');
          },
        );
        print('Supabase sign out successful');
      } catch (e) {
        // Ignore if not logged in via Supabase (e.g., hardcoded admin)
        print('Supabase sign out note: $e');
      }
      
      // Clear current user
      _currentUser = null;
      
      // Clear saved user data and login status from SharedPreferences
      try {
        await SharedPreferencesHelper.clearUserData();
        print('SharedPreferences cleared');
      } catch (e) {
        print('Error clearing SharedPreferences: $e');
      }
      
      print('User logged out successfully - session cleared');
    } catch (e) {
      print('Error during logout: $e');
      // Still try to clear local data even if Supabase logout fails
      _currentUser = null;
      try {
        await SharedPreferencesHelper.clearUserData();
      } catch (clearError) {
        print('Error clearing data during logout error handling: $clearError');
      }
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

  // Auto-login after successful registration
  Future<void> _autoLoginAfterRegistration(String email, String password) async {
    try {
      print('Auto-logging in user after registration...');
      // Wait a brief moment to ensure account is fully created
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Attempt to login with the credentials
      AuthResponse? response;
      try {
        response = await _supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        ).timeout(
          const Duration(seconds: 10),
        );
      } on TimeoutException {
        print('Auto-login timeout - user can login manually');
        return;
      }

      if (response.user != null) {
        await _fetchUserData(response.user!.id);
        print('Auto-login successful after registration');
      } else {
        print('Auto-login failed - no user returned');
      }
    } catch (e) {
      print('Auto-login failed after registration: $e');
      // Don't throw - registration succeeded, user can login manually
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

