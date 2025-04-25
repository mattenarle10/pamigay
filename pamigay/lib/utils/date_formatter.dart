import 'package:intl/intl.dart';

/// Utility class for formatting dates and times consistently throughout the app.
class DateFormatter {
  /// Formats a date string into a readable date time format: 'MMM d, yyyy • h:mm a'
  /// 
  /// Returns 'N/A' if the input is null or empty.
  static String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }
  
  /// Formats a date string into a readable date only format: 'MMM d, yyyy'
  /// 
  /// Returns 'N/A' if the input is null or empty.
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  
  /// Formats a date string into a readable time only format: 'h:mm a'
  /// 
  /// Returns 'N/A' if the input is null or empty.
  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    
    try {
      final time = DateTime.parse(timeStr);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      return timeStr;
    }
  }
  
  /// Formats a date string into a more detailed format: 'MMMM d, yyyy • h:mm a'
  /// 
  /// Returns 'N/A' if the input is null or empty.
  static String formatDetailedDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMMM d, yyyy • h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }
  
  /// Formats two date time strings to show a window period, handling same-day cases
  /// 
  /// If both dates are on the same day, returns: 'MMM d, yyyy from h:mm a to h:mm a'
  /// Otherwise returns: 'From MMM d, yyyy • h:mm a to MMM d, yyyy • h:mm a'
  static String formatDateTimeWindow(String? startStr, String? endStr) {
    if (startStr == null || startStr.isEmpty || endStr == null || endStr.isEmpty) {
      return 'Not specified';
    }
    
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      
      // Check if same day
      final isSameDay = start.year == end.year && 
                      start.month == end.month && 
                      start.day == end.day;
      
      if (isSameDay) {
        final dateFormat = DateFormat('MMM d, yyyy');
        final timeStartFormat = DateFormat('h:mm a');
        final timeEndFormat = DateFormat('h:mm a');
        
        return '${dateFormat.format(start)} from ${timeStartFormat.format(start)} to ${timeEndFormat.format(end)}';
      } else {
        final startFormat = DateFormat('MMM d, yyyy • h:mm a').format(start);
        final endFormat = DateFormat('MMM d, yyyy • h:mm a').format(end);
        return 'From $startFormat to $endFormat';
      }
    } catch (e) {
      return 'Not specified';
    }
  }
  
  /// Attempts to parse a date time string and return a DateTime object
  /// 
  /// Returns null if parsing fails.
  static DateTime? tryParse(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    
    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }
}
