import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/user_service.dart';
import 'package:pamigay/components/notification_badge.dart';
import 'package:pamigay/screens/notifications_screen.dart';
import 'package:pamigay/screens/restaurant_pickup_requests_screen.dart';
import 'package:pamigay/screens/my_pickups_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userRole;
  final Map<String, dynamic>? userData;

  const HomeScreen({
    Key? key,
    required this.userRole,
    this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              userRole == 'Restaurant' 
                ? _buildRestaurantContent(context)
                : _buildOrganizationContent(context),
            ],
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
            CircleAvatar(
              radius: 25,
              backgroundColor: PamigayColors.primary,
              backgroundImage: userData?['profile_image'] != null
                  ? NetworkImage(baseUrl.replaceFirst('/mobile', '') + '/' + userData!['profile_image'])
                  : null,
              child: userData?['profile_image'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData?['name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  userRole,
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
        // Notification badge - now navigates to the notifications screen
        NotificationBadge(
          count: userRole == 'Restaurant' ? 2 : 1, // Placeholder count
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(userData: userData),
              ),
            );
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
  
  // Organization-specific content
  Widget _buildOrganizationContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOrganizationStats(),
        const SizedBox(height: 20),
        _buildOrganizationActions(),
        const SizedBox(height: 20),
        _buildOrganizationActivity(),
      ],
    );
  }
  
  Widget _buildStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Donated', '0'),
            _buildStatItem('Collected', '0'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
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
            _buildActionCard(
              Icons.add_box,
              'Add Donation',
              userRole == 'Restaurant',
            ),
            _buildActionCard(
              Icons.list_alt,
              'My Donations',
              true,
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
          children: const [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('No recent activities'),
              subtitle: Text('Your activities will appear here'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrganizationStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Impact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Pickups', '0'),
                _buildStatItem('Saved', '0 kg'),
                _buildStatItem('Pending', '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrganizationActions() {
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
            _buildActionCard(
              Icons.food_bank,
              'Browse Donations',
              true,
            ),
            _buildActionCard(
              Icons.shopping_basket,
              'My Pickups',
              true,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildOrganizationActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Pickups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: PamigayColors.primary.withOpacity(0.2),
                child: Icon(Icons.shopping_basket, color: PamigayColors.primary),
              ),
              title: const Text('No recent pickups'),
              subtitle: const Text('Your pickup history will appear here'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  'View All Pickups',
                  style: TextStyle(
                    color: PamigayColors.primary,
                    fontWeight: FontWeight.bold,
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