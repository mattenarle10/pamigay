import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';

/// A shimmer loading effect component for displaying placeholder content while data is loading.
/// 
/// This component creates a shimmer animation effect on placeholder cards to indicate
/// that content is being loaded.
class ShimmerLoader extends StatelessWidget {
  /// Number of shimmer items to display
  final int itemCount;
  
  /// Height of each shimmer item
  final double itemHeight;
  
  /// Whether to show a circular avatar in the shimmer
  final bool showAvatar;
  
  /// Padding around each shimmer item
  final EdgeInsets padding;

  const ShimmerLoader({
    Key? key,
    this.itemCount = 3,
    this.itemHeight = 100,
    this.showAvatar = false,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildShimmerItem(),
        );
      },
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      height: itemHeight,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
        children: [
          // Header
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          
          // Content area - use Expanded to prevent overflow
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
                children: [
                  // Title and subtitle
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  
                  const SizedBox(height: 8), // Use fixed height instead of Spacer
                  
                  // Footer buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 24, // Reduced height
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 24, // Reduced height
                        width: 90,
                        decoration: BoxDecoration(
                          color: PamigayColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
