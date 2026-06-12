import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/sos_alert_model.dart';
import '../models/device_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class EmergencyStatPoint {
  final String label;
  final int sosCount;
  final int injuredCount;
  final int casualtyCount;
  final int rescuedCount;
  final int missingCount;
  final int totalOnboardCount;

  EmergencyStatPoint({
    required this.label,
    this.sosCount = 0,
    this.injuredCount = 0,
    this.casualtyCount = 0,
    this.rescuedCount = 0,
    this.missingCount = 0,
    this.totalOnboardCount = 0,
  });
}

class AdminProviderSimple with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Map<String, dynamic>> _usersWithBoats = [];
  List<SOSAlertModel> _rescueNotifications = [];
  List<DeviceModel> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Count properties
  int _totalUsers = 0;
  int _totalBoats = 0;
  int _totalRescued = 0;
  int _activeSOSAlerts = 0;
  int _totalDevices = 0;

  // Weekly rescue stats (Mon..Sun) - Keep for backward compatibility if needed, but we will use emergencyStats mainly
  Map<String, int> _weeklyRescueStats = {
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
    'Sat': 0,
    'Sun': 0,
  };

  // New Emergency Overview Stats
  List<EmergencyStatPoint> _emergencyStats = [];
  String _selectedTimeFilter = 'Weekly';

  // Getters
  List<Map<String, dynamic>> get usersWithBoats => _usersWithBoats;
  List<UserModel> get users =>
      _usersWithBoats.map((uwb) => UserModel.fromMap(uwb)).toList();
  List<SOSAlertModel> get rescueNotifications => _rescueNotifications;
  List<DeviceModel> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Updated getters for counts
  int get totalUsers => _totalUsers;
  int get totalBoats => _totalBoats;
  int get totalRescued => _totalRescued;
  int get activeSOSAlerts => _activeSOSAlerts;
  int get totalDevices => _totalDevices;
  Map<String, int> get weeklyRescueStats => _weeklyRescueStats;

  List<EmergencyStatPoint> get emergencyStats => _emergencyStats;
  String get selectedTimeFilter => _selectedTimeFilter;

  void setTimeFilter(String filter) {
    if (_selectedTimeFilter != filter) {
      _selectedTimeFilter = filter;
      loadEmergencyStats(filter: filter);
    }
  }

  // Load dashboard data
  Future<void> loadDashboardData({bool silent = false}) async {
    try {
      if (!silent) {
        _isLoading = true;
        notifyListeners();
      }
      _errorMessage = null;

      // Load all counts concurrently
      final results = await Future.wait([
        _databaseService.getTotalUsersCount(),
        _databaseService.getTotalBoatsCount(),
        _databaseService.getTotalRescuedCount(),
        _databaseService.getActiveSOSAlertsCount(),
        _getTotalDevicesCount(),
      ]);

      _totalUsers = results[0];
      _totalBoats = results[1];
      _totalRescued = results[2];
      _activeSOSAlerts = results[3];
      _totalDevices = results[4];

      // Load stats
      await _loadWeeklyRescueStats();
      await loadEmergencyStats(filter: _selectedTimeFilter);

      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      if (!silent) {
        _isLoading = false;
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load users with boats
  Future<void> loadUsersWithBoats() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get users with boats
      final usersWithBoats = await _databaseService.getAllUsersWithBoats();
      _usersWithBoats = usersWithBoats;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load rescue notifications
  Future<void> loadRescueNotifications() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final alerts = await _databaseService.getSOSAlerts();
      _rescueNotifications =
          alerts.map((alert) => SOSAlertModel.fromJson(alert)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update fisherman status
  Future<void> updateFishermanStatus(String fishermanId, bool isActive) async {
    try {
      await _databaseService.updateFishermanStatus(fishermanId, isActive);
      // Reload data
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update fisherman last active
  Future<void> updateFishermanLastActive(String fishermanId) async {
    try {
      await _databaseService.updateFishermanLastActive(fishermanId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating fisherman last active: $e');
      }
    }
  }

  // Update boat last used
  Future<void> updateBoatLastUsed(String boatId) async {
    try {
      await _databaseService.updateBoatLastUsed(boatId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating boat last used: $e');
      }
    }
  }

  // Delete fisherman
  Future<void> deleteFisherman(String fishermanId) async {
    try {
      final success = await _databaseService.deleteFisherman(fishermanId);
      if (!success) {
        throw Exception('Failed to delete fisherman');
      }
      // Reload data
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete boat
  Future<void> deleteBoat(String boatId) async {
    try {
      final success = await _databaseService.deleteBoat(boatId);
      if (!success) {
        throw Exception('Failed to delete boat');
      }
      // Reload data
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _loadWeeklyRescueStats() async {
    try {
      // Fetch recent alerts and compute weekly stats (limit to 1000 to ensure we catch recent resolutions)
      final alerts = await _databaseService.getAllSOSAlerts(limit: 1000);
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 6));
      final Map<String, int> counters = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };
      for (final alert in alerts) {
        final status = alert['status']?.toString().toLowerCase();
        // Include inactive, rescued, and resolved statuses
        if (status != 'inactive' && status != 'rescued' && status != 'resolved')
          continue;

        final resolvedAtStr = alert['resolved_at']?.toString();
        final createdAtStr = alert['created_at']?.toString();
        DateTime? ts;
        if (resolvedAtStr != null && resolvedAtStr.isNotEmpty) {
          ts = DateTime.tryParse(resolvedAtStr);
        }
        ts ??= createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
        if (ts == null) continue;
        // Only include last 7 days (including today)
        final isInRange =
            !ts.isBefore(DateTime(start.year, start.month, start.day)) &&
            !ts.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
        if (!isInRange) continue;
        final weekday = ts.weekday; // 1=Mon ... 7=Sun
        final dayLabel = switch (weekday) {
          DateTime.monday => 'Mon',
          DateTime.tuesday => 'Tue',
          DateTime.wednesday => 'Wed',
          DateTime.thursday => 'Thu',
          DateTime.friday => 'Fri',
          DateTime.saturday => 'Sat',
          DateTime.sunday => 'Sun',
          _ => 'Mon',
        };
        counters[dayLabel] = (counters[dayLabel] ?? 0) + 1;
      }
      _weeklyRescueStats = counters;
      notifyListeners();
    } catch (e) {
      // Keep existing stats if failed
      if (kDebugMode) {
        print('Error loading weekly rescue stats: $e');
      }
    }
  }

  Future<void> loadEmergencyStats({String filter = 'Weekly'}) async {
    try {
      // Fetch alerts
      final alerts = await _databaseService.getAllSOSAlerts(limit: 2000);
      final now = DateTime.now();

      List<EmergencyStatPoint> stats = [];

      if (filter == 'Daily') {
        // Show days of the current week: Monday, Tuesday, Wednesday, etc.
        stats = [];

        // Calculate current week boundaries (Monday to Sunday)
        final daysFromMonday = now.weekday - 1;
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: daysFromMonday));
        final weekEnd = weekStart.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );

        // Initialize all days of the week
        final Map<int, Map<String, int>> dayBuckets = {};
        for (int day = 1; day <= 7; day++) {
          dayBuckets[day] = {
            'sos': 0,
            'injured': 0,
            'casualty': 0,
            'rescued': 0,
            'missing': 0,
            'total_onboard': 0,
          };
        }

        for (final alert in alerts) {
          final created = DateTime.parse(alert['created_at'].toString());

          // Only include alerts from the current week
          if (created.isBefore(weekStart) || created.isAfter(weekEnd)) continue;

          final weekday = created.weekday; // 1=Monday, 7=Sunday
          _aggregateAlertToBucket(dayBuckets[weekday]!, alert);
        }

        // Add stats in order: Mon, Tue, Wed, Thu, Fri, Sat, Sun
        for (int day = 1; day <= 7; day++) {
          final dayLabel = _getDayLabel(day);
          stats.add(
            EmergencyStatPoint(
              label: dayLabel,
              sosCount: dayBuckets[day]!['sos']!,
              injuredCount: dayBuckets[day]!['injured']!,
              casualtyCount: dayBuckets[day]!['casualty']!,
              rescuedCount: dayBuckets[day]!['rescued']!,
              missingCount: dayBuckets[day]!['missing']!,
              totalOnboardCount: dayBuckets[day]!['total_onboard']!,
            ),
          );
        }
      } else if (filter == 'Weekly') {
        // Show Week 1, Week 2, Week 3, etc. (last 4-8 weeks)
        stats = [];
        final int numberOfWeeks = 8; // Show last 8 weeks

        for (int i = numberOfWeeks - 1; i >= 0; i--) {
          // Calculate week boundaries
          final weekEnd = now.subtract(Duration(days: i * 7));
          final weekStart = weekEnd.subtract(const Duration(days: 6));

          // Set to start and end of day
          final weekStartDay = DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day,
          );
          final weekEndDay = DateTime(
            weekEnd.year,
            weekEnd.month,
            weekEnd.day,
            23,
            59,
            59,
          );

          int sos = 0,
              injured = 0,
              casualty = 0,
              rescued = 0,
              missing = 0,
              totalOnboard = 0;

          for (final alert in alerts) {
            final created = DateTime.parse(alert['created_at'].toString());
            // Check if alert is within this week
            if (created.isAfter(
                  weekStartDay.subtract(const Duration(seconds: 1)),
                ) &&
                created.isBefore(weekEndDay.add(const Duration(seconds: 1)))) {
              sos++;
              final status =
                  alert['status']?.toString().toLowerCase() ?? 'active';
              if (status == 'rescued' ||
                  status == 'resolved' ||
                  status == 'inactive')
                rescued++;

              injured += (alert['injured'] as int? ?? 0);
              casualty += (alert['casualties'] as int? ?? 0);
              missing += (alert['missing'] as int? ?? 0);
              totalOnboard += (alert['total_onboard'] as int? ?? 0);
            }
          }

          stats.add(
            EmergencyStatPoint(
              label: 'Week ${numberOfWeeks - i}',
              sosCount: sos,
              injuredCount: injured,
              casualtyCount: casualty,
              rescuedCount: rescued,
              missingCount: missing,
              totalOnboardCount: totalOnboard,
            ),
          );
        }
      } else if (filter == 'Monthly') {
        // Show months: January, February, March, etc. (last 12 months)
        stats = [];
        for (int i = 11; i >= 0; i--) {
          // Calculate month correctly, handling year rollover
          int targetYear = now.year;
          int targetMonth = now.month - i;
          while (targetMonth < 1) {
            targetMonth += 12;
            targetYear -= 1;
          }
          while (targetMonth > 12) {
            targetMonth -= 12;
            targetYear += 1;
          }

          final monthStart = DateTime(targetYear, targetMonth, 1);
          final monthEnd =
              targetMonth == 12
                  ? DateTime(
                    targetYear + 1,
                    1,
                    1,
                  ).subtract(const Duration(seconds: 1))
                  : DateTime(
                    targetYear,
                    targetMonth + 1,
                    1,
                  ).subtract(const Duration(seconds: 1));

          final monthLabel = _getMonthLabel(targetMonth);

          int sos = 0,
              injured = 0,
              casualty = 0,
              rescued = 0,
              missing = 0,
              totalOnboard = 0;

          for (final alert in alerts) {
            final created = DateTime.parse(alert['created_at'].toString());
            // Check if alert is within this month
            if (created.isAfter(
                  monthStart.subtract(const Duration(seconds: 1)),
                ) &&
                created.isBefore(monthEnd.add(const Duration(seconds: 1)))) {
              sos++;
              final status =
                  alert['status']?.toString().toLowerCase() ?? 'active';
              if (status == 'rescued' ||
                  status == 'resolved' ||
                  status == 'inactive')
                rescued++;

              injured += (alert['injured'] as int? ?? 0);
              casualty += (alert['casualties'] as int? ?? 0);
              missing += (alert['missing'] as int? ?? 0);
              totalOnboard += (alert['total_onboard'] as int? ?? 0);
            }
          }

          stats.add(
            EmergencyStatPoint(
              label: monthLabel,
              sosCount: sos,
              injuredCount: injured,
              casualtyCount: casualty,
              rescuedCount: rescued,
              missingCount: missing,
              totalOnboardCount: totalOnboard,
            ),
          );
        }
      } else if (filter == 'Yearly') {
        // Show years: 2023, 2024, 2025, etc. (from 2023 to current year)
        stats = [];
        final int startYear = 2023;
        final int currentYear = now.year;
        final int numberOfYears = currentYear - startYear + 1;

        for (int i = 0; i < numberOfYears; i++) {
          final targetYear = startYear + i;
          final yearStart = DateTime(targetYear, 1, 1);
          final yearEnd = DateTime(
            targetYear + 1,
            1,
            1,
          ).subtract(const Duration(seconds: 1));

          int sos = 0,
              injured = 0,
              casualty = 0,
              rescued = 0,
              missing = 0,
              totalOnboard = 0;

          for (final alert in alerts) {
            final created = DateTime.parse(alert['created_at'].toString());
            // Check if alert is within this year
            if (created.isAfter(
                  yearStart.subtract(const Duration(seconds: 1)),
                ) &&
                created.isBefore(yearEnd.add(const Duration(seconds: 1)))) {
              sos++;
              final status =
                  alert['status']?.toString().toLowerCase() ?? 'active';
              if (status == 'rescued' ||
                  status == 'resolved' ||
                  status == 'inactive')
                rescued++;

              injured += (alert['injured'] as int? ?? 0);
              casualty += (alert['casualties'] as int? ?? 0);
              missing += (alert['missing'] as int? ?? 0);
              totalOnboard += (alert['total_onboard'] as int? ?? 0);
            }
          }

          stats.add(
            EmergencyStatPoint(
              label: targetYear.toString(),
              sosCount: sos,
              injuredCount: injured,
              casualtyCount: casualty,
              rescuedCount: rescued,
              missingCount: missing,
              totalOnboardCount: totalOnboard,
            ),
          );
        }
      }

      _emergencyStats = stats;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading emergency stats: $e');
      }
    }
  }

  void _aggregateAlertToBucket(
    Map<String, int> bucket,
    Map<String, dynamic> alert,
  ) {
    bucket['sos'] = (bucket['sos'] ?? 0) + 1;
    final status = alert['status']?.toString().toLowerCase() ?? 'active';
    if (status == 'rescued' || status == 'resolved' || status == 'inactive') {
      bucket['rescued'] = (bucket['rescued'] ?? 0) + 1;
    }

    bucket['injured'] =
        (bucket['injured'] ?? 0) + (alert['injured'] as int? ?? 0);
    bucket['casualty'] =
        (bucket['casualty'] ?? 0) + (alert['casualties'] as int? ?? 0);
    bucket['missing'] =
        (bucket['missing'] ?? 0) + (alert['missing'] as int? ?? 0);
    bucket['total_onboard'] =
        (bucket['total_onboard'] ?? 0) + (alert['total_onboard'] as int? ?? 0);
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getMonthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1) % 12];
  }

  // Create new user
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final authService = AuthService();

      // Get form data
      final firstName = userData['first_name'] ?? '';
      final middleName = userData['middle_name'] ?? '';
      final lastName = userData['last_name'] ?? '';

      // Create user using auth service (full name is built internally)
      // Extract boat information
      final boatNumber = userData['boat_number']?.toString() ?? '';
      final boatType = userData['boat_type']?.toString() ?? '';
      final boatRegistrationNumber =
          userData['registration_number']?.toString() ?? '';

      final success = await authService.registerBoatAndFisherman(
        email: userData['email'] ?? '',
        password: userData['password'] ?? '',
        firstName: firstName,
        lastName: lastName,
        middleName:
            middleName.toString().isNotEmpty ? middleName.toString() : null,
        phone: userData['phone'] ?? '',
        boatName:
            boatNumber.isNotEmpty
                ? boatNumber
                : 'Boat-${DateTime.now().millisecondsSinceEpoch}',
        boatType: boatType,
        boatRegistrationNumber: boatRegistrationNumber,
        boatCapacity: '0',
        profileImageUrl: userData['profile_image_url']?.toString(),
        address: userData['address']?.toString(),
        fishingArea: userData['fishing_area']?.toString(),
        emergencyContactPerson:
            userData['emergency_contact_person']?.toString(),
      );

      if (!success) {
        throw Exception('Failed to create user');
      }

      // Reload users to include the new one
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing user
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Build full name
      final firstName = userData['first_name'] ?? '';
      final middleName = userData['middle_name'] ?? '';
      final lastName = userData['last_name'] ?? '';
      final fullName = [
        firstName,
        if (middleName != null && middleName.toString().isNotEmpty) middleName,
        lastName,
      ].where((part) => part.toString().isNotEmpty).join(' ');

      // Prepare fisherman data including boat information (denormalized)
      final fishermanData = {
        'first_name': firstName,
        'middle_name':
            middleName.toString().isNotEmpty ? middleName.toString() : null,
        'last_name': lastName,
        'name': fullName,
        'email': userData['email'] ?? '',
        'phone': userData['phone'] ?? '',
        'address': userData['address']?.toString(),
        'fishing_area': userData['fishing_area']?.toString(),
        'emergency_contact_person':
            userData['emergency_contact_person']?.toString(),
        'is_active': userData['is_active'] ?? true,
        // Profile image URL - ensure it's saved
        'profile_image_url': userData['profile_image_url']?.toString(),
        // Boat information (denormalized to fishermen table)
        'boat_name': userData['boat_number']?.toString(),
        'boat_type': userData['boat_type']?.toString(),
        'boat_registration_number': userData['registration_number']?.toString(),
      };

      // Update fisherman (includes boat info)
      final success = await _databaseService.updateFisherman(
        userId,
        fishermanData,
      );

      if (!success) {
        throw Exception('Failed to update user');
      }

      // Also update boat table to keep it in sync
      final boatNumber = userData['boat_number']?.toString();
      final boatType = userData['boat_type']?.toString();
      final boatRegistrationNumber =
          userData['registration_number']?.toString();

      if (boatNumber != null ||
          boatType != null ||
          boatRegistrationNumber != null) {
        final boatData = {
          'boat_number': boatNumber,
          'boat_type': boatType,
          'registration_number': boatRegistrationNumber,
        };

        await _databaseService.createOrUpdateBoatForFisherman(userId, boatData);
      }

      // Reload users to reflect changes
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle user status (activate/deactivate)
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // This would typically call a service method to toggle status
      // For now, we'll simulate the toggle
      await Future.delayed(const Duration(seconds: 1));

      // Reload users to reflect changes
      await loadUsersWithBoats();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Find the user in the list
      final userWithBoat = _usersWithBoats.firstWhere((uwb) {
        final uid = uwb['user_id']?.toString() ?? uwb['id']?.toString();
        return uid == userId;
      }, orElse: () => {});

      if (userWithBoat.isEmpty) {
        throw Exception('User not found');
      }

      // Delete the fisherman (this will also delete all boats owned by the fisherman)
      await deleteFisherman(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Device Management Methods

  // Get total devices count
  Future<int> _getTotalDevicesCount() async {
    try {
      final stats = await _databaseService.getDeviceStatistics();
      return stats['total_devices'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Load devices
  Future<void> loadDevices() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get devices from database
      final deviceData = await _databaseService.getDevices();
      _devices = deviceData.map((data) => DeviceModel.fromMap(data)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Add device
  Future<void> addDevice(DeviceModel device) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Add device to database
      final deviceData = device.toMap();
      await _databaseService.addDevice(deviceData);

      // Reload devices to get updated list
      await loadDevices();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update device
  Future<void> updateDevice(DeviceModel device) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Update device in database
      final deviceData = device.toMap();
      await _databaseService.updateDevice(device.id, deviceData);

      // Reload devices to get updated list
      await loadDevices();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete device
  Future<void> deleteDevice(String deviceId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Delete device from database
      await _databaseService.deleteDevice(deviceId);

      // Reload devices to get updated list
      await loadDevices();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Toggle device status
  Future<void> toggleDeviceStatus(String deviceId, bool isActive) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Toggle device status in database
      await _databaseService.toggleDeviceStatus(deviceId, isActive);

      // Reload devices to get updated list
      await loadDevices();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Stop device signal
  Future<void> stopDeviceSignal(String deviceId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Stop device signal in database
      await _databaseService.stopDeviceSignal(deviceId);

      // Reload devices to get updated list
      await loadDevices();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
