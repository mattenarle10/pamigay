import 'package:flutter/material.dart';
import 'package:pamigay/screens/common/profile_screen.dart';
import 'package:pamigay/services/auth_service.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/screens/restaurant/add_donation_screen.dart';
import 'package:pamigay/screens/restaurant/donations_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pamigay/components/notifications/notification_badge.dart';
import 'package:pamigay/screens/common/auth/landing_screen.dart';
import 'package:pamigay/screens/common/notifications_screen.dart';
import 'package:pamigay/screens/common/dashboard_screen.dart';
import 'package:pamigay/services/notification_service.dart';

/// Restaurant-specific home screen.
///
/// This screen displays a restaurant dashboard with important metrics
/// and quick access to recent donations.
class RestaurantHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RestaurantHomeScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _myDonations = [];
  String _errorMessage = '';
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
    _fetchUnreadNotifications();
  }

  Future<void> _fetchDonations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resto-get_my_donations.php?restaurant_id=${widget.userData['id']}'),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      
      setState(() {
        _isLoading = false;
        if (responseData['success'] == true) {
          if (responseData['data'] != null && responseData['data']['donations'] != null) {
            _myDonations = List<Map<String, dynamic>>.from(responseData['data']['donations']);
          }
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to load donations';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final userId = widget.userData['id'].toString();
      final count = await _notificationService.getUnreadCount(userId);
      
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    } catch (e) {
      print('Error fetching unread notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildRestaurantContent(context),
              ],
            ),
          ),
        ),
      ),
    
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userData: widget.userData),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 25,
                backgroundColor: PamigayColors.primary,
                backgroundImage: widget.userData['profile_image'] != null
                    ? NetworkImage(baseUrl.replaceFirst('/mobile', '') + '/' + widget.userData['profile_image'])
                    : null,
                child: widget.userData['profile_image'] == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData['name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Restaurant',
                  style: TextStyle(
                    fontSize: 14,
                    color: PamigayColors.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Notification badge
        NotificationBadge(
          count: _unreadNotifications,
          onTap: () {
            // Navigate to notifications screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(
                  userData: widget.userData,
                ),
                fullscreenDialog: true,
              ),
            ).then((_) {
              // Refresh unread notifications count when returning from notifications screen
              _fetchUnreadNotifications();
            });
          },
        ),
      ],
    );
  }
  
  // Restaurant-specific content
  Widget _buildRestaurantContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStats(),
        const SizedBox(height: 20),
        _buildActions(),
        const SizedBox(height: 20),
        _buildRecentActivity(),
      ],
    );
  }
  
  Widget _buildStats() {
    int availableDonations = 0;
    int pendingPickups = 0;
    int completedDonations = 0;
    
    for (var donation in _myDonations) {
      if (donation['status'] == 'Available') {
        availableDonations++;
      } else if (donation['status'] == 'Pending Pickup') {
        pendingPickups++;
      } else if (donation['status'] == 'Completed') {
        completedDonations++;
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Donated', '$completedDonations'),
            _buildStatItem('Available', '$availableDonations'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(initialIndex: 1),
                  ),
                ).then((_) => _fetchDonations());
              },
              child: _buildActionCard(Icons.add_circle, 'Add Donation', true),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(initialIndex: 2),
                  ),
                ).then((_) => _fetchDonations());
              },
              child: _buildActionCard(Icons.list, 'My Donations', true),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard(IconData icon, String label, bool enabled) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: PamigayColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Donations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _myDonations.isEmpty
                ? const ListTile(
                    leading: Icon(Icons.history),
                    title: Text('No recent donations'),
                    subtitle: Text('Your donations will appear here'),
                  )
                : Column(
                    children: _myDonations.take(3).map((donation) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: PamigayColors.primary.withOpacity(0.2),
                          child: Icon(
                            Icons.fastfood,
                            color: PamigayColors.primary,
                          ),
                        ),
                        title: Text(
                          donation['name'] ?? 'Unnamed Donation',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Status: ${donation['status']} • ${donation['quantity']}',
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DashboardScreen(initialIndex: 2),
                            ),
                          ).then((_) => _fetchDonations());
                        },
                      );
                    }).toList(),
                  ),
            if (_myDonations.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardScreen(initialIndex: 2),
                        ),
                      ).then((_) => _fetchDonations());
                    },
                    child: Text(
                      'View All Donations',
                      style: TextStyle(
                        color: PamigayColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
