import 'package:flutter/material.dart';
import 'package:pamigay/components/base/base_card.dart';
import 'package:pamigay/components/base/card_image.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/utils/date_formatter.dart';
import 'package:pamigay/widgets/status_badge.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/services/user_service.dart';

/// A card component for displaying accepted pickup requests for restaurants.
///
/// This component displays information about a donation and the organization
/// that has been accepted to pick it up.
class RestaurantAcceptedPickupCard extends StatelessWidget {
  /// The donation data to display
  final Map<String, dynamic> donation;
  
  /// The pickup data to display
  final Map<String, dynamic> pickup;
  
  /// Callback function when a pickup is marked as completed
  final Function(String pickupId, String donationId) onComplete;

  const RestaurantAcceptedPickupCard({
    Key? key,
    required this.donation,
    required this.pickup,
    required this.onComplete,
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
      header: _buildHeader(donationName, quantity, category),
      image: photoUrl != null && photoUrl.isNotEmpty 
          ? CardImage(imageUrl: donationService.getDonationImageUrl(photoUrl)) 
          : null,
      content: SizedBox(
        height: 300, // Fixed height to prevent overflow
        child: _buildContent(userService),
      ),
      footer: null,
    );
  }
  
  /// Builds the header section with donation details
  Widget _buildHeader(String donationName, String quantity, String category) {
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
          StatusBadge.forPickupStatus(pickup['status'] ?? 'Unknown'),
        ],
      ),
    );
  }
  
  /// Builds the content section with pickup details
  Widget _buildContent(UserService userService) {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      children: [
        _buildPickupRequestItem(pickup, userService),
      ],
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
    final status = pickup['status'] ?? 'Unknown';
    final notes = pickup['notes'] ?? '';
    
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                    mainAxisSize: MainAxisSize.min,
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
            
            const SizedBox(height: 12),
            
            // Pickup time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: PamigayColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: PamigayColors.primary,
                  ),
                  const SizedBox(width: 6),
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
            if (status == 'Accepted') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => onComplete(pickupId, donationId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PamigayColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.check_circle, size: 14),
                    label: const Text('Mark as Completed', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
