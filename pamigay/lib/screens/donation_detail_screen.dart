import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/components/update_donation_modal.dart';
import 'package:pamigay/components/delete_donation_modal.dart';
import 'package:pamigay/components/request_pickup_modal.dart';
import 'package:pamigay/widgets/full_screen_image_viewer.dart';
import 'package:pamigay/widgets/status_card.dart';
import 'package:pamigay/widgets/detail_item.dart';

class DonationDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic> donation;

  const DonationDetailScreen({
    Key? key,
    required this.userData,
    required this.donation,
  }) : super(key: key);

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  final DonationService _donationService = DonationService();
  late Map<String, dynamic> _donation;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _userRole = '';
  String _pickupWindowText = '';

  @override
  void initState() {
    super.initState();
    _donation = Map<String, dynamic>.from(widget.donation);
    _userRole = widget.userData?['role'] ?? '';
    _formatPickupWindow();
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
      final userId = widget.userData?['id'] ?? '';
      if (userId.isEmpty) {
        setState(() {
          _isRefreshing = false;
        });
        return;
      }

      final donations = await _donationService.getMyDonations(userId);
      final updatedDonation = donations.firstWhere(
        (d) => d['id'].toString() == _donation['id'].toString(),
        orElse: () => _donation,
      );

      setState(() {
        _donation = updatedDonation;
        _isRefreshing = false;
      });
      
      // Update pickup window text with new donation data
      _formatPickupWindow();
    } catch (e) {
      print('Error refreshing donation: $e');
      setState(() {
        _isRefreshing = false;
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
          userData: widget.userData!,
          donation: _donation,
          onSuccess: _refreshDonation,
        ),
      ),
    );
  }

  void _showDeleteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DeleteDonationModal(
          userData: widget.userData!,
          donation: _donation,
          onSuccess: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrl: imageUrl,
          heroTag: 'donation_image_${_donation['id']}',
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMMM d, yyyy • h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Pending Pickup':
        return Colors.amber;
      case 'Completed':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Available':
        return '🟢';
      case 'Pending Pickup':
        return '🕒';
      case 'Completed':
        return '✅';
      case 'Cancelled':
        return '❌';
      default:
        return '⚪';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'Available':
        return 'This donation is available for pickup';
      case 'Pending Pickup':
        final pendingRequests = _donation['pending_requests'] != null ? 
            int.tryParse(_donation['pending_requests'].toString()) ?? 0 : 0;
        return pendingRequests > 0 
            ? 'This donation has $pendingRequests pending pickup ${pendingRequests == 1 ? 'request' : 'requests'}'
            : 'A pickup has been requested for this donation';
      case 'Completed':
        return 'This donation has been successfully picked up';
      case 'Cancelled':
        return 'This donation has been cancelled';
      default:
        return 'Status unknown';
    }
  }

  void _showRequestPickupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestPickupModal(
        userData: widget.userData,
        donation: _donation,
        onSuccess: _refreshDonation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationName = _donation['name'] ?? 'Unnamed Donation';
    final quantity = _donation['quantity'] ?? 'Unknown quantity';
    final status = _donation['status'] ?? 'Unknown status';
    final category = _donation['category'] ?? 'Unknown category';
    final conditionStatus = _donation['condition_status'] ?? 'Unknown condition';
    final pickupDeadline = _formatDateTime(_donation['pickup_deadline']);
    final pickupWindowStart = _formatDateTime(_donation['pickup_window_start']);
    final pickupWindowEnd = _formatDateTime(_donation['pickup_window_end']);
    final photoUrl = _donationService.getDonationImageUrl(_donation['photo_url']);
    final createdAt = _formatDateTime(_donation['created_at']);
    final isAvailable = status == 'Available';
    final isPendingPickup = status == 'Pending Pickup';

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _refreshDonation();
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar with Image
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    backgroundColor: PamigayColors.primary,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      // Add the zoom button to the app bar actions
                      IconButton(
                        icon: const Icon(Icons.zoom_in, color: Colors.white),
                        tooltip: 'Zoom image',
                        onPressed: () => _showFullScreenImage(photoUrl),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: photoUrl.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                GestureDetector(
                                  onTap: () => _showFullScreenImage(photoUrl),
                                  child: Hero(
                                    tag: 'donation_image_${_donation['id']}',
                                    child: Image.network(
                                      photoUrl,
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
                        // Status Card
                        StatusCard(
                          status: status,
                          statusColor: _getStatusColor(status),
                          statusIcon: _getStatusIcon(status),
                          description: _getStatusDescription(status),
                        ),

                        // Donation Details Card
                        Card(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                                if (_donation['pickup_window_end'] != null)
                                  DetailItem(
                                    icon: Icons.event_busy,
                                    label: 'Pickup Deadline',
                                    value: _formatDateTime(_donation['pickup_window_end']),
                                    iconColor: PamigayColors.primary,
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
                        else if (_userRole == 'Organization' &&
                            (_donation['status'] == 'Available' || _donation['status'] == 'Pending Pickup'))
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ElevatedButton.icon(
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
                            ),
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
