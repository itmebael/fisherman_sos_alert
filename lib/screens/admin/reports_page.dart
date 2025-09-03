import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../admin/admin_drawer.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // BantayDagat logo
            ClipOval(
              child: Image.asset(
                'assets/img/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            // Coast Guard logo
            ClipOval(
              child: Image.asset(
                'assets/img/coastguard.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // App title
            Text(
              "BantayDagat",
              style: const TextStyle(
                color: Color(0xFF13294B),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.homeBackground,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AdminDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.homeBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mobile Rescue And Location Tracking System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Rescue Reports',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(Icons.print, color: AppColors.textPrimary),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.dividerColor),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.search, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Search',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Reports table
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                // Table headers
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.homeBackground.withOpacity(0.3),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 2, child: Center(child: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 3, child: Center(child: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 2, child: Center(child: Text('Distress Time', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 2, child: Center(child: Text('Rescue Time', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 2, child: Center(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      Expanded(flex: 2, child: Center(child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)))),
                                    ],
                                  ),
                                ),
                                
                                // Sample table rows with examples
                                Expanded(
                                  child: Column(
                                    children: [
                                      // First row - In Distress (needs rescue)
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: AppColors.dividerColor.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Profile picture
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.blue,
                                                    size: 28,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Full Name
                                            Expanded(flex: 3, child: Center(child: Text('Juan P. Cruz', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 15)))),
                                            // Distress Time
                                            Expanded(flex: 2, child: Center(child: Text('2:15 pm', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)))),
                                            // Rescue Time
                                            Expanded(flex: 2, child: Center(child: Text('-', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))),
                                            // Date
                                            Expanded(flex: 2, child: Center(child: Text('9/02/2025', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)))),
                                            // Action status
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(16),
                                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: const [
                                                          Icon(Icons.circle, color: Colors.red, size: 10),
                                                          SizedBox(width: 6),
                                                          Text('In Distress', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius: BorderRadius.circular(6),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.green.withOpacity(0.3),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Second row - Already Rescued
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: AppColors.dividerColor.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Profile picture
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.blue,
                                                    size: 28,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Full Name
                                            Expanded(flex: 3, child: Center(child: Text('Eman P. Pascual', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 15)))),
                                            // Distress Time
                                            Expanded(flex: 2, child: Center(child: Text('12:30 pm', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)))),
                                            // Rescue Time
                                            Expanded(flex: 2, child: Center(child: Text('1:00 pm', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)))),
                                            // Date
                                            Expanded(flex: 2, child: Center(child: Text('8/15/2025', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)))),
                                            // Action status
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: const [
                                                      Icon(Icons.circle, color: Colors.green, size: 10),
                                                      SizedBox(width: 6),
                                                      Text('Rescued', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Empty space for remaining area
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}