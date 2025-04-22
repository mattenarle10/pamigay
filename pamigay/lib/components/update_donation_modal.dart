import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:pamigay/widgets/custom_button.dart';
import 'package:pamigay/widgets/custom_text_field.dart';
import 'package:pamigay/widgets/category_selector.dart';
import 'package:pamigay/widgets/date_time_picker.dart';

class UpdateDonationModal extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> donation;
  final Function() onSuccess;

  const UpdateDonationModal({
    Key? key,
    required this.userData,
    required this.donation,
    required this.onSuccess,
  }) : super(key: key);

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
  
  Future<void> _updateDonation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
        _errorMessage = '';
      });

      try {
        // Get user ID and donation ID
        final userId = widget.userData['id'] ?? '';
        final donationId = widget.donation['id'] ?? '';
        
        if (userId.isEmpty || donationId.isEmpty) {
          setState(() {
            _errorMessage = 'User ID or Donation ID not found';
            _isUpdating = false;
          });
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

        // Update donation
        final result = await _donationService.updateDonation(donationData);
        
        setState(() {
          _isUpdating = false;
        });

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Donation updated successfully!'))
          );
          
          // Close modal and refresh list
          Navigator.pop(context);
          widget.onSuccess();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to update donation';
          });
        }
      } catch (e) {
        setState(() {
          _isUpdating = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Update Donation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: PamigayColors.primary,
                  fontFamily: 'Montserrat',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          const Divider(),
          
          // Error message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
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
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Donation name (read-only)
                    Text(
                      widget.donation['name'] ?? 'Unnamed Donation',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quantity
                    CustomTextField(
                      controller: _quantityController,
                      label: 'Quantity',
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRadioOption('Fresh'),
                        _buildRadioOption('Near Expiry'),
                        _buildRadioOption('Expired'),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category
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
                    
                    // Pickup Window
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
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Update button
          CustomButton(
            text: 'Update Donation',
            onPressed: _updateDonation,
            isLoading: _isUpdating,
          ),
        ],
      ),
    );
  }
  
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
  
  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
}
