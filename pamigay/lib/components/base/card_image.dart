import 'package:flutter/material.dart';
import 'package:pamigay/services/donation_service.dart';

/// A reusable component for displaying images in cards.
///
/// This component handles image loading, error states, and maintains
/// consistent styling for images across different card types.
class CardImage extends StatelessWidget {
  /// The URL of the image to display
  final String? imageUrl;
  
  /// The height of the image container
  final double height;
  
  /// The width of the image container (defaults to double.infinity)
  final double? width;
  
  /// How the image should be fitted within its container
  final BoxFit fit;

  const CardImage({
    Key? key,
    required this.imageUrl,
    this.height = 150,
    this.width,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create the service locally in the build method to avoid const constructor issues
    final donationService = DonationService();
    
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Image.network(
        donationService.getDonationImageUrl(imageUrl!),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder(loadingProgress);
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(ImageChunkEvent loadingProgress) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
