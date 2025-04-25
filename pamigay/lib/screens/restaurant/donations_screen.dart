import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/components/cards/donation_card.dart';
import 'package:pamigay/screens/common/donation_detail_screen.dart';
import 'package:pamigay/components/search/search_filter_bar.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/screens/restaurant/add_donation_screen.dart';

/// A screen for restaurants to view and manage their donations.
///
/// This screen displays a list of all donations created by the restaurant,
/// with filtering options for status, date, and search functionality.
class DonationsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const DonationsScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  final DonationService _donationService = DonationService();
  List<Map<String, dynamic>> _donations = [];
  List<Map<String, dynamic>> _filteredDonations = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  DateTime? _selectedDate;
  
  final List<String> _statusOptions = [
    'All',
    'Available',
    'Pending Pickup',
    'Completed',
    'Cancelled'
  ];
  
  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchDonations() async {
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
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'User information not available. Please try again.';
        });
        return;
      }
      
      final donations = await _donationService.getMyDonations(userId);
      
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
          _errorMessage = 'Error fetching donations: $e';
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
    setState(() {
      _filteredDonations = _donations.where((donation) {
        // Apply search query filter
        final name = donation['name']?.toString().toLowerCase() ?? '';
        final category = donation['category']?.toString().toLowerCase() ?? '';
        final condition = donation['condition_status']?.toString().toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();
        
        final matchesSearch = _searchQuery.isEmpty || 
                             name.contains(searchLower) || 
                             category.contains(searchLower) ||
                             condition.contains(searchLower);
        
        // Apply status filter
        final status = donation['status'] ?? '';
        final matchesStatus = _selectedStatus == 'All' || status == _selectedStatus;
        
        // Apply date filter
        bool matchesDate = true;
        if (_selectedDate != null) {
          final createdAt = donation['created_at'] ?? '';
          if (createdAt.isEmpty) {
            matchesDate = false;
          } else {
            try {
              final donationDate = DateTime.parse(createdAt);
              final selectedDate = _selectedDate!;
              
              // Compare year, month, and day only
              matchesDate = donationDate.year == selectedDate.year &&
                           donationDate.month == selectedDate.month &&
                           donationDate.day == selectedDate.day;
            } catch (e) {
              matchesDate = false;
            }
          }
        }
        
        return matchesSearch && matchesStatus && matchesDate;
      }).toList();
    });
  }
  
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
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
            // Clean title with add and refresh buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Donations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      // Add donation button
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: PamigayColors.primary,
                          size: 28,
                        ),
                        tooltip: 'Add new donation',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddDonationScreen(
                                userData: widget.userData,
                              ),
                            ),
                          ).then((_) => _fetchDonations());
                        },
                      ),
                      // Refresh button
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        tooltip: 'Refresh donations',
                        onPressed: _fetchDonations,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Search and filter bar
            SearchFilterBar(
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
                            onPressed: _fetchDonations,
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
                            const Icon(Icons.no_food, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _donations.isEmpty
                                ? 'You haven\'t created any donations yet'
                                : 'No donations match your filters',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (_donations.isEmpty)
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddDonationScreen(
                                        userData: widget.userData,
                                      ),
                                    ),
                                  ).then((_) => _fetchDonations());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PamigayColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Add Donation'),
                              ),
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
                        onRefresh: () async {
                          await _fetchDonations();
                        },
                        color: PamigayColors.primary,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDonations.length,
                          itemBuilder: (context, index) {
                            final donation = _filteredDonations[index];
                            // Use the DonationCard from components directory
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DonationCard(
                                donation: donation,
                                onTap: () {
                                  // Use a safer navigation approach with named routes
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => DonationDetailScreen(
                                        userData: widget.userData,
                                        donation: donation,
                                        onDonationDeleted: () {
                                          // This callback ensures we properly handle deletion
                                          // from the detail screen
                                          _fetchDonations();
                                        },
                                      ),
                                    ),
                                  ).then((_) {
                                    // Refresh donations when returning from detail screen
                                    _fetchDonations();
                                  }).catchError((error) {
                                    // Handle any navigation errors
                                    print('Navigation error: $error');
                                    _fetchDonations();
                                  });
                                },
                                userRole: widget.userData?['role'],
                                userId: widget.userData?['id'],
                              ),
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
}
