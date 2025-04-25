import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:pamigay/widgets/custom_text_field.dart';
import 'package:pamigay/widgets/custom_button.dart';
import 'package:pamigay/services/user_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileEditScreen({
    Key? key,
    this.userData,
  }) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with user data
    if (widget.userData != null) {
      print('Initializing edit form with data: ${widget.userData}');
      _nameController.text = widget.userData!['name'] ?? '';
      _phoneController.text = widget.userData!['phone_number'] ?? '';
      _locationController.text = widget.userData!['location'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Upload profile image first if one is selected
      String? profileImageUrl;
      if (_imageFile != null) {
        profileImageUrl = await _userService.uploadProfileImage(
          _imageFile!, 
          widget.userData!['id'].toString()
        );
        
        if (profileImageUrl == null) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to upload profile image';
          });
          return;
        }
      }
      
      // Prepare update data
      final Map<String, String> updateData = {
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
      };
      
      // Update profile
      final updatedUserData = await _userService.updateProfile(
        widget.userData!,
        updateData
      );
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      // Return to previous screen with updated data
      Navigator.of(context).pop(updatedUserData);
    } catch (e) {
      print('Update Profile Error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 600,
      );
      
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PamigayColors.primary,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    String profileImageUrl = '';
    if (_imageFile == null && 
        widget.userData != null && 
        widget.userData!['profile_image'] != null && 
        widget.userData!['profile_image'].isNotEmpty) {
      profileImageUrl = _userService.getProfileImageUrl(widget.userData!['profile_image']);
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PamigayColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null 
                      ? FileImage(_imageFile!) as ImageProvider 
                      : (profileImageUrl.isNotEmpty 
                          ? NetworkImage(profileImageUrl) 
                          : null),
                  child: (_imageFile == null && profileImageUrl.isEmpty)
                      ? const Icon(Icons.person, size: 55, color: Colors.grey)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.camera_alt,
                      color: PamigayColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.userData != null ? widget.userData!['name'] ?? 'User' : 'User',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error message
          if (_errorMessage.isNotEmpty)
            _buildErrorMessage(),
          
          // Form fields
          _buildFormFields(),
          
          const SizedBox(height: 24),
          
          // Update button
          _buildUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          _errorMessage,
          style: TextStyle(color: Colors.red.shade800),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Name field
            CustomTextField(
              controller: _nameController,
              label: 'Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            // Phone field
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
              validator: (value) {
                return null;
              },
            ),
            // Location field
            CustomTextField(
              controller: _locationController,
              label: 'Location',
              validator: (value) {
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return CustomButton(
      text: 'Save Changes',
      onPressed: _updateProfile,
      isLoading: _isLoading,
      fontSize: 16,
    );
  }
}
