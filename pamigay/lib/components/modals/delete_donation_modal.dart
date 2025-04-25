import 'package:flutter/material.dart';
import 'package:pamigay/components/modals/delete_confirmation_modal.dart';
import 'package:pamigay/services/donation_service.dart';

/// A modal component for confirming and handling donation deletion.
///
/// This component uses the generic DeleteConfirmationModal and adds
/// donation-specific deletion logic.
class DeleteDonationModal extends StatefulWidget {
  /// The current user's data
  final Map<String, dynamic>? userData;
  
  /// The donation data to be deleted
  final Map<String, dynamic> donation;
  
  /// Callback function when deletion is successful
  final Function() onSuccess;
  
  /// Backward compatibility: Alternative name for onSuccess
  final Function()? onDelete;

  const DeleteDonationModal({
    Key? key,
    required this.userData,
    required this.donation,
    required this.onSuccess,
    this.onDelete, // For backward compatibility
  }) : super(key: key);

  /// Shows the delete donation modal
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> donation,
    required Function() onSuccess,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DeleteDonationModal(
        userData: userData,
        donation: donation,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<DeleteDonationModal> createState() => _DeleteDonationModalState();
}

class _DeleteDonationModalState extends State<DeleteDonationModal> {
  final _donationService = DonationService();
  bool _isDeleting = false;

  /// Handles the donation deletion process
  Future<void> _deleteDonation() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final userId = widget.userData?['id'] ?? '';
      final donationId = widget.donation['id'] ?? '';
      
      if (userId.isEmpty || donationId.isEmpty) {
        _showErrorSnackBar('User ID or Donation ID not found');
        return;
      }
      
      final result = await _donationService.deleteDonation(userId, donationId);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Donation deleted successfully')),
        );
        
        // Close modal and refresh list
        Navigator.pop(context);
        widget.onSuccess();
        // Call the onDelete callback if provided for backward compatibility
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to delete donation');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  /// Helper method to show error messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    
    if (mounted) {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationName = widget.donation['name'] ?? 'this donation';
    
    return DeleteConfirmationModal(
      itemTitle: donationName,
      itemType: 'donation',
      onConfirm: _deleteDonation,
      isLoading: _isDeleting,
    );
  }
}
