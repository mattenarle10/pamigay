import 'package:flutter/material.dart';
import 'package:pamigay/components/base/base_card.dart';
import 'package:pamigay/components/base/card_image.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/utils/date_formatter.dart';
import 'package:pamigay/widgets/status_badge.dart';

/// A card component for displaying donation information.
///
/// This component has been refactored to use base components for better
/// code organization and reusability.
class DonationCard extends StatelessWidget {
  /// The donation data to display
  final Map<String, dynamic> donation;
  
  /// Callback function when the card is tapped
  final Function() onTap;
  
  /// Additional information widget to display below main content
  final Widget? additionalInfo;
  
  /// The role of the current user
  final String? userRole;
  
  /// The ID of the current user
  final String? userId;

  const DonationCard({
    Key? key,
    required this.donation,
    required this.onTap,
    this.additionalInfo,
    this.userRole,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract essential data from donation
    final donationName = donation['name'] ?? 'Unnamed Donation';
    final quantity = donation['quantity'] ?? 'Unknown quantity';
    final status = donation['status'] ?? 'Unknown status';
    final category = donation['category'] ?? 'Unknown category';
    final conditionStatus = donation['condition_status'] ?? 'Unknown condition';
    final pickupDeadline = DateFormatter.formatDateTime(donation['pickup_deadline']);
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
    
    // If it's the restaurant's own donation, use "Your Donation" instead of the restaurant name
    final displayRestaurantName = isOwnDonation ? "" : restaurantName;
    
    return BaseCard(
      onTap: onTap,
      image: _buildImageSection(imageUrl, urgencyLevel, status, isOwnDonation, displayRestaurantName, timeRemaining),
      content: _buildContentSection(
        donationName, 
        quantity, 
        category,
        conditionStatus,
        pickupDeadline,
        displayRestaurantName,
        additionalInfo,
      ),
      footer: _buildFooterSection(
        isOwnDonation,
        status,
        pickupWindowStatus,
        pendingRequests,
      ),
    );
  }

  /// Builds the image section of the card
  Widget _buildImageSection(
    String? imageUrl, 
    String urgencyLevel, 
    String status, 
    bool isOwnDonation,
    String restaurantName,
    String timeRemaining,
  ) {
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
    
    return Stack(
      children: [
        // Donation image
        if (imageUrl != null && imageUrl.toString().isNotEmpty)
          CardImage(imageUrl: imageUrl)
        else
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.restaurant,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
          ),
        
        // Restaurant name overlay
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              restaurantName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        
        // Urgency indicator
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  urgencyLevel == 'high' ? Icons.alarm_on : 
                  urgencyLevel == 'medium' ? Icons.timelapse : 
                  Icons.access_time,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  timeRemaining.isNotEmpty ? timeRemaining : urgencyLevel.toUpperCase(),
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
        
        // Status label for restaurant's own donations
        if (isOwnDonation)
          Positioned(
            bottom: 12,
            right: 12,
            child: StatusBadge.forDonationStatus(status),
          ),
      ],
    );
  }

  /// Builds the content section of the card
  Widget _buildContentSection(
    String donationName,
    String quantity,
    String category,
    String conditionStatus,
    String pickupDeadline,
    String restaurantName,
    Widget? additionalInfo,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donation name
          Text(
            donationName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Donation details
          Row(
            children: [
              // Quantity
              Expanded(
                child: _buildInfoItem(
                  Icons.inventory_2,
                  'Quantity: $quantity',
                ),
              ),
              
              // Category
              Expanded(
                child: _buildInfoItem(
                  Icons.category,
                  'Category: $category',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Condition status
          _buildInfoItem(
            Icons.health_and_safety,
            'Condition: $conditionStatus',
          ),
          const SizedBox(height: 4),
          
          // Pickup deadline
          _buildInfoItem(
            Icons.event,
            'Deadline: $pickupDeadline',
          ),
          
          // Additional info if provided
          if (additionalInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: additionalInfo,
            ),
        ],
      ),
    );
  }

  /// Builds the footer section of the card
  Widget _buildFooterSection(
    bool isOwnDonation,
    String status,
    String pickupWindowStatus,
    int pendingRequests,
  ) {
    // Determine pickup window status
    Widget? statusWidget;
    if (!isOwnDonation) {
      // For non-restaurant users, show pickup window status
      statusWidget = StatusBadge.forPickupWindowStatus(pickupWindowStatus);
    } else {
      // For restaurant's own donations, don't show status here (already shown in image section)
      statusWidget = null;
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          if (statusWidget != null) statusWidget,
          
          if (pendingRequests > 0) ...[
            if (statusWidget != null) const Spacer(),
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
    );
  }

  /// Helper method to build an info item with icon and text
  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
