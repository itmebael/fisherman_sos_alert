import 'package:intl/intl.dart';

class DateFormatter {
  // Format date as MM/dd/yyyy (like in your UI)
  static String formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  // Format date as dd/MM/yyyy
  static String formatDateDMY(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format date with day name (e.g., "Monday, Jan 15, 2024")
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }

  // Format date and time
  static String formatDateTime(DateTime date) {
    return DateFormat('MM/dd/yyyy HH:mm').format(date);
  }

  // Format time only
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Format time with AM/PM
  static String formatTime12Hour(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  // Format relative time (e.g., "2 hours ago", "3 days ago")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Format date for display in lists (e.g., "Jan 15")
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  // Format month and year (e.g., "January 2024")
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  // Get age from date of birth
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  // Parse date from string (MM/dd/yyyy format)
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('MM/dd/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Parse date from string (flexible format)
  static DateTime? parseDateFlexible(String dateString) {
    // Try different formats
    final formats = [
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'MMM dd, yyyy',
      'MMMM dd, yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateString);
      } catch (e) {
        // Continue to next format
      }
    }
    
    return null;
  }

  // Format duration (e.g., "2h 30m", "1d 5h")
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      if (hours > 0) {
        return '${days}d ${hours}h';
      }
      return '${days}d';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Get formatted date based on how recent it is
  static String formatSmartDate(DateTime date) {
    if (isToday(date)) {
      return 'Today ${formatTime12Hour(date)}';
    } else if (isYesterday(date)) {
      return 'Yesterday ${formatTime12Hour(date)}';
    } else if (DateTime.now().difference(date).inDays < 7) {
      return '${DateFormat('EEEE').format(date)} ${formatTime12Hour(date)}';
    } else if (DateTime.now().year == date.year) {
      return DateFormat('MMM dd').format(date);
    } else {
      return formatDate(date);
    }
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToSunday)));
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = date.month == 12 
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(microseconds: 1));
  }
}