import 'package:flutter/material.dart';

/// A reusable widget for displaying information in a row with an icon and text.
///
/// This component is used throughout the app to create consistent 
/// information displays with an icon followed by text.
class InfoRow extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// The text to display next to the icon
  final String text;
  
  /// The icon color (defaults to grey)
  final Color iconColor;
  
  /// The text color (defaults to dark grey)
  final Color? textColor;
  
  /// The icon size (defaults to 16)
  final double iconSize;
  
  /// The text style to apply
  final TextStyle? textStyle;
  
  /// The maximum number of lines for the text
  final int maxLines;
  
  /// How to handle text overflow
  final TextOverflow overflow;
  
  /// Whether to crossAlign at the start (useful for multi-line text)
  final bool crossAlignStart;
  
  /// Optional padding to apply to the row
  final EdgeInsetsGeometry? padding;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.text,
    this.iconColor = Colors.grey,
    this.textColor,
    this.iconSize = 16,
    this.textStyle,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.crossAlignStart = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rowWidget = Row(
      crossAxisAlignment: crossAlignStart 
          ? CrossAxisAlignment.start 
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textStyle ?? TextStyle(
              color: textColor ?? Colors.grey[700],
              fontSize: 14,
            ),
            maxLines: maxLines,
            overflow: overflow,
          ),
        ),
      ],
    );

    if (padding != null) {
      return Padding(
        padding: padding!,
        child: rowWidget,
      );
    }
    
    return rowWidget;
  }
}
