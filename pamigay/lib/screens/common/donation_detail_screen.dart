import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/services/pickup_service.dart';
import 'package:pamigay/components/modals/update_donation_modal.dart';
import 'package:pamigay/components/modals/delete_donation_modal.dart';
import 'package:pamigay/components/modals/request_pickup_modal.dart';
import 'package:pamigay/widgets/full_screen_image_viewer.dart';
import 'package:pamigay/widgets/status_card.dart';
import 'package:pamigay/widgets/detail_item.dart';

/// Screen to display detailed information about a specific donation.
///
/// This screen is used by both restaurants and organizations to view donation details.
/// The UI and actions available differ based on the user's role.
class DonationDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic> donation;
  /// Callback function when a donation is deleted
  final Function()? onDonationDeleted;

  const DonationDetailScreen({
    Key? key,
    required this.userData,
    required this.donation,
    this.onDonationDeleted,
  }) : super(key: key);

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  final DonationService _donationService = DonationService();
  final PickupService _pickupService = PickupService();
  late Map<String, dynamic> _donation;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _userRole = '';
  String _pickupWindowText = '';
  bool _hasRequestedPickup = false;
  Map<String, dynamic>? _existingPickup;

  @override
  void initState() {
    super.initState();
    _donation = Map<String, dynamic>.from(widget.donation);
    _userRole = widget.userData?['role'] ?? '';
    
    // Fetch complete donation details from API
    _fetchDonationDetails();
  }
  
  Future<void> _fetchDonationDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get donation ID
      final donationId = _donation['id']?.toString() ?? '';
      if (donationId.isEmpty) {
        throw Exception('Invalid donation ID');
      }
      
      // Fetch complete donation details from API
      final donationDetails = await _donationService.getDonationById(donationId);
      
      if (donationDetails != null) {
        setState(() {
          _donation = donationDetails;
          _isLoading = false;
        });
        
        // Format pickup window with the new data
        _formatPickupWindow();
        
        // Check if organization has already requested pickup for this donation
        if (_userRole == 'Organization') {
          _checkExistingPickupRequest();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch donation details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching donation details: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _formatPickupWindow() {
    try {
      final pickupWindowStartStr = _donation['pickup_window_start'] as String?;
      final pickupWindowEndStr = _donation['pickup_window_end'] as String?;
      
      if (pickupWindowStartStr != null && pickupWindowStartStr.isNotEmpty &&
          pickupWindowEndStr != null && pickupWindowEndStr.isNotEmpty) {
        
        final pickupWindowStart = DateTime.parse(pickupWindowStartStr);
        final pickupWindowEnd = DateTime.parse(pickupWindowEndStr);
        
        // If same day, simplify the display
        if (pickupWindowStart.year == pickupWindowEnd.year &&
            pickupWindowStart.month == pickupWindowEnd.month &&
            pickupWindowStart.day == pickupWindowEnd.day) {
          final dateFormat = DateFormat('MMM d, yyyy');
          final timeStartFormat = DateFormat('h:mm a');
          final timeEndFormat = DateFormat('h:mm a');
          
          _pickupWindowText = '${timeStartFormat.format(pickupWindowStart)} - ${timeEndFormat.format(pickupWindowEnd)}';
        } else {
          _pickupWindowText = '${DateFormat('MMM d, h:mm a').format(pickupWindowStart)} - ${DateFormat('MMM d, h:mm a').format(pickupWindowEnd)}';
        }
      } else {
        _pickupWindowText = 'Not specified';
      }
    } catch (e) {
      print('Error formatting pickup window: $e');
      _pickupWindowText = 'Not specified';
    }
  }

  void _refreshDonation() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get donation ID
      final donationId = _donation['id']?.toString() ?? '';
      if (donationId.isEmpty) {
        throw Exception('Invalid donation ID');
      }
      
      // Fetch complete donation details from API
      final donationDetails = await _donationService.getDonationById(donationId);
      
      if (donationDetails != null) {
        setState(() {
          _donation = donationDetails;
          _isRefreshing = false;
        });
        
        // Format pickup window with the new data
        _formatPickupWindow();
      } else {
        setState(() {
          _isRefreshing = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh donation details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error refreshing donation: $e');
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _checkExistingPickupRequest() async {
    if (widget.userData == null || widget.userData!['id'] == null) {
      return;
    }
    
    final organizationId = widget.userData!['id'].toString();
    final donationId = _donation['id'].toString();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get all pickups for this organization
      final pickups = await _pickupService.getMyPickups(organizationId);
      
      // Check if any pickup is for this donation
      for (final pickup in pickups) {
        if (pickup['donation_id'].toString() == donationId) {
          setState(() {
            _hasRequestedPickup = true;
            _existingPickup = pickup;
          });
          break;
        }
      }
    } catch (e) {
      print('Error checking existing pickup requests: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showUpdateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: UpdateDonationModal(
          donation: _donation,
          userData: widget.userData,
          onSuccess: () {
            Navigator.pop(context);
            _refreshDonation();
          },
        ),
      ),
    );
  }

  Future<void> _showDeleteModal() async {
    // Use the DeleteDonationModal component
    await DeleteDonationModal.show(
      context: context,
      userData: widget.userData!,
      donation: _donation,
      onSuccess: () {
        // Call the onDonationDeleted callback if provided
        if (widget.onDonationDeleted != null) {
          widget.onDonationDeleted!();
        }
        
        // Safely pop back to the previous screen
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrl: imageUrl,
          heroTag: 'donation_image_${_donation['id']}',
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return 'Not specified';
    }
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Pending Pickup':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Available':
        return Icons.check_circle;
      case 'Pending Pickup':
        return Icons.access_time;
      case 'Completed':
        return Icons.done_all;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'This donation is available for pickup by organizations';
      case 'pending':
        return 'This donation has pending pickup requests';
      case 'reserved':
        return 'This donation is reserved for pickup';
      case 'completed':
        return 'This donation has been successfully picked up';
      case 'expired':
        return 'This donation has expired and is no longer available';
      case 'canceled':
        return 'This donation has been canceled by the restaurant';
      default:
        return 'Status: $status';
    }
  }

  void _showRequestPickupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: RequestPickupModal(donation: _donation, userData: widget.userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationId = _donation['id'] ?? '';
    final donationName = _donation['name'] ?? 'Unnamed Donation';
    final quantity = _donation['quantity'] ?? 'Unknown quantity';
    final status = _donation['status'] ?? 'Unknown status';
    final category = _donation['category'] ?? 'Unknown category';
    final conditionStatus = _donation['condition_status'] ?? 'Unknown condition';
    final pickupDeadline = _formatDateTime(_donation['pickup_deadline']);
    final imageUrl = _donation['photo_url'] ?? _donation['image'];
    final restaurantName = _donation['restaurant_name'] ?? 'Unknown Restaurant';
    final restaurantLocation = _donation['restaurant_location'] ?? _donation['restaurant_address'] ?? 'Location not specified';
    final restaurantContact = _donation['restaurant_contact'] ?? _donation['restaurant_phone'] ?? 'Contact not specified';
    final description = _donation['description'] ?? 'No description available';
    final createdAt = _formatDateTime(_donation['created_at']);
    
    // Check if the user is the restaurant that posted this donation
    final isOwnDonation = _userRole == 'Restaurant' && 
                       widget.userData?['id']?.toString() == _donation['restaurant_id']?.toString();
    
    // Format pickup request status for organization view
    String pickupRequestStatus = '';
    if (_hasRequestedPickup && _existingPickup != null) {
      pickupRequestStatus = _existingPickup!['status'] ?? 'Unknown';
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 300));
                _refreshDonation();
                if (_userRole == 'Organization') {
                  _checkExistingPickupRequest();
                }
              },
              child: CustomScrollView(
                slivers: [
                  // App bar with image
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    backgroundColor: PamigayColors.primary,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      // Add the zoom button to the app bar actions
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.zoom_in, color: Colors.white),
                          tooltip: 'Zoom image',
                          onPressed: () => _showFullScreenImage(_donationService.getFullImageUrl(imageUrl)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _refreshDonation,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: imageUrl != null && imageUrl.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                GestureDetector(
                                  onTap: () => _showFullScreenImage(_donationService.getFullImageUrl(imageUrl)),
                                  child: Hero(
                                    tag: 'donation_image_$donationId',
                                    child: Image.network(
                                      _donationService.getFullImageUrl(imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 80,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Gradient overlay for better text visibility
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      stops: const [0.7, 1.0],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          donationName,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(1, 1),
                                                blurRadius: 3,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Quantity: $quantity',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(1, 1),
                                                blurRadius: 3,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              color: PamigayColors.primary,
                              child: const Icon(
                                Icons.fastfood,
                                size: 80,
                                color: Colors.white54,
                              ),
                            ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card - Combined status information
                        StatusCard(
                          status: _hasRequestedPickup ? 'Your Request: $pickupRequestStatus' : status,
                          statusColor: _hasRequestedPickup ? _getStatusColor(pickupRequestStatus) : _getStatusColor(status),
                          statusIcon: _hasRequestedPickup ? '🚚' : '📦',
                          description: _hasRequestedPickup 
                              ? 'You have already requested to pick up this donation.' 
                              : _getStatusDescription(status),
                          iconData: _hasRequestedPickup ? Icons.local_shipping : _getStatusIcon(status),
                          margin: EdgeInsets.zero,
                        ),

                        // Description section (if available)
                        if (description.isNotEmpty && description != 'No description available')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Description'),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Donation Details Card
                        Card(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Donation Details'),
                                const SizedBox(height: 12),

                                // Two-column layout for details
                                Row(
                                  children: [
                                    Expanded(
                                      child: DetailItem(
                                        icon: Icons.category,
                                        label: 'Category',
                                        value: category,
                                      ),
                                    ),
                                    Expanded(
                                      child: DetailItem(
                                        icon: Icons.health_and_safety,
                                        label: 'Condition',
                                        value: conditionStatus,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DetailItem(
                                  icon: Icons.inventory_2,
                                  label: 'Quantity',
                                  value: quantity,
                                  fullWidth: true,
                                ),
                                const SizedBox(height: 12),
                                DetailItem(
                                  icon: Icons.calendar_today,
                                  label: 'Created',
                                  value: createdAt,
                                  fullWidth: true,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Pickup Information Card
                        Card(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Pickup Information'),
                                const SizedBox(height: 12),
                                if (_donation['pickup_window_start'] != null &&
                                    _donation['pickup_window_end'] != null)
                                  DetailItem(
                                    icon: Icons.access_time,
                                    label: 'Pickup Window',
                                    value: _pickupWindowText,
                                  ),
                                if (_donation['pickup_deadline'] != null)
                                  DetailItem(
                                    icon: Icons.event_busy,
                                    label: 'Pickup Deadline',
                                    value: pickupDeadline,
                                    iconColor: Colors.orange,
                                  ),
                                if (_donation['pickup_instructions'] != null && 
                                    _donation['pickup_instructions'].toString().isNotEmpty)
                                  DetailItem(
                                    icon: Icons.info_outline,
                                    label: 'Instructions',
                                    value: _donation['pickup_instructions'],
                                    fullWidth: true,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Restaurant details section
                        Card(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Restaurant Information'),
                                const SizedBox(height: 12),
                                DetailItem(
                                  icon: Icons.restaurant,
                                  label: 'Restaurant Name',
                                  value: restaurantName,
                                ),
                                const SizedBox(height: 8),
                                DetailItem(
                                  icon: Icons.location_on,
                                  label: 'Location',
                                  value: restaurantLocation,
                                ),
                                const SizedBox(height: 8),
                                DetailItem(
                                  icon: Icons.phone,
                                  label: 'Contact',
                                  value: restaurantContact,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Your Pickup Request Details (if already requested)
                        if (_userRole == 'Organization' && _hasRequestedPickup && _existingPickup != null)
                          Card(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Your Pickup Request'),
                                  const SizedBox(height: 12),
                                  DetailItem(
                                    icon: Icons.access_time,
                                    label: 'Requested Pickup Time',
                                    value: _formatDateTime(_existingPickup!['pickup_time']),
                                  ),
                                  if (_existingPickup!['notes'] != null && _existingPickup!['notes'].toString().isNotEmpty)
                                    DetailItem(
                                      icon: Icons.note,
                                      label: 'Your Notes',
                                      value: _existingPickup!['notes'],
                                      fullWidth: true,
                                    ),
                                ],
                              ),
                            ),
                          ),

                        // Actions based on user role and donation status
                        if (_userRole == 'Restaurant')
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (_donation['status'] == 'Available')
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _showUpdateModal,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                        side: const BorderSide(color: Colors.blue),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                if (_donation['status'] == 'Available')
                                  const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showDeleteModal,
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_userRole == 'Organization')
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: _hasRequestedPickup
                                ? _existingPickup!['status'] == 'Requested'
                                    ? OutlinedButton.icon(
                                        onPressed: () async {
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
                                          
                                          if (confirm == true) {
                                            // Get organization ID
                                            final organizationId = widget.userData?['id']?.toString();
                                            if (organizationId == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Error: Organization ID not found'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }
                                            
                                            final result = await _pickupService.updatePickup(
                                              pickupId: _existingPickup!['id'].toString(),
                                              status: 'Cancelled',
                                            );
                                            
                                            if (result['success']) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Pickup request cancelled successfully'),
                                                  backgroundColor: PamigayColors.primary,
                                                ),
                                              );
                                              
                                              // Refresh the pickup status
                                              _checkExistingPickupRequest();
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to cancel pickup: ${result['message']}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.cancel),
                                        label: const Text('Cancel Pickup Request'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          minimumSize: const Size(double.infinity, 0),
                                        ),
                                      )
                                    : const SizedBox.shrink()
                                : (_donation['status'] == 'Available' || _donation['status'] == 'Pending Pickup')
                                    ? ElevatedButton.icon(
                                        onPressed: _showRequestPickupModal,
                                        icon: const Icon(Icons.shopping_basket),
                                        label: const Text('Request Pickup'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: PamigayColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          minimumSize: const Size(double.infinity, 0),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: PamigayColors.primary,
        fontFamily: 'Montserrat',
      ),
    );
  }
}
