import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pamigay/utils/constants.dart';

class UserService {
  // Get base URL from constants
  final String baseUrl = getBaseUrl();
  final String getUserInfoEndpoint = '/user-get_user_info.php';
  final String updateProfileEndpoint = '/user-update_profile.php';
  final String uploadProfileImageEndpoint = '/upload_profile_image.php';
  
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  
  factory UserService() {
    return _instance;
  }
  
  UserService._internal();
  
  // Get user profile from API
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$getUserInfoEndpoint?user_id=$userId'),
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success']) {
        // Update local storage with latest user data
        await _updateLocalUserData(responseData['data']['user']);
        return responseData['data']['user'];
      } else {
        throw Exception(responseData['message'] ?? 'Failed to get user profile');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  // Get cached user profile from local storage
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        return json.decode(userData);
      }
      return null;
    } catch (e) {
      print('Error getting cached user profile: $e');
      return null;
    }
  }
  
  // Update local user data
  Future<void> _updateLocalUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString('user_data');
      
      if (existingData != null) {
        final existingUserData = json.decode(existingData);
        // Merge new data with existing data
        existingUserData.addAll(userData);
        await prefs.setString('user_data', json.encode(existingUserData));
      } else {
        await prefs.setString('user_data', json.encode(userData));
      }
    } catch (e) {
      print('Error updating user data: $e');
    }
  }
  
  // Refresh user profile (force fetch from API)
  Future<Map<String, dynamic>?> refreshUserProfile() async {
    try {
      final userData = await getCachedUserProfile();
      if (userData != null && userData['id'] != null) {
        return await getUserProfile(userData['id'].toString());
      }
      return null;
    } catch (e) {
      print('Error refreshing user profile: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData, Map<String, String> updateData) async {
    try {
      final Map<String, String> requestData = {
        'user_id': userData['id'].toString(),
      };
      
      // Add update fields
      requestData.addAll(updateData);
      
      final response = await http.post(
        Uri.parse('$baseUrl$updateProfileEndpoint'),
        body: requestData,
      );
      
      print('Update Profile Response: ${response.body}');
      final responseData = json.decode(response.body);
      
      if (responseData['status'] == 'success' || responseData['success'] == true) {
        // Create a complete updated user data object that includes ALL fields
        Map<String, dynamic> updatedUserData = Map<String, dynamic>.from(userData);
        
        // Update the fields we know have changed
        updateData.forEach((key, value) {
          updatedUserData[key] = value;
        });
        
        // Get any other fields from the response if available
        if (responseData['data'] != null && responseData['data']['user'] != null) {
          // Only update fields that exist in the response
          Map<String, dynamic> responseUser = responseData['data']['user'];
          responseUser.forEach((key, value) {
            if (key != 'profile_image' || value != null) {
              updatedUserData[key] = value;
            }
          });
        }
        
        // Update local storage
        await _updateLocalUserData(updatedUserData);
        
        return updatedUserData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Update Profile Error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
  
  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'profile_${userId}_$timestamp.jpg';
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl$uploadProfileImageEndpoint')
      );
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          imageFile.path,
          filename: filename,
        ),
      );
      
      // Add user ID
      request.fields['user_id'] = userId;
      
      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print('Upload response: $responseData');
      
      var jsonResponse = json.decode(responseData);
      
      if (response.statusCode == 200 && (jsonResponse['status'] == 'success' || jsonResponse['success'] == true)) {
        print('Image uploaded successfully');
        
        // Get the image URL from the response
        String? imageUrl;
        if (jsonResponse['data'] != null && jsonResponse['data']['image_url'] != null) {
          imageUrl = jsonResponse['data']['image_url'];
        } else if (jsonResponse['data'] != null && jsonResponse['data']['profile_image'] != null) {
          imageUrl = jsonResponse['data']['profile_image'];
        } else if (jsonResponse['image_url'] != null) {
          imageUrl = jsonResponse['image_url'];
        }
        
        // Update local user data with new image URL
        if (imageUrl != null) {
          final userData = await getCachedUserProfile();
          if (userData != null) {
            userData['profile_image'] = imageUrl;
            await _updateLocalUserData(userData);
          }
        }
        
        return imageUrl;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }
  
  // Get full profile image URL
  String getProfileImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Check if profile_image already contains the uploads/profile_images/ path
    if (imagePath.startsWith('uploads/profile_images/') || imagePath.startsWith('http')) {
      return imagePath.startsWith('http') ? imagePath : baseUrl.replaceFirst('/mobile', '') + '/' + imagePath;
    } else {
      return baseUrl.replaceFirst('/mobile', '') + '/uploads/profile_images/' + imagePath;
    }
  }
}
