import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/services/notification_service.dart';
import 'package:pamigay/screens/organization/available_donations_screen.dart';
import 'package:pamigay/screens/organization/my_pickups_screen.dart';
import 'package:pamigay/screens/restaurant/donations_screen.dart';
import 'package:pamigay/screens/restaurant/pickup_requests_screen.dart';
import 'package:pamigay/screens/common/dashboard_screen.dart';

/// Screen for displaying user notifications.
///
/// This screen is shared by both restaurant and organization users to view
/// their notifications such as pickup requests, accepted/rejected pickups,
/// and system messages.
class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const NotificationsScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];
  final _notificationService = NotificationService();
  bool _hasMore = false;
  int _offset = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (_hasMore && !_isLoading) {
          _loadMoreNotifications();
        }
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadNotifications({bool refresh = true}) async {
    if (widget.userData == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (refresh) {
        _offset = 0;
      }
      
      final userId = widget.userData!['id'].toString();
      final response = await _notificationService.getNotifications(
        userId,
        limit: _limit,
        offset: _offset
      );
      
      if (response['success'] == true) {
        final notifications = List<Map<String, dynamic>>.from(response['data']['notifications']);
        
        setState(() {
          if (refresh) {
            _notifications = notifications;
          } else {
            _notifications.addAll(notifications);
          }
          _hasMore = response['data']['has_more'] ?? false;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _loadMoreNotifications() async {
    _offset += _limit;
    await _loadNotifications(refresh: false);
  }
  
  Future<void> _markAsRead(String notificationId) async {
    print('Attempting to mark notification as read: $notificationId');
    
    try {
      final response = await _notificationService.markAsRead(notificationId);
      print('Mark as read response: $response');
      
      if (response['success'] == true) {
        print('Successfully marked notification $notificationId as read');
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'].toString() == notificationId);
          if (index != -1) {
            _notifications[index]['read'] = 1;
            print('Updated notification in UI: ${_notifications[index]}');
          } else {
            print('Could not find notification with ID $notificationId in the list');
          }
        });
      } else {
        print('Failed to mark notification as read: ${response['message']}');
        throw Exception(response['message']);
      }
    } catch (e) {
      print('Error in _markAsRead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notification as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _markAllAsRead() async {
    if (widget.userData == null) return;
    
    try {
      final userId = widget.userData!['id'].toString();
      final response = await _notificationService.markAllAsRead(userId);
      
      if (response['success'] == true) {
        setState(() {
          for (var notification in _notifications) {
            notification['read'] = 1;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking all notifications as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read when tapped
    if (notification['read'] != 1) {
      _markAsRead(notification['id'].toString());
      
      // Update the notification in the list to show as read
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notification['id']);
        if (index != -1) {
          _notifications[index]['read'] = 1;
        }
      });
    }
    
    // Handle navigation based on notification type
    final String type = notification['type'] ?? '';
    final String userRole = widget.userData?['role'] ?? '';
    
    // Navigate to the appropriate screen through the dashboard
    if (userRole == 'Organization') {
      // Organization user navigation
      if (type == 'donation_created') {
        // Navigate to available donations screen (index 1 in dashboard)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(initialIndex: 1),
          ),
          (route) => false,
        );
      } else if (type.contains('pickup')) {
        // Navigate to my pickups screen (index 2 in dashboard)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(initialIndex: 2),
          ),
          (route) => false,
        );
      }
    } else if (userRole == 'Restaurant') {
      // Restaurant user navigation
      if (type == 'donation_created') {
        // Navigate to donations screen (index 1 in dashboard)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(initialIndex: 1),
          ),
          (route) => false,
        );
      } else if (type.contains('pickup')) {
        // Navigate to pickup requests screen (index 3 in dashboard)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(initialIndex: 3),
          ),
          (route) => false,
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: PamigayColors.primary,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.grey),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.grey[700],
            ),
            onPressed: () => _loadNotifications(),
          ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadNotifications(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        return _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      
                      return _buildNotificationCard(_notifications[index]);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any notifications yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    // Parse creation time
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(notification['created_at']);
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    // Determine if notification is read
    final bool isRead = notification['read'] == 1;
    
    // Determine icon based on notification type
    IconData icon;
    Color iconColor;
    
    switch (notification['type']) {
      case 'donation_created':
        icon = Icons.fastfood;
        iconColor = Colors.green;
        break;
      case 'pickup_requested':
        icon = Icons.local_shipping_outlined;
        iconColor = Colors.blue;
        break;
      case 'pickup_accepted':
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case 'pickup_rejected':
        icon = Icons.cancel_outlined;
        iconColor = Colors.red;
        break;
      case 'pickup_completed':
        icon = Icons.done_all;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 2,
      color: isRead ? Colors.white : PamigayColors.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.grey[300]! : PamigayColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isRead ? 0.1 : 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isRead ? iconColor.withOpacity(0.8) : iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                              color: isRead ? Colors.black87 : Colors.black,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: PamigayColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: isRead ? Colors.grey[700] : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (notification['type'] == 'donation_created' || 
                            notification['type'].toString().contains('pickup'))
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: isRead ? Colors.grey[400] : PamigayColors.primary.withOpacity(0.7),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
