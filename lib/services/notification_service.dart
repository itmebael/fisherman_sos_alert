
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // Initialize notification service
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    print('Notification: $title - $body');
  }

  Future<void> showSOSNotification({
    required String fishermanName,
    required double latitude,
    required double longitude,
  }) async {
    await showNotification(
      title: 'Emergency SOS Alert',
      body: '$fishermanName needs assistance at $latitude, $longitude',
    );
  }
}