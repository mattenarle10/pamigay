import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/services/pickup_service.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/widgets/pickup_card.dart';
import 'package:pamigay/screens/donation_detail_screen.dart';

class MyPickupsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const MyPickupsScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<MyPickupsScreen> createState() => _MyPickupsScreenState();
}

class _MyPickupsScreenState extends State<MyPickupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isRefreshing = false;
  final PickupService _pickupService = PickupService();
  final DonationService _donationService = DonationService();
  
  // Pickup data
  List<Map<String, dynamic>> _pendingPickups = [];
  List<Map<String, dynamic>> _completedPickups = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPickups();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPickups() async {
    if (widget.userData == null || widget.userData!['id'] == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      if (!_isRefreshing) {
        _isLoading = true;
      }
    });

    try {
      final organizationId = widget.userData!['id'].toString();
      
      // Fetch all pickups
      final allPickups = await _pickupService.getMyPickups(organizationId);
      
      // Enhance pickup data with donation details
      final enhancedPickups = await _enhancePickupsWithDonationDetails(allPickups);
      
      // Separate into pending and completed
      final pending = <Map<String, dynamic>>[];
      final completed = <Map<String, dynamic>>[];
      
      for (final pickup in enhancedPickups) {
        final status = pickup['status'] as String? ?? '';
        if (status == 'Completed' || status == 'Cancelled' || status == 'Rejected') {
          completed.add(pickup);
        } else {
          pending.add(pickup);
        }
      }
      
      // Sort by pickup time (most recent first for pending)
      pending.sort((a, b) {
        try {
          final aTime = DateTime.parse(a['pickup_time'] ?? '');
          final bTime = DateTime.parse(b['pickup_time'] ?? '');
          return aTime.compareTo(bTime);
        } catch (e) {
          return 0;
        }
      });
      
      // Sort by pickup time (most recent first for completed)
      completed.sort((a, b) {
        try {
          final aTime = DateTime.parse(a['pickup_time'] ?? '');
          final bTime = DateTime.parse(b['pickup_time'] ?? '');
          return bTime.compareTo(aTime); // Reverse order for completed
        } catch (e) {
          return 0;
        }
      });
      
      setState(() {
        _pendingPickups = pending;
        _completedPickups = completed;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      print('Error fetching pickups: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pickups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<List<Map<String, dynamic>>> _enhancePickupsWithDonationDetails(List<Map<String, dynamic>> pickups) async {
    final enhancedPickups = <Map<String, dynamic>>[];
    
    for (final pickup in pickups) {
      final enhancedPickup = Map<String, dynamic>.from(pickup);
      
      // Get donation ID
      final donationId = pickup['donation_id']?.toString();
      if (donationId != null) {
        try {
          // Fetch donation details
          final donationDetails = await _donationService.getDonationById(donationId);
          if (donationDetails != null) {
            // Add donation details to pickup
            enhancedPickup['donation_name'] = donationDetails['name'];
            enhancedPickup['donation_description'] = donationDetails['description'];
            enhancedPickup['donation_image'] = donationDetails['photo_url']; // Match the field name in database
            enhancedPickup['restaurant_name'] = donationDetails['restaurant_name'];
            enhancedPickup['restaurant_phone'] = donationDetails['restaurant_phone'];
            enhancedPickup['restaurant_location'] = donationDetails['restaurant_location'];
            
            // Add pickup window details if available
            enhancedPickup['pickup_window_start'] = donationDetails['pickup_window_start'];
            enhancedPickup['pickup_window_end'] = donationDetails['pickup_window_end'];
          }
        } catch (e) {
          print('Failed to get donation: $e');
          // Still add the pickup even if we couldn't get donation details
          enhancedPickup['donation_name'] = 'Unknown Donation';
          enhancedPickup['restaurant_name'] = 'Unknown Restaurant';
        }
      }
      
      enhancedPickups.add(enhancedPickup);
    }
    
    return enhancedPickups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Pickups',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: PamigayColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isRefreshing = true;
              });
              _fetchPickups();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PamigayColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                // Pending Pickups Tab
                _pendingPickups.isEmpty
                    ? _buildEmptyState('No pending pickups', 'Your pending pickup requests will appear here.')
                    : _buildPickupsList(_pendingPickups, isPending: true),
                
                // Completed Pickups Tab
                _completedPickups.isEmpty
                    ? _buildEmptyState('No completed pickups', 'Your completed pickups will appear here.')
                    : _buildPickupsList(_completedPickups, isPending: false),
              ],
            ),
    );
  }
  
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to available donations
              Navigator.of(context).pop();
              // In a real implementation, we would navigate to the available donations tab
            },
            icon: const Icon(Icons.search),
            label: const Text('Browse Available Donations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PamigayColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPickupsList(List<Map<String, dynamic>> pickups, {required bool isPending}) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isRefreshing = true;
        });
        await _fetchPickups();
      },
      color: PamigayColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pickups.length,
        itemBuilder: (context, index) {
          return PickupCard(
            pickup: pickups[index],
            isPending: isPending,
            onCancel: _cancelPickup,
            onViewDetails: () {
              _viewDonationDetails(pickups[index]);
            },
          );
        },
      ),
    );
  }
  
  void _viewDonationDetails(Map<String, dynamic> pickup) {
    final donationId = pickup['donation_id']?.toString();
    if (donationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation details not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Create a donation object with the available details
    final donation = {
      'id': donationId,
      'name': pickup['donation_name'] ?? 'Unknown Donation',
      'description': pickup['donation_description'] ?? '',
      'restaurant_id': pickup['restaurant_id'] ?? '',
      'restaurant_name': pickup['restaurant_name'] ?? 'Unknown Restaurant',
      'image': pickup['donation_image'],
      'status': 'Pending Pickup', // This is the donation status, not the pickup status
      'pickup_window_start': pickup['pickup_window_start'],
      'pickup_window_end': pickup['pickup_window_end'],
    };
    
    // Navigate to donation details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DonationDetailScreen(
          userData: widget.userData,
          donation: donation,
        ),
      ),
    ).then((_) => _fetchPickups());
  }
  
  Future<void> _cancelPickup(Map<String, dynamic> pickup) async {
    final pickupId = pickup['id']?.toString();
    if (pickupId == null) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Pickup Request'),
        content: const Text('Are you sure you want to cancel this pickup request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _pickupService.updatePickup(
        pickupId: pickupId,
        status: 'Cancelled',
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup request cancelled successfully'),
            backgroundColor: PamigayColors.primary,
          ),
        );
        
        // Refresh pickups
        _fetchPickups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel pickup: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}
