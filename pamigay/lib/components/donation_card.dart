import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';

class DonationCard extends StatelessWidget {
  final Map<String, dynamic> donation;
  final Function() onTap;
  final DonationService _donationService = DonationService();
  final Widget? additionalInfo;
  final String? userRole;
  final String? userId;

  DonationCard({
    Key? key,
    required this.donation,
    required this.onTap,
    this.additionalInfo,
    this.userRole,
    this.userId,
  }) : super(key: key);

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract essential data from donation
    final donationName = donation['name'] ?? 'Unnamed Donation';
    final quantity = donation['quantity'] ?? 'Unknown quantity';
    final status = donation['status'] ?? 'Unknown status';
    final category = donation['category'] ?? 'Unknown category';
    final conditionStatus = donation['condition_status'] ?? 'Unknown condition';
    final pickupDeadline = _formatDateTime(donation['pickup_deadline']);
    final imageUrl = donation['photo_url'];
    final restaurantName = donation['restaurant_name'] ?? 'Unknown Restaurant';
    final restaurantId = donation['restaurant_id']?.toString() ?? '';
    
    // Extract time and urgency information
    final timeRemaining = donation['time_remaining'] ?? '';
    final urgencyLevel = donation['urgency'] ?? 'low';
    final pickupWindowStatus = donation['pickup_window_status'] ?? 'unknown';
    final pendingRequests = donation['pending_requests'] != null ? 
        int.tryParse(donation['pending_requests'].toString()) ?? 0 : 0;
    
    // Check if this is the restaurant's own donation
    final isOwnDonation = userRole == 'Restaurant' && userId == restaurantId;
    
    // Determine urgency color
    Color urgencyColor;
    switch (urgencyLevel) {
      case 'high':
        urgencyColor = Colors.red;
        break;
      case 'medium':
        urgencyColor = Colors.orange;
        break;
      default:
        urgencyColor = Colors.green;
    }
    
    // Determine pickup window status icon and color
    IconData statusIcon;
    Color statusColor;
    String statusMessage;
    
    switch (pickupWindowStatus) {
      case 'active':
        statusIcon = Icons.access_time;
        statusColor = Colors.green;
        statusMessage = 'Available now';
        break;
      case 'upcoming':
        statusIcon = Icons.event_available;
        statusColor = Colors.blue;
        statusMessage = 'Coming soon';
        break;
      case 'expired':
        statusIcon = Icons.event_busy;
        statusColor = Colors.red;
        statusMessage = 'Window expired';
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
        statusMessage = 'Unknown status';
    }
    
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                // Donation image
                if (imageUrl != null && imageUrl.toString().isNotEmpty)
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.network(
                      _donationService.getDonationImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.fastfood, color: PamigayColors.primary, size: 50),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.fastfood, color: PamigayColors.primary, size: 50),
                    ),
                  ),
                
                // Time remaining badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgencyColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          timeRemaining,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Pending requests badge (if any)
                if (pendingRequests > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '$pendingRequests ${pendingRequests == 1 ? 'request' : 'requests'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Category badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                
                // Condition badge
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: conditionStatus == 'Fresh' ? Colors.green : 
                             conditionStatus == 'Near Expiry' ? Colors.orange : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      conditionStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content section
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Restaurant name (only if not the restaurant's own donation)
                  if (!isOwnDonation) 
                    Row(
                      children: [
                        const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  
                  if (!isOwnDonation) 
                    const SizedBox(height: 4),
                  
                  // Quantity
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          quantity,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Pickup deadline
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Deadline: $pickupDeadline',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Additional info if provided
                  if (additionalInfo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: additionalInfo!,
                    ),
                  
                  // Status row at the bottom
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        // For restaurant's own donations, show actual status instead of window status
                        if (isOwnDonation) ...[
                          Icon(
                            status == 'Available' ? Icons.circle : 
                            status == 'Pending Pickup' ? Icons.access_time_filled : 
                            status == 'Completed' ? Icons.check_circle : Icons.cancel,
                            size: 16, 
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 8),
                          Text(
                            statusMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        
                        if (pendingRequests > 0) ...[
                          const Spacer(),
                          Text(
                            isOwnDonation ? 
                              '$pendingRequests pending ${pendingRequests == 1 ? 'request' : 'requests'}' :
                              '$pendingRequests ${pendingRequests == 1 ? 'organization' : 'organizations'} interested',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
