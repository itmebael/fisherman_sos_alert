import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/device_model.dart';
import '../../providers/admin_provider_simple.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/validators.dart';

class AddDeviceDialog extends StatefulWidget {
  final DeviceModel? device;

  const AddDeviceDialog({super.key, this.device});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Fisherman info controllers
  final _fishermanIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _fishingAreaController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  String _selectedDeviceType = 'SOS';
  String _selectedStatus = 'active';
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.device != null;
    if (_isEditMode) {
      _populateFields();
    }
  }

  void _populateFields() {
    final device = widget.device!;
    _deviceNumberController.text = device.deviceNumber;
    _descriptionController.text = device.description ?? '';
    _locationController.text = device.location ?? '';
    _fishermanIdController.text = device.fishermanUid ?? '';
    _selectedDeviceType = device.deviceType ?? 'SOS';
    _selectedStatus = device.status ?? 'active';
  }

  @override
  void dispose() {
    _deviceNumberController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _fishermanIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _fishingAreaController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final device = DeviceModel(
        id: _isEditMode ? widget.device!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        deviceNumber: _deviceNumberController.text.trim(),
        fishermanUid: _fishermanIdController.text.trim().isNotEmpty ? _fishermanIdController.text.trim() : null,
        fishermanDisplayId: _fishermanIdController.text.trim().isNotEmpty ? _fishermanIdController.text.trim() : null,
        fishermanFirstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : null,
        fishermanLastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
        fishermanEmail: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        fishermanPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        fishermanAddress: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        fishermanFishingArea: _fishingAreaController.text.trim().isNotEmpty ? _fishingAreaController.text.trim() : null,
        fishermanEmergencyContactPerson: _emergencyContactController.text.trim().isNotEmpty ? _emergencyContactController.text.trim() : null,
        isActive: _selectedStatus == 'active',
        createdAt: _isEditMode ? widget.device!.createdAt : DateTime.now(),
        deviceType: _selectedDeviceType,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        status: _selectedStatus,
      );

      if (_isEditMode) {
        await context.read<AdminProviderSimple>().updateDevice(device);
      } else {
        await context.read<AdminProviderSimple>().addDevice(device);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Device updated successfully' : 'Device added successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
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
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.devices_other,
                      color: AppColors.whiteColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode ? 'Edit Device' : 'Add New Device',
                          style: const TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Device and Fisherman Information',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device Information Section
                      const Text(
                        'Device Information',
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
                              controller: _deviceNumberController,
                              label: 'Device Number',
                              hint: 'Enter device number',
                              prefixIcon: Icons.confirmation_number,
                              validator: Validators.required,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedDeviceType,
                              decoration: InputDecoration(
                                labelText: 'Device Type',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              items: ['SOS', 'GPS', 'Emergency', 'Other']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDeviceType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _descriptionController,
                              label: 'Description (Optional)',
                              hint: 'Enter device description',
                              prefixIcon: Icons.description,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _locationController,
                              label: 'Location (Optional)',
                              hint: 'Enter device location',
                              prefixIcon: Icons.location_on,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        items: ['active', 'inactive', 'maintenance']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

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
                      
                      CustomTextField(
                        controller: _fishermanIdController,
                        label: 'Fisherman ID',
                        hint: 'Enter fisherman ID',
                        prefixIcon: Icons.person,
                        validator: Validators.required,
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
                              controller: _lastNameController,
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
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'Enter email address',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _addressController,
                        label: 'Address',
                        hint: 'Enter address',
                        prefixIcon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _fishingAreaController,
                        label: 'Fishing Area',
                        hint: 'Enter fishing area',
                        prefixIcon: Icons.water,
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _emergencyContactController,
                        label: 'Emergency Contact',
                        hint: 'Enter emergency contact person',
                        prefixIcon: Icons.emergency,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteColor),
                            ),
                          )
                        : Text(_isEditMode ? 'Update Device' : 'Add Device'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
