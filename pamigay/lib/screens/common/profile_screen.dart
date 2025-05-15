import 'package:flutter/material.dart';
import 'package:pamigay/screens/common/auth/login_screen.dart';
import 'package:pamigay/screens/common/profile_edit_screen.dart';
import 'package:pamigay/services/auth_service.dart';
import 'package:pamigay/services/user_service.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const ProfileScreen({
    Key? key,
    this.userData,
  }) : super(key: key);
  
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  void _refreshUserData() async {
    if (userData == null || userData!['id'] == null) return;
    
    try {
      final updatedUserData = await _userService.getUserProfile(userData!['id'].toString());
      if (mounted) {
        setState(() {
          userData = updatedUserData;
          print('Profile data refreshed: $userData');
        });
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildProfileInfo(),
              const SizedBox(height: 20),
              _buildOptions(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    String profileImageUrl = '';
    if (userData != null && userData!['profile_image'] != null && userData!['profile_image'].isNotEmpty) {
      profileImageUrl = _userService.getProfileImageUrl(userData!['profile_image']);
    }
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
            child: profileImageUrl.isEmpty
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          userData != null ? userData!['name'] ?? 'User' : 'User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        Text(
          userData != null ? userData!['role'] ?? '' : '',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('Email', userData != null ? userData!['email'] ?? 'N/A' : 'N/A'),
            const Divider(),
            _buildInfoRow('Phone', userData != null ? userData!['phone_number'] ?? 'N/A' : 'N/A'),
            const Divider(),
            _buildInfoRow('Location', userData != null ? userData!['location'] ?? 'Not set' : 'Not set'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontFamily: 'Montserrat'),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Montserrat'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptions(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: PamigayColors.primary),
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileEditScreen(userData: userData),
                ),
              );
              
              if (result != null && mounted) {
                print('Received updated data from edit screen: $result');
                
                // Force immediate UI update with new data
                setState(() {
                  userData = Map<String, dynamic>.from(result);
                });
                
                // Give UI time to update then call refresh for latest server data
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _refreshUserData();
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: PamigayColors.success,
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.contact_support, color: PamigayColors.primary),
            title: const Text(
              'Contact Admin',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showContactDialog(context);
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Assistance?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'pamigayadmin@gmail.com',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Contact us for reports and other requests',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'For any inquiries or to request reports, please contact us at:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: PamigayColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'pamigayadmin@gmail.com',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Response within 24-48 hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
