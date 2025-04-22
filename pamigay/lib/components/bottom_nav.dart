import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userRole;
  final int notificationCount;

  const BottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
    this.notificationCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PamigayColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
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

  List<Widget> _buildRestaurantNavItems() {
    return [
      _buildNavItem(0, Icons.home_outlined, Icons.home),
      _buildNavItem(1, Icons.list_alt_outlined, Icons.list_alt),
      _buildAddButton(),
      _buildNavItem(3, Icons.shopping_basket_outlined, Icons.shopping_basket, showBadge: notificationCount > 0, badgeCount: notificationCount),
      _buildNavItem(4, Icons.person_outline, Icons.person),
    ];
  }

  List<Widget> _buildOrganizationNavItems() {
    // Only 4 tabs for organizations: Home, Browse Donations, Pickups, Profile
    return [
      _buildNavItem(0, Icons.home_outlined, Icons.home),
      _buildNavItem(1, Icons.food_bank_outlined, Icons.food_bank),
      _buildNavItem(2, Icons.shopping_basket_outlined, Icons.shopping_basket),
      _buildNavItem(3, Icons.person_outline, Icons.person),
    ];
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, {bool showBadge = false, int badgeCount = 0}) {
    final bool isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: Colors.white,
              size: 28,
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
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: () => onTap(2),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.teal[300],
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