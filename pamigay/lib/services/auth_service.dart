import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/constants.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    validateStatus: (status) => true, // Accept all status codes for debugging
    receiveTimeout: const Duration(seconds: 30),
    connectTimeout: const Duration(seconds: 30),
  ));
  
  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final loginEndpoint = dotenv.get('API_LOGIN', fallback: '/user-login.php');
      print('Login URL: $baseUrl$loginEndpoint');
      
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        body: {
          'email': email,
          'password': password,
        },
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (responseData['success'] == true) {
        // Save user data to local storage
        await _saveUserData(responseData['data']['user']);
        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['data']['user']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Register user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData, File? profileImage, File? verificationDocument) async {
    try {
      final registerEndpoint = dotenv.get('API_REGISTER', fallback: '/user-register.php');
      print('Register URL: $baseUrl$registerEndpoint');
      print('Register data: $userData');
      
      FormData formData = FormData.fromMap(userData);
      
      // Add profile image if provided
      if (profileImage != null) {
        print('Adding profile image: ${profileImage.path}');
        
        // Get file extension
        String fileExt = profileImage.path.split('.').last.toLowerCase();
        MediaType contentType;
        
        // Set proper content type based on file extension
        if (fileExt == 'png') {
          contentType = MediaType('image', 'png');
        } else if (fileExt == 'jpg' || fileExt == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (fileExt == 'gif') {
          contentType = MediaType('image', 'gif');
        } else {
          contentType = MediaType('image', 'jpeg'); // Default
        }
        
        formData.files.add(MapEntry(
          'profile_image',
          await MultipartFile.fromFile(
            profileImage.path,
            filename: profileImage.path.split('/').last,
            contentType: contentType,
          ),
        ));
      }
      
      // Add verification document if provided
      if (verificationDocument != null) {
        print('Adding verification document: ${verificationDocument.path}');
        
        // Get file extension
        String fileExt = verificationDocument.path.split('.').last.toLowerCase();
        MediaType contentType;
        
        // Set proper content type based on file extension
        if (fileExt == 'png') {
          contentType = MediaType('image', 'png');
        } else if (fileExt == 'jpg' || fileExt == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (fileExt == 'gif') {
          contentType = MediaType('image', 'gif');
        } else if (fileExt == 'pdf') {
          contentType = MediaType('application', 'pdf');
        } else {
          contentType = MediaType('image', 'jpeg'); // Default
        }
        
        formData.files.add(MapEntry(
          'verification_document',
          await MultipartFile.fromFile(
            verificationDocument.path,
            filename: verificationDocument.path.split('/').last,
            contentType: contentType,
          ),
        ));
      }
      
      print('Register form data fields: ${formData.fields}');
      print('Register form data files: ${formData.files}');

      final response = await _dio.post(
        '$baseUrl$registerEndpoint',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
          },
          followRedirects: false,
        ),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response data: ${response.data}');

      // Parse response
      dynamic responseData;
      if (response.data is String) {
        // Remove any HTML warnings before parsing
        String responseStr = response.data.toString();
        
        // Check if the response contains HTML warnings
        if (responseStr.contains('<br />') || responseStr.contains('<b>')) {
          // Extract the JSON part from the response
          int jsonStart = responseStr.indexOf('{');
          if (jsonStart >= 0) {
            String jsonPart = responseStr.substring(jsonStart);
            try {
              responseData = json.decode(jsonPart);
              print('Successfully extracted JSON from HTML response');
            } catch (e) {
              print('Failed to parse extracted JSON: $e');
              return {
                'success': false,
                'message': 'Server returned invalid response format',
              };
            }
          } else {
            print('No JSON found in response: $responseStr');
            return {
              'success': false,
              'message': 'Server returned HTML with no JSON data',
            };
          }
        } else {
          // Regular JSON string response
          try {
            responseData = json.decode(responseStr);
          } catch (e) {
            print('Failed to parse response: $e');
            return {
              'success': false,
              'message': 'Failed to parse server response: ${e.toString()}',
            };
          }
        }
      } else {
        responseData = response.data;
      }
      
      if (responseData['success'] == true) {
        // Save user data
        if (responseData['data'] != null && responseData['data']['user'] != null) {
          await _saveUserData(responseData['data']['user']);
        }
        
        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('Register error: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Upload profile image separately
  Future<Map<String, dynamic>> uploadProfileImage(String userId, File imageFile) async {
    try {
      final uploadEndpoint = dotenv.get('API_UPLOAD_IMAGE', fallback: '/upload_profile_image.php');
      print('Upload URL: $baseUrl$uploadEndpoint');
      
      // Get file extension
      String fileExt = imageFile.path.split('.').last.toLowerCase();
      MediaType contentType;
      
      // Set proper content type based on file extension
      if (fileExt == 'png') {
        contentType = MediaType('image', 'png');
      } else if (fileExt == 'jpg' || fileExt == 'jpeg') {
        contentType = MediaType('image', 'jpeg');
      } else if (fileExt == 'gif') {
        contentType = MediaType('image', 'gif');
      } else {
        contentType = MediaType('image', 'jpeg'); // Default
      }
      
      FormData formData = FormData.fromMap({
        'user_id': userId,
        'profile_image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: contentType,
        ),
      });

      print('Upload form data fields: ${formData.fields}');
      print('Upload form data files: ${formData.files}');

      final response = await _dio.post(
        '$baseUrl$uploadEndpoint',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
          },
          followRedirects: false,
        ),
      );

      print('Upload response status: ${response.statusCode}');
      print('Upload response data: ${response.data}');

      final responseData = response.data is String 
          ? json.decode(response.data) 
          : response.data;
      
      if (responseData['success'] == true) {
        // Update user data in local storage
        if (responseData['data'] != null && responseData['data']['user'] != null) {
          await _saveUserData(responseData['data']['user']);
        }
        
        return {
          'success': true,
          'message': responseData['message'],
          'image_url': responseData['data']['image_url'],
          'user': responseData['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      print('Upload error: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Save user data to local storage
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        return json.decode(userData);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('token');
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }
}
