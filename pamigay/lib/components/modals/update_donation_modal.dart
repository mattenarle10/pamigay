import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/components/base/base_modal.dart';
import 'package:pamigay/components/forms/form_input_field.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/widgets/category_selector.dart';
import 'package:pamigay/widgets/date_time_picker.dart';

/// A modal component for updating donation information.
///
/// This component has been refactored to use the BaseModal component
/// for better code organization and reusability.
class UpdateDonationModal extends StatefulWidget {
  /// The current user's data
  final Map<String, dynamic>? userData;
  
  /// The donation data to be updated
  final Map<String, dynamic> donation;
  
  /// Callback function when update is successful
  final Function() onSuccess;
  
  /// Backward compatibility: Alternative name for onSuccess
  final Function()? onUpdate;

  const UpdateDonationModal({
    Key? key,
    required this.userData,
    required this.donation,
    required this.onSuccess,
    this.onUpdate, // For backward compatibility
  }) : super(key: key);

  /// Shows the update donation modal
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> donation,
    required Function() onSuccess,
  }) {
    return showDialog(
      context: context,
      builder: (context) => UpdateDonationModal(
        userData: userData,
        donation: donation,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<UpdateDonationModal> createState() => _UpdateDonationModalState();
}

class _UpdateDonationModalState extends State<UpdateDonationModal> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _donationService = DonationService();
  
  DateTime _pickupDeadline = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _pickupWindowStart = TimeOfDay.now();
  TimeOfDay _pickupWindowEnd = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2);
  
  String _conditionStatus = 'Fresh';
  String _category = 'Human Intake';
  bool _isUpdating = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _initializeFormValues();
  }
  
  /// Initialize form values from the donation data
  void _initializeFormValues() {
    // Set initial values from the donation data
    _quantityController.text = widget.donation['quantity'] ?? '';
    _conditionStatus = widget.donation['condition_status'] ?? 'Fresh';
    _category = widget.donation['category'] ?? 'Human Intake';
    
    // Parse pickup deadline
    if (widget.donation['pickup_deadline'] != null) {
      try {
        _pickupDeadline = DateTime.parse(widget.donation['pickup_deadline']);
      } catch (e) {
        print('Error parsing pickup deadline: $e');
      }
    }
    
    // Parse pickup window start
    if (widget.donation['pickup_window_start'] != null) {
      try {
        final startDateTime = DateTime.parse(widget.donation['pickup_window_start']);
        _pickupWindowStart = TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute);
      } catch (e) {
        print('Error parsing pickup window start: $e');
      }
    }
    
    // Parse pickup window end
    if (widget.donation['pickup_window_end'] != null) {
      try {
        final endDateTime = DateTime.parse(widget.donation['pickup_window_end']);
        _pickupWindowEnd = TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);
      } catch (e) {
        print('Error parsing pickup window end: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
  
  /// Update the donation with the form values
  Future<void> _updateDonation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
        _errorMessage = '';
      });

      try {
        // Get user ID and donation ID
        final userId = widget.userData?['id'] ?? '';
        final donationId = widget.donation['id'] ?? '';
        
        if (userId.isEmpty || donationId.isEmpty) {
          _showErrorMessage('User ID or Donation ID not found');
          return;
        }

        // Prepare donation data
        final donationData = {
          'restaurant_id': userId,
          'donation_id': donationId,
          'quantity': _quantityController.text,
          'condition_status': _conditionStatus,
          'category': _category,
          'pickup_deadline': DateFormat('yyyy-MM-dd HH:mm:ss').format(_pickupDeadline),
          'pickup_window_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(
            DateTime(
              _pickupDeadline.year,
              _pickupDeadline.month,
              _pickupDeadline.day,
              _pickupWindowStart.hour,
              _pickupWindowStart.minute,
            )
          ),
          'pickup_window_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(
            DateTime(
              _pickupDeadline.year,
              _pickupDeadline.month,
              _pickupDeadline.day,
              _pickupWindowEnd.hour,
              _pickupWindowEnd.minute,
            )
          ),
        };
        
        // Validate pickup window time range
        if (_timeToMinutes(_pickupWindowEnd) <= _timeToMinutes(_pickupWindowStart)) {
          _showErrorMessage('Pickup window end time must be after start time');
          return;
        }

        // Call update API
        final result = await _donationService.updateDonation(donationData);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Donation updated successfully')),
          );
          
          setState(() {
            _isUpdating = false;
          });
            
          if (mounted) {
            Navigator.of(context).pop();
            
            // Call both callbacks for backward compatibility
            widget.onSuccess();
            if (widget.onUpdate != null) {
              widget.onUpdate!();
            }
          }
        } else {
          _showErrorMessage(result['message'] ?? 'Failed to update donation');
        }
      } catch (e) {
        _showErrorMessage('Error: ${e.toString()}');
      }
    }
  }
  
  /// Helper method to display error messages
  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _isUpdating = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationName = widget.donation['name'] ?? 'Unnamed Donation';
    
    return BaseModal(
      title: 'Update Donation',
      hasFullHeightContent: true,
      isPrimaryButtonLoading: _isUpdating,
      primaryButtonText: 'Update Donation',
      onPrimaryButtonPressed: _updateDonation,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donation name (non-editable)
            Text(
              donationName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PamigayColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Error message (if any)
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
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
            
            // Quantity field
            FormInputField(
              controller: _quantityController,
              labelText: 'Quantity',
              hintText: 'Enter quantity (e.g. 2 kg, 3 servings)',
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the quantity';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Condition Status
            const Text(
              'Condition Status:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: [
                _buildRadioOption('Fresh'),
                _buildRadioOption('Near Expiry'),
                _buildRadioOption('Expired'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Category selector
            const Text(
              'Category:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            CategorySelector(
              selectedValue: _category,
              onCategorySelected: (category) {
                setState(() {
                  _category = category;
                });
              },
              categories: const ['Human Intake', 'Animal Intake'],
            ),
            
            const SizedBox(height: 16),
            
            // Pickup window selector
            const Text(
              'Pickup Details:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            PickupWindowSelector(
              selectedDate: _pickupDeadline,
              startTime: _pickupWindowStart,
              endTime: _pickupWindowEnd,
              onDateSelected: (date) {
                setState(() {
                  _pickupDeadline = date;
                });
              },
              onStartTimeSelected: (time) {
                setState(() {
                  _pickupWindowStart = time;
                  // If end time is before start time, adjust it
                  if (_timeToMinutes(_pickupWindowEnd) < _timeToMinutes(_pickupWindowStart)) {
                    _pickupWindowEnd = TimeOfDay(
                      hour: _pickupWindowStart.hour + 2,
                      minute: _pickupWindowStart.minute,
                    );
                  }
                });
              },
              onEndTimeSelected: (time) {
                setState(() {
                  _pickupWindowEnd = time;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Helper method to build a radio option for condition status
  Widget _buildRadioOption(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _conditionStatus,
          onChanged: (newValue) {
            setState(() {
              _conditionStatus = newValue!;
            });
          },
          activeColor: PamigayColors.primary,
        ),
        Text(value),
      ],
    );
  }
  
  /// Helper method to convert TimeOfDay to minutes for comparison
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
}
