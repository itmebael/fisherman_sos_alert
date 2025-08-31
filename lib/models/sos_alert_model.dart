class SOSAlertModel {
  final String id;
  final String fishermanId;
  final String fishermanName;
  final double latitude;
  final double longitude;
  final DateTime alertTime;
  final String status;
  final String? description;
  final String? coastguardId;
  final DateTime? responseTime;

  SOSAlertModel({
    required this.id,
    required this.fishermanId,
    required this.fishermanName,
    required this.latitude,
    required this.longitude,
    required this.alertTime,
    this.status = 'pending',
    this.description,
    this.coastguardId,
    this.responseTime,
  });

  factory SOSAlertModel.fromJson(Map<String, dynamic> json) {
    return SOSAlertModel(
      id: json['id'] ?? '',
      fishermanId: json['fishermanId'] ?? '',
      fishermanName: json['fishermanName'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      alertTime: DateTime.parse(json['alertTime'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      description: json['description'],
      coastguardId: json['coastguardId'],
      responseTime: json['responseTime'] != null ? DateTime.parse(json['responseTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fishermanId': fishermanId,
      'fishermanName': fishermanName,
      'latitude': latitude,
      'longitude': longitude,
      'alertTime': alertTime.toIso8601String(),
      'status': status,
      'description': description,
      'coastguardId': coastguardId,
      'responseTime': responseTime?.toIso8601String(),
    };
  }

  SOSAlertModel copyWith({
    String? id,
    String? fishermanId,
    String? fishermanName,
    double? latitude,
    double? longitude,
    DateTime? alertTime,
    String? status,
    String? description,
    String? coastguardId,
    DateTime? responseTime,
  }) {
    return SOSAlertModel(
      id: id ?? this.id,
      fishermanId: fishermanId ?? this.fishermanId,
      fishermanName: fishermanName ?? this.fishermanName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      alertTime: alertTime ?? this.alertTime,
      status: status ?? this.status,
      description: description ?? this.description,
      coastguardId: coastguardId ?? this.coastguardId,
      responseTime: responseTime ?? this.responseTime,
    );
  }
}