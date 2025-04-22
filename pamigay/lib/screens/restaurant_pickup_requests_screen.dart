import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/pickup_service.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:intl/intl.dart';

class RestaurantPickupRequestsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const RestaurantPickupRequestsScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<RestaurantPickupRequestsScreen> createState() => _RestaurantPickupRequestsScreenState();
}

class _RestaurantPickupRequestsScreenState extends State<RestaurantPickupRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PickupService _pickupService = PickupService();
  final DonationService _donationService = DonationService();
  bool _isLoading = true;
  
  // Group pickups by donation for better organization
  Map<String, List<Map<String, dynamic>>> _pendingPickupsByDonation = {};
  List<Map<String, dynamic>> _acceptedPickups = [];
  List<Map<String, dynamic>> _completedPickups = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPickupRequests();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchPickupRequests() async {
    if (widget.userData == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final restaurantId = widget.userData!['id'].toString();
      
      // In a real implementation, we would fetch pickup requests from the API
      // For now, we'll use placeholder data
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Reset data
      _pendingPickupsByDonation = {};
      _acceptedPickups = [];
      _completedPickups = [];
      
      // Placeholder data for pending pickups
      final pendingPickups = [
        {
          'id': '1',
          'donation_id': '101',
          'donation_name': 'Fresh Vegetables Bundle',
          'organization_id': '201',
          'organization_name': 'Food Bank Organization',
          'pickup_time': DateTime.now().add(const Duration(days: 1)).toString(),
          'status': 'Requested',
          'notes': 'Please keep refrigerated',
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toString(),
        },
        {
          'id': '2',
          'donation_id': '101', // Same donation as above
          'donation_name': 'Fresh Vegetables Bundle',
          'organization_id': '202',
          'organization_name': 'Community Shelter',
          'pickup_time': DateTime.now().add(const Duration(days: 2)).toString(),
          'status': 'Requested',
          'notes': 'We can pick up anytime',
          'created_at': DateTime.now().subtract(const Duration(hours: 5)).toString(),
        },
        {
          'id': '3',
          'donation_id': '102',
          'donation_name': 'Bread and Pastries',
          'organization_id': '203',
          'organization_name': 'Local Charity',
          'pickup_time': DateTime.now().add(const Duration(hours: 4)).toString(),
          'status': 'Requested',
          'notes': '',
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toString(),
        },
      ];
      
      // Group pending pickups by donation
      for (final pickup in pendingPickups) {
        final donationId = pickup['donation_id'].toString();
        if (!_pendingPickupsByDonation.containsKey(donationId)) {
          _pendingPickupsByDonation[donationId] = [];
        }
        _pendingPickupsByDonation[donationId]!.add(pickup);
      }
      
      // Placeholder data for accepted pickups
      _acceptedPickups = [
        {
          'id': '4',
          'donation_id': '103',
          'donation_name': 'Canned Goods',
          'organization_id': '204',
          'organization_name': 'Homeless Shelter',
          'pickup_time': DateTime.now().add(const Duration(hours: 4)).toString(),
          'status': 'Accepted',
          'notes': 'Will arrive around 2pm',
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toString(),
        },
      ];
      
      // Placeholder data for completed pickups
      _completedPickups = [
        {
          'id': '5',
          'donation_id': '104',
          'donation_name': 'Rice and Grains',
          'organization_id': '205',
          'organization_name': 'Homeless Shelter',
          'pickup_time': DateTime.now().subtract(const Duration(days: 2)).toString(),
          'status': 'Completed',
          'notes': '',
          'created_at': DateTime.now().subtract(const Duration(days: 3)).toString(),
        },
      ];
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching pickup requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _handleAcceptPickup(String pickupId, String donationId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accepting pickup request...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real implementation, we would call the API to accept the pickup
      // and update the donation status
      
      // Update local state
      setState(() {
        // Find the accepted pickup
        Map<String, dynamic>? acceptedPickup;
        
        // Remove the accepted pickup from pending and add to accepted
        if (_pendingPickupsByDonation.containsKey(donationId)) {
          final pickups = _pendingPickupsByDonation[donationId]!;
          final index = pickups.indexWhere((p) => p['id'] == pickupId);
          
          if (index != -1) {
            acceptedPickup = Map<String, dynamic>.from(pickups[index]);
            acceptedPickup['status'] = 'Accepted';
            _acceptedPickups.add(acceptedPickup);
            
            // Remove the donation from pending pickups entirely
            // since it's no longer available for other organizations
            _pendingPickupsByDonation.remove(donationId);
          }
        }
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup request accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error accepting pickup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept pickup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _handleRejectPickup(String pickupId, String donationId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Pickup Request'),
        content: const Text('Are you sure you want to reject this pickup request?'),
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
    
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rejecting pickup request...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real implementation, we would call the API to reject the pickup
      
      // Update local state
      setState(() {
        // Remove the rejected pickup from pending
        if (_pendingPickupsByDonation.containsKey(donationId)) {
          final pickups = _pendingPickupsByDonation[donationId]!;
          final index = pickups.indexWhere((p) => p['id'] == pickupId);
          
          if (index != -1) {
            pickups.removeAt(index);
            
            // If no more pickups for this donation, remove the donation entry
            if (pickups.isEmpty) {
              _pendingPickupsByDonation.remove(donationId);
            }
          }
        }
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup request rejected successfully'),
          backgroundColor: PamigayColors.primary,
        ),
      );
    } catch (e) {
      print('Error rejecting pickup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject pickup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _handleCompletePickup(String pickupId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completing pickup...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real implementation, we would call the API to complete the pickup
      
      // Update local state
      setState(() {
        // Find the pickup to complete
        final index = _acceptedPickups.indexWhere((p) => p['id'] == pickupId);
        
        if (index != -1) {
          final completedPickup = Map<String, dynamic>.from(_acceptedPickups[index]);
          completedPickup['status'] = 'Completed';
          _completedPickups.add(completedPickup);
          _acceptedPickups.removeAt(index);
        }
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup marked as completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error completing pickup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete pickup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pickup Requests',
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
            onPressed: _fetchPickupRequests,
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
            Tab(text: 'Accepted'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Pickups Tab
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingPickupsByDonation.isEmpty
              ? _buildEmptyState('No pending pickup requests', 'When organizations request to pick up your donations, they will appear here.')
              : _buildPendingPickupsList(),
          
          // Accepted Pickups Tab
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _acceptedPickups.isEmpty
              ? _buildEmptyState('No accepted pickups', 'Pickups you have accepted will appear here.')
              : _buildPickupsList(_acceptedPickups, status: 'Accepted'),
          
          // Completed Pickups Tab
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _completedPickups.isEmpty
              ? _buildEmptyState('No completed pickups', 'Completed pickups will appear here.')
              : _buildPickupsList(_completedPickups, status: 'Completed'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPendingPickupsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPickupsByDonation.length,
      itemBuilder: (context, index) {
        final donationId = _pendingPickupsByDonation.keys.elementAt(index);
        final pickups = _pendingPickupsByDonation[donationId]!;
        final donation = pickups.first; // Use the first pickup to get donation info
        
        return _buildDonationCard(donation, pickups);
      },
    );
  }
  
  Widget _buildDonationCard(Map<String, dynamic> donation, List<Map<String, dynamic>> pickups) {
    final donationId = donation['donation_id'];
    final donationName = donation['donation_name'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donation header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PamigayColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.fastfood, color: PamigayColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donationName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pickups.length} pickup request${pickups.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Pickup requests
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pickups.length,
            itemBuilder: (context, index) {
              final pickup = pickups[index];
              return _buildPickupRequestItem(pickup, donationId);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPickupRequestItem(Map<String, dynamic> pickup, String donationId) {
    final organizationName = pickup['organization_name'];
    final pickupId = pickup['id'];
    
    // Parse pickup time
    DateTime? pickupTime;
    if (pickup['pickup_time'] != null) {
      try {
        pickupTime = DateTime.parse(pickup['pickup_time']);
      } catch (e) {
        print('Error parsing pickup time: $e');
      }
    }
    
    // Format pickup time
    final pickupTimeStr = pickupTime != null 
        ? DateFormat('MMM d, yyyy • h:mm a').format(pickupTime)
        : 'Not specified';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization name
          Row(
            children: [
              const Icon(Icons.business, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  organizationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Pickup time
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Requested for: $pickupTimeStr',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          
          // Notes if available
          if (pickup['notes'] != null && pickup['notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notes: ${pickup['notes']}',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleRejectPickup(pickupId, donationId),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleAcceptPickup(pickupId, donationId),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPickupsList(List<Map<String, dynamic>> pickups, {required String status}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pickups.length,
      itemBuilder: (context, index) {
        return _buildPickupCard(pickups[index], status: status);
      },
    );
  }
  
  Widget _buildPickupCard(Map<String, dynamic> pickup, {required String status}) {
    // Extract data from pickup
    final pickupId = pickup['id'];
    final donationName = pickup['donation_name'];
    final organizationName = pickup['organization_name'];
    
    // Parse pickup time
    DateTime? pickupTime;
    if (pickup['pickup_time'] != null) {
      try {
        pickupTime = DateTime.parse(pickup['pickup_time']);
      } catch (e) {
        print('Error parsing pickup time: $e');
      }
    }
    
    // Format pickup time
    final pickupTimeStr = pickupTime != null 
        ? DateFormat('MMM d, yyyy • h:mm a').format(pickupTime)
        : 'Not specified';
    
    // Determine status color
    Color statusColor;
    switch (status) {
      case 'Accepted':
        statusColor = Colors.blue;
        break;
      case 'Completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: #$pickupId',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Donation name
                Text(
                  donationName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Organization info
                Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Organization: $organizationName',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Pickup time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Pickup: $pickupTimeStr',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                
                // Notes if available
                if (pickup['notes'] != null && pickup['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickup['notes'],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Actions based on status
                if (status == 'Accepted')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // View details logic would go here
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handleCompletePickup(pickupId),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Mark as Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PamigayColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // View details logic would go here
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PamigayColors.primary,
                          side: BorderSide(color: PamigayColors.primary),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
