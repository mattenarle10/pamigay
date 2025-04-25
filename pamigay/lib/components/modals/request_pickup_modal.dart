import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/components/base/base_modal.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/utils/date_formatter.dart';
import 'package:pamigay/services/pickup_service.dart';
import 'package:pamigay/screens/organization/my_pickups_screen.dart';
import 'package:pamigay/screens/common/dashboard_screen.dart';

/// A modal component for requesting pickup of a donation.
///
/// This component has been refactored to use the BaseModal component for
/// better code organization and reusability.
class RequestPickupModal extends StatefulWidget {
  /// The data of the current user
  final Map<String, dynamic>? userData;
  
  /// The donation data for which pickup is being requested
  final Map<String, dynamic> donation;
  
  /// Callback function when pickup request is successful
  final Function? onSuccess;

  const RequestPickupModal({
    Key? key,
    required this.userData,
    required this.donation,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<RequestPickupModal> createState() => _RequestPickupModalState();
}

class _RequestPickupModalState extends State<RequestPickupModal> {
  final PickupService _pickupService = PickupService();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedPickupTime;
  bool _isSubmitting = false;
  
  // Pickup window details
  DateTime? _pickupWindowStart;
  DateTime? _pickupWindowEnd;
  String _pickupWindowText = '';
  bool _isSameDay = false;
  
  @override
  void initState() {
    super.initState();
    _parsePickupWindow();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  /// Parses the pickup window information from the donation
  void _parsePickupWindow() {
    try {
      final pickupWindowStartStr = widget.donation['pickup_window_start'] as String?;
      final pickupWindowEndStr = widget.donation['pickup_window_end'] as String?;
      
      if (pickupWindowStartStr != null && pickupWindowStartStr.isNotEmpty) {
        _pickupWindowStart = DateTime.parse(pickupWindowStartStr);
      }
      if (pickupWindowEndStr != null && pickupWindowEndStr.isNotEmpty) {
        _pickupWindowEnd = DateTime.parse(pickupWindowEndStr);
      }
      
      if (_pickupWindowStart != null && _pickupWindowEnd != null) {
        _pickupWindowText = DateFormatter.formatDateTimeWindow(
          pickupWindowStartStr, 
          pickupWindowEndStr
        );
        
        // Check if same day
        _isSameDay = _pickupWindowStart!.year == _pickupWindowEnd!.year &&
                    _pickupWindowStart!.month == _pickupWindowEnd!.month &&
                    _pickupWindowStart!.day == _pickupWindowEnd!.day;
      }
    } catch (e) {
      print('Error parsing pickup window: $e');
      _pickupWindowText = 'Not specified';
    }
  }

  /// Opens a time picker dialog to select the pickup time
  Future<void> _selectPickupTime() async {
    if (_pickupWindowStart == null || _pickupWindowEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup window not specified for this donation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // For same-day pickup windows, we only need to select the time
    if (_isSameDay) {
      // Determine allowed time range
      TimeOfDay minTime = TimeOfDay(hour: _pickupWindowStart!.hour, minute: _pickupWindowStart!.minute);
      TimeOfDay maxTime = TimeOfDay(hour: _pickupWindowEnd!.hour, minute: _pickupWindowEnd!.minute);
      
      // If start time is in the past, use current time as min
      final now = DateTime.now();
      if (_pickupWindowStart!.year == now.year && 
          _pickupWindowStart!.month == now.month && 
          _pickupWindowStart!.day == now.day) {
        if (now.hour > _pickupWindowStart!.hour || 
            (now.hour == _pickupWindowStart!.hour && now.minute >= _pickupWindowStart!.minute)) {
          minTime = TimeOfDay(hour: now.hour, minute: now.minute);
        }
      }
      
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: minTime,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: PamigayColors.primary,
              ),
              timePickerTheme: TimePickerThemeData(
                dayPeriodTextColor: PamigayColors.primary,
                dayPeriodColor: PamigayColors.primary.withOpacity(0.1),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        // Validate that picked time is within allowed range
        final pickupDate = DateTime(
          _pickupWindowStart!.year,
          _pickupWindowStart!.month,
          _pickupWindowStart!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        if (pickupDate.isBefore(_pickupWindowStart!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected time is before the pickup window start time'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (pickupDate.isAfter(_pickupWindowEnd!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected time is after the pickup window end time'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        setState(() {
          _selectedPickupTime = pickupDate;
        });
      }
    } else {
      // For multi-day windows, show date picker first
      final now = DateTime.now();
      DateTime firstAllowedDate;
      
      // If start date is in the past, use today as the first allowed date
      if (_pickupWindowStart!.isBefore(now)) {
        firstAllowedDate = DateTime(now.year, now.month, now.day);
      } else {
        firstAllowedDate = _pickupWindowStart!;
      }
      
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: firstAllowedDate,
        firstDate: firstAllowedDate,
        lastDate: _pickupWindowEnd!,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: PamigayColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedDate != null) {
        // Now show time picker
        TimeOfDay minTime = TimeOfDay(hour: 0, minute: 0);
        TimeOfDay maxTime = TimeOfDay(hour: 23, minute: 59);
        
        // If selected date is the start date, use start time as minimum
        if (pickedDate.year == _pickupWindowStart!.year &&
            pickedDate.month == _pickupWindowStart!.month &&
            pickedDate.day == _pickupWindowStart!.day) {
          minTime = TimeOfDay(hour: _pickupWindowStart!.hour, minute: _pickupWindowStart!.minute);
        }
        
        // If selected date is the end date, use end time as maximum
        if (pickedDate.year == _pickupWindowEnd!.year &&
            pickedDate.month == _pickupWindowEnd!.month &&
            pickedDate.day == _pickupWindowEnd!.day) {
          maxTime = TimeOfDay(hour: _pickupWindowEnd!.hour, minute: _pickupWindowEnd!.minute);
        }
        
        // If selected date is today, ensure we don't allow times in the past
        final now = DateTime.now();
        if (pickedDate.year == now.year &&
            pickedDate.month == now.month &&
            pickedDate.day == now.day) {
          if (now.hour > minTime.hour || 
              (now.hour == minTime.hour && now.minute > minTime.minute)) {
            minTime = TimeOfDay(hour: now.hour, minute: now.minute);
          }
        }
        
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: minTime,
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: PamigayColors.primary,
                ),
                timePickerTheme: TimePickerThemeData(
                  dayPeriodTextColor: PamigayColors.primary,
                  dayPeriodColor: PamigayColors.primary.withOpacity(0.1),
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (pickedTime != null) {
          final pickupDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          
          // Final validation
          if (pickupDateTime.isBefore(_pickupWindowStart!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected time is before the pickup window start time'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          if (pickupDateTime.isAfter(_pickupWindowEnd!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected time is after the pickup window end time'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          setState(() {
            _selectedPickupTime = pickupDateTime;
          });
        }
      }
    }
  }

  /// Submits the pickup request to the server
  Future<void> _submitPickupRequest() async {
    if (_selectedPickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (widget.userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final organizationId = widget.userData!['id'];
      final donationId = widget.donation['id'];
      final notes = _notesController.text.trim();
      
      final result = await _pickupService.requestPickup(
        organizationId: organizationId,
        donationId: donationId,
        pickupTime: DateFormat("yyyy-MM-dd HH:mm:ss").format(_selectedPickupTime!),
        notes: notes,
      );
      
      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        String errorMessage = result['message'] ?? 'Failed to request pickup';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Shows a success dialog after the pickup request is submitted
  void _showSuccessDialog() {
    BaseModal.show(
      context: context,
      title: 'Pickup Requested',
      isDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success illustration
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          
          // Success text
          const Text(
            'Your pickup request has been submitted successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Details
          Text(
            'You have requested to pick up "${widget.donation['name']}" from ${widget.donation['restaurant_name']} on ${DateFormat('MMMM d, yyyy').format(_selectedPickupTime!)} at ${DateFormat('h:mm a').format(_selectedPickupTime!)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Next steps
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Steps:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildNextStepItem(
                  '1',
                  'Wait for the restaurant to confirm your request.',
                ),
                const SizedBox(height: 4),
                _buildNextStepItem(
                  '2',
                  'Once confirmed, arrive at the restaurant at the scheduled time.',
                ),
                const SizedBox(height: 4),
                _buildNextStepItem(
                  '3',
                  'Bring appropriate containers if needed.',
                ),
              ],
            ),
          ),
        ],
      ),
      primaryButtonText: 'View My Pickups',
      onPrimaryButtonPressed: () {
        // Close the modal and success dialog
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        
        // Call the success callback
        widget.onSuccess?.call();
        
        // Navigate to my pickups screen through the dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(initialIndex: 2), // 2 is the index for My Pickups
          ),
          (route) => false, // Remove all previous routes
        );
      },
      secondaryButtonText: 'Done',
      onSecondaryButtonPressed: () {
        // Close the modal and success dialog
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        
        // Call the success callback
        widget.onSuccess?.call();
      },
    );
  }

  /// Helper method to build a next step item in the success dialog
  Widget _buildNextStepItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: PamigayColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationName = widget.donation['name'] ?? 'Unknown Donation';
    final restaurantName = widget.donation['restaurant_name'] ?? 'Unknown Restaurant';
    
    return BaseModal(
      title: 'Request Pickup',
      hasFullHeightContent: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donation information
          Text(
            donationName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PamigayColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From: $restaurantName',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          
          // Pickup window information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Pickup Window:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: PamigayColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickupWindowText,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Pickup Details section
          const Text(
            'Pickup Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pickup time selection
          const Text(
            'When would you like to pick up this donation?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectPickupTime,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedPickupTime == null
                        ? 'Select pickup time'
                        : _isSameDay
                              ? DateFormat('h:mm a').format(_selectedPickupTime!)
                              : DateFormat('MMM d, yyyy • h:mm a').format(_selectedPickupTime!),
                    style: TextStyle(
                      color: _selectedPickupTime == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    color: PamigayColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Notes field
          const Text(
            'Additional Notes',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any special instructions or notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: PamigayColors.primary),
              ),
            ),
          ),
        ],
      ),
      primaryButtonText: 'Submit Request',
      isPrimaryButtonLoading: _isSubmitting,
      onPrimaryButtonPressed: _submitPickupRequest,
    );
  }
}
