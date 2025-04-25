import 'package:flutter/material.dart';
import 'package:pamigay/components/navigation/bottom_nav_bar.dart';
import 'package:pamigay/screens/common/profile_screen.dart';
import 'package:pamigay/screens/common/notifications_screen.dart';
import 'package:pamigay/screens/organization/available_donations_screen.dart';
import 'package:pamigay/screens/organization/my_pickups_screen.dart';
import 'package:pamigay/screens/restaurant/add_donation_screen.dart';
import 'package:pamigay/screens/restaurant/donations_screen.dart';
import 'package:pamigay/screens/restaurant/home_screen.dart' as restaurant;
import 'package:pamigay/screens/organization/home_screen.dart' as organization;
import 'package:pamigay/screens/restaurant/pickup_requests_screen.dart';
import 'package:pamigay/services/auth_service.dart';
import 'package:pamigay/services/user_service.dart';
import 'package:pamigay/services/pickup_service.dart';

/// The main dashboard screen that serves as a container for role-specific content.
///
/// This screen handles user authentication, bottom navigation, and displays
/// the appropriate screen based on the user's role and selected navigation tab.
class DashboardScreen extends StatefulWidget {
  final int initialIndex;
  
  const DashboardScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _currentIndex;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final PickupService _pickupService = PickupService();
  String _userRole = '';
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _notificationCount = 0;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First try to get cached user data
      final userData = await _authService.getCurrentUser();
      
      if (userData != null) {
        setState(() {
          _userData = userData;
          _userRole = userData['role'] ?? '';
          _isLoading = false;
        });
        
        // Then refresh from API in background
        _refreshUserData();
        
        // Load notification count (pending pickups)
        _loadNotificationCount();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _refreshUserData() async {
    try {
      final refreshedData = await _userService.refreshUserProfile();
      if (refreshedData != null) {
        setState(() {
          _userData = refreshedData;
          _userRole = refreshedData['role'] ?? '';
        });
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }
  
  Future<void> _loadNotificationCount() async {
    try {
      if (_userData == null) return;
      
      final userId = _userData!['id'].toString();
      
      // In a real implementation, we would fetch the count from the API
      // For now, we'll use placeholder data
      
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        // Placeholder notification count
        _notificationCount = _userRole == 'Restaurant' ? 2 : 1;
      });
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  // This method handles navigation through the bottom nav bar
  void _handleNavigation(int index) {
    // Special case for Add Donation button (index 2)
    if (_userRole == 'Restaurant' && index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddDonationScreen(userData: _userData),
        ),
      );
      return;
    }
    
    // For all other navigation, update the current index
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: _getScreen(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        userRole: _userRole,
        notificationCount: _notificationCount,
        onTap: _handleNavigation,
      ),
    );
  }
  
  Widget _getScreen() {
    if (_userRole == 'Restaurant') {
      switch (_currentIndex) {
        case 0:
          return restaurant.RestaurantHomeScreen(userData: _userData!);
        case 1:
          return DonationsScreen(userData: _userData);
        case 2: // This is the add button - we handle navigation in _handleNavigation
          return restaurant.RestaurantHomeScreen(userData: _userData!);
        case 3:
          return PickupRequestsScreen(userData: _userData);
        case 4:
          return ProfileScreen(userData: _userData);
        default:
          return restaurant.RestaurantHomeScreen(userData: _userData!);
      }
    } else if (_userRole == 'Organization') {
      // Organization role screens
      switch (_currentIndex) {
        case 0:
          return organization.OrganizationHomeScreen(userData: _userData!);
        case 1:
          // Available Donations screen
          return AvailableDonationsScreen(userData: _userData);
        case 2:
          // My Pickups screen
          return MyPickupsScreen(userData: _userData);
        case 3:
          // Profile screen
          return ProfileScreen(userData: _userData);
        default:
          return organization.OrganizationHomeScreen(userData: _userData!);
      }
    } else {
      // Default fallback
      return organization.OrganizationHomeScreen(userData: _userData!);
    }
  }
}
