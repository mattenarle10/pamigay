import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';

/// A reusable widget for displaying status badges with consistent styling.
///
/// This component displays a status with an icon and background color,
/// and provides factory constructors for common status types.
class StatusBadge extends StatelessWidget {
  /// The status text to display
  final String status;
  
  /// The icon to display next to the status text
  final IconData icon;
  
  /// The background color of the badge
  final Color color;
  
  /// The text color (defaults to white)
  final Color textColor;
  
  /// The font size of the status text
  final double fontSize;
  
  /// Whether to show the icon
  final bool showIcon;

  const StatusBadge({
    Key? key,
    required this.status,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    this.fontSize = 12,
    this.showIcon = true,
  }) : super(key: key);

  /// Creates a StatusBadge with predefined styling based on common donation statuses
  factory StatusBadge.forDonationStatus(String status) {
    switch (status) {
      case 'Available':
        return StatusBadge(
          status: status,
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case 'Pending Pickup':
        return StatusBadge(
          status: status,
          icon: Icons.access_time_filled,
          color: Colors.amber,
        );
      case 'Completed':
        return StatusBadge(
          status: status,
          icon: Icons.check_circle,
          color: Colors.blue,
        );
      case 'Cancelled':
        return StatusBadge(
          status: status,
          icon: Icons.cancel,
          color: Colors.red,
        );
      default:
        return StatusBadge(
          status: status,
          icon: Icons.help_outline,
          color: Colors.grey,
        );
    }
  }

  /// Creates a StatusBadge with predefined styling based on common pickup statuses
  factory StatusBadge.forPickupStatus(String status) {
    switch (status) {
      case 'Requested':
        return StatusBadge(
          status: status,
          icon: Icons.pending,
          color: Colors.orange,
        );
      case 'Accepted':
        return StatusBadge(
          status: status,
          icon: Icons.check_circle_outline,
          color: Colors.blue,
        );
      case 'Completed':
        return StatusBadge(
          status: status,
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case 'Cancelled':
      case 'Rejected':
        return StatusBadge(
          status: status,
          icon: Icons.cancel,
          color: Colors.red,
        );
      default:
        return StatusBadge(
          status: status,
          icon: Icons.help_outline,
          color: Colors.grey,
        );
    }
  }

  /// Creates a StatusBadge with predefined styling based on pickup window status
  factory StatusBadge.forPickupWindowStatus(String status) {
    switch (status) {
      case 'active':
        return StatusBadge(
          status: 'Available now',
          icon: Icons.access_time,
          color: Colors.green,
        );
      case 'upcoming':
        return StatusBadge(
          status: 'Coming soon',
          icon: Icons.event_available,
          color: Colors.blue,
        );
      case 'expired':
        return StatusBadge(
          status: 'Window expired',
          icon: Icons.event_busy,
          color: Colors.red,
        );
      default:
        return StatusBadge(
          status: 'Unknown status',
          icon: Icons.help_outline,
          color: Colors.grey,
        );
    }
  }

  /// Creates a StatusBadge with the primary app color
  factory StatusBadge.primary(String status, {IconData? icon}) {
    return StatusBadge(
      status: status,
      icon: icon ?? Icons.info,
      color: PamigayColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
