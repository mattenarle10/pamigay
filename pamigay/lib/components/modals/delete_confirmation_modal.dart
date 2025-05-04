import 'package:flutter/material.dart';
import 'package:pamigay/components/base/base_modal.dart';

/// A reusable confirmation modal for delete operations.
///
/// This modal provides a consistent way to confirm deletion actions
/// throughout the application.
class DeleteConfirmationModal extends StatelessWidget {
  /// The title of the item being deleted
  final String itemTitle;
  
  /// The type of item being deleted (e.g., "donation", "pickup request")
  final String itemType;
  
  /// Callback function when deletion is confirmed
  final VoidCallback onConfirm;
  
  /// Whether the confirmation is in progress
  final bool isLoading;

  /// Error message to display (if any)
  final String? errorMessage;

  const DeleteConfirmationModal({
    Key? key,
    required this.itemTitle,
    required this.itemType,
    required this.onConfirm,
    this.isLoading = false,
    this.errorMessage,
  }) : super(key: key);

  /// Shows the delete confirmation modal
  static Future<bool?> show({
    required BuildContext context,
    required String itemTitle,
    required String itemType,
    required VoidCallback onConfirm,
    bool isLoading = false,
    String? errorMessage,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationModal(
        itemTitle: itemTitle,
        itemType: itemType,
        onConfirm: onConfirm,
        isLoading: isLoading,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Confirm Deletion',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          
          // Warning text
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              children: [
                const TextSpan(
                  text: 'Are you sure you want to delete ',
                ),
                TextSpan(
                  text: itemType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' "',
                ),
                TextSpan(
                  text: itemTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: '"?',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Warning message
          const Text(
            'This action cannot be undone.',
            style: TextStyle(
              color: Colors.red,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          // Error message if provided
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      primaryButtonText: errorMessage != null ? 'OK' : 'Delete',
      onPrimaryButtonPressed: errorMessage != null 
          ? () => Navigator.of(context).pop(false) 
          : onConfirm,
      isPrimaryButtonLoading: isLoading,
      secondaryButtonText: errorMessage != null ? null : 'Cancel',
      onSecondaryButtonPressed: errorMessage != null 
          ? null 
          : () => Navigator.of(context).pop(false),
    );
  }
}
