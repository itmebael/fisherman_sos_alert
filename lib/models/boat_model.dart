class BoatModel {
  final String id; // Required by database rules
  final String boatNumber; // Required by database rules
  final String ownerUid; // Required by database rules
  final bool isActive; // Required by database rules
  final DateTime createdAt; // Required by database rules
  final String? name; // Optional field
  final String? registrationNumber; // Optional field
  final String? boatType; // Optional field
  final DateTime? lastUsed; // NEW: Track last boat usage

  BoatModel({
    required this.id,
    required this.boatNumber,
    required this.ownerUid,
    required this.isActive,
    required this.createdAt,
    this.name,
    this.registrationNumber,
    this.boatType,
    this.lastUsed, // NEW: Optional last used time
  });

  factory BoatModel.fromMap(Map<String, dynamic> map) {
    return BoatModel.fromJson(map);
  }

  factory BoatModel.fromJson(Map<String, dynamic> json) {
    // Parse createdAt
    DateTime createdDate;
    if (json['createdAt'] is String) {
      createdDate = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    } else if (json['createdAt'] is DateTime) {
      createdDate = json['createdAt'];
    } else {
      createdDate = DateTime.now();
    }

    // Parse lastUsed
    DateTime? lastUsedDate;
    if (json['lastUsed'] is String) {
      lastUsedDate = DateTime.tryParse(json['lastUsed']);
    } else if (json['lastUsed'] is DateTime) {
      lastUsedDate = json['lastUsed'];
    }

    return BoatModel(
      id: json['id'] ?? '',
      boatNumber: json['boatNumber'] ?? '',
      ownerUid: json['ownerUid'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: createdDate,
      name: json['name'],
      registrationNumber: json['registrationNumber'],
      boatType: json['boatType'],
      lastUsed: lastUsedDate, // NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boatNumber': boatNumber,
      'ownerUid': ownerUid,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      if (name != null) 'name': name,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (boatType != null) 'boatType': boatType,
      if (lastUsed != null) 'lastUsed': lastUsed!.toIso8601String(), // NEW
    };
  }

  BoatModel copyWith({
    String? id,
    String? boatNumber,
    String? ownerUid,
    bool? isActive,
    DateTime? createdAt,
    String? name,
    String? registrationNumber,
    String? boatType,
    DateTime? lastUsed, // NEW
  }) {
    return BoatModel(
      id: id ?? this.id,
      boatNumber: boatNumber ?? this.boatNumber,
      ownerUid: ownerUid ?? this.ownerUid,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      boatType: boatType ?? this.boatType,
      lastUsed: lastUsed ?? this.lastUsed, // NEW
    );
  }

  // NEW: Helper method to get formatted last used display
  String get lastUsedDisplay {
    if (lastUsed == null) return 'Never Used';
    
    final now = DateTime.now();
    final difference = now.difference(lastUsed!);
    
    if (difference.inMinutes < 1) {
      return 'Just Used';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
}