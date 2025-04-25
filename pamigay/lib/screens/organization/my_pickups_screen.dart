import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/pickup_service.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/components/cards/pickup_card.dart';
import 'package:pamigay/screens/common/donation_detail_screen.dart';
import 'package:pamigay/components/search/search_filter_bar.dart';
import 'package:pamigay/components/notifications/notification_badge.dart';
import 'package:pamigay/screens/common/notifications_screen.dart';
import 'package:pamigay/components/loaders/shimmer_loader.dart';
import 'package:pamigay/screens/organization/available_donations_screen.dart';
import 'package:pamigay/screens/organization/home_screen.dart';
import 'package:pamigay/screens/common/profile_screen.dart';

/// Screen for organizations to view and manage their pickup requests.
///
/// This screen displays both pending and completed pickups, allowing
/// organizations to track their food rescue activities.
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
  List<Map<String, dynamic>> _filteredPendingPickups = [];
  List<Map<String, dynamic>> _filteredCompletedPickups = [];
  
  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  DateTime? _selectedDate;
  
  final List<String> _statusOptions = [
    'All',
    'Requested',
    'Accepted',
    'Completed',
    'Cancelled'
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPickups();
    
    // Listen for tab changes to apply filters correctly
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _applyFilters();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        _filteredPendingPickups = List.from(_pendingPickups);
        _filteredCompletedPickups = List.from(_completedPickups);
        _isLoading = false;
        _isRefreshing = false;
      });
      
      // Apply any existing filters
      _applyFilters();
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
      final donationId = pickup['donation_id']?.toString();
      if (donationId == null) {
        enhancedPickups.add(pickup);
        continue;
      }
      
      try {
        final donationDetails = await _donationService.getDonationById(donationId);
        
        if (donationDetails != null) {
          // Merge donation details with pickup
          final enhancedPickup = Map<String, dynamic>.from(pickup);
          enhancedPickup['donation_name'] = donationDetails['name'];
          enhancedPickup['donation_description'] = donationDetails['description'];
          enhancedPickup['donation_image'] = donationDetails['image'];
          enhancedPickup['restaurant_name'] = donationDetails['restaurant_name'];
          enhancedPickup['restaurant_id'] = donationDetails['restaurant_id'];
          enhancedPickup['pickup_window_start'] = donationDetails['pickup_window_start'];
          enhancedPickup['pickup_window_end'] = donationDetails['pickup_window_end'];
          
          enhancedPickups.add(enhancedPickup);
        } else {
          enhancedPickups.add(pickup);
        }
      } catch (e) {
        print('Error fetching donation details for pickup $donationId: $e');
        enhancedPickups.add(pickup);
      }
    }
    
    return enhancedPickups;
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _applyFilters();
  }

  void _onDateChanged(DateTime? date) {
    setState(() {
      _selectedDate = date;
    });
    _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedStatus = 'All';
      _selectedDate = null;
    });
    _applyFilters();
  }
  
  void _applyFilters() {
    if (!mounted) return;
    
    setState(() {
      // Filter pending pickups
      _filteredPendingPickups = _pendingPickups.where((pickup) {
        // Filter by search query
        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final donationName = (pickup['donation_name'] ?? '').toString().toLowerCase();
          final restaurantName = (pickup['restaurant_name'] ?? '').toString().toLowerCase();
          final pickupId = (pickup['id'] ?? '').toString().toLowerCase();
          
          matchesSearch = donationName.contains(searchLower) || 
                          restaurantName.contains(searchLower) ||
                          pickupId.contains(searchLower);
        }
        
        // Filter by status
        bool matchesStatus = true;
        if (_selectedStatus != 'All') {
          matchesStatus = (pickup['status'] ?? '') == _selectedStatus;
        }
        
        // Filter by date
        bool matchesDate = true;
        if (_selectedDate != null) {
          try {
            final pickupTime = DateTime.parse(pickup['pickup_time'] ?? '');
            final selectedDate = _selectedDate!;
            
            matchesDate = pickupTime.year == selectedDate.year &&
                          pickupTime.month == selectedDate.month &&
                          pickupTime.day == selectedDate.day;
          } catch (e) {
            matchesDate = false;
          }
        }
        
        return matchesSearch && matchesStatus && matchesDate;
      }).toList();
      
      // Filter completed pickups
      _filteredCompletedPickups = _completedPickups.where((pickup) {
        // Filter by search query
        bool matchesSearch = true;
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final donationName = (pickup['donation_name'] ?? '').toString().toLowerCase();
          final restaurantName = (pickup['restaurant_name'] ?? '').toString().toLowerCase();
          final pickupId = (pickup['id'] ?? '').toString().toLowerCase();
          
          matchesSearch = donationName.contains(searchLower) || 
                          restaurantName.contains(searchLower) ||
                          pickupId.contains(searchLower);
        }
        
        // Filter by status
        bool matchesStatus = true;
        if (_selectedStatus != 'All') {
          matchesStatus = (pickup['status'] ?? '') == _selectedStatus;
        }
        
        // Filter by date
        bool matchesDate = true;
        if (_selectedDate != null) {
          try {
            final pickupTime = DateTime.parse(pickup['pickup_time'] ?? '');
            final selectedDate = _selectedDate!;
            
            matchesDate = pickupTime.year == selectedDate.year &&
                          pickupTime.month == selectedDate.month &&
                          pickupTime.day == selectedDate.day;
          } catch (e) {
            matchesDate = false;
          }
        }
        
        return matchesSearch && matchesStatus && matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = _searchQuery.isNotEmpty || 
                               _selectedStatus != 'All' || 
                               _selectedDate != null;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Pickups',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          // Notification badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NotificationBadge(
              count: 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(userData: widget.userData),
                  ),
                );
              },
              iconSize: 24,
            ),
          ),
          // Refresh button
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.grey[600],
              size: 24,
            ),
            tooltip: 'Refresh pickups',
            onPressed: _fetchPickups,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: PamigayColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: PamigayColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: PamigayColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_filteredPendingPickups.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: PamigayColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('History'),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_filteredCompletedPickups.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Compact search bar (collapsible by default)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchFilterBar(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onStatusChanged: _onStatusChanged,
              onDateChanged: _onDateChanged,
              statusOptions: _statusOptions,
              selectedStatus: _selectedStatus,
              selectedDate: _selectedDate,
              onClearFilters: _clearFilters,
              filteredCount: _tabController.index == 0 
                ? _filteredPendingPickups.length 
                : _filteredCompletedPickups.length,
              totalCount: _tabController.index == 0 
                ? _pendingPickups.length 
                : _completedPickups.length,
              initiallyExpanded: false, // Keep filters collapsed by default
            ),
          ),
          
          // Tab content
          Expanded(
            child: _isLoading
              ? const ShimmerLoader(itemCount: 3, itemHeight: 150)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Pending pickups tab
                    _filteredPendingPickups.isEmpty
                      ? _buildEmptyState(
                          hasActiveFilters ? 'No Pickups Match Your Filters' : 'No Pending Pickups',
                          hasActiveFilters 
                            ? 'Try adjusting your search or filters to find what you\'re looking for'
                            : 'You don\'t have any scheduled or pending pickup requests',
                          hasActiveFilters,
                        )
                      : _buildPickupsList(_filteredPendingPickups, isPending: true),
                    
                    // Completed pickups tab
                    _filteredCompletedPickups.isEmpty
                      ? _buildEmptyState(
                          hasActiveFilters ? 'No Pickups Match Your Filters' : 'No Pickup History',
                          hasActiveFilters 
                            ? 'Try adjusting your search or filters to find what you\'re looking for'
                            : 'Your completed and cancelled pickups will appear here',
                          hasActiveFilters,
                        )
                      : _buildPickupsList(_filteredCompletedPickups, isPending: false),
                  ],
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String subtitle, [bool hasFilters = false]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_list : Icons.local_shipping_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasFilters)
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_list_off, size: 16),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PamigayColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else if (_tabController.index == 0)
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to available donations
                  Navigator.pushNamed(context, '/organization/available-donations');
                },
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Browse Donations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PamigayColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PickupCard(
              pickup: pickups[index],
              isPending: isPending,
              onCancel: _cancelPickup,
              onViewDetails: () {
                _viewDonationDetails(pickups[index]);
              },
            ),
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
      // Get organization ID
      final organizationId = widget.userData?['id']?.toString();
      if (organizationId == null) {
        throw Exception('Organization ID not found');
      }
      
      final result = await _pickupService.updatePickup(
        pickupId: pickupId,
        status: 'Cancelled',
        collectorId: organizationId,
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
