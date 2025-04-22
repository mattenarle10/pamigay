import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/components/donation_card.dart';
import 'package:pamigay/screens/donation_detail_screen.dart';
import 'package:pamigay/components/search_filter_bar.dart';
import 'package:intl/intl.dart';

class AvailableDonationsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const AvailableDonationsScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<AvailableDonationsScreen> createState() => _AvailableDonationsScreenState();
}

class _AvailableDonationsScreenState extends State<AvailableDonationsScreen> {
  final DonationService _donationService = DonationService();
  List<Map<String, dynamic>> _donations = [];
  List<Map<String, dynamic>> _filteredDonations = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _refreshTimer;
  DateTime _lastRefreshTime = DateTime.now();
  
  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  DateTime? _selectedDate;
  
  final List<String> _statusOptions = [
    'All',
    'Human Intake',
    'Animal Intake'
  ];
  
  @override
  void initState() {
    super.initState();
    _fetchAvailableDonations();
    
    // Set up a timer to refresh every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateTimeRemaining();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _fetchAvailableDonations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }
    
    try {
      final userId = widget.userData?['id'] ?? '';
      if (userId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'User information not available. Please try again.';
          });
        }
        return;
      }
      
      final donations = await _donationService.getAvailableDonations(userId);
      _lastRefreshTime = DateTime.now();
      
      if (mounted) {
        setState(() {
          _donations = donations;
          _filteredDonations = List.from(_donations);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error fetching available donations: $e';
        });
      }
    }
  }
  
  void _updateTimeRemaining() {
    if (!mounted) return;
    
    final now = DateTime.now();
    final timeSinceLastRefresh = now.difference(_lastRefreshTime);
    
    // If it's been more than 10 minutes since the last refresh, fetch new data
    if (timeSinceLastRefresh.inMinutes >= 10) {
      _fetchAvailableDonations();
      return;
    }
    
    bool needsUpdate = false;
    List<Map<String, dynamic>> updatedDonations = [];
    
    for (var donation in _donations) {
      try {
        final deadlineStr = donation['pickup_deadline'] as String?;
        if (deadlineStr == null || deadlineStr.isEmpty) {
          updatedDonations.add(donation);
          continue;
        }
        
        final deadline = DateTime.parse(deadlineStr);
        
        // If deadline has passed, mark for removal
        if (deadline.isBefore(now)) {
          needsUpdate = true;
          continue; // Skip this donation
        }
        
        // Calculate and update time remaining
        final difference = deadline.difference(now);
        String timeRemaining = '';
        String urgencyLevel = 'low';
        
        if (difference.inDays > 0) {
          timeRemaining = '${difference.inDays}d ${difference.inHours % 24}h';
          urgencyLevel = 'low';
        } else if (difference.inHours > 3) {
          timeRemaining = '${difference.inHours}h ${difference.inMinutes % 60}m';
          urgencyLevel = 'medium';
        } else {
          timeRemaining = '${difference.inHours}h ${difference.inMinutes % 60}m';
          urgencyLevel = 'high';
        }
        
        // Create a new map to avoid modifying the original
        Map<String, dynamic> updatedDonation = Map.from(donation);
        updatedDonation['time_remaining'] = timeRemaining;
        updatedDonation['time_remaining_formatted'] = timeRemaining;
        updatedDonation['urgency_level'] = urgencyLevel;
        
        // Update color based on urgency
        if (urgencyLevel == 'high') {
          updatedDonation['urgency_color'] = 0xFFFF3B30; // Red
        } else if (urgencyLevel == 'medium') {
          updatedDonation['urgency_color'] = 0xFFFF9500; // Orange
        } else {
          updatedDonation['urgency_color'] = 0xFF4CD964; // Green
        }
        
        updatedDonations.add(updatedDonation);
      } catch (e) {
        // Keep the original donation if there's an error
        updatedDonations.add(donation);
      }
    }
    
    if (needsUpdate || updatedDonations.length != _donations.length) {
      setState(() {
        _donations = updatedDonations;
        _applyFilters(); // This will update _filteredDonations
      });
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }
  
  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }
  
  void _onDateChanged(DateTime? date) {
    setState(() {
      _selectedDate = date;
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    setState(() {
      _filteredDonations = _donations.where((donation) {
        // Apply search query filter
        final name = donation['name']?.toString().toLowerCase() ?? '';
        final restaurantName = donation['restaurant_name']?.toString().toLowerCase() ?? '';
        final category = donation['category']?.toString().toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        
        final matchesSearch = _searchQuery.isEmpty || 
                             name.contains(searchLower) || 
                             restaurantName.contains(searchLower) ||
                             category.contains(searchLower);
        
        // Apply status filter (category filter)
        final donationCategory = donation['category'] ?? '';
        final matchesStatus = _selectedStatus == 'All' || donationCategory == _selectedStatus;
        
        // Apply date filter
        bool matchesDate = true;
        if (_selectedDate != null) {
          final pickupDeadline = donation['pickup_deadline'] ?? '';
          if (pickupDeadline.isNotEmpty) {
            try {
              final deadlineDate = DateTime.parse(pickupDeadline);
              matchesDate = deadlineDate.year == _selectedDate!.year && 
                           deadlineDate.month == _selectedDate!.month && 
                           deadlineDate.day == _selectedDate!.day;
            } catch (e) {
              matchesDate = false;
            }
          } else {
            matchesDate = false;
          }
        }
        
        return matchesSearch && matchesStatus && matchesDate;
      }).toList();
      
      // Sort by urgency (high to low) and then by pickup deadline (soonest first)
      _filteredDonations.sort((a, b) {
        // First sort by urgency level
        final urgencyOrder = {'high': 0, 'medium': 1, 'low': 2};
        final urgencyA = urgencyOrder[a['urgency_level'] ?? 'low'] ?? 2;
        final urgencyB = urgencyOrder[b['urgency_level'] ?? 'low'] ?? 2;
        
        if (urgencyA != urgencyB) {
          return urgencyA.compareTo(urgencyB);
        }
        
        // Then sort by pickup deadline
        try {
          final deadlineA = DateTime.parse(a['pickup_deadline'] ?? '');
          final deadlineB = DateTime.parse(b['pickup_deadline'] ?? '');
          return deadlineA.compareTo(deadlineB);
        } catch (e) {
          return 0;
        }
      });
    });
  }
  
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedStatus = 'All';
      _selectedDate = null;
      _filteredDonations = List.from(_donations);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Clean title with info icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Donations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Tooltip(
                    message: 'Donations with red timers are expiring soon!',
                    child: IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Donations with red timers are expiring soon and need immediate attention!',
                            ),
                            backgroundColor: PamigayColors.primary,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Search and filter bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchFilterBar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                statusOptions: _statusOptions,
                selectedStatus: _selectedStatus,
                onStatusChanged: _onStatusChanged,
                selectedDate: _selectedDate,
                onDateChanged: _onDateChanged,
                onClearFilters: _clearFilters,
                filteredCount: _filteredDonations.length,
                totalCount: _donations.length,
              ),
            ),
            // Donations list
            Expanded(
              child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: PamigayColors.primary,
                    ),
                  )
                : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchAvailableDonations,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PamigayColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : _filteredDonations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.no_food,
                              color: Colors.grey,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _donations.isEmpty
                                ? 'No available donations found'
                                : 'No donations match your filters',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),
                            if (_donations.isNotEmpty)
                              ElevatedButton(
                                onPressed: _clearFilters,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PamigayColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Clear Filters'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchAvailableDonations,
                        color: PamigayColors.primary,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDonations.length,
                          itemBuilder: (context, index) {
                            final donation = _filteredDonations[index];
                            // Add null check to ensure donation is not null
                            if (donation == null) {
                              return const SizedBox.shrink(); // Skip rendering if donation is null
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildAvailableDonationCard(donation),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvailableDonationCard(Map<String, dynamic> donation) {
    // Add restaurant information to the donation for display
    final restaurantName = donation['restaurant_name'] ?? 'Unknown Restaurant';
    final timeRemaining = donation['time_remaining_formatted'] ?? donation['time_remaining'] ?? '';
    final urgencyLevel = donation['urgency_level'] ?? 'low';
    final pickupWindowStatus = donation['pickup_window_status'] ?? 'unknown';
    
    // Determine color based on urgency
    Color timeColor;
    IconData timeIcon;
    
    if (urgencyLevel == 'high') {
      timeColor = Colors.red;
      timeIcon = Icons.alarm;
    } else if (urgencyLevel == 'medium') {
      timeColor = Colors.orange;
      timeIcon = Icons.access_time;
    } else {
      timeColor = Colors.green;
      timeIcon = Icons.timer;
    }
    
    // Determine pickup window status display
    String statusMessage;
    IconData statusIcon;
    Color statusColor;
    
    if (pickupWindowStatus == 'active') {
      statusMessage = 'Available now';
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else if (pickupWindowStatus == 'upcoming') {
      statusMessage = 'Available later';
      statusIcon = Icons.schedule;
      statusColor = Colors.blue;
    } else {
      statusMessage = 'Window expired';
      statusIcon = Icons.error;
      statusColor = Colors.grey;
    }
    
    return DonationCard(
      donation: donation,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonationDetailScreen(
              userData: widget.userData,
              donation: donation,
            ),
          ),
        ).then((_) => _fetchAvailableDonations());
      },
      // Add additional information for organization view
      additionalInfo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.restaurant, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  restaurantName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (timeRemaining.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(timeIcon, size: 14, color: timeColor),
                  const SizedBox(width: 4),
                  Text(
                    'Time left: $timeRemaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: timeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
