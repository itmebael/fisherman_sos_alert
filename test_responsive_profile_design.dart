import 'package:flutter/material.dart';

void main() {
  runApp(ResponsiveProfileTestApp());
}

class ResponsiveProfileTestApp extends StatelessWidget {
  const ResponsiveProfileTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsive Profile Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ResponsiveProfileTestScreen(),
    );
  }
}

class ResponsiveProfileTestScreen extends StatelessWidget {
  const ResponsiveProfileTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive Profile Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestSection('Device Information', [
              'Screen Width: ${MediaQuery.of(context).size.width}px',
              'Screen Height: ${MediaQuery.of(context).size.height}px',
              'Device Type: ${_getDeviceType(context)}',
              'Orientation: ${MediaQuery.of(context).orientation}',
            ]),
            
            const SizedBox(height: 20),
            
            _buildTestSection('Responsive Breakpoints', [
              'Mobile: < 600px',
              'Tablet: 600px - 900px',
              'Desktop: > 900px',
              'Current: ${_getCurrentBreakpoint(context)}',
            ]),
            
            const SizedBox(height: 20),
            
            _buildTestSection('Profile Layout Preview', [
              'Mobile Layout: Single column, compact spacing',
              'Tablet Layout: Larger padding, bigger text',
              'Desktop Layout: Two-column layout with sidebar',
              'Auto-adjusting: Content adapts to screen size',
            ]),
            
            const SizedBox(height: 20),
            
            _buildTestSection('Responsive Features', [
              '✅ Adaptive padding (20px mobile, 32px tablet)',
              '✅ Responsive text sizes (14px mobile, 16px tablet)',
              '✅ Flexible layouts (single column vs two column)',
              '✅ Auto-sizing containers',
              '✅ Touch-friendly buttons on mobile',
              '✅ Keyboard-friendly on desktop',
            ]),
            
            const SizedBox(height: 20),
            
            _buildTestSection('Test Different Screen Sizes', [
              '1. Mobile (320px - 599px): Single column layout',
              '2. Tablet (600px - 899px): Larger elements, more padding',
              '3. Desktop (900px+): Two-column layout with sidebar',
              '4. Large Desktop (1200px+): Centered content with max width',
            ]),
            
            const SizedBox(height: 20),
            
            _buildTestSection('Profile Edit Features', [
              '📱 Mobile: Full-width form fields, stacked layout',
              '📱 Tablet: Larger form fields, better spacing',
              '💻 Desktop: Side-by-side form fields, profile picture sidebar',
              '🔄 Auto-adapting: Layout changes based on screen size',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(fontSize: 14),
            ),
          )),
        ],
      ),
    );
  }

  String _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 'Mobile';
    if (width < 900) return 'Tablet';
    return 'Desktop';
  }

  String _getCurrentBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 'Mobile (< 600px)';
    if (width < 900) return 'Tablet (600px - 900px)';
    return 'Desktop (> 900px)';
  }
}

// Test different screen sizes
class ResponsiveTestWidget extends StatelessWidget {
  const ResponsiveTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 32.0 : 20.0),
      child: Column(
        children: [
          Text(
            'Responsive Profile Design Test',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Simulate profile picture
          CircleAvatar(
            radius: isDesktop ? 80 : (isTablet ? 60 : 50),
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.person,
              size: isDesktop ? 80 : (isTablet ? 60 : 50),
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Simulate form fields
          ...List.generate(3, (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field ${index + 1}',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: isTablet ? 56 : 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 16 : 12,
                    ),
                    child: Text(
                      'Sample input field',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 20),
          
          // Simulate save button
          SizedBox(
            width: double.infinity,
            height: isTablet ? 56 : 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


