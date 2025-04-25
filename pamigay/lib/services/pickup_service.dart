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
      
      // Attempt as form data first
      final response = await http.post(
        Uri.parse('$baseUrl$requestPickupEndpoint'),
        body: requestBody,
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
        print('Failed to request pickup: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to request pickup. Server returned ${response.statusCode}: ${response.body}',
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
      print('Get my pickups status code: ${response.statusCode}');
      print('Get my pickups response: ${response.body}');
      
      // Check if response is XML (error) or JSON
      if (response.body.trim().startsWith('<?xml')) {
        print('Received XML response instead of JSON');
        return [];
      }
      
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
  
  // Update pickup status (for organization to cancel their own pickup)
  Future<Map<String, dynamic>> updatePickup({
    required String pickupId,
    required String status,
    String? notes,
    String? collectorId,
  }) async {
    try {
      final Map<String, String> requestBody = {
        'pickup_id': pickupId,
        'status': status,
      };
      
      // Add collector_id if provided (required by the backend)
      if (collectorId != null) {
        requestBody['collector_id'] = collectorId;
      }
      
      if (notes != null) {
        requestBody['notes'] = notes;
      }
      
      print('Organization update pickup request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$updatePickupEndpoint'),
        body: requestBody,
      );
      
      print('Organization update pickup status code: ${response.statusCode}');
      print('Organization update pickup response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Add a small delay to ensure the database has time to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        return {
          'success': jsonResponse['success'] == true,
          'message': jsonResponse['message'],
          'data': jsonResponse['data'],
        };
      } else {
        print('Failed to update pickup: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to update pickup. Server returned ${response.statusCode}: ${response.body}',
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
        final jsonResponse = json.decode(response.body);
        return {
          'success': jsonResponse['success'] == true,
          'message': jsonResponse['message'],
          'data': jsonResponse['data'],
        };
      } else {
        print('Failed to get restaurant pickup requests: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to get pickup requests. Server returned ${response.statusCode}: ${response.body}',
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
      // Validate the status
      if (!['Accepted', 'Rejected', 'Completed'].contains(status)) {
        return {
          'success': false,
          'message': 'Invalid status. Must be Accepted, Rejected, or Completed',
        };
      }
      
      // Create body map with exactly what the backend expects
      final Map<String, String> requestBody = {
        'pickup_id': pickupId,
        'status': status,
        'restaurant_id': restaurantId,
      };
      
      print('Restaurant update pickup status request body: $requestBody');
      
      // Use the restaurant-specific endpoint
      final response = await http.post(
        Uri.parse('$baseUrl$updateRestaurantPickupEndpoint'),
        body: requestBody,
      );
      
      print('Restaurant update pickup status code: ${response.statusCode}');
      print('Restaurant update pickup status response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Add a small delay to ensure the database has time to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        return {
          'success': jsonResponse['success'] == true,
          'message': jsonResponse['message'],
          'data': jsonResponse['data'],
        };
      } else {
        print('Failed to update pickup status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to update pickup status. Server returned ${response.statusCode}: ${response.body}',
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