import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/boat_model.dart';
import '../models/user_with_boat_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For subcollections, "next id" logic may need to be changed, but here's a root-level fallback
  Future<String> getNextFishermenId(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('fishermen')
        .orderBy('id', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return '00001';
    }
    final lastId = int.tryParse(snapshot.docs.first['id']) ?? 0;
    return lastId < 99999 
      ? (lastId + 1).toString().padLeft(5, '0') 
      : throw Exception('ID overflow');
  }

  Future<String> getNextCoastguardId(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('coastguards')
        .orderBy('id', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return '00001';
    }
    final lastId = int.tryParse(snapshot.docs.first['id']) ?? 0;
    return lastId < 99999 
      ? (lastId + 1).toString().padLeft(5, '0') 
      : throw Exception('ID overflow');
  }

  Future<String> getNextBoatId() async {
    final snapshot = await _firestore
        .collection('boats')
        .orderBy('id', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return '00001';
    }
    final lastId = int.tryParse(snapshot.docs.first['id']) ?? 0;
    return lastId < 99999 
      ? (lastId + 1).toString().padLeft(5, '0') 
      : throw Exception('ID overflow');
  }

// Count total users (fishermen only)
Future<int> getTotalUsersCount() async {
  try {
    final fishermen = await _firestore.collectionGroup('fishermen').get();
    return fishermen.docs.length;
  } catch (e) {
    print('Error getting users count: $e');
    return 0;
  }
}

  // Count total boats
  Future<int> getTotalBoatsCount() async {
    try {
      final boats = await _firestore.collection('boats').get();
      return boats.docs.length;
    } catch (e) {
      print('Error getting boats count: $e');
      return 0;
    }
  }

  // Count total rescued (SOS alerts with status 'resolved')
  Future<int> getTotalRescuedCount() async {
    try {
      final rescuedAlerts = await _firestore
          .collection('sos_alerts')
          .where('status', isEqualTo: 'resolved')
          .get();
      return rescuedAlerts.docs.length;
    } catch (e) {
      print('Error getting rescued count: $e');
      return 0;
    }
  }

  // Save fisherman to fishermen subcollection
  Future<void> saveFisherman(String uid, Map<String, dynamic> fishermenData) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fishermen')
        .doc(uid)
        .set(fishermenData);
  }

  // Save coastguard to coastguards subcollection
  Future<void> saveCoastguard(String uid, Map<String, dynamic> coastguardData) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('coastguards')
        .doc(uid)
        .set(coastguardData);
  }

  // Save user to appropriate subcollection based on userType
  Future<void> saveUser(UserModel user) async {
    if (user.userType == 'fisherman') {
      final fishermenData = {
        'id': user.id,
        'firstName': user.firstName ?? '',
        'middleName': user.middleName,
        'lastName': user.lastName ?? '',
        'email': user.email,
        'phone': user.phone,
        'address': user.address ?? '',
        'fishingArea': user.fishingArea ?? '',
        'emergencyContactPerson': user.emergencyContactPerson ?? '',
        'isActive': user.isActive,
        'registrationDate': Timestamp.fromDate(user.registrationDate),
        if (user.lastActive != null) 'lastActive': Timestamp.fromDate(user.lastActive!),
      };
      await saveFisherman(user.id, fishermenData);
    } else if (user.userType == 'coastguard') {
      final coastguardData = {
        'id': user.id,
        'firstName': user.firstName ?? '',
        'middleName': user.middleName,
        'lastName': user.lastName ?? '',
        'email': user.email,
        'isActive': user.isActive,
        'registrationDate': Timestamp.fromDate(user.registrationDate),
        if (user.lastActive != null) 'lastActive': Timestamp.fromDate(user.lastActive!),
      };
      await saveCoastguard(user.id, coastguardData);
    }
  }

  Future<void> saveBoat(BoatModel boat) async {
    await _firestore.collection('boats').doc(boat.id).set(boat.toJson());
  }

  // Fetch user from appropriate subcollection
  Future<UserModel?> getUser(String uid) async {
    try {
      // Try coastguards subcollection first
      DocumentSnapshot coastguardDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('coastguards')
          .doc(uid)
          .get();

      if (coastguardDoc.exists && coastguardDoc.data() != null) {
        final data = coastguardDoc.data() as Map<String, dynamic>;
        return UserModel(
          id: data['id'],
          firstName: data['firstName'],
          middleName: data['middleName'],
          lastName: data['lastName'],
          name: "${data['firstName']}${data['middleName'] != null && data['middleName'].toString().isNotEmpty ? ' ${data['middleName']}' : ''} ${data['lastName']}",
          email: data['email'],
          phone: '',
          userType: 'coastguard',
          registrationDate: (data['registrationDate'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          lastActive: data['lastActive'] != null 
              ? (data['lastActive'] as Timestamp).toDate() 
              : null,
        );
      }

      // Try fishermen subcollection
      DocumentSnapshot fishermenDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('fishermen')
          .doc(uid)
          .get();

      if (fishermenDoc.exists && fishermenDoc.data() != null) {
        final data = fishermenDoc.data() as Map<String, dynamic>;
        return UserModel(
          id: data['id'],
          firstName: data['firstName'],
          middleName: data['middleName'],
          lastName: data['lastName'],
          name: "${data['firstName']}${data['middleName'] != null && data['middleName'].toString().isNotEmpty ? ' ${data['middleName']}' : ''} ${data['lastName']}",
          email: data['email'],
          phone: data['phone'] ?? '',
          userType: 'fisherman',
          registrationDate: (data['registrationDate'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          address: data['address'],
          fishingArea: data['fishingArea'],
          emergencyContactPerson: data['emergencyContactPerson'],
          lastActive: data['lastActive'] != null 
              ? (data['lastActive'] as Timestamp).toDate() 
              : null,
        );
      }

      return null;
    } catch (e) {
      throw 'Failed to fetch user data: $e';
    }
  }

  // Get all fishermen with their boats (for admin dashboard)
  Stream<List<UserWithBoatModel>> getAllUsersWithBoats() {
    return _firestore.collectionGroup('fishermen').snapshots().asyncMap((snapshot) async {
      List<UserWithBoatModel> usersWithBoats = [];
      
      for (var doc in snapshot.docs) {
        try {
          final userData = doc.data();
          
          // Create user model
          final user = UserModel(
            id: userData['id'],
            firstName: userData['firstName'],
            middleName: userData['middleName'],
            lastName: userData['lastName'],
            name: "${userData['firstName']}${userData['middleName'] != null && userData['middleName'].toString().isNotEmpty ? ' ${userData['middleName']}' : ''} ${userData['lastName']}",
            email: userData['email'],
            phone: userData['phone'] ?? '',
            userType: 'fisherman',
            registrationDate: (userData['registrationDate'] as Timestamp).toDate(),
            isActive: userData['isActive'] ?? true,
            address: userData['address'],
            fishingArea: userData['fishingArea'],
            emergencyContactPerson: userData['emergencyContactPerson'],
            lastActive: userData['lastActive'] != null 
                ? (userData['lastActive'] as Timestamp).toDate() 
                : null,
          );
          
          // Get the boat for this fisherman
          BoatModel? boat;
          final boatQuery = await _firestore
              .collection('boats')
              .where('ownerUid', isEqualTo: user.id)
              .limit(1)
              .get();
          
          if (boatQuery.docs.isNotEmpty) {
            boat = BoatModel.fromJson(boatQuery.docs.first.data());
          }
          
          usersWithBoats.add(UserWithBoatModel(
            user: user,
            boat: boat,
          ));
        } catch (e) {
          print('Error parsing user data: $e');
          continue;
        }
      }
      
      // Sort by registration date (newest first)
      usersWithBoats.sort((a, b) => b.registrationDate.compareTo(a.registrationDate));
      return usersWithBoats;
    });
  }

  // Update fisherman last active (called when fisherman does any activity)
  Future<void> updateFishermanLastActive(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishermen')
          .doc(userId)
          .update({'lastActive': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Failed to update fisherman last active: $e');
    }
  }

  // Update boat last used (called when boat is tracked/used)
  Future<void> updateBoatLastUsed(String boatId) async {
    try {
      await _firestore
          .collection('boats')
          .doc(boatId)
          .update({'lastUsed': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Failed to update boat last used: $e');
    }
  }

  // Update fisherman status (for admin)
  Future<void> updateFishermanStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishermen')
          .doc(userId)
          .update({'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to update fisherman status: $e');
    }
  }

  // Update boat status (for admin)
  Future<void> updateBoatStatus(String boatId, bool isActive) async {
    try {
      await _firestore
          .collection('boats')
          .doc(boatId)
          .update({'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to update boat status: $e');
    }
  }

  // Delete fisherman (for admin)
  Future<void> deleteFisherman(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fishermen')
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete fisherman: $e');
    }
  }

  // Delete boat (for admin)
  Future<void> deleteBoat(String boatId) async {
    try {
      await _firestore
          .collection('boats')
          .doc(boatId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete boat: $e');
    }
  }

  // Get all fishermen (for admin use)
  Future<List<UserModel>> getAllFishermen() async {
    try {
      final snapshot = await _firestore.collectionGroup('fishermen').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: data['id'],
          firstName: data['firstName'],
          middleName: data['middleName'],
          lastName: data['lastName'],
          name: "${data['firstName']}${data['middleName'] != null && data['middleName'].toString().isNotEmpty ? ' ${data['middleName']}' : ''} ${data['lastName']}",
          email: data['email'],
          phone: data['phone'] ?? '',
          userType: 'fisherman',
          registrationDate: (data['registrationDate'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          address: data['address'],
          fishingArea: data['fishingArea'],
          emergencyContactPerson: data['emergencyContactPerson'],
          lastActive: data['lastActive'] != null 
              ? (data['lastActive'] as Timestamp).toDate() 
              : null,
        );
      }).toList();
    } catch (e) {
      throw 'Failed to fetch fishermen: $e';
    }
  }

  // Get all coastguards (for admin use)
  Future<List<UserModel>> getAllCoastguards() async {
    try {
      final snapshot = await _firestore.collectionGroup('coastguards').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: data['id'],
          firstName: data['firstName'],
          middleName: data['middleName'],
          lastName: data['lastName'],
          name: "${data['firstName']}${data['middleName'] != null && data['middleName'].toString().isNotEmpty ? ' ${data['middleName']}' : ''} ${data['lastName']}",
          email: data['email'],
          phone: '',
          userType: 'coastguard',
          registrationDate: (data['registrationDate'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          lastActive: data['lastActive'] != null 
              ? (data['lastActive'] as Timestamp).toDate() 
              : null,
        );
      }).toList();
    } catch (e) {
      throw 'Failed to fetch coastguards: $e';
    }
  }
}