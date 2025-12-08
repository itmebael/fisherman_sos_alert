import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/auth_provider.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with TickerProviderStateMixin {
  bool _isSending = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendSOSAlert() async {
    // Show confirmation dialog first to prevent false SOS alerts
    final confirmed = await _showSOSConfirmationDialog();
    if (!confirmed) {
      print('SOS alert cancelled by user');
      return;
    }

    final supabase = Supabase.instance.client;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    // Allow SOS alerts even if user is not authenticated
    // This is important for emergency situations
    print('SOS Alert confirmed - User authenticated: ${user != null}');

    try {
      setState(() => _isSending = true);

      // Check and request location permissions using permission_handler
      print('Checking location permissions...');
      
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable location services in device settings.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      // Check location permission using permission_handler
      PermissionStatus locationPermission = await Permission.location.status;
      print('Location permission status: $locationPermission');

      if (locationPermission.isDenied) {
        print('Requesting location permission...');
        locationPermission = await Permission.location.request();
        print('Location permission after request: $locationPermission');
      }

      if (locationPermission.isPermanentlyDenied) {
        print('Location permission permanently denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions are permanently denied. Please enable location permissions in device settings.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      if (locationPermission.isDenied) {
        print('Location permission denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission is required to send SOS alerts. Please grant location permission in device settings.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      print('Location permission granted, getting current position...');

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print('Location obtained: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Error getting location: $e');
        // Show dialog to ask user for manual location input
        final manualLocation = await _showLocationInputDialog(context);
        if (manualLocation != null) {
          position = Position(
            latitude: manualLocation['latitude']!,
            longitude: manualLocation['longitude']!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SOS alert cancelled. Location is required for emergency response.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSending = false);
          return;
        }
      }

      // Generate alert ID and save to database
      final alertId = const Uuid().v4();

      print('SOS alert completed successfully');

      // Prepare SOS alert data - include user data if available, otherwise use defaults
      // Add null safety checks to prevent NoSuchMethodError
      final sosAlertData = {
        'id': alertId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'message': 'Emergency SOS Alert - Fisherman in distress',
        'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'fisherman_uid': user?.id,
        'fisherman_display_id': user?.displayId,
        'fisherman_first_name': user?.firstName ?? 'Unknown',
        'fisherman_middle_name': user?.middleName,
        'fisherman_last_name': user?.lastName ?? 'User',
        'fisherman_name': user != null 
            ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty 
                ? 'Anonymous User' 
                : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
            : 'Anonymous User',
        'fisherman_email': user?.email ?? 'anonymous@emergency.com',
        'fisherman_phone': user?.phone ?? 'Not provided',
        'fisherman_user_type': user?.userType ?? 'anonymous',
        'fisherman_address': user?.address ?? 'Location not provided',
        'fisherman_fishing_area': user?.fishingArea ?? 'Unknown area',
        'fisherman_emergency_contact_person': user?.emergencyContactPerson ?? 'Not provided',
        'fisherman_profile_picture_url': user?.profileImageUrl,
        'fisherman_profile_image_url': user?.profileImageUrl,
      };

      print('SOS Alert data prepared:');
      print('- User authenticated: ${user != null}');
      print('- Location: ${position.latitude}, ${position.longitude}');
      print('- Fisherman name: ${sosAlertData['fisherman_name']}');
      print('- Fisherman email: ${sosAlertData['fisherman_email']}');

      try {
        final response = await supabase.from('sos_alerts').insert(sosAlertData);
        
        // If we get here without exception, the insert was successful
        print('✅ SOS alert saved successfully to public.sos_alerts');
        print('Response data: $response');
        final userStatus = user != null ? 'authenticated user' : 'anonymous user';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS Alert successfully sent and saved! ($userStatus)'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (insertError) {
        // Handle insert-specific errors
        print('❌ Error saving SOS alert: $insertError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save SOS alert: $insertError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception while sending SOS: $e');
      print('Exception type: ${e.runtimeType}');
      
      String errorMessage = 'Error sending SOS alert';
      if (e.toString().contains('NoSuchMethodError')) {
        errorMessage = 'Error: Missing method or property. Please check user data.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Error: Permission denied. Please check your settings.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Error: Network connection failed. Please check your internet.';
      } else {
        errorMessage = 'Error sending SOS alert: ${e.toString().length > 50 ? '${e.toString().substring(0, 50)}...' : e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isSending ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: 250, // 2x bigger (was 125)
            height: 250, // 2x bigger (was 125)
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSending ? Colors.grey : Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 4,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 25,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(125),
                onTap: _isSending ? null : _sendSOSAlert,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                          )
                        : const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40, // 2x bigger (was 20)
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
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
      },
    );
  }

  Future<Map<String, double>?> _showLocationInputDialog(BuildContext context) async {
    final latController = TextEditingController();
    final lngController = TextEditingController();
    
    return showDialog<Map<String, double>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Your Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Location permission was denied. Please enter your coordinates manually for emergency response:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: latController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g., 11.7753',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g., 124.8861',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can find your coordinates using Google Maps or other GPS apps.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final lat = double.tryParse(latController.text);
                final lng = double.tryParse(lngController.text);
                
                if (lat != null && lng != null && 
                    lat >= -90 && lat <= 90 && 
                    lng >= -180 && lng <= 180) {
                  Navigator.of(context).pop({
                    'latitude': lat,
                    'longitude': lng,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid coordinates (Latitude: -90 to 90, Longitude: -180 to 180)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Send SOS'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showSOSConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Emergency SOS Alert',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you in a real emergency situation?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This will send an emergency alert to rescue services with your location. Only use this in genuine emergency situations.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'False alarms waste emergency resources and may delay help for real emergencies.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send SOS Alert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }
}
