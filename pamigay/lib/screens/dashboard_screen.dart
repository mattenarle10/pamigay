import 'package:flutter/material.dart';
import 'package:pamigay/components/bottom_nav.dart';
import 'package:pamigay/screens/home_screen.dart';
import 'package:pamigay/screens/profile_screen.dart';
import 'package:pamigay/screens/add_donation_screen.dart';
import 'package:pamigay/screens/donations_screen.dart';
import 'package:pamigay/screens/available_donations_screen.dart';
import 'package:pamigay/screens/my_pickups_screen.dart';
import 'package:pamigay/screens/restaurant_pickup_requests_screen.dart';
import 'package:pamigay/services/auth_service.dart';
import 'package:pamigay/services/user_service.dart';
import 'package:pamigay/services/pickup_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
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
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        userRole: _userRole,
        notificationCount: _notificationCount,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
  
  Widget _getScreen() {
    if (_userRole == 'Restaurant') {
      switch (_currentIndex) {
        case 0:
          return HomeScreen(userRole: _userRole, userData: _userData);
        case 1:
          return DonationsScreen(userData: _userData);
        case 2:
          // Navigate to AddDonationScreen as a separate screen
          // Use addPostFrameCallback to avoid build errors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Check if context is still valid before navigating
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDonationScreen(userData: _userData),
                ),
              ).then((_) {
                // Reset to home tab when returning from AddDonationScreen
                if (mounted) {
                  setState(() {
                    _currentIndex = 0;
                  });
                }
              });
            }
          });
          // Return the home screen while navigating
          return HomeScreen(userRole: _userRole, userData: _userData);
        case 3:
          // Replace notifications with Restaurant Pickup Requests
          return RestaurantPickupRequestsScreen(userData: _userData);
        case 4:
          return ProfileScreen(userData: _userData);
        default:
          return HomeScreen(userRole: _userRole, userData: _userData);
      }
    } else if (_userRole == 'Organization') {
      // Organization role screens - now only 4 tabs
      switch (_currentIndex) {
        case 0:
          return HomeScreen(userRole: _userRole, userData: _userData);
        case 1:
          // Available Donations screen
          return AvailableDonationsScreen(userData: _userData);
        case 2:
          // My Pickups screen
          return MyPickupsScreen(userData: _userData);
        case 3:
          // Profile screen (moved from index 4 to 3)
          return ProfileScreen(userData: _userData);
        default:
          return HomeScreen(userRole: _userRole, userData: _userData);
      }
    } else {
      // Default fallback
      return HomeScreen(userRole: _userRole, userData: _userData);
    }
  }
}