import 'package:flutter/material.dart';

/// Custom widget for role selection icons
class RoleIconWidget extends StatelessWidget {
  final String roleName;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleIconWidget({
    Key? key,
    required this.roleName,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;
    String displayName;

    // Set appropriate icon and name based on role
    switch (roleName.toLowerCase()) {
      case 'restaurant':
        iconData = Icons.restaurant;
        displayName = 'Restaurant';
        break;
      case 'collector':
        iconData = Icons.delivery_dining;
        displayName = 'Collector';
        break;
      case 'organization':
        iconData = Icons.group;
        displayName = 'Organization';
        break;
      default:
        iconData = Icons.help_outline;
        displayName = roleName;
    }

    iconColor = isSelected ? Theme.of(context).primaryColor : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color: Colors.white,
            ),
            child: Center(
              child: Icon(
                iconData,
                size: 50,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
