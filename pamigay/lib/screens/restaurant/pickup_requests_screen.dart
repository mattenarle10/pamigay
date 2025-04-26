import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/pickup_service.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/components/loaders/shimmer_loader.dart';
import 'package:pamigay/components/cards/restaurant_pickup_request_card.dart';
import 'package:pamigay/components/cards/restaurant_accepted_pickup_card.dart';
import 'package:pamigay/components/search/search_filter_bar.dart';

/// Screen for restaurants to manage pickup requests for their donations.
///
/// This screen allows restaurants to view and manage pickup requests from
/// organizations. They can accept, reject, or mark pickups as completed.
class PickupRequestsScreen extends StatefulWidget {
  /// The user data for the restaurant
  final Map<String, dynamic>? userData;

  const PickupRequestsScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<PickupRequestsScreen> createState() => _PickupRequestsScreenState();
}

class _PickupRequestsScreenState extends State<PickupRequestsScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final _pickupService = PickupService();
  final _donationService = DonationService();
  final _userService = UserService();

  // Tab controller
  late TabController _tabController;

  // State variables
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _pendingPickupsByDonation = {};
  List<Map<String, dynamic>> _acceptedPickups = [];
  List<Map<String, dynamic>> _completedPickups = [];
  
  // Original data (unfiltered)
  Map<String, List<Map<String, dynamic>>> _allPendingPickupsByDonation = {};
  List<Map<String, dynamic>> _allAcceptedPickups = [];
  List<Map<String, dynamic>> _allCompletedPickups = [];
  
  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  DateTime? _selectedDate;
  final List<String> _statusOptions = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPickupRequests();
    
    // Add listener to search controller
    _searchController.addListener(_filterPickups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPickupRequests() async {
    if (widget.userData == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final restaurantId = widget.userData!['id'];
      
      // Call the API to get pickup requests for this restaurant
      final response = await _pickupService.getRestaurantPickupRequests(restaurantId);
      
      if (response['success'] == true) {
        final List<dynamic> pickupsData = response['data']['pickups'] ?? [];
        
        // Reset collections
        _allPendingPickupsByDonation = {};
        _allAcceptedPickups = [];
        _allCompletedPickups = [];
        
        // Process the pickups
        for (var pickup in pickupsData) {
          final Map<String, dynamic> pickupMap = Map<String, dynamic>.from(pickup);
          
          switch (pickupMap['status']) {
            case 'Requested':
              final donationId = pickupMap['donation_id'].toString();
              if (!_allPendingPickupsByDonation.containsKey(donationId)) {
                _allPendingPickupsByDonation[donationId] = [];
              }
              _allPendingPickupsByDonation[donationId]!.add(pickupMap);
              break;
            case 'Accepted':
              _allAcceptedPickups.add(pickupMap);
              break;
            case 'Completed':
              _allCompletedPickups.add(pickupMap);
              break;
            default:
              // Skip other statuses like 'Cancelled'
              break;
          }
        }
        
        // Apply initial filtering
        _filterPickups();
        
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load pickup requests');
      }
    } catch (e) {
      print('Error fetching pickup requests: $e');
      
      // For demo purposes, populate with sample data if API fails
      // In production, you would show an error message instead
      _allPendingPickupsByDonation = {};
      _allAcceptedPickups = [];
      _allCompletedPickups = [];
      
      // Apply initial filtering
      _filterPickups();
      
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading pickup requests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Filter pickups based on search query, status, and date
  void _filterPickups() {
    final String searchQuery = _searchController.text.toLowerCase();
    
    // Filter pending pickups
    _pendingPickupsByDonation = {};
    _allPendingPickupsByDonation.forEach((donationId, pickups) {
      final List<Map<String, dynamic>> filteredPickups = pickups.where((pickup) {
        // Check if matches search query
        final bool matchesSearch = searchQuery.isEmpty ||
            (pickup['donation_name']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
            (pickup['organization_name']?.toString().toLowerCase().contains(searchQuery) ?? false);
        
        // Check if matches date filter
        final bool matchesDate = _matchesDateFilter(pickup['pickup_time']);
        
        return matchesSearch && matchesDate;
      }).toList();
      
      if (filteredPickups.isNotEmpty) {
        _pendingPickupsByDonation[donationId] = filteredPickups;
      }
    });
    
    // Filter accepted pickups
    _acceptedPickups = _allAcceptedPickups.where((pickup) {
      // Check if matches search query
      final bool matchesSearch = searchQuery.isEmpty ||
          (pickup['donation_name']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
          (pickup['organization_name']?.toString().toLowerCase().contains(searchQuery) ?? false);
      
      // Check if matches date filter
      final bool matchesDate = _matchesDateFilter(pickup['pickup_time']);
      
      return matchesSearch && matchesDate;
    }).toList();
    
    // Filter completed pickups
    _completedPickups = _allCompletedPickups.where((pickup) {
      // Check if matches search query
      final bool matchesSearch = searchQuery.isEmpty ||
          (pickup['donation_name']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
          (pickup['organization_name']?.toString().toLowerCase().contains(searchQuery) ?? false);
      
      // Check if matches date filter
      final bool matchesDate = _matchesDateFilter(pickup['pickup_time']);
      
      return matchesSearch && matchesDate;
    }).toList();
    
    setState(() {});
  }
  
  /// Check if a pickup date matches the selected date filter
  bool _matchesDateFilter(dynamic pickupTimeStr) {
    // If no filter is selected or specific date is selected
    if (_selectedStatus == 'All' && _selectedDate == null) {
      return true;
    }
    
    try {
      // Parse the pickup time
      DateTime? pickupTime;
      if (pickupTimeStr != null) {
        pickupTime = DateTime.parse(pickupTimeStr.toString());
      } else {
        return false;
      }
      
      // If a specific date is selected
      if (_selectedDate != null) {
        return DateUtils.isSameDay(pickupTime, _selectedDate);
      }
      
      // Get current date at midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      switch (_selectedStatus) {
        case 'Today':
          return DateUtils.isSameDay(pickupTime, today);
        case 'This Week':
          // Calculate start of week (Sunday)
          final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          return pickupTime.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
                 pickupTime.isBefore(endOfWeek);
        case 'This Month':
          // Same month and year
          return pickupTime.month == today.month && pickupTime.year == today.year;
        default:
          return true;
      }
    } catch (e) {
      print('Error parsing date: $e');
      return false;
    }
  }
  
  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _searchController.text = '';
      _selectedStatus = 'All';
      _selectedDate = null;
    });
    _filterPickups();
  }

  Future<void> _handleCompletePickup(String pickupId, String donationId) async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      // Call the API to complete the pickup
      final response = await _pickupService.updatePickupStatus(
        pickupId: pickupId,
        status: 'Completed',
        restaurantId: widget.userData!['id'].toString(),
      );
      
      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the pickup requests
        await _fetchPickupRequests();
        
        // Add a small delay to ensure the UI has time to update
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Switch to the completed tab (index 2)
        if (mounted) {
          setState(() {
            _isLoading = false;
            _tabController.animateTo(2); // Switch to the completed tab
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to complete pickup');
      }
    } catch (e) {
      print('Error completing pickup: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing pickup: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAcceptPickup(String pickupId, String donationId) async {
    try {
      // Call the API to accept the pickup
      final response = await _pickupService.updatePickupStatus(
        pickupId: pickupId,
        status: 'Accepted',
        restaurantId: widget.userData!['id'].toString(),
      );
      
      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup request accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the pickup requests
        _fetchPickupRequests();
      } else {
        throw Exception(response['message'] ?? 'Failed to accept pickup request');
      }
    } catch (e) {
      print('Error accepting pickup request: $e');
      
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
    try {
      // Call the API to reject the pickup
      final response = await _pickupService.updatePickupStatus(
        pickupId: pickupId,
        status: 'Rejected',
        restaurantId: widget.userData!['id'].toString(),
      );
      
      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Refresh the pickup requests
        _fetchPickupRequests();
      } else {
        throw Exception(response['message'] ?? 'Failed to reject pickup request');
      }
    } catch (e) {
      print('Error rejecting pickup request: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting pickup request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPendingPickupsList() {
    if (_pendingPickupsByDonation.isEmpty) {
      return _buildEmptyState(
        'No Matching Requests',
        'No pickup requests match your search criteria',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPickupsByDonation.length,
      itemBuilder: (context, index) {
        final donationId = _pendingPickupsByDonation.keys.elementAt(index);
        final pickups = _pendingPickupsByDonation[donationId]!;
        
        // Get the first pickup to extract donation details
        final firstPickup = pickups.first;
        final donation = {
          'donation_id': firstPickup['donation_id'],
          'donation_name': firstPickup['donation_name'],
          'quantity': firstPickup['quantity'],
          'category': firstPickup['category'],
          'photo_url': firstPickup['photo_url'],
        };
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RestaurantPickupRequestCard(
            donation: donation,
            pickupRequests: pickups,
            onAccept: _handleAcceptPickup,
            onReject: _handleRejectPickup,
          ),
        );
      },
    );
  }

  Widget _buildPickupsList(List<Map<String, dynamic>> pickups, {required String status}) {
    if (pickups.isEmpty) {
      return _buildEmptyState(
        'No Matching Pickups',
        'No $status pickups match your search criteria',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pickups.length,
      itemBuilder: (context, index) {
        final pickup = pickups[index];
        
        // Extract donation details from the pickup
        final donation = {
          'donation_id': pickup['donation_id'],
          'donation_name': pickup['donation_name'],
          'quantity': pickup['quantity'],
          'category': pickup['category'],
          'photo_url': pickup['photo_url'],
        };
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RestaurantAcceptedPickupCard(
            donation: donation,
            pickup: pickup,
            onComplete: _handleCompletePickup,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (title.contains('No Matching')) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PamigayColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.filter_list_off, size: 18),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate filtered counts for each tab
    final int pendingCount = _pendingPickupsByDonation.length;
    final int pendingTotal = _allPendingPickupsByDonation.length;
    
    final int acceptedCount = _acceptedPickups.length;
    final int acceptedTotal = _allAcceptedPickups.length;
    
    final int completedCount = _completedPickups.length;
    final int completedTotal = _allCompletedPickups.length;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pickup Requests',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.grey[700],
            ),
            onPressed: _fetchPickupRequests,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
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
                  text: 'Pending ($pendingCount)',
                ),
                Tab(
                  text: 'Accepted ($acceptedCount)',
                ),
                Tab(
                  text: 'Completed ($completedCount)',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and filter bar
          SearchFilterBar(
            searchController: _searchController,
            selectedStatus: _selectedStatus,
            selectedDate: _selectedDate,
            statusOptions: _statusOptions,
            onSearchChanged: (value) => _filterPickups(),
            onStatusChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
              _filterPickups();
            },
            onDateChanged: (value) {
              setState(() {
                _selectedDate = value;
              });
              _filterPickups();
            },
            onClearFilters: _clearFilters,
            filteredCount: _tabController.index == 0
                ? pendingCount
                : _tabController.index == 1
                    ? acceptedCount
                    : completedCount,
            totalCount: _tabController.index == 0
                ? pendingTotal
                : _tabController.index == 1
                    ? acceptedTotal
                    : completedTotal,
            primaryColor: PamigayColors.primary,
          ),
          
          // Tab content - Wrap in SafeArea to prevent overflow
          Expanded(
            child: SafeArea(
              child: _isLoading
                  ? const ShimmerLoader(itemCount: 3)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Pending requests tab
                        _buildPendingPickupsList(),
                        
                        // Accepted pickups tab
                        _buildPickupsList(_acceptedPickups, status: 'Accepted'),
                        
                        // Completed pickups tab
                        _buildPickupsList(_completedPickups, status: 'Completed'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
