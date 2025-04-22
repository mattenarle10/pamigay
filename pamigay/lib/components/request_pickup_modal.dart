import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/services/pickup_service.dart';
import 'package:pamigay/screens/my_pickups_screen.dart';

class RequestPickupModal extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic> donation;
  final Function onSuccess;

  const RequestPickupModal({
    Key? key,
    required this.userData,
    required this.donation,
    required this.onSuccess,
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
        // Check if same day
        _isSameDay = _pickupWindowStart!.year == _pickupWindowEnd!.year &&
                    _pickupWindowStart!.month == _pickupWindowEnd!.month &&
                    _pickupWindowStart!.day == _pickupWindowEnd!.day;
        
        if (_isSameDay) {
          final dateFormat = DateFormat('MMM d, yyyy');
          final timeStartFormat = DateFormat('h:mm a');
          final timeEndFormat = DateFormat('h:mm a');
          
          _pickupWindowText = '${dateFormat.format(_pickupWindowStart!)} from ${timeStartFormat.format(_pickupWindowStart!)} to ${timeEndFormat.format(_pickupWindowEnd!)}';
        } else {
          final startFormat = DateFormat('MMM d, yyyy • h:mm a').format(_pickupWindowStart!);
          final endFormat = DateFormat('MMM d, yyyy • h:mm a').format(_pickupWindowEnd!);
          _pickupWindowText = 'From $startFormat to $endFormat';
        }
      }
    } catch (e) {
      print('Error parsing pickup window: $e');
      _pickupWindowText = 'Not specified';
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMMM d, yyyy • h:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

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
        final currentTime = TimeOfDay.now();
        if (currentTime.hour > minTime.hour || 
            (currentTime.hour == minTime.hour && currentTime.minute > minTime.minute)) {
          minTime = currentTime;
        }
      }
      
      // Show time picker
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedPickupTime != null 
            ? TimeOfDay(hour: _selectedPickupTime!.hour, minute: _selectedPickupTime!.minute)
            : TimeOfDay(
                hour: (minTime.hour + maxTime.hour) ~/ 2,
                minute: (minTime.minute + maxTime.minute) ~/ 2,
              ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: PamigayColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime == null) return;
      
      // Validate the picked time is within the allowed range
      final pickedMinutes = pickedTime.hour * 60 + pickedTime.minute;
      final minMinutes = minTime.hour * 60 + minTime.minute;
      final maxMinutes = maxTime.hour * 60 + maxTime.minute;
      
      if (pickedMinutes < minMinutes || pickedMinutes > maxMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a time between ${minTime.format(context)} and ${maxTime.format(context)}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Set the selected pickup time
      setState(() {
        _selectedPickupTime = DateTime(
          _pickupWindowStart!.year,
          _pickupWindowStart!.month,
          _pickupWindowStart!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    } else {
      // For multi-day pickup windows, we need to select both date and time
      // First, select the date
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedPickupTime ?? _pickupWindowStart!,
        firstDate: _pickupWindowStart!,
        lastDate: _pickupWindowEnd!,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: PamigayColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedDate == null) return;
      
      // Determine allowed time range for the selected date
      TimeOfDay minTime = const TimeOfDay(hour: 0, minute: 0);
      TimeOfDay maxTime = const TimeOfDay(hour: 23, minute: 59);
      
      // If selected date is the same as window start date, use window start time as min
      if (pickedDate.year == _pickupWindowStart!.year && 
          pickedDate.month == _pickupWindowStart!.month && 
          pickedDate.day == _pickupWindowStart!.day) {
        minTime = TimeOfDay(hour: _pickupWindowStart!.hour, minute: _pickupWindowStart!.minute);
      }
      
      // If selected date is the same as window end date, use window end time as max
      if (pickedDate.year == _pickupWindowEnd!.year && 
          pickedDate.month == _pickupWindowEnd!.month && 
          pickedDate.day == _pickupWindowEnd!.day) {
        maxTime = TimeOfDay(hour: _pickupWindowEnd!.hour, minute: _pickupWindowEnd!.minute);
      }
      
      // If today is the selected date, ensure we don't allow past times
      final now = DateTime.now();
      if (pickedDate.year == now.year && 
          pickedDate.month == now.month && 
          pickedDate.day == now.day) {
        final currentTime = TimeOfDay.now();
        if (currentTime.hour > minTime.hour || 
            (currentTime.hour == minTime.hour && currentTime.minute > minTime.minute)) {
          minTime = currentTime;
        }
      }
      
      // Show time picker
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedPickupTime != null 
            ? TimeOfDay(hour: _selectedPickupTime!.hour, minute: _selectedPickupTime!.minute)
            : TimeOfDay(
                hour: (minTime.hour + maxTime.hour) ~/ 2,
                minute: (minTime.minute + maxTime.minute) ~/ 2,
              ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: PamigayColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime == null) return;
      
      // Validate the picked time is within the allowed range
      final pickedMinutes = pickedTime.hour * 60 + pickedTime.minute;
      final minMinutes = minTime.hour * 60 + minTime.minute;
      final maxMinutes = maxTime.hour * 60 + maxTime.minute;
      
      if (pickedMinutes < minMinutes || pickedMinutes > maxMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a time between ${minTime.format(context)} and ${maxTime.format(context)}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Set the selected pickup time
      setState(() {
        _selectedPickupTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

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
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final organizationId = widget.userData?['id'] ?? '';
      if (organizationId.isEmpty) {
        throw Exception('Organization ID not found');
      }
      
      final donationId = widget.donation['id'].toString();
      final pickupTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedPickupTime!);
      final notes = _notesController.text;
      
      // Call API to request pickup
      final result = await _pickupService.requestPickup(
        organizationId: organizationId,
        donationId: donationId,
        pickupTime: pickupTime,
        notes: notes,
      );
      
      setState(() {
        _isSubmitting = false;
      });
      
      if (result['success']) {
        // Show success dialog
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit pickup request: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: PamigayColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: PamigayColors.primary,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Success message
                const Text(
                  'Pickup Request Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Your pickup request for "${widget.donation['name']}" has been submitted successfully.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'The restaurant will review your request and respond soon.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Close both dialogs
                        Navigator.of(context).pop(); // Close success dialog
                        Navigator.of(context).pop(); // Close pickup modal
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PamigayColors.primary,
                        side: const BorderSide(color: PamigayColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Continue Browsing'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Close both dialogs and navigate to My Pickups screen
                        Navigator.of(context).pop(); // Close success dialog
                        Navigator.of(context).pop(); // Close pickup modal
                        
                        // Navigate to My Pickups screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyPickupsScreen(
                              userData: widget.userData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PamigayColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View My Pickups'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Request Pickup',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const Divider(),
            
            // Content in a scrollable container
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Donation details
                    Text(
                      'Donation: ${widget.donation['name']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Restaurant: ${widget.donation['restaurant_name'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Pickup window
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Available: $_pickupWindowText',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Pickup Details Section
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPickupRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: PamigayColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Request',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
