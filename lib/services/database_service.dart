import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/boat_model.dart';

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
        );
      }

      return null;
    } catch (e) {
      throw 'Failed to fetch user data: $e';
    }
  }

  // Get all fishermen (for admin use)
  Future<List<UserModel>> getAllFishermen() async {
    try {
      // This will only fetch all fishermen for the given userId (not global). Adjust as needed.
      // For global, you need to aggregate all users' subcollections, which is not directly supported by Firestore.
      throw UnimplementedError('Fetching all fishermen globally in subcollections is not directly supported. Consider using a Cloud Function or changing your data model.');
    } catch (e) {
      throw 'Failed to fetch fishermen: $e';
    }
  }

  // Get all coastguards (for admin use)
  Future<List<UserModel>> getAllCoastguards() async {
    try {
      // This will only fetch all coastguards for the given userId (not global). Adjust as needed.
      throw UnimplementedError('Fetching all coastguards globally in subcollections is not directly supported. Consider using a Cloud Function or changing your data model.');
    } catch (e) {
      throw 'Failed to fetch coastguards: $e';
    }
  }
}