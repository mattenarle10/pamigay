import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/components/notifications/notification_badge.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pamigay/screens/common/profile_screen.dart';
import 'package:pamigay/screens/common/notifications_screen.dart';
import 'package:pamigay/screens/organization/available_donations_screen.dart';
import 'package:pamigay/screens/organization/my_pickups_screen.dart';
import 'package:pamigay/components/navigation/bottom_nav_bar.dart';
import 'package:pamigay/screens/common/dashboard_screen.dart';
import 'package:pamigay/services/notification_service.dart';

/// Organization-specific home screen.
///
/// This screen displays an organization dashboard with important metrics
/// and quick access to available donations and pickup requests.
class OrganizationHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OrganizationHomeScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<OrganizationHomeScreen> createState() => _OrganizationHomeScreenState();
}

class _OrganizationHomeScreenState extends State<OrganizationHomeScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableDonations = [];
  List<Map<String, dynamic>> _myPickups = [];
  String _errorMessage = '';
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchUnreadNotifications();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch available donations
      await _fetchAvailableDonations();
      
      // Fetch my pickups
      await _fetchMyPickups();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching data: $e';
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

  Future<void> _fetchAvailableDonations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_available_donations.php'),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData['status'] == 'success') {
        if (responseData['data'] != null) {
          setState(() {
            _availableDonations = List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } 
    } catch (e) {
      print('Error fetching available donations: $e');
    }
  }

  Future<void> _fetchMyPickups() async {
    try {
      final organizationId = widget.userData['id'].toString();
      
      final response = await http.get(
        Uri.parse('$baseUrl/get_my_pickups.php?organization_id=$organizationId'),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData['status'] == 'success') {
        if (responseData['data'] != null) {
          setState(() {
            _myPickups = List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      }
    } catch (e) {
      print('Error fetching my pickups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 20),
                            _buildDashboardContent(),
                          ],
                        ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Organization',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        NotificationBadge(
          count: _unreadNotifications,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(
                  userData: widget.userData,
                ),
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

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome message
        const Text(
          'Welcome to your Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s what\'s happening today',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 24),
        
        // Stats section
        const Text(
          'Your Impact',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 16),
        
        // Stats cards - removed Available Donations and Cancelled
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('My Pickups', _myPickups.length.toString(), Icons.delivery_dining),
            _buildStatCard('Completed', '0', Icons.check_circle),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // My pickups section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Pickups',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(initialIndex: 2),
                          ),
                        ).then((_) => _fetchData());
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: PamigayColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _myPickups.isEmpty
                    ? _buildEmptyState(
                        'No Pickup Requests',
                        'You haven\'t requested any pickups yet',
                        Icons.delivery_dining,
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myPickups.length > 3 ? 3 : _myPickups.length,
                        itemBuilder: (context, index) {
                          final pickup = _myPickups[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: PamigayColors.primary.withOpacity(0.2),
                                child: Icon(
                                  Icons.delivery_dining,
                                  color: PamigayColors.primary,
                                ),
                              ),
                              title: Text(
                                pickup['donation_name'] ?? 'Unnamed Donation',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${pickup['restaurant_name'] ?? 'Unknown Restaurant'}\nStatus: ${pickup['status'] ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              onTap: () {
                                // Navigate to pickup details
                              },
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: PamigayColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
