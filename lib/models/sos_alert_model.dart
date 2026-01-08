class SOSAlertModel {
  final String id;
  final String fishermanId;
  final double latitude;
  final double longitude;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final int casualties;
  final int injured;

  SOSAlertModel({
    required this.id,
    required this.fishermanId,
    required this.latitude,
    required this.longitude,
    this.message,
    this.status = 'active',
    required this.createdAt,
    this.resolvedAt,
    this.casualties = 0,
    this.injured = 0,
  });

  factory SOSAlertModel.fromJson(Map<String, dynamic> json) {
    return SOSAlertModel(
      id: json['id'] ?? '',
      fishermanId: json['fisherman_id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      message: json['message'],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      casualties: json['casualties'] ?? 0,
      injured: json['injured'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fisherman_id': fishermanId,
      'latitude': latitude,
      'longitude': longitude,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'casualties': casualties,
      'injured': injured,
    };
  }

  SOSAlertModel copyWith({
    String? id,
    String? fishermanId,
    double? latitude,
    double? longitude,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    int? casualties,
    int? injured,
  }) {
    return SOSAlertModel(
      id: id ?? this.id,
      fishermanId: fishermanId ?? this.fishermanId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      casualties: casualties ?? this.casualties,
      injured: injured ?? this.injured,
    );
  }
}