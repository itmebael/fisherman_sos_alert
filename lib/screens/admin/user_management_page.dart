import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/admin_provider_simple.dart';
import '../../models/user_model.dart';
import '../../models/boat_model.dart';
import '../admin/admin_drawer.dart';
import 'add_edit_user_dialog.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProviderSimple>().loadUsersWithBoats();
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
          'Fishermen Management',
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
              context.read<AdminProviderSimple>().loadUsersWithBoats();
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
              color: Colors.white,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search fishermen by name, email, or boat number...',
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
                  const SizedBox(height: 12),
                  // Filter Row
                  Row(
                    children: [
                      // Status Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ['All', 'Active', 'Inactive'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _filterStatus = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Users List
            Expanded(
              child: Consumer<AdminProviderSimple>(
                builder: (context, adminProvider, child) {
                  if (adminProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (adminProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading users',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            adminProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              adminProvider.loadUsersWithBoats();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredUsers = _getFilteredUsers(adminProvider.usersWithBoats);

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _filterStatus != 'All'
                                ? 'No fishermen found matching your criteria'
                                : 'No fishermen found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _filterStatus != 'All')
                            const SizedBox(height: 8),
                          if (_searchQuery.isNotEmpty || _filterStatus != 'All')
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _filterStatus = 'All';
                                  _searchController.clear();
                                });
                              },
                              child: const Text('Clear Filters'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final userWithBoat = filteredUsers[index];
                      return _buildUserCard(context, userWithBoat, adminProvider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Fisherman'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> users) {
    return users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final name = (user['full_name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final boatNumber = (user['boat_number'] ?? '').toLowerCase();
        
        if (!name.contains(searchLower) && 
            !email.contains(searchLower) && 
            !boatNumber.contains(searchLower)) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus != 'All') {
        final isActive = user['is_active'] == true;
        if (_filterStatus == 'Active' && !isActive) return false;
        if (_filterStatus == 'Inactive' && isActive) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> userWithBoat, AdminProviderSimple adminProvider) {
    final user = UserModel.fromMap(userWithBoat);
    final boat = userWithBoat['boat'] != null ? BoatModel.fromMap(userWithBoat['boat']) : null;
    final isActive = userWithBoat['is_active'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryColor,
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          (user.firstName != null && user.firstName!.isNotEmpty) ? user.firstName![0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(user.userType),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.userType.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(context, value, userWithBoat, adminProvider),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit User'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.pause : Icons.play_arrow,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete User', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Boat Information
            if (boat != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_boat, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Boat: ${boat.boatNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      boat.boatType ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Additional Info
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  user.phone ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  user.createdAt != null ? _formatDate(user.createdAt!) : 'Unknown',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'fisherman':
        return Colors.blue;
      case 'coastguard':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone call';
      }
    } catch (e) {
      // Handle error - phone call not available
      print('Error making phone call: $e');
    }
  }

  void _handleMenuAction(BuildContext context, String action, Map<String, dynamic> userWithBoat, AdminProviderSimple adminProvider) {
    switch (action) {
      case 'view':
        _showUserDetails(context, userWithBoat);
        break;
      case 'edit':
        _showEditUserDialog(context, userWithBoat);
        break;
      case 'toggle_status':
        _toggleUserStatus(context, userWithBoat, adminProvider);
        break;
      case 'delete':
        _showDeleteConfirmation(context, userWithBoat, adminProvider);
        break;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditUserDialog(),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> userWithBoat) {
    showDialog(
      context: context,
      builder: (context) => AddEditUserDialog(userWithBoat: userWithBoat),
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> userWithBoat) {
    final user = UserModel.fromMap(userWithBoat);
    final boat = userWithBoat['boat'] != null ? BoatModel.fromMap(userWithBoat['boat']) : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details - ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', user.fullName),
              _buildDetailRow('Email', user.email ?? ''),
              _buildDetailRow('Phone', user.phone ?? ''),
              _buildDetailRow('User Type', user.userType.toUpperCase()),
              _buildDetailRow('Status', userWithBoat['is_active'] == true ? 'Active' : 'Inactive'),
              _buildDetailRow('Created', user.createdAt != null ? _formatDate(user.createdAt!) : 'Unknown'),
              if (user.lastActive != null)
                _buildDetailRow('Last Active', _formatDate(user.lastActive!)),
              if (boat != null) ...[
                const Divider(),
                const Text('Boat Information', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow('Boat Number', boat.boatNumber),
                _buildDetailRow('Boat Type', boat.boatType ?? 'Unknown'),
                _buildDetailRow('Registration', boat.registrationNumber ?? 'N/A'),
              ],
            ],
          ),
        ),
        actions: [
          if (user.phone != null && user.phone!.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _makePhoneCall(user.phone!),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(BuildContext context, Map<String, dynamic> userWithBoat, AdminProviderSimple adminProvider) async {
    try {
      final userId = userWithBoat['user_id'];
      final isActive = userWithBoat['is_active'] == true;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Toggle status
      await adminProvider.toggleUserStatus(userId, !isActive);
      
      // Hide loading
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${!isActive ? 'activated' : 'deactivated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hide loading
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> userWithBoat, AdminProviderSimple adminProvider) {
    final user = UserModel.fromMap(userWithBoat);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get user_id before closing dialog
              final userId = userWithBoat['user_id'] as String? ?? userWithBoat['id'] as String?;
              if (userId == null || userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: User ID is missing'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.of(context).pop();
                return;
              }

              // Store scaffold messenger and root context before closing dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final rootContext = Navigator.of(context, rootNavigator: true).context;
              
              // Close the confirmation dialog first
              Navigator.of(context).pop();
              
              // Wait a moment to ensure dialog is fully closed
              await Future.delayed(const Duration(milliseconds: 100));
              
              try {
                // Show loading dialog - use rootNavigator to ensure it's on top
                if (!rootContext.mounted) return;
                
                showDialog(
                  context: rootContext,
                  barrierDismissible: false,
                  barrierColor: Colors.black54,
                  builder: (dialogContext) {
                    return const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Deleting user...'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );

                // Delete the user
                await adminProvider.deleteUser(userId);
                
                // Ensure minimum display time for loading (at least 500ms)
                await Future.delayed(const Duration(milliseconds: 300));
                
                // Hide loading dialog
                if (rootContext.mounted) {
                  Navigator.of(rootContext, rootNavigator: true).pop();
                }
                
                // Show success message
                if (rootContext.mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                // Hide loading dialog
                if (rootContext.mounted) {
                  final nav = Navigator.of(rootContext, rootNavigator: true);
                  if (nav.canPop()) {
                    nav.pop();
                  }
                }
                
                // Show error message
                if (rootContext.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
