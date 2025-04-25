import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';

/// A base modal component that provides consistent styling and structure
/// for all modal dialogs in the application.
///
/// This component defines the common structure for modals, including headers,
/// content sections, and action buttons with consistent styling.
class BaseModal extends StatelessWidget {
  /// The title displayed in the modal header
  final String title;
  
  /// The content of the modal
  final Widget content;
  
  /// Optional custom header widget that replaces the default header
  final Widget? customHeader;
  
  /// Primary action button text
  final String? primaryButtonText;
  
  /// Primary action button callback
  final VoidCallback? onPrimaryButtonPressed;
  
  /// Whether the primary button is in a loading state
  final bool isPrimaryButtonLoading;
  
  /// Secondary action button text
  final String? secondaryButtonText;
  
  /// Secondary action button callback
  final VoidCallback? onSecondaryButtonPressed;
  
  /// Controls if the modal can be dismissed by clicking outside
  final bool isDismissible;
  
  /// Max width constraint for the modal
  final double maxWidth;
  
  /// The padding around the content
  final EdgeInsetsGeometry contentPadding;
  
  /// Whether to show a close button in the header
  final bool showCloseButton;
  
  /// Whether the modal has full-height content
  /// (useful for forms that might need scrolling)
  final bool hasFullHeightContent;

  const BaseModal({
    Key? key,
    required this.title,
    required this.content,
    this.customHeader,
    this.primaryButtonText,
    this.onPrimaryButtonPressed,
    this.isPrimaryButtonLoading = false,
    this.secondaryButtonText,
    this.onSecondaryButtonPressed,
    this.isDismissible = true,
    this.maxWidth = 500.0,
    this.contentPadding = const EdgeInsets.all(24.0),
    this.showCloseButton = true,
    this.hasFullHeightContent = false,
  }) : super(key: key);

  /// Factory constructor to create a simple dialog with 'OK' button
  factory BaseModal.info({
    required String title,
    required Widget content,
    String okButtonText = 'OK',
    VoidCallback? onOkPressed,
  }) {
    return BaseModal(
      title: title,
      content: content,
      primaryButtonText: okButtonText,
      onPrimaryButtonPressed: onOkPressed,
    );
  }

  /// Factory constructor to create a confirmation dialog with 'Yes' and 'No' buttons
  factory BaseModal.confirm({
    required String title,
    required Widget content,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Yes',
    String cancelText = 'No',
    bool isDismissible = true,
  }) {
    return BaseModal(
      title: title,
      content: content,
      primaryButtonText: confirmText,
      onPrimaryButtonPressed: onConfirm,
      secondaryButtonText: cancelText,
      onSecondaryButtonPressed: onCancel,
      isDismissible: isDismissible,
    );
  }

  /// Shows a base modal dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? primaryButtonText,
    VoidCallback? onPrimaryButtonPressed,
    bool isPrimaryButtonLoading = false,
    String? secondaryButtonText,
    VoidCallback? onSecondaryButtonPressed,
    bool isDismissible = true,
    double maxWidth = 500.0,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(24.0),
    bool showCloseButton = true,
    bool hasFullHeightContent = false,
    Widget? customHeader,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (BuildContext context) {
        return BaseModal(
          title: title,
          content: content,
          customHeader: customHeader,
          primaryButtonText: primaryButtonText,
          onPrimaryButtonPressed: onPrimaryButtonPressed,
          isPrimaryButtonLoading: isPrimaryButtonLoading,
          secondaryButtonText: secondaryButtonText,
          onSecondaryButtonPressed: onSecondaryButtonPressed,
          isDismissible: isDismissible,
          maxWidth: maxWidth,
          contentPadding: contentPadding,
          showCloseButton: showCloseButton,
          hasFullHeightContent: hasFullHeightContent,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: hasFullHeightContent ? 
              MediaQuery.of(context).size.height * 0.9 : double.infinity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Use custom header or default one
              customHeader ?? _buildHeader(context),
              
              // Content section, possibly scrollable
              hasFullHeightContent ?
                Expanded(
                  child: SingleChildScrollView(
                    padding: contentPadding,
                    child: content,
                  ),
                ) :
                Padding(
                  padding: contentPadding,
                  child: content,
                ),
              
              // Footer with action buttons
              if (primaryButtonText != null || secondaryButtonText != null)
                _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header section of the modal
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        color: PamigayColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PamigayColors.primary,
              ),
            ),
          ),
          if (showCloseButton)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 24,
            ),
        ],
      ),
    );
  }

  /// Builds the footer section with action buttons
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Secondary button (usually cancel or no)
          if (secondaryButtonText != null)
            OutlinedButton(
              onPressed: onSecondaryButtonPressed ?? () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(secondaryButtonText!),
            ),
            
          if (primaryButtonText != null && secondaryButtonText != null)
            const SizedBox(width: 12),
            
          // Primary button (usually submit, save, or yes)
          if (primaryButtonText != null)
            ElevatedButton(
              onPressed: isPrimaryButtonLoading ? null : onPrimaryButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: PamigayColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: isPrimaryButtonLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(primaryButtonText!),
            ),
        ],
      ),
    );
  }
}
