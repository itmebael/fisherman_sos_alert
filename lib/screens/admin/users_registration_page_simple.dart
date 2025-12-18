import 'package:flutter/material.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../services/auth_service.dart';

class UsersRegistrationPageSimple extends StatefulWidget {
  const UsersRegistrationPageSimple({super.key});

  @override
  State<UsersRegistrationPageSimple> createState() => _UsersRegistrationPageSimpleState();
}

class _UsersRegistrationPageSimpleState extends State<UsersRegistrationPageSimple> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _fishingAreaController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _boatNumberController = TextEditingController();
  final _boatTypeController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _fishingAreaController.dispose();
    _emergencyContactController.dispose();
    _boatNumberController.dispose();
    _boatTypeController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      
      // Get form values
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final boatNumber = _boatNumberController.text.trim();
      final boatType = _boatTypeController.text.trim();
      final boatRegistrationNumber = _registrationNumberController.text.trim();

      final success = await authService.registerBoatAndFisherman(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: firstName,
        lastName: lastName,
        middleName: middleName.isNotEmpty ? middleName : null,
        phone: _phoneController.text.trim(),
        boatName: boatNumber.isNotEmpty ? boatNumber : 'Boat-${DateTime.now().millisecondsSinceEpoch}',
        boatType: boatType,
        boatRegistrationNumber: boatRegistrationNumber,
        boatCapacity: '0',
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        fishingArea: _fishingAreaController.text.trim().isNotEmpty ? _fishingAreaController.text.trim() : null,
        emergencyContactPerson: _emergencyContactController.text.trim().isNotEmpty ? _emergencyContactController.text.trim() : null,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User registered successfully!')),
          );
          
          // Clear form
          _firstNameController.clear();
          _middleNameController.clear();
          _lastNameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _addressController.clear();
          _fishingAreaController.clear();
          _emergencyContactController.clear();
          _boatNumberController.clear();
          _boatTypeController.clear();
          _registrationNumberController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register User'),
        backgroundColor: const Color(0xFF13294B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Register New User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF13294B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // First Name
                    CustomTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'Enter first name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Middle Name
                    CustomTextField(
                      controller: _middleNameController,
                      label: 'Middle Name',
                      hint: 'Enter middle name (optional)',
                    ),
                    const SizedBox(height: 16),
                    
                    // Last Name
                    CustomTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter last name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Confirm password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter address',
                      keyboardType: TextInputType.streetAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Fishing Area
                    CustomTextField(
                      controller: _fishingAreaController,
                      label: 'Fishing Area',
                      hint: 'Enter fishing area',
                    ),
                    const SizedBox(height: 16),
                    
                    // Emergency Contact Person
                    CustomTextField(
                      controller: _emergencyContactController,
                      label: 'Emergency Contact Person',
                      hint: 'Enter emergency contact person',
                    ),
                    const SizedBox(height: 24),
                    
                    // Boat Information Section
                    const Text(
                      'Boat Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF13294B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Boat Number
                    CustomTextField(
                      controller: _boatNumberController,
                      label: 'Boat Number',
                      hint: 'Enter boat number',
                    ),
                    const SizedBox(height: 16),
                    
                    // Boat Type and Registration Number
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _boatTypeController,
                            label: 'Boat Type',
                            hint: 'Enter boat type',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _registrationNumberController,
                            label: 'Registration Number',
                            hint: 'Enter registration number',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Register Button
                    CustomButton(
                      text: 'Register User',
                      onPressed: _registerUser,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
