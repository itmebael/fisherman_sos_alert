import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../constants/routes.dart';
import 'sos_button.dart';
import '../../services/global_notification_manager.dart';
import '../../providers/auth_provider.dart';
import 'fisherman_drawer.dart';

class FishermanHomeScreen extends StatefulWidget {
  const FishermanHomeScreen({super.key});

  @override
  State<FishermanHomeScreen> createState() => _FishermanHomeScreenState();
}

class _FishermanHomeScreenState extends State<FishermanHomeScreen> {
  final GlobalNotificationManager _globalNotificationManager =
      GlobalNotificationManager();

  @override
  void initState() {
    super.initState();
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
    // Always use the emergency call number 09393898330
    final String phoneNumber = AppStrings.emergencyCallNumber;
    final String contactName = AppStrings.emergencyContactName;

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
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

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
                  padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 20 : 24)),
                  child: Column(
                    children: [
                      Container(
                        width: isMobile
                            ? screenWidth * 0.25
                            : (isTablet
                                  ? screenWidth * 0.2
                                  : screenWidth * 0.15),
                        height: isMobile
                            ? screenWidth * 0.25
                            : (isTablet
                                  ? screenWidth * 0.2
                                  : screenWidth * 0.15),
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
                      SizedBox(
                        height: isMobile
                            ? screenHeight * 0.015
                            : screenHeight * 0.02,
                      ),
                      Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: isMobile
                              ? screenWidth * 0.06
                              : (isTablet
                                    ? screenWidth * 0.05
                                    : screenWidth * 0.04),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // SOS Button + Instructions
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile
                        ? screenWidth * 0.05
                        : (isTablet ? screenWidth * 0.08 : screenWidth * 0.1),
                    vertical: isMobile
                        ? screenHeight * 0.03
                        : screenHeight * 0.05,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SOSButton(),
                      SizedBox(
                        height: isMobile
                            ? screenHeight * 0.02
                            : screenHeight * 0.03,
                      ),
                      Text(
                        'Press the SOS button in case of emergency.\nThis will immediately alert the Salbar Mangirisda Coast Guard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(
                        height: isMobile
                            ? screenHeight * 0.02
                            : screenHeight * 0.03,
                      ),
                      // Call Coast Guard Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showCallDialog,
                          icon: Icon(Icons.phone, size: isMobile ? 20 : 24),
                          label: Text(
                            'Call Coast Guard',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : (isTablet ? 17 : 18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile
                                  ? screenHeight * 0.012
                                  : screenHeight * 0.018,
                              horizontal: isMobile
                                  ? screenWidth * 0.04
                                  : screenWidth * 0.05,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: isMobile
                            ? screenHeight * 0.012
                            : screenHeight * 0.018,
                      ),
                      Text(
                        'Contact the Coast Guard directly for assistance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(
                        height: isMobile
                            ? screenHeight * 0.012
                            : screenHeight * 0.018,
                      ),
                      // Emergency Contact Number Display
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: isMobile
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Emergency: ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _makePhoneCall(
                                      AppStrings.emergencyCallNumber,
                                    ),
                                    child: Text(
                                      AppStrings.emergencyCallNumber,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: Colors.blue,
                                    size: isTablet ? 18 : 20,
                                  ),
                                  SizedBox(width: isTablet ? 6 : 8),
                                  const Text(
                                    'Emergency: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _makePhoneCall(
                                      AppStrings.emergencyCallNumber,
                                    ),
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
                      SizedBox(
                        height: isMobile
                            ? screenHeight * 0.02
                            : screenHeight * 0.03,
                      ),
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
