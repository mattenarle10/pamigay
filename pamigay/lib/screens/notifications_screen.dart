import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:intl/intl.dart';

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
  String _userRole = '';
  
  @override
  void initState() {
    super.initState();
    _userRole = widget.userData?['role'] ?? '';
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real implementation, we would fetch notifications from an API
      // For now, we'll use placeholder data based on user role
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      if (_userRole == 'Restaurant') {
        _notifications = [
          {
            'id': '1',
            'type': 'pickup_request',
            'title': 'New Pickup Request',
            'message': 'Food Bank Organization has requested to pick up "Fresh Vegetables Bundle"',
            'read': false,
            'created_at': DateTime.now().subtract(const Duration(hours: 2)).toString(),
            'data': {
              'pickup_id': '101',
              'donation_id': '201',
            }
          },
          {
            'id': '2',
            'type': 'pickup_request',
            'title': 'New Pickup Request',
            'message': 'Community Shelter has requested to pick up "Bread and Pastries"',
            'read': false,
            'created_at': DateTime.now().subtract(const Duration(hours: 5)).toString(),
            'data': {
              'pickup_id': '102',
              'donation_id': '202',
            }
          },
          {
            'id': '3',
            'type': 'system',
            'title': 'Donation Expiring Soon',
            'message': 'Your donation "Rice and Grains" will expire in 24 hours',
            'read': true,
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toString(),
            'data': {
              'donation_id': '203',
            }
          },
        ];
      } else {
        // Organization notifications
        _notifications = [
          {
            'id': '1',
            'type': 'pickup_accepted',
            'title': 'Pickup Request Accepted',
            'message': 'Restaurant ABC has accepted your pickup request for "Canned Goods"',
            'read': false,
            'created_at': DateTime.now().subtract(const Duration(hours: 3)).toString(),
            'data': {
              'pickup_id': '301',
              'donation_id': '401',
            }
          },
          {
            'id': '2',
            'type': 'pickup_rejected',
            'title': 'Pickup Request Rejected',
            'message': 'Restaurant XYZ has rejected your pickup request for "Dairy Products"',
            'read': true,
            'created_at': DateTime.now().subtract(const Duration(days: 2)).toString(),
            'data': {
              'pickup_id': '302',
              'donation_id': '402',
            }
          },
          {
            'id': '3',
            'type': 'system',
            'title': 'New Donations Available',
            'message': '5 new donations are available in your area',
            'read': true,
            'created_at': DateTime.now().subtract(const Duration(days: 3)).toString(),
            'data': {}
          },
        ];
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _markAsRead(String notificationId) async {
    try {
      // In a real implementation, we would call an API to mark the notification as read
      // For now, we'll just update the local state
      
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    // Mark as read
    await _markAsRead(notification['id']);
    
    // Handle navigation based on notification type
    if (!mounted) return;
    
    // In a real implementation, we would navigate to the appropriate screen
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to: ${notification['title']}'),
        backgroundColor: PamigayColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: PamigayColors.primary,
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification['read'] = true;
                  }
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: PamigayColors.primary,
                  ),
                );
              },
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationCard(notification);
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
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any notifications at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(
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
    
    // Determine icon based on notification type
    IconData icon;
    Color iconColor;
    
    switch (notification['type']) {
      case 'pickup_request':
        icon = Icons.shopping_basket;
        iconColor = Colors.orange;
        break;
      case 'pickup_accepted':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'pickup_rejected':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'system':
        icon = Icons.info;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification['read'] ? Colors.transparent : PamigayColors.primary.withOpacity(0.5),
          width: notification['read'] ? 0 : 1,
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
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
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
                              fontWeight: notification['read'] ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification['read'])
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
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
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
