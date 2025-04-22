import 'package:flutter/material.dart';
import 'package:pamigay/screens/landing_screen.dart';
import 'package:pamigay/services/auth_service.dart';
import 'package:pamigay/utils/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  bool _isLoading = false;
  List<Map<String, dynamic>> _myDonations = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurant-get_my_donations.php?restaurant_id=${widget.userData['id']}'),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      
      setState(() {
        _isLoading = false;
        if (responseData['status'] == 'success') {
          if (responseData['data'] != null) {
            _myDonations = List<Map<String, dynamic>>.from(responseData['data']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: PamigayColors.primary,
        title: const Text(
          'Restaurant Dashboard',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Info Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: PamigayColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.userData['name']}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.userData['email'] ?? 'No email',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Stats Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Donations',
                    _myDonations.where((d) => d['status'] == 'Available').length.toString(),
                    Icons.restaurant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    _myDonations.where((d) => d['status'] == 'Completed').length.toString(),
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ),
          // Donations List
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: const Text(
              'Your Donations',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchDonations,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_myDonations.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No donations yet. Create a new donation to get started!',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDonations,
                child: ListView.builder(
                  itemCount: _myDonations.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final donation = _myDonations[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        title: Text(
                          '${donation['category']} - ${donation['quantity']}',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Condition: ${donation['condition_status']}'),
                            Text('Status: ${donation['status']}'),
                            Text('Created: ${donation['created_at']}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: donation['status'] == 'Available' 
                                ? Colors.green.shade100 
                                : donation['status'] == 'Pending Pickup'
                                    ? Colors.orange.shade100
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            donation['status'],
                            style: TextStyle(
                              color: donation['status'] == 'Available' 
                                  ? Colors.green.shade800 
                                  : donation['status'] == 'Pending Pickup'
                                      ? Colors.orange.shade800
                                      : Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add donation screen (to be implemented)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Donation feature coming soon')),
          );
        },
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Donate Food',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
