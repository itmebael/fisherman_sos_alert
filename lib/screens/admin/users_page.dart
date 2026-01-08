import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';
import '../../constants/routes.dart';
import '../admin/admin_drawer.dart';
import '../../services/database_service.dart';
import '../../models/user_with_boat_model.dart';
import '../../utils/date_formatter.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final DatabaseService _databaseService = DatabaseService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // BantayDagat logo
            ClipOval(
              child: Image.asset(
                'assets/img/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            // Coast Guard logo
            ClipOval(
              child: Image.asset(
                'assets/img/coastguard.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // App title
            const Text(
              "BantayDagat",
              style: TextStyle(
                color: Color(0xFF13294B),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.homeBackground,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: Builder(
          builder: (context) {
            final canPop = Navigator.of(context).canPop();
            return IconButton(
              icon: Icon(
                canPop ? Icons.arrow_back : Icons.menu,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                if (canPop) {
                  Navigator.of(context).pop();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            );
          },
        ),
      ),
      drawer: const AdminDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.homeBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with search and register button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Users List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context, 
                          AppRoutes.usersRegistration,
                        );
                        if (result == true) {
                          setState(() {}); // Refresh the stream
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.whiteColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.directions_boat, color: AppColors.whiteColor),
                      label: const Text('Register Boat'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by name, email, or boat number...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Users table
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _databaseService.getAllUsersWithBoats(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: AppColors.errorColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading users: ${snapshot.error}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.errorColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        final users = snapshot.data ?? [];
                        
                        // Filter users based on search query
                        final filteredUsers = _searchQuery.isEmpty 
                            ? users 
                            : users.where((userData) =>
                                (userData['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                (userData['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                (userData['boats']?[0]?['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
                              ).toList();

                        if (filteredUsers.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return _UsersTable(users: filteredUsers);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const _UsersTable({required this.users});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table headers (UPDATED - Now centered)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD), // Light blue header like your screenshot
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 2, 
                child: Text(
                  'Last Active', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center, // CENTERED
                )
              ),
              Expanded(
                flex: 2, 
                child: Text(
                  'Date', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center, // CENTERED
                )
              ),
              Expanded(
                flex: 3, 
                child: Text(
                  'Full Name', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center, // CENTERED
                )
              ),
              Expanded(
                flex: 2, 
                child: Text(
                  'Boat No.', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center, // CENTERED
                )
              ),
              Expanded(
                flex: 2, 
                child: Text(
                  'Status', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center, // CENTERED
                )
              ),
              Expanded(
                flex: 2, 
                child: Text(
                  'Action', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center, // CENTERED
                )
              ),
            ],
          ),
        ),
        
        // Table rows with actual data
        Expanded(
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userWithBoat = users[index];
              // Convert Map to UserWithBoatModel
              final userModel = UserWithBoatModel.fromMap(userWithBoat);
              return _UserTableRow(
                userWithBoat: userModel,
                onToggleStatus: () => _toggleUserStatus(context, userWithBoat),
                onView: () => _viewUser(context, userModel),
                onEdit: () => _editUser(context, userModel),
                onDelete: () => _deleteUser(context, userModel),
              );
            },
          ),
        ),
      ],
    );
  }

  void _toggleUserStatus(BuildContext context, Map<String, dynamic> userData) async {
    try {
      final databaseService = DatabaseService();
      final isActive = userData['is_active'] ?? true;
      await databaseService.updateFishermanStatus(
        userData['id'], 
        !isActive
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${userData['name']} is now ${!isActive ? 'Active' : 'Inactive'}',
          ),
          backgroundColor: !isActive ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewUser(BuildContext context, UserWithBoatModel userWithBoat) {
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(userWithBoat: userWithBoat),
    );
  }

  void _editUser(BuildContext context, UserWithBoatModel userWithBoat) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit user feature coming soon!'),
      ),
    );
  }

  void _deleteUser(BuildContext context, UserWithBoatModel userWithBoat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${userWithBoat.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final databaseService = DatabaseService();
                await databaseService.deleteFisherman(userWithBoat.userId);
                
                if (userWithBoat.boat != null) {
                  await databaseService.deleteBoat(userWithBoat.boat!.id);
                }
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${userWithBoat.fullName} has been deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting user: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _UserTableRow extends StatelessWidget {
  final UserWithBoatModel userWithBoat;
  final VoidCallback onToggleStatus;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserTableRow({
    required this.userWithBoat,
    required this.onToggleStatus,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerColor.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Last Active column (UPDATED - Now centered)
          Expanded(
            flex: 2,
            child: Text(
              userWithBoat.lastActiveDisplay,
              style: TextStyle(
                color: _getLastActiveColor(userWithBoat.user.lastActive),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center, // CENTERED
            ),
          ),
          
          // Registration Date column (UPDATED - Now centered)
          Expanded(
            flex: 2,
            child: Text(
              DateFormatter.formatDate(userWithBoat.registrationDate),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center, // CENTERED
            ),
          ),
          
          // Full Name column (UPDATED - Now centered)
          Expanded(
            flex: 3,
            child: Text(
              userWithBoat.fullName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center, // CENTERED
            ),
          ),
          
          // Boat Number column (UPDATED - Now centered)
          Expanded(
            flex: 2,
            child: Text(
              userWithBoat.boatNumber,
              style: TextStyle(
                color: userWithBoat.hasBoat 
                    ? AppColors.textPrimary 
                    : AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center, // CENTERED
            ),
          ),
          
          // Status column with toggle (UPDATED - Now centered)
          Expanded(
            flex: 2,
            child: Center( // WRAPPED IN CENTER WIDGET
              child: GestureDetector(
                onTap: onToggleStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: userWithBoat.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userWithBoat.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          
          // Action buttons column (UPDATED - Now centered)
          Expanded(
            flex: 2,
            child: Center( // WRAPPED IN CENTER WIDGET
              child: Row(
                mainAxisSize: MainAxisSize.min, // Keep buttons together
                children: [
                  _ActionIcon(Icons.person, Colors.green, onEdit),
                  const SizedBox(width: 4),
                  _ActionIcon(Icons.visibility, Colors.blue, onView),
                  const SizedBox(width: 4),
                  _ActionIcon(Icons.delete, Colors.red, onDelete),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLastActiveColor(DateTime? lastActive) {
    if (lastActive == null) return Colors.red;
    
    final difference = DateTime.now().difference(lastActive);
    
    if (difference.inMinutes < 60) return Colors.green;
    if (difference.inDays < 7) return Colors.orange;
    if (difference.inDays < 30) return Colors.red.shade300;
    return Colors.red;
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 12),
      ),
    );
  }
}

class _UserDetailsDialog extends StatelessWidget {
  final UserWithBoatModel userWithBoat;

  const _UserDetailsDialog({required this.userWithBoat});

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

  @override
  Widget build(BuildContext context) {
    final user = userWithBoat.user;
    final boat = userWithBoat.boat;
    
    return AlertDialog(
      title: Text(user.name ?? user.fullName),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow('User ID', user.displayId ?? user.id),
            _DetailRow('Email', user.email ?? 'N/A'),
            _DetailRow('Phone', user.phone ?? 'N/A'),
            _DetailRow('Address', user.address ?? 'N/A'),
            _DetailRow('Fishing Area', user.fishingArea ?? 'N/A'),
            _DetailRow('Emergency Contact', user.emergencyContactPerson ?? 'N/A'),
            _DetailRow('Registration Date', DateFormatter.formatDate(user.registrationDate ?? DateTime.now())),
            _DetailRow('Last Active', user.lastActiveDisplay),
            _DetailRow('Status', (user.isActive ?? false) ? 'Active' : 'Inactive'),
            const SizedBox(height: 16),
            const Text(
              'Boat Information:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (boat != null) ...[
              _DetailRow('Boat Number', boat.boatNumber),
              _DetailRow('Boat Name', boat.name ?? 'N/A'),
              _DetailRow('Registration Number', boat.registrationNumber ?? 'N/A'),
              _DetailRow('Boat Status', boat.isActive ? 'Active' : 'Inactive'),
              _DetailRow('Last Used', boat.lastUsedDisplay),
            ] else
              const Text(
                'No boat registered',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}