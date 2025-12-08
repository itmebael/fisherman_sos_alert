import 'package:flutter_test/flutter_test.dart';
import 'package:fisherman_sos_alert/models/sos_alert_model.dart';

void main() {
  group('SOS Alert Model Tests', () {
    test('SOSAlertModel should serialize and deserialize correctly', () {
      // Arrange
      final now = DateTime.now();
      final sosAlert = SOSAlertModel(
        id: 'test_123',
        fishermanId: 'fisherman_456',
        latitude: 11.7753,
        longitude: 124.8861,
        message: 'Test emergency',
        status: 'active',
        createdAt: now,
        resolvedAt: null,
      );

      // Act
      final json = sosAlert.toJson();
      final fromJson = SOSAlertModel.fromJson(json);

      // Assert
      expect(fromJson.id, equals('test_123'));
      expect(fromJson.fishermanId, equals('fisherman_456'));
      expect(fromJson.latitude, equals(11.7753));
      expect(fromJson.longitude, equals(124.8861));
      expect(fromJson.message, equals('Test emergency'));
      expect(fromJson.status, equals('active'));
      expect(fromJson.createdAt, equals(now));
      expect(fromJson.resolvedAt, isNull);
    });

    test('SOSAlertModel should handle null values correctly', () {
      // Arrange
      final now = DateTime.now();
      final sosAlert = SOSAlertModel(
        id: 'test_123',
        fishermanId: 'fisherman_456',
        latitude: 11.7753,
        longitude: 124.8861,
        message: null,
        status: 'active',
        createdAt: now,
        resolvedAt: null,
      );

      // Act
      final json = sosAlert.toJson();
      final fromJson = SOSAlertModel.fromJson(json);

      // Assert
      expect(fromJson.message, isNull);
      expect(fromJson.resolvedAt, isNull);
    });

    test('SOSAlertModel copyWith should work correctly', () {
      // Arrange
      final now = DateTime.now();
      final sosAlert = SOSAlertModel(
        id: 'test_123',
        fishermanId: 'fisherman_456',
        latitude: 11.7753,
        longitude: 124.8861,
        message: 'Test emergency',
        status: 'active',
        createdAt: now,
        resolvedAt: null,
      );

      // Act
      final updatedAlert = sosAlert.copyWith(
        status: 'resolved',
        resolvedAt: now.add(const Duration(minutes: 5)),
      );

      // Assert
      expect(updatedAlert.id, equals('test_123'));
      expect(updatedAlert.status, equals('resolved'));
      expect(updatedAlert.resolvedAt, equals(now.add(const Duration(minutes: 5))));
      expect(updatedAlert.latitude, equals(11.7753)); // Should remain unchanged
    });

    test('SOS alert should be created with proper GPS coordinates', () {
      // Arrange
      final now = DateTime.now();
      const latitude = 11.7753;
      const longitude = 124.8861;
      const fishermanId = 'fisherman_123';

      // Act
      final sosAlert = SOSAlertModel(
        id: 'sos_${now.millisecondsSinceEpoch}',
        fishermanId: fishermanId,
        latitude: latitude,
        longitude: longitude,
        message: 'Emergency SOS Alert',
        status: 'active',
        createdAt: now,
      );

      // Assert
      expect(sosAlert.latitude, equals(latitude));
      expect(sosAlert.longitude, equals(longitude));
      expect(sosAlert.fishermanId, equals(fishermanId));
      expect(sosAlert.status, equals('active'));
      expect(sosAlert.message, equals('Emergency SOS Alert'));
    });

    test('SOS alert JSON should match database schema', () {
      // Arrange
      final now = DateTime.now();
      final sosAlert = SOSAlertModel(
        id: 'sos_1234567890',
        fishermanId: 'fisherman_123',
        latitude: 11.7753,
        longitude: 124.8861,
        message: 'Emergency SOS Alert',
        status: 'active',
        createdAt: now,
        resolvedAt: null,
      );

      // Act
      final json = sosAlert.toJson();

      // Assert
      expect(json['id'], equals('sos_1234567890'));
      expect(json['fisherman_id'], equals('fisherman_123'));
      expect(json['latitude'], equals(11.7753));
      expect(json['longitude'], equals(124.8861));
      expect(json['message'], equals('Emergency SOS Alert'));
      expect(json['status'], equals('active'));
      expect(json['created_at'], equals(now.toIso8601String()));
      expect(json['resolved_at'], isNull);
    });
  });

  group('GPS Location Tests', () {
    test('GPS coordinates should be valid for Philippines waters', () {
      // Test coordinates for Philippines waters
      const latitude = 11.7753;  // Within Philippines latitude range
      const longitude = 124.8861; // Within Philippines longitude range

      // Philippines is roughly between:
      // Latitude: 4.5°N to 21.1°N
      // Longitude: 116.9°E to 126.6°E
      expect(latitude, greaterThan(4.5));
      expect(latitude, lessThan(21.1));
      expect(longitude, greaterThan(116.9));
      expect(longitude, lessThan(126.6));
    });

    test('SOS alert should handle different GPS coordinate formats', () {
      // Test with different coordinate formats
      final now = DateTime.now();
      
      // Test with decimal degrees
      final sosAlert1 = SOSAlertModel(
        id: 'sos_1',
        fishermanId: 'fisherman_1',
        latitude: 11.7753,
        longitude: 124.8861,
        message: 'Emergency 1',
        status: 'active',
        createdAt: now,
      );

      // Test with more precise coordinates
      final sosAlert2 = SOSAlertModel(
        id: 'sos_2',
        fishermanId: 'fisherman_2',
        latitude: 11.7753456,
        longitude: 124.8861234,
        message: 'Emergency 2',
        status: 'active',
        createdAt: now,
      );

      // Assert both are valid
      expect(sosAlert1.latitude, isA<double>());
      expect(sosAlert1.longitude, isA<double>());
      expect(sosAlert2.latitude, isA<double>());
      expect(sosAlert2.longitude, isA<double>());
    });

    test('SOS alert should handle status transitions', () {
      final now = DateTime.now();
      final sosAlert = SOSAlertModel(
        id: 'sos_123',
        fishermanId: 'fisherman_123',
        latitude: 11.7753,
        longitude: 124.8861,
        message: 'Emergency',
        status: 'active',
        createdAt: now,
      );

      // Test status change to resolved
      final resolvedAlert = sosAlert.copyWith(
        status: 'resolved',
        resolvedAt: now.add(const Duration(minutes: 10)),
      );

      expect(resolvedAlert.status, equals('resolved'));
      expect(resolvedAlert.resolvedAt, isNotNull);
      expect(resolvedAlert.resolvedAt!.isAfter(now), isTrue);
    });
  });

  group('Database Schema Validation', () {
    test('SOS alert data should match expected database fields', () {
      final now = DateTime.now();
      final sosAlert = SOSAlertModel(
        id: 'sos_${now.millisecondsSinceEpoch}',
        fishermanId: 'fisherman_123',
        latitude: 11.7753,
        longitude: 124.8861,
        message: 'Emergency SOS Alert',
        status: 'active',
        createdAt: now,
        resolvedAt: null,
      );

      final json = sosAlert.toJson();

      // Verify all required fields are present
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('fisherman_id'), isTrue);
      expect(json.containsKey('latitude'), isTrue);
      expect(json.containsKey('longitude'), isTrue);
      expect(json.containsKey('message'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
      expect(json.containsKey('resolved_at'), isTrue);

      // Verify data types
      expect(json['id'], isA<String>());
      expect(json['fisherman_id'], isA<String>());
      expect(json['latitude'], isA<double>());
      expect(json['longitude'], isA<double>());
      expect(json['status'], isA<String>());
      expect(json['created_at'], isA<String>());
    });
  });
}
