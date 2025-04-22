import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/widgets/custom_button.dart';
import 'package:pamigay/widgets/custom_text_field.dart';
import 'package:pamigay/widgets/image_picker_widget.dart';
import 'package:pamigay/widgets/category_selector.dart';
import 'package:pamigay/widgets/date_time_picker.dart';
import 'package:pamigay/services/donation_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddDonationScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const AddDonationScreen({
    Key? key, 
    required this.userData,
  }) : super(key: key);

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _donationService = DonationService();
  
  DateTime _pickupDeadline = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _pickupWindowStart = TimeOfDay.now();
  TimeOfDay _pickupWindowEnd = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2);
  
  String _conditionStatus = 'Fresh';
  String _category = 'Human Intake';
  String _quantityUnit = 'kg';
  File? _imageFile;
  bool _isUploading = false;
  String _errorMessage = '';
  
  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitDonation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
        _errorMessage = '';
      });

      try {
        // Get user ID from userData
        final userId = widget.userData?['id'] ?? '';
        if (userId.isEmpty) {
          setState(() {
            _errorMessage = 'User ID not found';
            _isUploading = false;
          });
          return;
        }

        // Upload image first if available
        String? imageUrl;
        if (_imageFile != null) {
          imageUrl = await _donationService.uploadDonationImage(_imageFile!, userId);
          
          if (imageUrl == null) {
            setState(() {
              _errorMessage = 'Failed to upload image. Please try again.';
              _isUploading = false;
            });
            return;
          }
        }

        // Prepare donation data
        final donationData = {
          'restaurant_id': userId,
          'name': _nameController.text,
          'quantity': '${_quantityController.text} $_quantityUnit',
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
          'photo_url': imageUrl ?? '',
        };

        // Submit donation
        final result = await _donationService.addDonation(donationData);
        
        setState(() {
          _isUploading = false;
        });

        if (result['success']) {
          // Show success message and navigate back to donations screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Donation added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            )
          );
          
          // Navigate back to the donations screen
          Navigator.of(context).pop();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to add donation';
          });
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    
    try {
      final userId = widget.userData?['id'] ?? '';
      if (userId.isEmpty) return null;
      
      return await _donationService.uploadDonationImage(_imageFile!, userId);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm(); // 5:08 PM
    return format.format(dt);
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Your donation has been added successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _quantityController.clear();
    _conditionStatus = 'Fresh';
    _category = 'Human Intake';
    _pickupDeadline = DateTime.now().add(const Duration(days: 1));
    _pickupWindowStart = TimeOfDay.now();
    _pickupWindowEnd = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2);
    _imageFile = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Clean title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const Text(
                        'Add Donation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker
                      Center(
                        child: ImagePickerWidget(
                          onImageSelected: (file) {
                            setState(() {
                              _imageFile = file;
                            });
                          },
                          imageFile: _imageFile,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Name
                      CustomTextField(
                        controller: _nameController,
                        label: 'Donation Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quantity
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: CustomTextField(
                              controller: _quantityController,
                              label: 'Quantity',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a quantity';
                                }
                                // Check if the value is a valid number
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: DropdownButtonFormField<String>(
                                value: _quantityUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _quantityUnit = value!;
                                  });
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: 'kg',
                                    child: Text('kg'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'g',
                                    child: Text('g'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pcs',
                                    child: Text('pcs'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'boxes',
                                    child: Text('boxes'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Condition Status
                      const Text(
                        'Condition Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Fresh'),
                            selected: _conditionStatus == 'Fresh',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _conditionStatus = 'Fresh';
                                });
                              }
                            },
                            selectedColor: PamigayColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _conditionStatus == 'Fresh' 
                                  ? PamigayColors.primary 
                                  : Colors.black,
                              fontWeight: _conditionStatus == 'Fresh'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Near Expiry'),
                            selected: _conditionStatus == 'Near Expiry',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _conditionStatus = 'Near Expiry';
                                });
                              }
                            },
                            selectedColor: PamigayColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _conditionStatus == 'Near Expiry' 
                                  ? PamigayColors.primary 
                                  : Colors.black,
                              fontWeight: _conditionStatus == 'Near Expiry'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Expired'),
                            selected: _conditionStatus == 'Expired',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _conditionStatus = 'Expired';
                                });
                              }
                            },
                            selectedColor: PamigayColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _conditionStatus == 'Expired' 
                                  ? PamigayColors.primary 
                                  : Colors.black,
                              fontWeight: _conditionStatus == 'Expired'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
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
                      
                      const SizedBox(height: 24),
                      
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
                            if (_pickupWindowEnd.hour < _pickupWindowStart.hour || 
                                (_pickupWindowEnd.hour == _pickupWindowStart.hour && _pickupWindowEnd.minute < _pickupWindowStart.minute)) {
                              _pickupWindowEnd = TimeOfDay(hour: _pickupWindowStart.hour + 2, minute: _pickupWindowStart.minute);
                            }
                          });
                        },
                        onEndTimeSelected: (time) {
                          setState(() {
                            _pickupWindowEnd = time;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      Center(
                        child: CustomButton(
                          text: 'Submit Donation',
                          onPressed: _submitDonation,
                          isLoading: _isUploading,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
