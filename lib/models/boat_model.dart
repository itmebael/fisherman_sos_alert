  import 'package:cloud_firestore/cloud_firestore.dart';

  class BoatModel {
    final String id; // Required by Firestore rules
    final String boatNumber; // Required by Firestore rules
    final String ownerUid; // Required by Firestore rules
    final bool isActive; // Required by Firestore rules
    final Timestamp createdAt; // Required by Firestore rules
    final String? name; // Optional field
    final String? registrationNumber; // Optional field
    final DateTime? lastUsed; // NEW: Track last boat usage

    BoatModel({
      required this.id,
      required this.boatNumber,
      required this.ownerUid,
      required this.isActive,
      required this.createdAt,
      this.name,
      this.registrationNumber,
      this.lastUsed, // NEW: Optional last used time
    });

    factory BoatModel.fromJson(Map<String, dynamic> json) {
      // Parse lastUsed
      DateTime? lastUsedDate;
      if (json['lastUsed'] is Timestamp) {
        lastUsedDate = (json['lastUsed'] as Timestamp).toDate();
      } else if (json['lastUsed'] is String) {
        lastUsedDate = DateTime.tryParse(json['lastUsed']);
      } else if (json['lastUsed'] is DateTime) {
        lastUsedDate = json['lastUsed'];
      }

      return BoatModel(
        id: json['id'] ?? '',
        boatNumber: json['boatNumber'] ?? '',
        ownerUid: json['ownerUid'] ?? '',
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'] ?? Timestamp.now(),
        name: json['name'],
        registrationNumber: json['registrationNumber'],
        lastUsed: lastUsedDate, // NEW
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'boatNumber': boatNumber,
        'ownerUid': ownerUid,
        'isActive': isActive,
        'createdAt': createdAt,
        if (name != null) 'name': name,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        if (lastUsed != null) 'lastUsed': Timestamp.fromDate(lastUsed!), // NEW
      };
    }

    BoatModel copyWith({
      String? id,
      String? boatNumber,
      String? ownerUid,
      bool? isActive,
      Timestamp? createdAt,
      String? name,
      String? registrationNumber,
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