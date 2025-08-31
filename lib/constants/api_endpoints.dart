class ApiEndpoints {
  // User management
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  
  // SOS alerts
  static const String sendSOS = '/sos/send';
  static const String getSOSAlerts = '/sos/alerts';
  static const String updateSOSStatus = '/sos/update-status';
  
  // User data
  static const String getUserProfile = '/user/profile';
  static const String updateUserProfile = '/user/update';
  
  // News
  static const String getNews = '/news';
  static const String getNewsById = '/news/';
  
  // Reports
  static const String getReports = '/reports';
  static const String createReport = '/reports/create';
  
  // Location
  static const String updateLocation = '/location/update';
  static const String getNearbyAlerts = '/location/nearby-alerts';
}
