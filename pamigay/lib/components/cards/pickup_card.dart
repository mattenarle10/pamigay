import 'package:flutter/material.dart';
import 'package:pamigay/components/base/base_card.dart';
import 'package:pamigay/components/base/card_image.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/utils/date_formatter.dart';
import 'package:pamigay/widgets/status_badge.dart';

/// A card component for displaying pickup information.
/// 
/// This component has been refactored to use base components for better
/// code organization and reusability.
class PickupCard extends StatelessWidget {
  /// The pickup data to display
  final Map<String, dynamic> pickup;
  
  /// Whether the pickup is in a pending state
  final bool isPending;
  
  /// Callback function when the pickup is cancelled
  final Function(Map<String, dynamic>) onCancel;
  
  /// Callback function when the user wants to view pickup details
  final Function() onViewDetails;

  const PickupCard({
    Key? key,
    required this.pickup,
    required this.isPending,
    required this.onCancel,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract data from pickup
    final pickupId = pickup['id'] ?? 'N/A';
    final donationName = pickup['donation_name'] ?? 'Unknown Donation';
    final restaurantName = pickup['restaurant_name'] ?? 'Unknown Restaurant';
    final status = pickup['status'] ?? 'Unknown';
    final donationImage = pickup['donation_image'];
    final pickupTimeStr = DateFormatter.formatDateTime(pickup['pickup_time']);
    
    return BaseCard(
      header: _buildHeader(status, pickupId),
      image: donationImage != null ? CardImage(imageUrl: donationImage) : null,
      content: _buildContent(donationName, restaurantName, pickupTimeStr),
      footer: _buildFooter(context, status),
    );
  }

  /// Builds the header section of the card with status information
  Widget _buildHeader(String status, String pickupId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          StatusBadge.forPickupStatus(status),
          const Spacer(),
          Text(
            '#$pickupId',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main content section of the card
  Widget _buildContent(String donationName, String restaurantName, String pickupTimeStr) {
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
          const SizedBox(height: 8),
          
          // Restaurant name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 4),
          
          // Pickup time
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pickup: $pickupTimeStr',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          // Notes if available
          if (pickup['notes'] != null && pickup['notes'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pickup['notes'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the footer section of the card with action buttons
  Widget _buildFooter(BuildContext context, String status) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: isPending && status == 'Requested'
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => onCancel(pickup),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PamigayColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PamigayColors.primary,
                  side: BorderSide(color: PamigayColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Returns the appropriate color for a given pickup status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Requested':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
