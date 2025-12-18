import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants/colors.dart';
import '../../providers/admin_provider_simple.dart';
import '../../services/image_upload_service.dart';
import '../../utils/validators.dart';

class AddEditUserDialog extends StatefulWidget {
  final Map<String, dynamic>? userWithBoat;

  const AddEditUserDialog({super.key, this.userWithBoat});

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _fishingAreaController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _boatNumberController = TextEditingController();
  final _boatTypeController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.userWithBoat != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final user = widget.userWithBoat!;
    _firstNameController.text = user['first_name'] ?? '';
    _middleNameController.text = user['middle_name'] ?? '';
    _lastNameController.text = user['last_name'] ?? '';
    _emailController.text = user['email'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _addressController.text = user['address'] ?? '';
    _fishingAreaController.text = user['fishing_area'] ?? '';
    _emergencyContactController.text = user['emergency_contact_person'] ?? '';
    _isActive = user['is_active'] == true;
    _profileImageUrl = user['profile_image_url'] ?? user['profile_picture_url'];
    
    if (user['boat'] != null) {
      final boat = user['boat'];
      // Map database fields (name, type, registration_number) to form fields
      _boatNumberController.text = boat['name'] ?? boat['boat_number'] ?? '';
      _boatTypeController.text = boat['type'] ?? boat['boat_type'] ?? '';
      _registrationNumberController.text = boat['registration_number'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _profileImageUrl = null; // Clear URL when new image is picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _profileImageUrl = null; // Clear URL when new image is taken
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
              if (_profileImage != null || _profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _profileImage = null;
                      _profileImageUrl = null;
                    });
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _fishingAreaController.dispose();
    _emergencyContactController.dispose();
    _boatNumberController.dispose();
    _boatTypeController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        _isEditing ? Icons.edit : Icons.person_add,
                        color: AppColors.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing ? 'Edit User' : 'Add New User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Image Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? Image.network(
                                          _profileImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: AppColors.primaryColor,
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.primaryColor,
                                        ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _showImagePicker,
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: Text(_profileImage != null || (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) ? 'Change Photo' : 'Add Photo'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information Section
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person,
                          validator: Validators.name,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _middleNameController,
                          label: 'Middle Name',
                          icon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                    validator: Validators.name,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phoneNumber,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _fishingAreaController,
                    label: 'Fishing Area',
                    icon: Icons.map,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emergencyContactController,
                    label: 'Emergency Contact Person',
                    icon: Icons.contact_emergency,
                  ),
                  const SizedBox(height: 16),

                  // Password Field (only for new users)
                  if (!_isEditing) ...[
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Boat Information Section
                  _buildSectionHeader('Boat Information'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _boatNumberController,
                    label: 'Boat Number',
                    icon: Icons.directions_boat,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _boatTypeController,
                          label: 'Boat Type',
                          icon: Icons.category,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _registrationNumberController,
                          label: 'Registration Number',
                          icon: Icons.assignment,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status Toggle
                  _buildSectionHeader('Account Status'),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active Account'),
                    subtitle: Text(_isActive ? 'User can log in and use the system' : 'User account is disabled'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(_isEditing ? 'Update User' : 'Create User'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adminProvider = context.read<AdminProviderSimple>();

      // Build full name from first, middle, and last name
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = [
        firstName,
        if (middleName.isNotEmpty) middleName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' ');

      if (_isEditing) {
        // Update existing user
        final updateData = {
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'name': fullName,
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'fishing_area': _fishingAreaController.text.trim(),
          'emergency_contact_person': _emergencyContactController.text.trim(),
          'user_type': 'fisherman',
          'is_active': _isActive,
          'boat_number': _boatNumberController.text.trim(),
          'boat_type': _boatTypeController.text.trim(),
          'registration_number': _registrationNumberController.text.trim(),
        };
        
        // Upload profile image if a new one was selected
        String? profileImageUrl = _profileImageUrl;
        if (_profileImage != null) {
          try {
            final imageUploadService = ImageUploadService();
            final userId = widget.userWithBoat!['user_id'] ?? widget.userWithBoat!['id'];
            profileImageUrl = await imageUploadService.uploadProfileImage(_profileImage!, userId.toString());
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e. Updating without new image...'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            // Keep existing URL if upload fails
            profileImageUrl = _profileImageUrl;
          }
        }
        
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          updateData['profile_image_url'] = profileImageUrl;
        }
        
        await adminProvider.updateUser(
          widget.userWithBoat!['user_id'],
          updateData,
        );
      } else {
        // Create new user
        final createData = {
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'name': fullName,
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
          'address': _addressController.text.trim(),
          'fishing_area': _fishingAreaController.text.trim(),
          'emergency_contact_person': _emergencyContactController.text.trim(),
          'user_type': 'fisherman',
          'is_active': _isActive,
          'boat_number': _boatNumberController.text.trim(),
          'boat_type': _boatTypeController.text.trim(),
          'registration_number': _registrationNumberController.text.trim(),
        };
        
        // Upload profile image if selected
        String? profileImageUrl;
        if (_profileImage != null) {
          try {
            final imageUploadService = ImageUploadService();
            // Use email + timestamp as temporary identifier before account creation
            final tempUserId = 'temp_${_emailController.text.trim().replaceAll('@', '_').replaceAll('.', '_')}_${DateTime.now().millisecondsSinceEpoch}';
            profileImageUrl = await imageUploadService.uploadProfileImage(_profileImage!, tempUserId);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $e. Creating account without image...'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            // Continue with account creation even if image upload fails
            profileImageUrl = null;
          }
        } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
          // Use existing URL if no new image was selected
          profileImageUrl = _profileImageUrl;
        }
        
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          createData['profile_image_url'] = profileImageUrl;
        }
        
        await adminProvider.createUser(createData);
      }

      // Close dialog and show success message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'User updated successfully' : 'User created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
