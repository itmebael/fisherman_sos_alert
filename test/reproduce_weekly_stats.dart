
void main() {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 6));
  
  print('Now: $now');
  print('Start (6 days ago): $start');
  print('Start Date Boundary: ${DateTime(start.year, start.month, start.day)}');
  print('End Date Boundary: ${DateTime(now.year, now.month, now.day, 23, 59, 59)}');
  
  // Sample data
  final alerts = [
    // 1. Valid inactive alert today
    {
      'status': 'inactive',
      'resolved_at': now.toIso8601String(),
      'created_at': now.subtract(Duration(hours: 1)).toIso8601String(),
      'desc': 'Today inactive'
    },
    // 2. Valid rescued alert yesterday
    {
      'status': 'rescued',
      'resolved_at': now.subtract(Duration(days: 1)).toIso8601String(),
      'created_at': now.subtract(Duration(days: 1, hours: 1)).toIso8601String(),
      'desc': 'Yesterday rescued'
    },
    // 3. Inactive alert 8 days ago (should be excluded)
    {
      'status': 'inactive',
      'resolved_at': now.subtract(Duration(days: 8)).toIso8601String(),
      'created_at': now.subtract(Duration(days: 8, hours: 1)).toIso8601String(),
      'desc': '8 days ago inactive'
    },
    // 4. Active alert today (should be excluded)
    {
      'status': 'active',
      'created_at': now.toIso8601String(),
      'desc': 'Today active'
    },
    // 5. Inactive alert 6 days ago (boundary case - should be included)
    {
      'status': 'inactive',
      'resolved_at': start.add(Duration(hours: 1)).toIso8601String(),
      'created_at': start.toIso8601String(),
      'desc': '6 days ago inactive'
    },
  ];

  final Map<String, int> counters = {
    'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0,
  };

  for (final alert in alerts) {
    final status = alert['status']?.toString().toLowerCase();
    if (status != 'inactive' && status != 'rescued') {
      print('Skipping status: $status (${alert['desc']})');
      continue;
    }
    
    final resolvedAtStr = alert['resolved_at']?.toString();
    final createdAtStr = alert['created_at']?.toString();
    DateTime? ts;
    if (resolvedAtStr != null && resolvedAtStr.isNotEmpty) {
      ts = DateTime.tryParse(resolvedAtStr);
    }
    ts ??= createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    
    if (ts == null) continue;
    
    // Logic from provider
    final isInRange = !ts.isBefore(DateTime(start.year, start.month, start.day)) &&
        !ts.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
        
    print('Alert: ${alert['desc']}, date: $ts, isInRange: $isInRange');
    
    if (!isInRange) continue;
    
    final weekday = ts.weekday;
    final dayLabel = switch (weekday) {
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
      7 => 'Sun',
      _ => 'Mon',
    };
    counters[dayLabel] = (counters[dayLabel] ?? 0) + 1;
  }
  
  print('Counters: $counters');
}
