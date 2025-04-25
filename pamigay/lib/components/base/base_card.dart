import 'package:flutter/material.dart';

/// A base card component that provides consistent styling and structure
/// for all cards in the application.
///
/// This component defines the common structure for cards, including optional
/// header, image, content, and footer sections, with consistent styling.
class BaseCard extends StatelessWidget {
  /// The header widget to display at the top of the card
  final Widget? header;
  
  /// The image widget to display below the header
  final Widget? image;
  
  /// The main content widget of the card
  final Widget content;
  
  /// The footer widget to display at the bottom of the card
  final Widget? footer;
  
  /// Callback function when the card is tapped
  final VoidCallback? onTap;
  
  /// The card's elevation (shadow depth)
  final double elevation;
  
  /// The border radius for the card
  final BorderRadius borderRadius;
  
  /// The margin around the card
  final EdgeInsetsGeometry margin;

  /// Whether to clip the card content that extends beyond the card's bounds
  final Clip clipBehavior;

  const BaseCard({
    Key? key,
    this.header,
    this.image,
    required this.content,
    this.footer,
    this.onTap,
    this.elevation = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.clipBehavior = Clip.antiAlias,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: clipBehavior,
      margin: margin,
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) header!,
            if (image != null) image!,
            content,
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}
