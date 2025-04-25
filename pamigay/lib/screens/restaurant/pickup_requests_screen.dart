import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/pickup_service.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/components/loaders/shimmer_loader.dart';

/// Screen for restaurants to manage pickup requests for their donations.
///
/// This screen allows restaurants to view, accept, reject, and mark as completed
/// the pickup requests from organizations.
class PickupRequestsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const PickupRequestsScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<PickupRequestsScreen> createState() => _PickupRequestsScreenState();
}

class _PickupRequestsScreenState extends State<PickupRequestsScreen> with SingleTickerProviderStateMixin {
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
          'pickup_time': DateTime.now().add(const Duration(hours: 5)).toString(),
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
          'donation_name': 'Packaged Meals',
          'organization_id': '205',
          'organization_name': 'Food Not Bombs',
          'pickup_time': DateTime.now().subtract(const Duration(days: 1)).toString(),
          'status': 'Completed',
          'notes': '',
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toString(),
          'completed_at': DateTime.now().subtract(const Duration(days: 1)).toString(),
        },
        {
          'id': '6',
          'donation_id': '105',
          'donation_name': 'Fruits and Vegetables',
          'organization_id': '206',
          'organization_name': 'Community Kitchen',
          'pickup_time': DateTime.now().subtract(const Duration(days: 3)).toString(),
          'status': 'Completed',
          'notes': '',
          'created_at': DateTime.now().subtract(const Duration(days: 4)).toString(),
          'completed_at': DateTime.now().subtract(const Duration(days: 3)).toString(),
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
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Pickup Request'),
        content: const Text('Are you sure you want to accept this pickup request? Other requests for this donation will be automatically rejected.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PamigayColors.primary,
            ),
            child: const Text('Accept'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call service to accept pickup
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // In a real implementation, we would update the status through the API
      // and then refresh the data
      
      // For now, we'll just update our local state
      // 1. Remove the pickup from pending and add to accepted
      // 2. Remove all other pickups for the same donation
      
      final donationPickups = _pendingPickupsByDonation[donationId] ?? [];
      final acceptedPickup = donationPickups.firstWhere(
        (p) => p['id'] == pickupId,
        orElse: () => <String, dynamic>{},
      );
      
      if (acceptedPickup.isNotEmpty) {
        acceptedPickup['status'] = 'Accepted';
        _acceptedPickups.add(acceptedPickup);
        _pendingPickupsByDonation.remove(donationId);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup request accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting pickup request: $e'),
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
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call service to reject pickup
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // In a real implementation, we would update the status through the API
      // and then refresh the data
      
      // For now, we'll just update our local state
      // Remove the rejected pickup from the pending list
      
      final donationPickups = _pendingPickupsByDonation[donationId] ?? [];
      final updatedPickups = donationPickups.where((p) => p['id'] != pickupId).toList();
      
      if (updatedPickups.isEmpty) {
        _pendingPickupsByDonation.remove(donationId);
      } else {
        _pendingPickupsByDonation[donationId] = updatedPickups;
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup request rejected successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting pickup request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _handleCompletePickup(String pickupId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Pickup'),
        content: const Text('Mark this pickup as completed?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PamigayColors.primary,
            ),
            child: const Text('Complete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call service to complete pickup
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // For now, we'll just update our local state
      final pickupIndex = _acceptedPickups.indexWhere((p) => p['id'] == pickupId);
      
      if (pickupIndex != -1) {
        final pickup = _acceptedPickups[pickupIndex];
        pickup['status'] = 'Completed';
        pickup['completed_at'] = DateTime.now().toString();
        
        _completedPickups.add(pickup);
        _acceptedPickups.removeAt(pickupIndex);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Clean title with refresh button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pickup Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                    tooltip: 'Refresh pickup requests',
                    onPressed: _fetchPickupRequests,
                  ),
                ],
              ),
            ),
            
            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: PamigayColors.primary,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: PamigayColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    text: 'Pending (${_pendingPickupsByDonation.length})',
                  ),
                  Tab(
                    text: 'Accepted (${_acceptedPickups.length})',
                  ),
                  Tab(
                    text: 'Completed (${_completedPickups.length})',
                  ),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: _isLoading
                ? const ShimmerLoader(itemCount: 3)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Pending requests tab
                      _pendingPickupsByDonation.isEmpty
                          ? _buildEmptyState(
                              'No Pending Requests',
                              'You don\'t have any pending pickup requests',
                            )
                          : _buildPendingPickupsList(),
                      
                      // Accepted pickups tab
                      _acceptedPickups.isEmpty
                          ? _buildEmptyState(
                              'No Accepted Pickups',
                              'You haven\'t accepted any pickup requests yet',
                            )
                          : _buildPickupsList(_acceptedPickups, status: 'Accepted'),
                      
                      // Completed pickups tab
                      _completedPickups.isEmpty
                          ? _buildEmptyState(
                              'No Completed Pickups',
                              'Your completed pickups will appear here',
                            )
                          : _buildPickupsList(_completedPickups, status: 'Completed'),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        return _buildDonationCard(pickups.first, pickups);
      },
    );
  }
  
  Widget _buildDonationCard(Map<String, dynamic> donation, List<Map<String, dynamic>> pickups) {
    final donationId = donation['donation_id'].toString();
    final donationName = donation['donation_name'].toString();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PamigayColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2,
                  color: PamigayColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    donationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: PamigayColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${pickups.length} ${pickups.length == 1 ? 'Request' : 'Requests'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Pickup requests
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: pickups.length,
            itemBuilder: (context, index) {
              return _buildPickupRequestItem(pickups[index], donationId);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPickupRequestItem(Map<String, dynamic> pickup, String donationId) {
    final pickupId = pickup['id'].toString();
    final organizationName = pickup['organization_name'].toString();
    
    // Format pickup time
    final pickupTime = DateTime.parse(pickup['pickup_time']);
    final now = DateTime.now();
    final isToday = pickupTime.year == now.year && 
                    pickupTime.month == now.month && 
                    pickupTime.day == now.day;
    final isTomorrow = pickupTime.year == now.year && 
                       pickupTime.month == now.month && 
                       pickupTime.day == now.day + 1;
    
    String pickupDateStr;
    if (isToday) {
      pickupDateStr = 'Today';
    } else if (isTomorrow) {
      pickupDateStr = 'Tomorrow';
    } else {
      pickupDateStr = DateFormat('MMM d').format(pickupTime);
    }
    
    final pickupTimeStr = '$pickupDateStr at ${DateFormat('h:mm a').format(pickupTime)}';
    
    // Format created time
    final createdAt = DateTime.parse(pickup['created_at']);
    final timeAgo = DateTime.now().difference(createdAt);
    
    String timeAgoStr;
    if (timeAgo.inMinutes < 60) {
      timeAgoStr = '${timeAgo.inMinutes} minute${timeAgo.inMinutes == 1 ? '' : 's'} ago';
    } else if (timeAgo.inHours < 24) {
      timeAgoStr = '${timeAgo.inHours} hour${timeAgo.inHours == 1 ? '' : 's'} ago';
    } else {
      timeAgoStr = '${timeAgo.inDays} day${timeAgo.inDays == 1 ? '' : 's'} ago';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                organizationName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                timeAgoStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Pickup time
          Row(
            children: [
              const Icon(Icons.event, size: 16, color: Colors.grey),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: ${pickup['notes']}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _handleRejectPickup(pickupId, donationId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _handleAcceptPickup(pickupId, donationId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PamigayColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accept'),
              ),
            ],
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
    final pickupId = pickup['id'].toString();
    final donationName = pickup['donation_name'].toString();
    final organizationName = pickup['organization_name'].toString();
    
    // Format pickup time
    final pickupTime = DateTime.parse(pickup['pickup_time']);
    final pickupTimeStr = DateFormat('MMM d, yyyy, h:mm a').format(pickupTime);
    
    // Format completed time if available
    String? completedTimeStr;
    if (status == 'Completed' && pickup['completed_at'] != null) {
      final completedTime = DateTime.parse(pickup['completed_at']);
      completedTimeStr = DateFormat('MMM d, yyyy, h:mm a').format(completedTime);
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status == 'Accepted' 
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  status == 'Accepted' ? Icons.access_time : Icons.check_circle,
                  color: status == 'Accepted' ? Colors.blue : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: status == 'Accepted' ? Colors.blue : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // Pickup details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Donation name
                Text(
                  donationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Organization name
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
                
                // Completed time for completed pickups
                if (completedTimeStr != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Completed on: $completedTimeStr',
                        style: TextStyle(
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
                
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
