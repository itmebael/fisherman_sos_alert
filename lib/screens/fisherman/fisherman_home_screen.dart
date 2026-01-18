import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
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
    // Clean phone number - remove any non-digit characters except +
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
    
    try {
      // Ensure we're on the UI thread before making the call
      if (!mounted) return;
      
      // Try to launch the phone call directly
      // On some devices/emulators, canLaunchUrl may return false even if tel: works
      try {
        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
        // If successful, return early
        return;
      } catch (launchError) {
        // If launch fails, check if URL can be launched
        final canLaunch = await canLaunchUrl(phoneUri);
        
        if (canLaunch) {
          // Try again with platform default mode
          await launchUrl(phoneUri);
        } else {
          // Show dialog with phone number for manual dialing
          if (mounted) {
            _showManualDialDialog(cleanedNumber);
          }
        }
      }
    } catch (e) {
      // Handle error - phone call not available
      print('Error making phone call: $e');
      if (mounted) {
        _showManualDialDialog(cleanedNumber);
      }
    }
  }

  void _showManualDialDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: Colors.blue),
            SizedBox(width: 8),
            Text('Phone Call Not Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to make phone call automatically. Please dial the number manually:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  SelectableText(
                    phoneNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog() {
    // Always use the emergency call number 09393898330
    final String phoneNumber = AppStrings.emergencyCallNumber;
    final String contactName = AppStrings.emergencyContactName;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.local_police,
              color: Colors.green,
              size: isMobile ? 24 : 28,
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Flexible(
              child: Text(
                'Call Coast Guard',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: isMobile ? 18 : 20, color: Colors.blue),
                SizedBox(width: isMobile ? 8 : 12),
                Flexible(
                  child: Text(
                    'Contact: $contactName',
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Row(
              children: [
                Icon(Icons.phone, size: isMobile ? 18 : 20, color: Colors.green),
                SizedBox(width: isMobile ? 8 : 12),
                Flexible(
                  child: Text(
                    'Phone: $phoneNumber',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'Do you want to call the Coast Guard?',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: isMobile ? 8 : 12,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Use post frame callback to ensure UI thread
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _makePhoneCall(phoneNumber);
                    });
                  },
                  icon: Icon(Icons.phone, size: isMobile ? 18 : 20),
                  label: Text(
                    'Call',
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 24,
                      vertical: isMobile ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
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
