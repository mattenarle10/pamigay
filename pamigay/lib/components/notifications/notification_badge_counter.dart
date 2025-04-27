import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import 'notification_badge.dart';

/// A widget that displays a notification badge with the count of unread notifications
/// 
/// This widget automatically fetches the unread notification count for the current user
/// and displays it using the NotificationBadge component.
class NotificationBadgeCounter extends StatefulWidget {
  /// The callback when the badge is tapped
  final VoidCallback onTap;
  
  /// The icon to display (defaults to notifications icon)
  final IconData icon;
  
  /// The color of the icon
  final Color iconColor;
  
  /// The size of the icon
  final double iconSize;
  
  /// The color of the badge
  final Color badgeColor;
  
  /// The text color of the badge count
  final Color badgeTextColor;
  
  /// Whether to show the badge when count is zero
  final bool showZeroBadge;
  
  /// Maximum count to display before showing '+'
  final int maxDisplayCount;
  
  /// Optional child widget (for backward compatibility)
  final Widget? child;
  
  /// How often to refresh the unread count (defaults to 30 seconds)
  final Duration refreshInterval;

  const NotificationBadgeCounter({
    Key? key,
    required this.onTap,
    this.icon = Icons.notifications_outlined,
    this.iconColor = Colors.black,
    this.iconSize = 28,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
    this.showZeroBadge = false,
    this.maxDisplayCount = 9,
    this.child,
    this.refreshInterval = const Duration(seconds: 30),
  }) : super(key: key);

  @override
  State<NotificationBadgeCounter> createState() => _NotificationBadgeCounterState();
}

class _NotificationBadgeCounterState extends State<NotificationBadgeCounter> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    
    // Set up periodic refresh
    Future.delayed(Duration.zero, () {
      _setupPeriodicRefresh();
    });
  }

  void _setupPeriodicRefresh() {
    Future.doWhile(() async {
      await Future.delayed(widget.refreshInterval);
      if (mounted) {
        _fetchUnreadCount();
        return true; // Continue the loop
      }
      return false; // Stop the loop if widget is disposed
    });
  }

  Future<void> _fetchUnreadCount() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user ID
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      _userId = user?.id?.toString();
      
      if (_userId != null) {
        final count = await _notificationService.getUnreadCount(_userId!);
        
        if (mounted) {
          setState(() {
            _unreadCount = count;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _unreadCount = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching unread count: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      count: _unreadCount,
      onTap: () {
        widget.onTap();
        // Refresh count after tap (in case user navigates to notifications screen)
        Future.delayed(const Duration(milliseconds: 500), () {
          _fetchUnreadCount();
        });
      },
      icon: widget.icon,
      iconColor: widget.iconColor,
      iconSize: widget.iconSize,
      badgeColor: widget.badgeColor,
      badgeTextColor: widget.badgeTextColor,
      showZeroBadge: widget.showZeroBadge,
      maxDisplayCount: widget.maxDisplayCount,
      child: widget.child,
    );
  }
}
