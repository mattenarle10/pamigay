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
  List<Map<String, dynamic>> _requestedPickups = [];
  List<Map<String, dynamic>> _activePickups = [];
  List<Map<String, dynamic>> _historyPickups = [];
  List<Map<String, dynamic>> _filteredRequestedPickups = [];
  List<Map<String, dynamic>> _filteredActivePickups = [];
  List<Map<String, dynamic>> _filteredHistoryPickups = [];
  
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
    // Create a new TabController with length 3 to match the 3 tabs
    _tabController = TabController(length: 3, vsync: this);
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
    // Properly dispose of the TabController
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
      
      // Separate into requested, active, and history
      final requested = <Map<String, dynamic>>[];
      final active = <Map<String, dynamic>>[];
      final history = <Map<String, dynamic>>[];
      
      for (final pickup in enhancedPickups) {
        final status = pickup['status'] as String? ?? '';
        
        // Categorize based on status
        if (status == 'Requested') {
          // Check if the donation is still available
          final donationStatus = pickup['donation_status'] as String? ?? '';
          
          // Only add to requested if the donation is still available
          if (donationStatus != 'Cancelled' && donationStatus != 'Completed') {
            requested.add(pickup);
          } else {
            // If donation is no longer available, treat as cancelled
            pickup['status'] = 'Cancelled';
            history.add(pickup);
          }
        } else if (status == 'Accepted') {
          active.add(pickup);
        } else if (status == 'Completed' || status == 'Cancelled') {
          history.add(pickup);
        }
      }
      
      // Sort by date (newest first)
      requested.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      active.sort((a, b) {
        final aDate = DateTime.tryParse(a['pickup_time'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['pickup_time'] ?? '') ?? DateTime.now();
        return aDate.compareTo(bDate); // Sort by pickup time (soonest first)
      });
      
      history.sort((a, b) {
        final aDate = DateTime.tryParse(a['updated_at'] ?? a['created_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['updated_at'] ?? b['created_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      setState(() {
        _requestedPickups = requested;
        _activePickups = active;
        _historyPickups = history;
        
        // Initialize filtered lists
        _filteredRequestedPickups = List.from(requested);
        _filteredActivePickups = List.from(active);
        _filteredHistoryPickups = List.from(history);
        
        _isLoading = false;
        _isRefreshing = false;
        
        // Apply filters to update the filtered lists
        _applyFilters();
      });
    } catch (e) {
      print('Error fetching pickups: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
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
    // Get current tab
    final currentTab = _tabController.index;
    
    // Apply search query filter
    List<Map<String, dynamic>> filteredRequested = List.from(_requestedPickups);
    List<Map<String, dynamic>> filteredActive = List.from(_activePickups);
    List<Map<String, dynamic>> filteredHistory = List.from(_historyPickups);
    
    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      
      filteredRequested = filteredRequested.where((pickup) {
        final donationName = (pickup['donation_name'] ?? '').toString().toLowerCase();
        final restaurantName = (pickup['restaurant_name'] ?? '').toString().toLowerCase();
        final notes = (pickup['notes'] ?? '').toString().toLowerCase();
        
        return donationName.contains(query) || 
               restaurantName.contains(query) || 
               notes.contains(query);
      }).toList();
      
      filteredActive = filteredActive.where((pickup) {
        final donationName = (pickup['donation_name'] ?? '').toString().toLowerCase();
        final restaurantName = (pickup['restaurant_name'] ?? '').toString().toLowerCase();
        final notes = (pickup['notes'] ?? '').toString().toLowerCase();
        
        return donationName.contains(query) || 
               restaurantName.contains(query) || 
               notes.contains(query);
      }).toList();
      
      filteredHistory = filteredHistory.where((pickup) {
        final donationName = (pickup['donation_name'] ?? '').toString().toLowerCase();
        final restaurantName = (pickup['restaurant_name'] ?? '').toString().toLowerCase();
        final notes = (pickup['notes'] ?? '').toString().toLowerCase();
        
        return donationName.contains(query) || 
               restaurantName.contains(query) || 
               notes.contains(query);
      }).toList();
    }
    
    // Apply status filter
    if (_selectedStatus != 'All') {
      // For the Requested tab, we only show Requested status
      // For the Active tab, we only show Accepted status
      // For the History tab, we can filter by Completed or Cancelled
      if (currentTab == 2) { // History tab
        filteredHistory = filteredHistory.where((pickup) {
          return pickup['status'] == _selectedStatus;
        }).toList();
      }
    }
    
    // Apply date filter
    if (_selectedDate != null) {
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      
      filteredRequested = filteredRequested.where((pickup) {
        final pickupDate = pickup['created_at'] != null 
            ? DateTime.tryParse(pickup['created_at'])
            : null;
        
        if (pickupDate != null) {
          final pickupDateStr = DateFormat('yyyy-MM-dd').format(pickupDate);
          return pickupDateStr == selectedDateStr;
        }
        return false;
      }).toList();
      
      filteredActive = filteredActive.where((pickup) {
        final pickupDate = pickup['pickup_time'] != null 
            ? DateTime.tryParse(pickup['pickup_time'])
            : null;
        
        if (pickupDate != null) {
          final pickupDateStr = DateFormat('yyyy-MM-dd').format(pickupDate);
          return pickupDateStr == selectedDateStr;
        }
        return false;
      }).toList();
      
      filteredHistory = filteredHistory.where((pickup) {
        final pickupDate = pickup['updated_at'] != null 
            ? DateTime.tryParse(pickup['updated_at'])
            : pickup['created_at'] != null
                ? DateTime.tryParse(pickup['created_at'])
                : null;
        
        if (pickupDate != null) {
          final pickupDateStr = DateFormat('yyyy-MM-dd').format(pickupDate);
          return pickupDateStr == selectedDateStr;
        }
        return false;
      }).toList();
    }
    
    setState(() {
      _filteredRequestedPickups = filteredRequested;
      _filteredActivePickups = filteredActive;
      _filteredHistoryPickups = filteredHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 16.0,
          toolbarHeight: 48.0,
          title: const Text(
            'My Pickups',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: NotificationBadge(
                count: 0,
                onTap: () {},
                showZeroBadge: false,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(
                      userData: widget.userData,
                    ),
                  ),
                );
              },
              color: Colors.black,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1.0,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: PamigayColors.primary,
                labelColor: PamigayColors.primary,
                unselectedLabelColor: Colors.grey[600],
                indicatorWeight: 3.0,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                labelPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                tabs: [
                  _buildTabLabel('Requested', _requestedPickups.length),
                  _buildTabLabel('Active', _activePickups.length),
                  _buildTabLabel('History', _historyPickups.length),
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
              onSearchChanged: _onSearchChanged,
              onStatusChanged: _onStatusChanged,
              onDateChanged: _onDateChanged,
              onClearFilters: _clearFilters,
              statusOptions: _tabController.index == 2 
                  ? _statusOptions.where((s) => s == 'All' || s == 'Completed' || s == 'Cancelled').toList()
                  : ['All'],
              selectedStatus: _selectedStatus,
              selectedDate: _selectedDate,
              filteredCount: _getCurrentFilteredCount(),
              totalCount: _getCurrentTotalCount(),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Requested pickups tab
                  _isLoading
                      ? ShimmerLoader(
                          itemCount: 3,
                          itemHeight: 160,
                          padding: const EdgeInsets.all(16),
                        )
                      : _requestedPickups.isEmpty
                          ? _buildEmptyState(
                              'No Requested Pickups',
                              'You don\'t have any pending pickup requests.',
                              false,
                            )
                          : _filteredRequestedPickups.isEmpty
                              ? _buildEmptyState(
                                  'No Results Found',
                                  'No pickups match your filters.',
                                  true,
                                )
                              : _buildPickupsList(_filteredRequestedPickups, isPending: true),
                  
                  // Active pickups tab
                  _isLoading
                      ? ShimmerLoader(
                          itemCount: 3,
                          itemHeight: 160,
                          padding: const EdgeInsets.all(16),
                        )
                      : _activePickups.isEmpty
                          ? _buildEmptyState(
                              'No Active Pickups',
                              'You don\'t have any accepted pickup requests.',
                              false,
                            )
                          : _filteredActivePickups.isEmpty
                              ? _buildEmptyState(
                                  'No Results Found',
                                  'No pickups match your filters.',
                                  true,
                                )
                              : _buildPickupsList(_filteredActivePickups, isPending: true),
                  
                  // History pickups tab
                  _isLoading
                      ? ShimmerLoader(
                          itemCount: 3,
                          itemHeight: 160,
                          padding: const EdgeInsets.all(16),
                        )
                      : _historyPickups.isEmpty
                          ? _buildEmptyState(
                              'No Pickup History',
                              'Your completed and cancelled pickups will appear here.',
                              false,
                            )
                          : _filteredHistoryPickups.isEmpty
                              ? _buildEmptyState(
                                  'No Results Found',
                                  'No pickups match your filters.',
                                  true,
                                )
                              : _buildPickupsList(_filteredHistoryPickups, isPending: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build tab labels with count badges
  Widget _buildTabLabel(String title, int count) {
    final color = title == 'Requested' 
        ? PamigayColors.primary 
        : Colors.grey[700]!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods to get current filtered and total counts based on tab
  int _getCurrentFilteredCount() {
    switch (_tabController.index) {
      case 0:
        return _filteredRequestedPickups.length;
      case 1:
        return _filteredActivePickups.length;
      case 2:
        return _filteredHistoryPickups.length;
      default:
        return 0;
    }
  }
  
  int _getCurrentTotalCount() {
    switch (_tabController.index) {
      case 0:
        return _requestedPickups.length;
      case 1:
        return _activePickups.length;
      case 2:
        return _historyPickups.length;
      default:
        return 0;
    }
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
              onCancel: isPending ? _cancelPickup : null,
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
