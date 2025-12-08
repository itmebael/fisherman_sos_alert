// Test script to fix database issues and verify SOS alert storage
import 'dart:convert';
import 'dart:io';

// Generate a proper UUID v4
String _generateUUID() {
  final random = DateTime.now().millisecondsSinceEpoch;
  final random2 = DateTime.now().microsecondsSinceEpoch;
  
  final part1 = (random & 0xffffffff).toRadixString(16).padLeft(8, '0');
  final part2 = ((random >> 32) & 0xffff).toRadixString(16).padLeft(4, '0');
  final part3 = (4 << 12) | ((random2 & 0xfff));
  final part4 = (0x8 << 12) | ((random2 >> 4) & 0xfff);
  final part5 = ((random2 >> 16) & 0xffffffffffff).toRadixString(16).padLeft(12, '0');
  
  return '$part1-$part2-${part3.toRadixString(16).padLeft(4, '0')}-${part4.toRadixString(16).padLeft(4, '0')}-$part5';
}

void main() async {
  print('=== Database Fix and Test ===\n');

  final supabaseUrl = 'https://khptgibwfuvsrcjgqgsf.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtocHRnaWJ3ZnV2c3JjamdxZ3NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyMzU3OTIsImV4cCI6MjA3MzgxMTc5Mn0.iZYGU2SkUyDsZfbvYqdsBjZbz_wY7HcZGi0GX64gPEc';

  final client = HttpClient();

  try {
    // Step 1: Check current RLS status
    print('1. Checking RLS status...');
    final rlsRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/sos_alerts?select=*&limit=1'));
    rlsRequest.headers.set('apikey', supabaseKey);
    rlsRequest.headers.set('Authorization', 'Bearer $supabaseKey');
    rlsRequest.headers.set('Content-Type', 'application/json');
    
    final rlsResponse = await rlsRequest.close();
    print('   RLS test status: ${rlsResponse.statusCode}');
    
    // Step 2: Create a fisherman first
    print('\n2. Creating fisherman...');
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
      print('   ✓ Fisherman created: $fishermanId\n');
      
      // Step 3: Try different approaches to create SOS alert
      print('3. Testing SOS alert creation with different approaches...');
      
      // Approach 1: Try with service role key (if available)
      print('   Approach 1: Using anon key...');
      final sosData1 = {
        'id': 'sos-${DateTime.now().millisecondsSinceEpoch}',
        'fisherman_id': fishermanId,
        'latitude': 11.7753,
        'longitude': 124.8861,
        'message': 'Test SOS Alert - Approach 1',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'resolved_at': null,
      };
      
      final sosRequest1 = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/sos_alerts'));
      sosRequest1.headers.set('apikey', supabaseKey);
      sosRequest1.headers.set('Authorization', 'Bearer $supabaseKey');
      sosRequest1.headers.set('Content-Type', 'application/json');
      sosRequest1.headers.set('Prefer', 'return=minimal');
      
      sosRequest1.write(jsonEncode(sosData1));
      final sosResponse1 = await sosRequest1.close();
      
      print('   Status: ${sosResponse1.statusCode}');
      if (sosResponse1.statusCode != 201) {
        final errorBody1 = await sosResponse1.transform(utf8.decoder).join();
        print('   Error: $errorBody1');
      } else {
        print('   ✓ SOS alert created successfully!');
      }
      
      // Step 4: Try with different headers
      print('\n   Approach 2: With additional headers...');
      final sosData2 = {
        'id': 'sos-${DateTime.now().millisecondsSinceEpoch + 1}',
        'fisherman_id': fishermanId,
        'latitude': 11.7754,
        'longitude': 124.8862,
        'message': 'Test SOS Alert - Approach 2',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'resolved_at': null,
      };
      
      final sosRequest2 = await client.postUrl(Uri.parse('$supabaseUrl/rest/v1/sos_alerts'));
      sosRequest2.headers.set('apikey', supabaseKey);
      sosRequest2.headers.set('Authorization', 'Bearer $supabaseKey');
      sosRequest2.headers.set('Content-Type', 'application/json');
      sosRequest2.headers.set('Prefer', 'return=minimal');
      sosRequest2.headers.set('X-Client-Info', 'supabase-flutter');
      
      sosRequest2.write(jsonEncode(sosData2));
      final sosResponse2 = await sosRequest2.close();
      
      print('   Status: ${sosResponse2.statusCode}');
      if (sosResponse2.statusCode != 201) {
        final errorBody2 = await sosResponse2.transform(utf8.decoder).join();
        print('   Error: $errorBody2');
      } else {
        print('   ✓ SOS alert created successfully!');
      }
      
      // Step 5: Check if data was actually inserted
      print('\n4. Verifying data insertion...');
      final verifyRequest = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/sos_alerts?select=*&fisherman_id=eq.$fishermanId'));
      verifyRequest.headers.set('apikey', supabaseKey);
      verifyRequest.headers.set('Authorization', 'Bearer $supabaseKey');
      verifyRequest.headers.set('Content-Type', 'application/json');
      
      final verifyResponse = await verifyRequest.close();
      final verifyBody = await verifyResponse.transform(utf8.decoder).join();
      
      print('   Verification status: ${verifyResponse.statusCode}');
      print('   Data found: $verifyBody');
      
      if (verifyResponse.statusCode == 200) {
        final data = jsonDecode(verifyBody);
        if (data is List && data.isNotEmpty) {
          print('   ✓ SOS alerts found in database!');
          for (var alert in data) {
            print('   - ID: ${alert['id']}');
            print('   - Location: ${alert['latitude']}, ${alert['longitude']}');
            print('   - Status: ${alert['status']}');
            print('   - Created: ${alert['created_at']}');
          }
        } else {
          print('   ✗ No SOS alerts found in database');
        }
      }
      
    } else {
      final errorBody = await fishermanResponse.transform(utf8.decoder).join();
      print('   ✗ Fisherman creation failed: $errorBody');
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }

  print('\n=== Test Complete ===');
  print('\nIf SOS alerts are still not being created, you need to:');
  print('1. Go to your Supabase dashboard');
  print('2. Navigate to Authentication > Policies');
  print('3. Find the sos_alerts table');
  print('4. Create a policy that allows INSERT for authenticated users');
  print('5. Or temporarily disable RLS with: ALTER TABLE public.sos_alerts DISABLE ROW LEVEL SECURITY;');
}

































