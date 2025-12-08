import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/validators.dart';

class BoatRegistrationPage extends StatefulWidget {
  const BoatRegistrationPage({super.key});

  @override
  State<BoatRegistrationPage> createState() => _BoatRegistrationPageState();
}

class _BoatRegistrationPageState extends State<BoatRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _boatNumberController = TextEditingController();
  final _boatNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ownerFirstNameController = TextEditingController();
  final _ownerLastNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _fishingAreaController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateBoatId();
  }

  Future<void> _generateBoatId() async {
    try {
      final response = await Supabase.instance.client
          .from('boats')
          .select('id')
          .order('id', ascending: false)
          .limit(1);
      
      String nextId = '00001';
      if (response.isNotEmpty) {
        final lastId = int.tryParse(response.first['id']) ?? 0;
        nextId = (lastId + 1).toString().padLeft(5, '0');
      }
      setState(() {
        _boatNumberController.text = nextId;
      });
    } catch (e) {
      print('Error generating boat ID: $e');
    }
  }

  Future<void> _registerBoatAndOwner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Create fisherman account
      final response = await Supabase.instance.client.auth.signUp(
        email: _ownerEmailController.text.trim(),
        password: _ownerPasswordController.text,
        data: {
          'user_type': 'fisherman',
          'first_name': _ownerFirstNameController.text.trim(),
          'last_name': _ownerLastNameController.text.trim(),
        },
      );

      if (response.user == null) {
        throw Exception('Failed to create user account');
      }

      final ownerUid = response.user!.id;

      // Step 2: Create fisherman profile
      final fishermanData = {
        'id': ownerUid,
        'first_name': _ownerFirstNameController.text.trim(),
        'last_name': _ownerLastNameController.text.trim(),
        'email': _ownerEmailController.text.trim(),
        'phone': _ownerPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'fishing_area': _fishingAreaController.text.trim(),
        'emergency_contact_person': _emergencyContactController.text.trim(),
        'user_type': 'fisherman',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('fishermen')
          .insert(fishermanData);

      // Step 3: Create boat record
      final boatData = {
        'id': _boatNumberController.text.trim(),
        'boat_number': _boatNumberController.text.trim(),
        'name': _boatNameController.text.trim(),
        'registration_number': _registrationNumberController.text.trim(),
        'owner_uid': ownerUid,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('boats')
          .insert(boatData);

      if (mounted) {
        _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.successColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.whiteColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Successfully Registered!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.dividerColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Boat and fisherman account have been created successfully.\n\nThe fisherman can now login using their email and password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _clearForm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                      foregroundColor: AppColors.whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearForm() {
    FocusScope.of(context).unfocus();
    _boatNameController.clear();
    _registrationNumberController.clear();
    _ownerEmailController.clear();
    _ownerPasswordController.clear();
    _confirmPasswordController.clear();
    _ownerFirstNameController.clear();
    _ownerLastNameController.clear();
    _ownerPhoneController.clear();
    _fishingAreaController.clear();
    _addressController.clear();
    _emergencyContactController.clear();
    _generateBoatId();
    
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
    
    if (mounted) {
      setState(() {
        _isPasswordVisible = false;
        _isConfirmPasswordVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _boatNumberController.dispose();
    _boatNameController.dispose();
    _registrationNumberController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    _confirmPasswordController.dispose();
    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    _ownerPhoneController.dispose();
    _fishingAreaController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register Boat & Fisherman',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
                      // Boat Information Section
                      const Text(
                        'Boat Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _boatNumberController,
                              label: 'Boat Number',
                              hint: 'Auto-generated',
                              prefixIcon: Icons.confirmation_number,
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _boatNameController,
                              label: 'Boat Name',
                              hint: 'Enter boat name',
                              prefixIcon: Icons.directions_boat,
                              validator: Validators.required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _registrationNumberController,
                        label: 'Registration Number',
                        hint: 'Enter registration number',
                        prefixIcon: Icons.assignment,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Fisherman Information Section
                      const Text(
                        'Fisherman Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _ownerFirstNameController,
                              label: 'First Name',
                              hint: 'Enter first name',
                              prefixIcon: Icons.person,
                              validator: Validators.required,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _ownerLastNameController,
                              label: 'Last Name',
                              hint: 'Enter last name',
                              prefixIcon: Icons.person,
                              validator: Validators.required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _ownerEmailController,
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
                              controller: _ownerPasswordController,
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
                              validator: (value) => Validators.confirmPassword(value, _ownerPasswordController.text),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _ownerPhoneController,
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phoneNumber,
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _fishingAreaController,
                        label: 'Fishing Area',
                        hint: 'Enter fishing area',
                        prefixIcon: Icons.location_on,
                        validator: Validators.required,
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
                        controller: _emergencyContactController,
                        label: 'Emergency Contact Person',
                        hint: 'Enter emergency contact',
                        prefixIcon: Icons.emergency,
                        validator: Validators.required,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      CustomButton(
                        text: 'Register Boat & Fisherman',
                        onPressed: _isLoading ? null : _registerBoatAndOwner,
                        isLoading: _isLoading,
                        icon: Icons.directions_boat,
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

