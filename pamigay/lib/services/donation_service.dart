import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pamigay/utils/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DonationService {
  // Get base URL from .env file
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  
  // Get endpoints from .env file
  final String uploadDonationImageEndpoint = dotenv.env['API_UPLOAD_DONATION_IMAGE'] ?? '/upload_donation_image.php';
  final String addDonationEndpoint = dotenv.env['API_ADD_DONATION'] ?? '/resto-add_food_donation.php';
  final String getDonationsEndpoint = dotenv.env['API_GET_DONATIONS'] ?? '/get_donations.php';
  final String getMyDonationsEndpoint = dotenv.env['API_GET_MY_DONATIONS'] ?? '/resto-get_my_donations.php';
  final String updateDonationEndpoint = dotenv.env['API_UPDATE_DONATION'] ?? '/resto-update_donation.php';
  final String deleteDonationEndpoint = dotenv.env['API_DELETE_DONATION'] ?? '/resto-delete_donation.php';
  final String getAvailableDonationsEndpoint = dotenv.env['API_GET_AVAILABLE_DONATIONS'] ?? '/organization-browse_available_donations.php';
  final String getDonationByIdEndpoint = dotenv.env['API_GET_DONATION_BY_ID'] ?? '/get_donation_by_id.php';
  
  // Singleton pattern
  static final DonationService _instance = DonationService._internal();
  
  factory DonationService() {
    return _instance;
  }
  
  DonationService._internal();
  
  // Get all donations
  Future<List<Map<String, dynamic>>> getDonations(String userId, String role) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$getDonationsEndpoint?user_id=$userId&role=$role'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']['donations']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load donations');
      }
    } catch (e) {
      print('Error getting donations: $e');
      return [];
    }
  }
  
  // Upload donation image
  Future<String?> uploadDonationImage(File imageFile, String userId) async {
    if (imageFile == null) return null;
    
    try {
      print('Uploading to URL: $baseUrl$uploadDonationImageEndpoint');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$uploadDonationImageEndpoint'));
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'donation_image', // This must match the field name in the PHP script
          imageFile.path,
        ),
      );
      
      // Add user ID
      request.fields['user_id'] = userId.toString();
      
      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print('Upload response: $responseData');
      
      // Check if the response is HTML (error page) instead of JSON
      if (responseData.trim().startsWith('<')) {
        print('Error: Received HTML response instead of JSON');
        return null;
      }
      
      try {
        var jsonResponse = json.decode(responseData);
        
        if (jsonResponse['success'] == true) {
          print('Image uploaded successfully');
          return jsonResponse['data']['image_url'];
        } else {
          print('Failed to upload image: ${jsonResponse['message']}');
          return null;
        }
      } catch (e) {
        print('Error parsing JSON response: $e');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  
  // Get full donation image URL
  String getDonationImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Check if image already contains http or https (full URL)
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // In local development, use the local web server URL
    // Strip API endpoints from baseUrl to get the web root
    String webRoot = baseUrl;
    if (webRoot.contains('/mobile')) {
      webRoot = webRoot.substring(0, webRoot.indexOf('/mobile'));
    }
    
    // Ensure there are no double slashes by removing any leading slashes
    String cleanImagePath = imagePath.replaceAll(RegExp(r'^/+'), '');
    
    // Construct the full URL
    return '$webRoot/$cleanImagePath';
  }
  
  // Get full image URL (alias for getDonationImageUrl for backward compatibility)
  String getFullImageUrl(String? imagePath) {
    return getDonationImageUrl(imagePath);
  }
  
  // Add a new donation
  Future<Map<String, dynamic>> addDonation(Map<String, dynamic> donationData) async {
    try {
      print('Adding donation: $donationData');
      
      final response = await http.post(
        Uri.parse('$baseUrl$addDonationEndpoint'),
        body: donationData,
      );
      
      print('Add donation response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': jsonResponse['success'] == true,
          'message': jsonResponse['message'],
          'data': jsonResponse['data'],
          'photo_url': jsonResponse['photo_url'],
        };
      } else {
        print('Failed to add donation: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to add donation. Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error adding donation: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get available donations for organizations
  Future<List<Map<String, dynamic>>> getAvailableDonations(String organizationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$getAvailableDonationsEndpoint?collector_id=$organizationId')
      );
      
      print('Get available donations response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Ensure donations exists and is non-null
          if (data['data']['donations'] != null) {
            final donations = List<Map<String, dynamic>>.from(
              data['data']['donations'].map((item) => 
                // Ensure each item is a Map<String, dynamic>
                item != null ? Map<String, dynamic>.from(item) : <String, dynamic>{}
              )
            );
            
            // Process each donation to ensure proper data types and add additional fields
            for (var donation in donations) {
              // Process urgency level
              donation['urgency_level'] = donation['urgency'] ?? 'low';
              
              // Process pickup window status
              donation['pickup_window_status'] = donation['pickup_window_status'] ?? 'unknown';
              
              // Process time remaining
              donation['time_remaining_formatted'] = donation['time_remaining'] ?? 'Unknown';
              
              // Add color based on urgency
              if (donation['urgency_level'] == 'high') {
                donation['urgency_color'] = 0xFFFF3B30; // Red
              } else if (donation['urgency_level'] == 'medium') {
                donation['urgency_color'] = 0xFFFF9500; // Orange
              } else {
                donation['urgency_color'] = 0xFF4CD964; // Green
              }
              
              // Add icon based on pickup window status
              if (donation['pickup_window_status'] == 'active') {
                donation['status_icon'] = 'check_circle';
                donation['status_message'] = 'Available now';
              } else if (donation['pickup_window_status'] == 'upcoming') {
                donation['status_icon'] = 'schedule';
                donation['status_message'] = 'Available later';
              } else {
                donation['status_icon'] = 'error';
                donation['status_message'] = 'Window expired';
              }
            }
            
            return donations;
          }
          print('Donations data is null or malformed');
          return [];
        } else {
          print('Failed to get available donations: ${data['message']}');
          return [];
        }
      } else {
        print('Failed to get available donations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting available donations: $e');
      return [];
    }
  }
  
  // Get restaurant's own donations
  Future<List<Map<String, dynamic>>> getMyDonations(String restaurantId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$getMyDonationsEndpoint?restaurant_id=$restaurantId'));
      print('Get my donations response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Ensure donations exists and is non-null
          if (data['data']['donations'] != null) {
            final donations = List<Map<String, dynamic>>.from(
              data['data']['donations'].map((item) => 
                // Ensure each item is a Map<String, dynamic>
                item != null ? Map<String, dynamic>.from(item) : <String, dynamic>{}
              )
            );
            
            // Process each donation to add the new fields
            for (var donation in donations) {
              // Add pickup window status if available
              donation['pickup_window_status'] = donation['pickup_window_status'] ?? 'not_applicable';
              
              // Add time remaining if available and status is Available
              if (donation['status'] == 'Available' && donation['time_remaining'] != null) {
                donation['time_remaining_formatted'] = donation['time_remaining'];
                
                // Add urgency level
                donation['urgency_level'] = donation['urgency'] ?? 'low';
                
                // Add color based on urgency
                if (donation['urgency_level'] == 'high') {
                  donation['urgency_color'] = 0xFFFF3B30; // Red
                } else if (donation['urgency_level'] == 'medium') {
                  donation['urgency_color'] = 0xFFFF9500; // Orange
                } else {
                  donation['urgency_color'] = 0xFF4CD964; // Green
                }
              }
            }
            
            return donations;
          }
          print('Donations data is null or malformed');
          return [];
        } else {
          print('Failed to get donations: ${data['message']}');
          return [];
        }
      } else {
        print('Failed to get donations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting donations: $e');
      return [];
    }
  }
  
  // Update an existing donation
  Future<Map<String, dynamic>> updateDonation(Map<String, dynamic> donationData) async {
    try {
      print('Updating donation: $donationData');
      
      final response = await http.post(
        Uri.parse('$baseUrl$updateDonationEndpoint'),
        body: donationData,
      );
      
      print('Update donation response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': jsonResponse['success'] == true,
          'message': jsonResponse['message'],
          'data': jsonResponse['data'],
        };
      } else {
        print('Failed to update donation: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to update donation. Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error updating donation: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Delete a donation
  Future<Map<String, dynamic>> deleteDonation(String restaurantId, String donationId) async {
    try {
      print('Deleting donation: $donationId');
      
      final response = await http.post(
        Uri.parse('$baseUrl$deleteDonationEndpoint'),
        body: {
          'restaurant_id': restaurantId,
          'donation_id': donationId,
        },
      );
      
      print('Delete donation response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': jsonResponse['success'] == true,
          'message': jsonResponse['message'],
        };
      } else {
        print('Failed to delete donation: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to delete donation. Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error deleting donation: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get a single donation by ID
  Future<Map<String, dynamic>?> getDonationById(String donationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$getDonationByIdEndpoint?donation_id=$donationId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null && data['data']['donation'] != null) {
          // Get the donation data
          final donation = data['data']['donation'];
          
          // Normalize field names if needed
          if (donation['photo_url'] != null && donation['image'] == null) {
            donation['image'] = donation['photo_url'];
          }
          
          return donation;
        } else {
          print('Failed to get donation: ${data['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('Failed to get donation. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting donation: $e');
      return null;
    }
  }
}
