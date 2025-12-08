// Simple debug script to test database connection
import 'dart:convert';
import 'dart:io';

// Generate a proper UUID v4
String _generateUUID() {
  // Generate a proper UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  final random = DateTime.now().millisecondsSinceEpoch;
  final random2 = DateTime.now().microsecondsSinceEpoch;
  
  // Create hex strings for each part
  final part1 = (random & 0xffffffff).toRadixString(16).padLeft(8, '0');
  final part2 = ((random >> 32) & 0xffff).toRadixString(16).padLeft(4, '0');
  final part3 = (4 << 12) | ((random2 & 0xfff)); // Version 4
  final part4 = (0x8 << 12) | ((random2 >> 4) & 0xfff); // Variant bits
  final part5 = ((random2 >> 16) & 0xffffffffffff).toRadixString(16).padLeft(12, '0');
  
  return '$part1-$part2-${part3.toRadixString(16).padLeft(4, '0')}-${part4.toRadixString(16).padLeft(4, '0')}-$part5';
}

void main() async {
  print('=== Simple Database Debug ===\n');

  // Test Supabase connection directly
  final supabaseUrl = 'https://khptgibwfuvsrcjgqgsf.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtocHRnaWJ3ZnV2c3JjamdxZ3NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyMzU3OTIsImV4cCI6MjA3MzgxMTc5Mn0.iZYGU2SkUyDsZfbvYqdsBjZbz_wY7HcZGi0GX64gPEc';

  print('1. Testing Supabase connection...');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/sos_alerts?select=id&limit=1'));
    request.headers.set('apikey', supabaseKey);
    request.headers.set('Authorization', 'Bearer $supabaseKey');
    request.headers.set('Content-Type', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('   Status Code: ${response.statusCode}');
    print('   Response: $responseBody');
    
    if (response.statusCode == 200) {
      print('   ✓ Database connection successful\n');
      
      // Test creating a fisherman
      print('2. Testing fisherman creation...');
      final fishermanId = _generateUUID();
      final fishermanData = {
        'id': fishermanId,
        'email': 'test@example.com',
        'first_name': 'Test',
        'last_name': 'Fisherman',
        'name': 'Test Fisherman',
        'phone': '1234567890',
        'user_type': 'fisherman',
        'is_active': true,
        'registration_date': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      };
      
      final fishermanRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/fishermen'));
      fishermanRequest.headers.set('apikey', supabaseKey);
      fishermanRequest.headers.set('Authorization', 'Bearer $supabaseKey');
      fishermanRequest.headers.set('Content-Type', 'application/json');
      fishermanRequest.headers.set('Prefer', 'return=minimal');
      
      fishermanRequest.write(jsonEncode(fishermanData));
      final fishermanResponse = await fishermanRequest.close();
      
      print('   Fisherman creation status: ${fishermanResponse.statusCode}');
      
      if (fishermanResponse.statusCode == 201) {
        print('   ✓ Fisherman created successfully\n');
        
        // Test creating SOS alert
        print('3. Testing SOS alert creation...');
        final sosData = {
          'id': 'sos-${DateTime.now().millisecondsSinceEpoch}',
          'fisherman_id': fishermanId,
          'latitude': 11.7753,
          'longitude': 124.8861,
          'message': 'Test SOS Alert',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'resolved_at': null,
        };
        
        final sosRequest = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/sos_alerts'));
        sosRequest.headers.set('apikey', supabaseKey);
        sosRequest.headers.set('Authorization', 'Bearer $supabaseKey');
        sosRequest.headers.set('Content-Type', 'application/json');
        sosRequest.headers.set('Prefer', 'return=minimal');
        
        sosRequest.write(jsonEncode(sosData));
        final sosResponse = await sosRequest.close();
        
        print('   SOS alert creation status: ${sosResponse.statusCode}');
        
        if (sosResponse.statusCode == 201) {
          print('   ✓ SOS alert created successfully\n');
        } else {
          final errorBody = await sosResponse.transform(utf8.decoder).join();
          print('   ✗ SOS alert creation failed: $errorBody\n');
        }
        
        // Test retrieving SOS alerts
        print('4. Testing SOS alert retrieval...');
        final getRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/sos_alerts?select=*&limit=5'));
        getRequest.headers.set('apikey', supabaseKey);
        getRequest.headers.set('Authorization', 'Bearer $supabaseKey');
        getRequest.headers.set('Content-Type', 'application/json');
        
        final getResponse = await getRequest.close();
        final getBody = await getResponse.transform(utf8.decoder).join();
        
        print('   Get status: ${getResponse.statusCode}');
        print('   Response: $getBody\n');
        
      } else {
        final errorBody = await fishermanResponse.transform(utf8.decoder).join();
        print('   ✗ Fisherman creation failed: $errorBody\n');
      }
      
    } else {
      print('   ✗ Database connection failed\n');
    }
    
    client.close();
    
  } catch (e) {
    print('   ✗ Error: $e\n');
  }

  print('=== Debug Complete ===');
}
