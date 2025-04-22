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
  }) async {
    try {
      final Map<String, String> requestBody = {
        'pickup_id': pickupId,
        'status': status,
      };
      
      if (notes != null) {
        requestBody['notes'] = notes;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl$updatePickupEndpoint'),
        body: requestBody,
      );
      
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
}
