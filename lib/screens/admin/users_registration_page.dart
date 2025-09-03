import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // <-- for AuthProvider

import '../../constants/colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../models/user_model.dart';
import '../../models/boat_model.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart' as my_auth; // <--- ALIAS your AuthProvider!

class UsersRegistrationPage extends StatefulWidget {
  const UsersRegistrationPage({Key? key}) : super(key: key);

  @override
  State<UsersRegistrationPage> createState() => _UsersRegistrationPageState();
}

class _UsersRegistrationPageState extends State<UsersRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _fishingAreaController = TextEditingController();
  final _contactController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _idController = TextEditingController();
  final _boatNumberController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNextUserId();
  }

  Future<void> _fetchNextUserId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('fishermen')
        .orderBy('id', descending: true)
        .limit(1)
        .get();
    String nextId = '00001';
    if (snapshot.docs.isNotEmpty) {
      final lastId = int.tryParse(snapshot.docs.first['id'] ?? '0') ?? 0;
      nextId = (lastId + 1).toString().padLeft(5, '0');
    }
    setState(() {
      _idController.text = nextId;
    });
  }

 Future<String> _fetchNextBoatId() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('boats')
        .orderBy('id', descending: true)
        .limit(1)
        .get();
    
    String nextId = '00001';
    if (snapshot.docs.isNotEmpty) {
      final lastId = int.tryParse(snapshot.docs.first['id']) ?? 0;
      nextId = (lastId + 1).toString().padLeft(5, '0');
    }
    return nextId;
  } catch (e) {
    print('Error fetching next boat ID: $e');
    // Fallback to checking manually or returning a default
    return '00001';
  }
}

  /// Registration flow with admin re-auth, using admin's real credentials from AuthProvider.
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use alias to refer to your AuthProvider, not Firebase's internal one!
      final authProvider = Provider.of<my_auth.AuthProvider>(context, listen: false);
      final String? adminEmail = authProvider.firebaseUser?.email;
      final String? adminPassword = authProvider.adminPassword; // <-- make sure it's a public getter!

      if (adminEmail == null || adminPassword == null || adminPassword.isEmpty) {
        throw Exception("Admin credentials not available. Please re-login as admin.");
      }

      // Step 1. Register the fisherman Auth user (this signs you in as fisherman)
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final fishermanUid = userCredential.user!.uid;

      // Step 2. Immediately sign out and sign back in as admin
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      // Step 3. Now, as admin, do the writes
      // Create boat if boat number is provided
      String? boatId;
      if (_boatNumberController.text.trim().isNotEmpty) {
        boatId = await _fetchNextBoatId();
        final boat = BoatModel(
          id: boatId,
          boatNumber: _boatNumberController.text.trim(),
          name: 'Boat of ${_firstNameController.text} ${_lastNameController.text}',
          registrationNumber: _boatNumberController.text.trim(),
          ownerUid: fishermanUid,
          isActive: true,
          createdAt: Timestamp.now(),
        );
        await FirebaseFirestore.instance.collection('boats').doc(boatId).set(boat.toJson());
      }

      // Create fisherman document in users/{uid}/fishermen/{uid} subcollection
      final fishermenData = {
        'id': fishermanUid,
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'fishingArea': _fishingAreaController.text.trim(),
        'emergencyContactPerson': _emergencyContactController.text.trim(),
        'isActive': true,
        'registrationDate': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(fishermanUid)
          .collection('fishermen')
          .doc(fishermanUid)
          .set(fishermenData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fisherman registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _fishingAreaController.dispose();
    _contactController.dispose();
    _emergencyContactController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _idController.dispose();
    _boatNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register Fisherman',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
      ),
      body: Container(
        color: AppColors.homeBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Photo upload feature coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Upload Photo'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ID Number - First field (much shorter width)
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: CustomTextField(
                              controller: _idController,
                              label: 'ID',
                              hint: 'Auto-generated',
                              prefixIcon: Icons.badge,
                              readOnly: true,
                            ),
                          ),
                          const Expanded(
                            flex: 4,
                            child: SizedBox(), // More empty space to make ID field much shorter
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hint: 'Enter first name',
                              prefixIcon: Icons.person,
                              validator: Validators.required,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _middleNameController,
                              label: 'Middle Name',
                              hint: 'Enter middle name',
                              prefixIcon: Icons.person_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hint: 'Enter last name',
                              prefixIcon: Icons.person,
                              validator: Validators.required,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _fishingAreaController,
                              label: 'Fishing Area / Zone',
                              hint: 'Enter fishing area',
                              prefixIcon: Icons.location_on,
                              validator: Validators.required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _contactController,
                              label: 'Contact No',
                              hint: 'Enter contact number',
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: Validators.phoneNumber,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _emergencyContactController,
                              label: 'Emergency Contact Person',
                              hint: 'Enter emergency contact',
                              prefixIcon: Icons.emergency,
                              keyboardType: TextInputType.text,
                              validator: Validators.required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Address',
                        hint: 'Enter complete address',
                        prefixIcon: Icons.home,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _boatNumberController,
                        label: 'Boat Number',
                        hint: 'Enter boat number',
                        prefixIcon: Icons.directions_boat,
                      ),
                      const SizedBox(height: 16),
                      // Email Address - After Boat Number
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'Enter email address',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Enter password',
                              prefixIcon: Icons.lock,
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              onPasswordToggle: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              validator: Validators.password,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Confirm password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              isPasswordVisible: _isConfirmPasswordVisible,
                              onPasswordToggle: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                              validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Register',
                        onPressed: _isLoading ? null : _registerUser,
                        isLoading: _isLoading,
                        icon: Icons.person_add,
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}