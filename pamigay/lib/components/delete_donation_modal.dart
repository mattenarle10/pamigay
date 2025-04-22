import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/widgets/custom_button.dart';

class DeleteDonationModal extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> donation;
  final Function() onSuccess;

  const DeleteDonationModal({
    Key? key,
    required this.userData,
    required this.donation,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<DeleteDonationModal> createState() => _DeleteDonationModalState();
}

class _DeleteDonationModalState extends State<DeleteDonationModal> {
  final _donationService = DonationService();
  bool _isDeleting = false;
  String _errorMessage = '';

  Future<void> _deleteDonation() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = '';
    });

    try {
      final userId = widget.userData['id'] ?? '';
      final donationId = widget.donation['id'] ?? '';
      
      if (userId.isEmpty || donationId.isEmpty) {
        setState(() {
          _errorMessage = 'User ID or Donation ID not found';
          _isDeleting = false;
        });
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
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to delete donation';
          _isDeleting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationName = widget.donation['name'] ?? 'this donation';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            'Delete Donation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PamigayColors.primary,
              fontFamily: 'Montserrat',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Warning icon
          Icon(
            Icons.warning_amber_rounded,
            size: 60,
            color: Colors.amber[700],
          ),
          
          const SizedBox(height: 16),
          
          // Confirmation text
          Text(
            'Are you sure you want to delete "$donationName"?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Montserrat',
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Montserrat',
            ),
          ),
          
          // Error message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: PamigayColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Delete button
              Expanded(
                child: ElevatedButton(
                  onPressed: _isDeleting ? null : _deleteDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
