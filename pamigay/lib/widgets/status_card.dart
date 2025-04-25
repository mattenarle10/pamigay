import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String status;
  final Color statusColor;
  final String statusIcon;
  final String description;
  final IconData? iconData;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;

  const StatusCard({
    Key? key,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.description,
    this.iconData,
    this.backgroundColor,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: iconData != null 
                ? Icon(iconData, color: statusColor, size: 24)
                : Text(
                    statusIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
