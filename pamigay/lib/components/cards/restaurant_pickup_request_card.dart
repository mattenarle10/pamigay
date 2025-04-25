import 'package:flutter/material.dart';
import 'package:pamigay/components/base/base_card.dart';
import 'package:pamigay/components/base/card_image.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/utils/date_formatter.dart';
import 'package:pamigay/widgets/status_badge.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/services/user_service.dart';

/// A card component for displaying pickup requests for restaurants.
///
/// This component displays information about a donation and the organizations
/// that have requested to pick it up.
class RestaurantPickupRequestCard extends StatelessWidget {
  /// The donation data to display
  final Map<String, dynamic> donation;
  
  /// The list of pickup requests for this donation
  final List<Map<String, dynamic>> pickupRequests;
  
  /// Callback function when a pickup request is accepted
  final Function(String pickupId, String donationId) onAccept;
  
  /// Callback function when a pickup request is rejected
  final Function(String pickupId, String donationId) onReject;

  const RestaurantPickupRequestCard({
    Key? key,
    required this.donation,
    required this.pickupRequests,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create services
    final donationService = DonationService();
    final userService = UserService();
    
    // Extract donation data
    final donationId = donation['donation_id'].toString();
    final donationName = donation['donation_name'] ?? 'Unknown Donation';
    final quantity = donation['quantity'] ?? '';
    final category = donation['category'] ?? '';
    final photoUrl = donation['photo_url'];
    
    return BaseCard(
      header: _buildHeader(donationName, quantity, category, pickupRequests.length),
      image: photoUrl != null && photoUrl.isNotEmpty 
          ? CardImage(imageUrl: donationService.getDonationImageUrl(photoUrl)) 
          : null,
      content: _buildContent(userService),
      footer: null,
    );
  }
  
  /// Builds the header section with donation details
  Widget _buildHeader(String donationName, String quantity, String category, int requestCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PamigayColors.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                if (quantity.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.scale,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        quantity,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (category.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PamigayColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$requestCount ${requestCount == 1 ? 'request' : 'requests'}',
              style: TextStyle(
                color: PamigayColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the content section with pickup requests
  Widget _buildContent(UserService userService) {
    return Column(
      children: pickupRequests.map((pickup) => _buildPickupRequestItem(pickup, userService)).toList(),
    );
  }
  
  /// Builds a single pickup request item
  Widget _buildPickupRequestItem(Map<String, dynamic> pickup, UserService userService) {
    final pickupId = pickup['id'].toString();
    final donationId = pickup['donation_id'].toString();
    final organizationName = pickup['organization_name'] ?? 'Unknown Organization';
    final organizationPhone = pickup['organization_phone'] ?? 'No phone provided';
    final organizationLocation = pickup['organization_location'];
    final pickupTime = pickup['pickup_time'] != null
        ? DateFormatter.formatDateTime(pickup['pickup_time'])
        : 'No time specified';
    final notes = pickup['notes'] ?? '';
    final collectorId = pickup['collector_id'];
    
    // Get organization profile image if available
    final organizationImage = pickup['organization_profile_image'];
    final hasProfileImage = organizationImage != null && organizationImage.toString().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization header with profile image
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Organization profile image or default icon
              hasProfileImage
                ? CircleAvatar(
                    radius: 22.5,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(userService.getProfileImageUrl(organizationImage)),
                  )
                : Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.business,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ),
              const SizedBox(width: 12),
              
              // Organization details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            organizationPhone,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (organizationLocation != null && organizationLocation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              organizationLocation,
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
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Pickup time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: PamigayColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: PamigayColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  pickupTime,
                  style: TextStyle(
                    color: PamigayColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Notes
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 14,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => onReject(pickupId, donationId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Reject', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => onAccept(pickupId, donationId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PamigayColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Accept', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
