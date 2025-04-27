import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final String getNotificationsEndpoint = dotenv.env['API_GET_NOTIFICATIONS'] ?? '/get_notifications.php';
  final String markNotificationReadEndpoint = dotenv.env['API_MARK_NOTIFICATION_READ'] ?? '/mark_notification_read.php';
  final String markAllNotificationsReadEndpoint = dotenv.env['API_MARK_ALL_NOTIFICATIONS_READ'] ?? '/mark_all_notifications_read.php';
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  /// Get notifications for a user
  /// 
  /// Returns a map with success status and data containing notifications and unread count
  Future<Map<String, dynamic>> getNotifications(String userId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$getNotificationsEndpoint?user_id=$userId&limit=$limit&offset=$offset'),
      );
      
      print('Get notifications status code: ${response.statusCode}');
      print('Get notifications response: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get notifications. Server returned ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('Error getting notifications: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  /// Mark a notification as read
  /// 
  /// Returns a map with success status
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      print('Marking notification as read: $notificationId');
      
      // Ensure notification ID is valid
      if (notificationId == null || notificationId.isEmpty) {
        print('Invalid notification ID: $notificationId');
        return {
          'success': false,
          'message': 'Invalid notification ID',
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl$markNotificationReadEndpoint'),
        body: {'notification_id': notificationId},
      );
      
      print('Mark notification read status code: ${response.statusCode}');
      print('Mark notification read response: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Notification marked as read successfully: $responseData');
        return responseData;
      } else {
        print('Failed to mark notification as read. Server returned ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to mark notification as read. Server returned ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  /// Mark all notifications as read for a user
  /// 
  /// Returns a map with success status
  Future<Map<String, dynamic>> markAllAsRead(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$markAllNotificationsReadEndpoint'),
        body: {'user_id': userId},
      );
      
      print('Mark all notifications read status code: ${response.statusCode}');
      print('Mark all notifications read response: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to mark all notifications as read. Server returned ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  /// Get unread notification count for a user
  /// 
  /// Returns the number of unread notifications
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await getNotifications(userId, limit: 1);
      
      if (response['success'] == true) {
        return response['data']['unread_count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}
