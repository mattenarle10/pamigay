import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';

/// A reusable bottom navigation bar component with role-based navigation items.
///
/// This component provides different navigation options based on the user's role
/// and supports notification badges.
class BottomNavBar extends StatelessWidget {
  /// The currently selected tab index
  final int currentIndex;
  
  /// Callback when a tab is tapped
  final Function(int) onTap;
  
  /// The role of the current user ('Restaurant' or 'Organization')
  final String userRole;
  
  /// Number of notifications to display as a badge
  final int notificationCount;
  
  /// Background color of the navigation bar
  final Color backgroundColor;
  
  /// Color of the selected item
  final Color selectedItemColor;
  
  /// Color of unselected items
  final Color unselectedItemColor;
  
  /// Add button color (for Restaurant role)
  final Color addButtonColor;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
    this.notificationCount = 0,
    this.backgroundColor = PamigayColors.primary,
    this.selectedItemColor = Colors.white,
    this.unselectedItemColor = Colors.white70,
    this.addButtonColor = const Color(0xFF4DB6AC), // teal[300]
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: userRole == 'Restaurant' 
          ? _buildRestaurantNavItems()
          : _buildOrganizationNavItems(),
      ),
    );
  }

  /// Builds navigation items for restaurant users
  List<Widget> _buildRestaurantNavItems() {
    return [
      _buildNavItem(0, Icons.home_outlined, Icons.home, label: 'Home'),
      _buildNavItem(1, Icons.list_alt_outlined, Icons.list_alt, label: 'Donations'),
      _buildAddButton(),
      _buildNavItem(3, Icons.shopping_basket_outlined, Icons.shopping_basket, 
        showBadge: notificationCount > 0, 
        badgeCount: notificationCount,
        label: 'Pickups'
      ),
      _buildNavItem(4, Icons.person_outline, Icons.person, label: 'Profile'),
    ];
  }

  /// Builds navigation items for organization users
  List<Widget> _buildOrganizationNavItems() {
    // Only 4 tabs for organizations: Home, Browse Donations, Pickups, Profile
    return [
      _buildNavItem(0, Icons.home_outlined, Icons.home, label: 'Home'),
      _buildNavItem(1, Icons.food_bank_outlined, Icons.food_bank, label: 'Donations'),
      _buildNavItem(2, Icons.shopping_basket_outlined, Icons.shopping_basket, label: 'Pickups'),
      _buildNavItem(3, Icons.person_outline, Icons.person, label: 'Profile'),
    ];
  }

  /// Builds a single navigation item
  Widget _buildNavItem(
    int index, 
    IconData iconOutlined, 
    IconData iconFilled, {
    bool showBadge = false, 
    int badgeCount = 0,
    String? label,
  }) {
    final bool isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? iconFilled : iconOutlined,
                  color: isSelected ? selectedItemColor : unselectedItemColor,
                  size: 26,
                ),
                if (showBadge)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedItemColor : unselectedItemColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the add button for restaurant users
  Widget _buildAddButton() {
    return InkWell(
      onTap: () => onTap(2),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: addButtonColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
