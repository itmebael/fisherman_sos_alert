class RescueReportModel {
  final String id;
  final String sosAlertId;
  final String coastguardId;
  final String coastguardName;
  final DateTime responseTime;
  final DateTime? completionTime;
  final String status;
  final String? notes;
  final String? actionTaken;

  RescueReportModel({
    required this.id,
    required this.sosAlertId,
    required this.coastguardId,
    required this.coastguardName,
    required this.responseTime,
    this.completionTime,
    this.status = 'in_progress',
    this.notes,
    this.actionTaken,
  });

  factory RescueReportModel.fromJson(Map<String, dynamic> json) {
    return RescueReportModel(
      id: json['id'] ?? '',
      sosAlertId: json['sosAlertId'] ?? '',
      coastguardId: json['coastguardId'] ?? '',
      coastguardName: json['coastguardName'] ?? '',
      responseTime: DateTime.parse(json['responseTime'] ?? DateTime.now().toIso8601String()),
      completionTime: json['completionTime'] != null ? DateTime.parse(json['completionTime']) : null,
      status: json['status'] ?? 'in_progress',
      notes: json['notes'],
      actionTaken: json['actionTaken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sosAlertId': sosAlertId,
      'coastguardId': coastguardId,
      'coastguardName': coastguardName,
      'responseTime': responseTime.toIso8601String(),
      'completionTime': completionTime?.toIso8601String(),
      'status': status,
      'notes': notes,
      'actionTaken': actionTaken,
    };
  }
}
