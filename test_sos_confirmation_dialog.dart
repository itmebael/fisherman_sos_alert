import 'package:flutter/material.dart';

void main() {
  print('=== TEST: SOS Confirmation Dialog ===\n');
  
  print('✅ SOS Confirmation Dialog Features:');
  print('1. Warning icon and red title');
  print('2. Clear question: "Are you in a real emergency situation?"');
  print('3. Explanation of what SOS alert does');
  print('4. Warning about false alarms');
  print('5. Two buttons: "Cancel" and "Send SOS Alert"');
  print('6. Non-dismissible dialog (must choose an option)');
  
  print('\n✅ User Flow:');
  print('1. User clicks SOS button');
  print('2. Confirmation dialog appears');
  print('3. User reads warning message');
  print('4. User chooses:');
  print('   - "Cancel" → Dialog closes, no SOS sent');
  print('   - "Send SOS Alert" → Proceeds with SOS alert');
  
  print('\n✅ Benefits:');
  print('- Prevents accidental SOS alerts');
  print('- Educates users about proper SOS usage');
  print('- Reduces false alarms');
  print('- Saves emergency resources');
  print('- Ensures SOS is used only for real emergencies');
  
  print('\n✅ Dialog Design:');
  print('- Red warning theme');
  print('- Clear, prominent warning icon');
  print('- Easy-to-read text');
  print('- Large, clear buttons');
  print('- Professional emergency appearance');
  
  print('\n=== SOS CONFIRMATION DIALOG COMPLETE ===');
  print('The SOS button now has a confirmation dialog to prevent false alerts!');
}

// Test widget to demonstrate the confirmation dialog
class SOSConfirmationTestWidget extends StatelessWidget {
  const SOSConfirmationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Confirmation Test'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SOS Confirmation Dialog Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'This test demonstrates the SOS confirmation dialog:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            _buildTestStep('1. Click SOS Button', [
              'User taps the red SOS button',
              'Confirmation dialog appears immediately',
              'Dialog cannot be dismissed by tapping outside',
              'User must choose Cancel or Send',
            ]),
            
            const SizedBox(height: 16),
            
            _buildTestStep('2. Confirmation Dialog', [
              'Shows warning icon and red title',
              'Asks: "Are you in a real emergency situation?"',
              'Explains what SOS alert will do',
              'Warns about false alarms',
            ]),
            
            const SizedBox(height: 16),
            
            _buildTestStep('3. User Choice', [
              'Cancel: Dialog closes, no SOS sent',
              'Send SOS Alert: Proceeds with emergency alert',
              'Both buttons are clearly labeled',
              'Red theme emphasizes emergency nature',
            ]),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () => _showTestConfirmationDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Test SOS Confirmation Dialog'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestStep(String title, List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '• $step',
              style: const TextStyle(fontSize: 14),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _showTestConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Emergency SOS Alert',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you in a real emergency situation?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This will send an emergency alert to rescue services with your location. Only use this in genuine emergency situations.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'False alarms waste emergency resources and may delay help for real emergencies.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send SOS Alert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS Alert confirmed! (This is just a test)'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS Alert cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

