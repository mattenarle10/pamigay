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

/// Screen for restaurants to add new food donations.
///
/// This screen provides a form for restaurants to enter details about their
/// food donations including name, quantity, condition, category, and pickup window.
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
            ),
          );
          
          // Reset form for new entry or navigate back
          _showSuccessDialog();
        } else {
          // Show error message
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to add donation';
          });
          _showErrorSnackBar(_errorMessage);
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'An error occurred: $e';
        });
        _showErrorSnackBar(_errorMessage);
      }
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success!'),
          content: const Text('Your donation has been added successfully.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Add Another Donation'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
            ),
            TextButton(
              child: const Text('View My Donations'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red)
    );
  }

  void _resetForm() {
    _nameController.clear();
    _quantityController.clear();
    setState(() {
      _imageFile = null;
      _conditionStatus = 'Fresh';
      _category = 'Human Intake';
      _quantityUnit = 'kg';
      _pickupDeadline = DateTime.now().add(const Duration(days: 1));
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Validation for pickup window times
    final pickupWindowStartMinutes = _timeToMinutes(_pickupWindowStart);
    final pickupWindowEndMinutes = _timeToMinutes(_pickupWindowEnd);
    final validPickupWindow = pickupWindowEndMinutes > pickupWindowStartMinutes;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add New Donation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              
              // Image Picker
              ImagePickerWidget(
                imageFile: _imageFile,
                onImageSelected: (File file) {
                  setState(() {
                    _imageFile = file;
                  });
                },
                isCircular: false,
                height: 200,
                placeholder: 'Add Food Image',
                backgroundColor: Colors.grey.shade200,
                iconColor: PamigayColors.primary,
              ),
              
              const SizedBox(height: 24),
              
              // Donation Name
              CustomTextField(
                controller: _nameController,
                label: 'Food Item Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the food item name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quantity with unit selector
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the quantity';
                        }
                        
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            'Unit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _quantityUnit,
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _quantityUnit = newValue;
                                  });
                                }
                              },
                              items: <String>['kg', 'g', 'lb', 'pieces', 'servings', 'boxes']
                                .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Condition Status
              const Text(
                'Food Condition',
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
    );
  }
}
