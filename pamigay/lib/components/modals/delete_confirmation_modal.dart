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

  const DeleteConfirmationModal({
    Key? key,
    required this.itemTitle,
    required this.itemType,
    required this.onConfirm,
    this.isLoading = false,
  }) : super(key: key);

  /// Shows the delete confirmation modal
  static Future<bool?> show({
    required BuildContext context,
    required String itemTitle,
    required String itemType,
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationModal(
        itemTitle: itemTitle,
        itemType: itemType,
        onConfirm: onConfirm,
        isLoading: isLoading,
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
        ],
      ),
      primaryButtonText: 'Delete',
      onPrimaryButtonPressed: onConfirm,
      isPrimaryButtonLoading: isLoading,
      secondaryButtonText: 'Cancel',
      onSecondaryButtonPressed: () => Navigator.of(context).pop(false),
    );
  }
}
