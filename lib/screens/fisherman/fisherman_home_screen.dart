import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import 'sos_button.dart';
import '../../services/database_service.dart';
import '../../services/global_notification_manager.dart';
import '../../providers/auth_provider.dart';
import 'fisherman_drawer.dart';

class FishermanHomeScreen extends StatefulWidget {
  const FishermanHomeScreen({super.key});

  @override
  State<FishermanHomeScreen> createState() => _FishermanHomeScreenState();
}

class _FishermanHomeScreenState extends State<FishermanHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final GlobalNotificationManager _globalNotificationManager = GlobalNotificationManager();
  List<Map<String, dynamic>> _coastguards = [];
  bool _isLoadingCoastguards = false;

  @override
  void initState() {
    super.initState();
    _loadCoastguards();
    // Initialize global notification manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _globalNotificationManager.initialize(context, authProvider);
    });
  }

  @override
  void dispose() {
    _globalNotificationManager.dispose();
    super.dispose();
  }

  Future<void> _loadCoastguards() async {
    setState(() {
      _isLoadingCoastguards = true;
    });
    try {
      final coastguards = await _databaseService.getActiveCoastguards();
      setState(() {
        _coastguards = coastguards;
        _isLoadingCoastguards = false;
      });
    } catch (e) {
      print('Error loading coastguards: $e');
      setState(() {
        _isLoadingCoastguards = false;
      });
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Unable to make phone call. $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCallDialog() {
    // Find first coastguard with a phone number
    final coastguardWithPhone = _coastguards.firstWhere(
      (cg) => cg['phone'] != null && cg['phone'].toString().isNotEmpty,
      orElse: () => <String, dynamic>{},
    );

    // Use coastguard phone if available, otherwise use default emergency number
    final String phoneNumber;
    final String contactName;
    
    if (coastguardWithPhone.isNotEmpty) {
      phoneNumber = coastguardWithPhone['phone'].toString();
      contactName = coastguardWithPhone['name'] ?? 
                   coastguardWithPhone['first_name'] ?? 
                   'Coast Guard';
    } else {
      // Use default emergency call number
      phoneNumber = AppStrings.emergencyCallNumber;
      contactName = AppStrings.emergencyContactName;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_police, color: Colors.green),
            SizedBox(width: 8),
            Text('Call Coast Guard'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact: $contactName'),
            const SizedBox(height: 8),
            Text('Phone: $phoneNumber'),
            const SizedBox(height: 16),
            const Text(
              'Do you want to call the Coast Guard?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _makePhoneCall(phoneNumber);
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.home,
          style: TextStyle(
            color: AppColors.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: AppColors.whiteColor),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.whiteColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: const [],
      ),
      drawer: const FishermanDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.homeBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Logo + App Name
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: screenWidth * 0.3,
                        height: screenWidth * 0.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/img/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.08, // scales with screen
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // SOS Button + Instructions
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.05,
                  ),
                  child: Column(
                    children: [
                      const SOSButton(),
                      SizedBox(height: screenHeight * 0.03),
                      const Text(
                        'Press the SOS button in case of emergency.\nThis will immediately alert the Salbar_Mangirisda Coast Guard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      // Call Coast Guard Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingCoastguards ? null : _showCallDialog,
                          icon: _isLoadingCoastguards
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.phone, size: 24),
                          label: Text(
                            _isLoadingCoastguards
                                ? 'Loading...'
                                : 'Call Coast Guard',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                              horizontal: screenWidth * 0.05,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      const Text(
                        'Contact the Coast Guard directly for assistance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Emergency Contact Number Display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Emergency: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _makePhoneCall(AppStrings.emergencyCallNumber),
                              child: Text(
                                AppStrings.emergencyCallNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                    ],
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