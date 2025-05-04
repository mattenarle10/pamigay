import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/components/cards/donation_card.dart';
import 'package:pamigay/screens/common/donation_detail_screen.dart';
import 'package:pamigay/components/search/search_filter_bar.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/screens/common/profile_screen.dart';

/// Organization-specific screen to view and filter available donations from restaurants.
///
/// This screen displays a list of available donations that organizations can
/// request for pickup.
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
        } else if (difference.inHours > 8) {
          timeRemaining = '${difference.inHours}h ${difference.inMinutes % 60}m';
          urgencyLevel = 'low';
        } else if (difference.inHours > 3) {
          timeRemaining = '${difference.inHours}h ${difference.inMinutes % 60}m';
          urgencyLevel = 'medium';
        } else if (difference.inHours > 0) {
          timeRemaining = '${difference.inHours}h ${difference.inMinutes % 60}m';
          urgencyLevel = 'high';
        } else if (difference.inMinutes > 0) {
          timeRemaining = '${difference.inMinutes}m';
          urgencyLevel = 'high';
        } else {
          timeRemaining = 'Expiring';
          urgencyLevel = 'high';
        }
        
        // Create a formatted version too
        String timeRemainingFormatted = '';
        if (difference.inDays > 0) {
          timeRemainingFormatted = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
        } else if (difference.inHours > 0) {
          timeRemainingFormatted = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
        } else if (difference.inMinutes > 0) {
          timeRemainingFormatted = '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
        } else {
          timeRemainingFormatted = 'Expiring soon';
        }
        
        // Update donation with calculated values
        final updatedDonation = Map<String, dynamic>.from(donation);
        updatedDonation['time_remaining'] = timeRemaining;
        updatedDonation['time_remaining_formatted'] = timeRemainingFormatted;
        updatedDonation['urgency_level'] = urgencyLevel;
        
        // Determine pickup window status
        final pickupWindowStartStr = donation['pickup_window_start'] as String?;
        final pickupWindowEndStr = donation['pickup_window_end'] as String?;
        
        if (pickupWindowStartStr != null && pickupWindowEndStr != null) {
          final pickupWindowStart = DateTime.parse(pickupWindowStartStr);
          final pickupWindowEnd = DateTime.parse(pickupWindowEndStr);
          
          if (now.isAfter(pickupWindowEnd)) {
            updatedDonation['pickup_window_status'] = 'expired';
          } else if (now.isAfter(pickupWindowStart) && now.isBefore(pickupWindowEnd)) {
            updatedDonation['pickup_window_status'] = 'active';
          } else {
            updatedDonation['pickup_window_status'] = 'upcoming';
          }
        }
        
        updatedDonations.add(updatedDonation);
      } catch (e) {
        // If there's an error processing a donation, just add it unchanged
        updatedDonations.add(donation);
      }
    }
    
    if (needsUpdate || updatedDonations.isNotEmpty) {
      if (mounted) {
        setState(() {
          _donations = updatedDonations;
          _applyFilters(); // Re-apply filters to the updated donations
        });
      }
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
    List<Map<String, dynamic>> result = _donations;
    
    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((donation) {
        final name = (donation['name'] ?? '').toLowerCase();
        final description = (donation['description'] ?? '').toLowerCase();
        final category = (donation['category'] ?? '').toLowerCase();
        final restaurantName = (donation['restaurant_name'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || 
               description.contains(query) || 
               category.contains(query) ||
               restaurantName.contains(query);
      }).toList();
    }
    
    // Apply status filter
    if (_selectedStatus != 'All') {
      result = result.where((donation) {
        final category = donation['category'] ?? '';
        
        if (_selectedStatus == 'Human Intake') {
          return category != 'Pet Food' && category != 'Animal Feed';
        } else if (_selectedStatus == 'Animal Intake') {
          return category == 'Pet Food' || category == 'Animal Feed';
        }
        
        return true;
      }).toList();
    }
    
    // Apply date filter
    if (_selectedDate != null) {
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      
      result = result.where((donation) {
        final deadlineStr = donation['pickup_deadline'] as String?;
        if (deadlineStr == null || deadlineStr.isEmpty) return false;
        
        try {
          final deadlineDate = DateTime.parse(deadlineStr);
          final deadlineDateStr = DateFormat('yyyy-MM-dd').format(deadlineDate);
          
          return deadlineDateStr == selectedDateStr;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    // Sort by urgency first, then by pickup deadline
    result.sort((a, b) {
      // First sort by urgency level
      final urgencyA = a['urgency_level'] ?? 'low';
      final urgencyB = b['urgency_level'] ?? 'low';
      
      // Convert urgency to numeric value for comparison
      int urgencyValueA = urgencyA == 'high' ? 3 : (urgencyA == 'medium' ? 2 : 1);
      int urgencyValueB = urgencyB == 'high' ? 3 : (urgencyB == 'medium' ? 2 : 1);
      
      int urgencyComparison = urgencyValueB.compareTo(urgencyValueA);
      if (urgencyComparison != 0) {
        return urgencyComparison;
      }
      
      // Then sort by pickup deadline
      final deadlineStrA = a['pickup_deadline'] as String?;
      final deadlineStrB = b['pickup_deadline'] as String?;
      
      if (deadlineStrA == null && deadlineStrB == null) return 0;
      if (deadlineStrA == null) return 1;
      if (deadlineStrB == null) return -1;
      
      try {
        final deadlineA = DateTime.parse(deadlineStrA);
        final deadlineB = DateTime.parse(deadlineStrB);
        return deadlineA.compareTo(deadlineB);
      } catch (e) {
        return 0;
      }
    });
    
    setState(() {
      _filteredDonations = result;
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
    final bool hasActiveFilters = _searchQuery.isNotEmpty || 
                               _selectedStatus != 'All' || 
                               _selectedDate != null;
    
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
                    'Available Donations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      // Refresh button
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        tooltip: 'Refresh donations',
                        onPressed: _fetchAvailableDonations,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Search and filter bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SearchFilterBar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onStatusChanged: _onStatusChanged,
                onDateChanged: _onDateChanged,
                statusOptions: _statusOptions,
                selectedStatus: _selectedStatus,
                selectedDate: _selectedDate,
                onClearFilters: _clearFilters,
                filteredCount: _filteredDonations.length,
                totalCount: _donations.length,
              ),
            ),
            
            // Donations list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
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
                          ),
                        )
                      : _filteredDonations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.no_food,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No available donations found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                    child: Text(
                                      'Check back later or adjust your filters to find available donations',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (hasActiveFilters)
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
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredDonations.length,
                                itemBuilder: (context, index) {
                                  final donation = _filteredDonations[index];
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
