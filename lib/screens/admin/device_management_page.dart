import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/admin_provider_simple.dart';
import '../../models/device_model.dart';
import '../admin/admin_drawer.dart';
import 'add_device_dialog.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterDeviceType = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProviderSimple>().loadDevices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Device Management',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminProviderSimple>().loadDevices();
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Container(
        color: AppColors.homeBackground,
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search devices by number or fisherman...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryColor),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ['All', 'Active', 'Inactive', 'Maintenance', 'Sending Signal']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterStatus = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterDeviceType,
                          decoration: InputDecoration(
                            labelText: 'Device Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ['All', 'SOS', 'GPS', 'Emergency', 'Other']
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _filterDeviceType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Device List
            Expanded(
              child: Consumer<AdminProviderSimple>(
                builder: (context, admin, _) {
                  if (admin.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                    );
                  }

                  // Use client-side filtering for now (can be optimized later)
                  final filteredDevices = admin.devices.where((device) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        device.deviceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (device.fishermanDisplayId ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (device.fishermanFirstName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (device.fishermanLastName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                    
                    final matchesStatus = _filterStatus == 'All' ||
                        (_filterStatus == 'Active' && device.isActive) ||
                        (_filterStatus == 'Inactive' && !device.isActive) ||
                        (_filterStatus == 'Maintenance' && device.status == 'maintenance') ||
                        (_filterStatus == 'Sending Signal' && device.isSendingSignal);
                    
                    final matchesType = _filterDeviceType == 'All' ||
                        device.deviceType == _filterDeviceType;

                    return matchesSearch && matchesStatus && matchesType;
                  }).toList();

                  if (filteredDevices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _filterStatus != 'All' || _filterDeviceType != 'All'
                                ? 'No devices found matching your criteria'
                                : 'No devices registered yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add a new device',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDevices.length,
                    itemBuilder: (context, index) {
                      final device = filteredDevices[index];
                      return _buildDeviceCard(device, admin);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: AppColors.whiteColor),
      ),
    );
  }

  Widget _buildDeviceCard(DeviceModel device, AdminProviderSimple admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: device.isSendingSignal 
                ? AppColors.errorColor.withOpacity(0.1)
                : device.isActive 
                    ? AppColors.successColor.withOpacity(0.1) 
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            device.isSendingSignal ? Icons.emergency : Icons.devices_other,
            color: device.isSendingSignal 
                ? AppColors.errorColor
                : device.isActive 
                    ? AppColors.successColor 
                    : Colors.grey,
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.deviceNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            if (device.fishermanDisplayId != null)
              Text(
                'User: ${device.fishermanDisplayId}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primaryColor,
                ),
              )
            else if (device.fishermanName != null)
              Text(
                'User: ${device.fishermanName}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primaryColor,
                ),
              )
            else if (device.fishermanFirstName != null && device.fishermanLastName != null)
              Text(
                'User: ${device.fishermanFirstName} ${device.fishermanLastName}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primaryColor,
                ),
              )
            else if (device.fishermanEmail != null)
              Text(
                'User: ${device.fishermanEmail}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primaryColor,
                ),
              )
            else
              Text(
                'User: Not assigned',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (device.fishermanDisplayId != null && (device.fishermanFirstName != null || device.fishermanLastName != null))
              Text(
                'Name: ${device.fishermanFirstName ?? ''} ${device.fishermanLastName ?? ''}'.trim(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            if (device.fishermanEmail != null && device.fishermanDisplayId != null)
              Text(
                'Email: ${device.fishermanEmail}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            if (device.deviceType != null) 
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Type: ${device.deviceType}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            if (device.description != null) 
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Description: ${device.description}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            if (device.isSendingSignal) ...[
              Text(
                '🚨 SENDING SIGNAL - NEEDS HELP',
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (device.signalMessage != null)
                Text('Message: ${device.signalMessage}'),
              if (device.lastSignalSent != null)
                Text('Signal sent: ${_formatDate(device.lastSignalSent!)}'),
            ] else
              Text(
                'Status: ${device.isActive ? 'Active' : 'Inactive'}',
                style: TextStyle(
                  color: device.isActive ? AppColors.successColor : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              'Created: ${_formatDate(device.createdAt)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditDeviceDialog(device);
                break;
              case 'stop_signal':
                _stopDeviceSignal(device);
                break;
              case 'delete':
                _showDeleteConfirmation(device);
                break;
              case 'toggle':
                _toggleDeviceStatus(device);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.primaryColor),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (device.isSendingSignal)
              const PopupMenuItem(
                value: 'stop_signal',
                child: Row(
                  children: [
                    Icon(Icons.stop, color: AppColors.errorColor),
                    SizedBox(width: 8),
                    Text('Stop Signal'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(Icons.toggle_on, color: AppColors.warningColor),
                  SizedBox(width: 8),
                  Text('Toggle Status'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.errorColor),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddDeviceDialog(),
    );
  }

  void _showEditDeviceDialog(DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AddDeviceDialog(device: device),
    );
  }

  void _showDeleteConfirmation(DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete device ${device.deviceNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AdminProviderSimple>().deleteDevice(device.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
  }

  void _toggleDeviceStatus(DeviceModel device) {
    context.read<AdminProviderSimple>().toggleDeviceStatus(device.id, !device.isActive);
  }

  void _stopDeviceSignal(DeviceModel device) {
    context.read<AdminProviderSimple>().stopDeviceSignal(device.id);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
