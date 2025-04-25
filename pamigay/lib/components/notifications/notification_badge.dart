import 'package:flutter/material.dart';

/// A reusable notification badge component that can be used with any icon.
///
/// This component displays a badge with a count on top of any icon,
/// making it useful for notifications, cart items, etc.
class NotificationBadge extends StatelessWidget {
  /// The count to display in the badge
  final int count;
  
  /// Callback when the badge is tapped
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

  const NotificationBadge({
    Key? key,
    required this.count,
    required this.onTap,
    this.icon = Icons.notifications_outlined,
    this.iconColor = Colors.black,
    this.iconSize = 28,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
    this.showZeroBadge = false,
    this.maxDisplayCount = 9,
    this.child,
  }) : super(key: key);

  /// Creates a notification badge with the bell icon
  factory NotificationBadge.bell({
    required int count,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
    double iconSize = 28,
  }) {
    return NotificationBadge(
      count: count,
      onTap: onTap,
      icon: Icons.notifications_outlined,
      iconColor: iconColor,
      iconSize: iconSize,
    );
  }

 
  factory NotificationBadge.cart({
    required int count,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
    double iconSize = 28,
  }) {
    return NotificationBadge(
      count: count,
      onTap: onTap,
      icon: Icons.shopping_cart_outlined,
      iconColor: iconColor,
      iconSize: iconSize,
    );
  }

  /// Creates a notification badge with the message icon
  factory NotificationBadge.message({
    required int count,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
    double iconSize = 28,
  }) {
    return NotificationBadge(
      count: count,
      onTap: onTap,
      icon: Icons.mail_outline,
      iconColor: iconColor,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(iconSize / 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          child ?? Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
          if ((count > 0 || showZeroBadge))
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count > maxDisplayCount ? '$maxDisplayCount+' : count.toString(),
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
