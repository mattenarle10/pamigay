import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pamigay/utils/constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PickupService {
  // Get base URL from .env file
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  
  // Get endpoints from .env file
  final String requestPickupEndpoint = dotenv.env['API_REQUEST_PICKUP'] ?? '/organization-request_pickup.php';
  final String getMyPickupsEndpoint = dotenv.env['API_GET_MY_PICKUPS'] ?? '/organization-get_my_pickups.php';
  final String updatePickupEndpoint = dotenv.env['API_UPDATE_PICKUP'] ?? '/organization-update_pickup.php';
  final String getRestaurantPickupsEndpoint = dotenv.env['API_GET_RESTAURANT_PICKUPS'] ?? '/resto-get_pickup_requests.php';
  final String updateRestaurantPickupEndpoint = dotenv.env['API_UPDATE_RESTAURANT_PICKUP'] ?? '/resto-update_pickup.php';
  
  // Singleton pattern
  static final PickupService _instance = PickupService._internal();
  
  factory PickupService() {
    return _instance;
  }
  
  PickupService._internal();
  
  // Request pickup for a donation
  Future<Map<String, dynamic>> requestPickup({
    required String organizationId,
    required String donationId,
    required String pickupTime,
    String notes = '',
  }) async {
    try {
      print('Requesting pickup for donation: $donationId');
      print('Request parameters: collector_id=$organizationId, donation_id=$donationId, pickup_time=$pickupTime, notes=$notes');
      
      // Create body map
      final Map<String, String> requestBody = {
        'collector_id': organizationId,
        'donation_id': donationId,
        'pickup_time': pickupTime,
        'notes': notes,
      };
      
      print('Request body: $requestBody');
      
      // Add proper headers for form data
      final response = await http.post(
        Uri.parse('$baseUrl$requestPickupEndpoint'),
        body: requestBody,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      print('Request pickup status code: ${response.statusCode}');
      print('Request pickup response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': jsonResponse['success'] == true,
          'message': jsonResponse['message'],
          'data': jsonResponse['data'],
        };
      } else {
        String errorBody = response.body.isNotEmpty ? response.body : 'No response body';
        print('Failed to request pickup: ${response.statusCode}, Body: $errorBody');
        return {
          'success': false,
          'message': 'Failed to request pickup. Server returned ${response.statusCode}: $errorBody',
        };
      }
    } catch (e) {
      print('Error requesting pickup: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get my pickup requests
  Future<List<Map<String, dynamic>>> getMyPickups(String organizationId, {String? status}) async {
    try {
      String url = '$baseUrl$getMyPickupsEndpoint?collector_id=$organizationId';
      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (data['data']['pickups'] != null) {
            return List<Map<String, dynamic>>.from(data['data']['pickups']);
          }
          return [];
        } else {
          print('Failed to get pickups: ${data['message']}');
          return [];
        }
      } else {
        print('Failed to get pickups: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting pickups: $e');
      return [];
    }
  }
  
  // Update pickup status
  Future<Map<String, dynamic>> updatePickup({
    required String pickupId,
    required String status,
    String? notes,
    String? collectorId,
  }) async {
    try {
      // Get collector ID from local storage if not provided
      final String? userId = collectorId;
      
      if (userId == null) {
        return {
          'success': false,
          'message': 'Organization ID is required',
        };
      }
      
      final Map<String, String> requestBody = {
        'pickup_id': pickupId,
        'status': status,
        'collector_id': userId,
      };
      
      if (notes != null) {
        requestBody['notes'] = notes;
      }
      
      print('Updating pickup: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$updatePickupEndpoint'),
        body: requestBody,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      print('Update pickup response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': jsonResponse['success'] == true,
          'message': jsonResponse['message'],
          'data': jsonResponse['data'],
        };
      } else {
        print('Failed to update pickup: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to update pickup. Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error updating pickup: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
  
  // Get pickup requests for a restaurant
  Future<Map<String, dynamic>> getRestaurantPickupRequests(String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$getRestaurantPickupsEndpoint?restaurant_id=$restaurantId'),
      );
      
      print('Get restaurant pickup requests status code: ${response.statusCode}');
      print('Get restaurant pickup requests response: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get pickup requests. Status code: ${response.statusCode}',
          'data': {'pickups': []}
        };
      }
    } catch (e) {
      print('Error getting restaurant pickup requests: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'data': {'pickups': []}
      };
    }
  }
  
  // Update pickup status (for restaurant to accept/reject/complete)
  Future<Map<String, dynamic>> updatePickupStatus({
    required String pickupId,
    required String status,
    required String restaurantId,
  }) async {
    try {
      // Create body map
      final Map<String, String> requestBody = {
        'pickup_id': pickupId,
        'status': status,
        'restaurant_id': restaurantId,
      };
      
      print('Update pickup status request body: $requestBody');
      
      // Add proper headers for form data
      final response = await http.post(
        Uri.parse('$baseUrl$updateRestaurantPickupEndpoint'),
        body: requestBody,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      print('Update pickup status code: ${response.statusCode}');
      print('Update pickup status response: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to update pickup status. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error updating pickup status: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
