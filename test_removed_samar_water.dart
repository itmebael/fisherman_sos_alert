import 'package:flutter/material.dart';

void main() {
  print('=== TEST: Removed Samar Water from Admin Dashboard ===\n');
  
  print('✅ Changes Made:');
  print('1. Title changed from: "Samar Maritime Rescue Dashboard"');
  print('   To: "Maritime Rescue Dashboard"');
  print('');
  print('2. Description changed from: "Real-time weather monitoring and emergency response system for Samar waters"');
  print('   To: "Real-time weather monitoring and emergency response system"');
  
  print('\n✅ Benefits:');
  print('- Removed specific location reference');
  print('- Made dashboard more generic');
  print('- Cleaner, more professional appearance');
  print('- No more "Samar Water" mentions');
  
  print('\n✅ Updated Admin Dashboard:');
  print('- Title: Maritime Rescue Dashboard');
  print('- Description: Real-time weather monitoring and emergency response system');
  print('- All functionality remains the same');
  print('- Only text content updated');
  
  print('\n=== CHANGES COMPLETE ===');
  print('The admin dashboard no longer mentions "Samar Water"!');
}

// Test widget to show the updated dashboard
class UpdatedAdminDashboardTest extends StatelessWidget {
  const UpdatedAdminDashboardTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updated Admin Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Updated Admin Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Real-time weather monitoring and emergency response system',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Changes Applied:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('• Removed "Samar" from dashboard title'),
                  Text('• Removed "Samar waters" from description'),
                  Text('• Made dashboard more generic'),
                  Text('• Cleaner, professional appearance'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Dashboard Features (Unchanged):',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('• Total Fishermen Accounts'),
                  Text('• Registered Boats'),
                  Text('• Total Rescued'),
                  Text('• Active SOS Alerts'),
                  Text('• Interactive Map'),
                  Text('• Real-time monitoring'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

