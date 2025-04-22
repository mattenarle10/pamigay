<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Enable error logging to help debug the 500 error
ini_set('display_errors', 1);
error_reporting(E_ALL);
ini_set('log_errors', 1);
ini_set('error_log', '/Applications/XAMPP/xamppfiles/logs/php_error.log');

// Set content type to JSON
header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::send(ApiResponse::error('Only POST method is allowed', null, 405));
}

// Get POST data
$data = getPostData();

// Debug: Log incoming data
error_log('Request data: ' . json_encode($data));

// Check if required fields are present
if (!isset($data['collector_id']) || empty($data['collector_id'])) {
    ApiResponse::send(ApiResponse::error('Organization ID is required'));
}

if (!isset($data['donation_id']) || empty($data['donation_id'])) {
    ApiResponse::send(ApiResponse::error('Donation ID is required'));
}

// Sanitize inputs
$collector_id = mysqli_real_escape_string($conn, $data['collector_id']);
$donation_id = mysqli_real_escape_string($conn, $data['donation_id']);
$notes = isset($data['notes']) ? mysqli_real_escape_string($conn, $data['notes']) : '';
$pickup_time = isset($data['pickup_time']) ? mysqli_real_escape_string($conn, $data['pickup_time']) : null;

// Verify user is a collector/organization
try {
    $check_collector = mysqli_query($conn, "SELECT id FROM users WHERE id = '$collector_id' AND role = 'Organization'");
    if (!$check_collector) {
        throw new Exception("Query error: " . mysqli_error($conn));
    }
    
    if (mysqli_num_rows($check_collector) == 0) {
        ApiResponse::send(ApiResponse::error('User is not registered as an organization', null, 403));
    }

    // Check if the donation exists and is available
    $check_donation = mysqli_query($conn, "SELECT id, restaurant_id, status FROM food_donations WHERE id = '$donation_id'");
    if (!$check_donation) {
        throw new Exception("Query error: " . mysqli_error($conn));
    }
    
    if (mysqli_num_rows($check_donation) == 0) {
        ApiResponse::send(ApiResponse::error('Donation not found', null, 404));
    }

    $donation = mysqli_fetch_assoc($check_donation);
    if ($donation['status'] !== 'Available' && $donation['status'] !== 'Pending Pickup') {
        ApiResponse::send(ApiResponse::error('Donation is not available for pickup', null, 400));
    }

    // Check if food_pickups table exists
    $check_table = mysqli_query($conn, "SHOW TABLES LIKE 'food_pickups'");
    if (!$check_table) {
        throw new Exception("Query error: " . mysqli_error($conn));
    }
    
    // Check if this collector has already requested this donation
    $check_duplicate = mysqli_query($conn, "
        SELECT id FROM food_pickups 
        WHERE donation_id = '$donation_id' 
        AND collector_id = '$collector_id'
        AND status NOT IN ('Cancelled', 'Rejected')
    ");
    if (!$check_duplicate) {
        throw new Exception("Query error: " . mysqli_error($conn));
    }

    if (mysqli_num_rows($check_duplicate) > 0) {
        ApiResponse::send(ApiResponse::error('You have already requested this donation', null, 400));
    }

    // Begin transaction
    if (!mysqli_begin_transaction($conn)) {
        throw new Exception("Failed to start transaction: " . mysqli_error($conn));
    }

    // Create pickup request
    $pickup_time_value = $pickup_time ? "'$pickup_time'" : "NULL";
    $create_pickup = "
        INSERT INTO food_pickups (donation_id, collector_id, pickup_time, notes, status)
        VALUES ('$donation_id', '$collector_id', $pickup_time_value, '$notes', 'Requested')
    ";
    
    error_log("Executing query: $create_pickup");
    
    if (!mysqli_query($conn, $create_pickup)) {
        throw new Exception("Failed to create pickup request: " . mysqli_error($conn));
    }
    
    $pickup_id = mysqli_insert_id($conn);
    
    // We no longer update the donation status to 'Pending Pickup'
    // The donation remains 'Available' until a restaurant accepts a specific pickup request
    // This allows multiple organizations to request the same donation
    
    // Commit transaction
    if (!mysqli_commit($conn)) {
        throw new Exception("Failed to commit transaction: " . mysqli_error($conn));
    }
    
    // Get restaurant info for notification
    $restaurant_query = "
        SELECT u.name, u.email, u.phone_number 
        FROM users u
        JOIN food_donations fd ON fd.restaurant_id = u.id
        WHERE fd.id = '$donation_id'
    ";
    
    $restaurant_result = mysqli_query($conn, $restaurant_query);
    if (!$restaurant_result) {
        throw new Exception("Failed to get restaurant info: " . mysqli_error($conn));
    }
    
    $restaurant = mysqli_fetch_assoc($restaurant_result);
    
    // Get donation details
    $donation_query = "
        SELECT name as donation_name, quantity, category
        FROM food_donations
        WHERE id = '$donation_id'
    ";
    
    $donation_result = mysqli_query($conn, $donation_query);
    if (!$donation_result) {
        throw new Exception("Failed to get donation details: " . mysqli_error($conn));
    }
    
    $donation_details = mysqli_fetch_assoc($donation_result);
    
    ApiResponse::send(ApiResponse::success('Pickup request created successfully', [
        'pickup_id' => $pickup_id,
        'status' => 'Requested',
        'restaurant' => $restaurant,
        'donation' => $donation_details
    ]));
}
catch (Exception $e) {
    // Roll back transaction on error
    if (isset($conn) && $conn) {
        mysqli_rollback($conn);
    }
    error_log("Error in organization-request_pickup.php: " . $e->getMessage());
    ApiResponse::send(ApiResponse::error('Failed to create pickup request: ' . $e->getMessage(), null, 500));
}

mysqli_close($conn);

// Helper function to get POST data
function getPostData() {
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);
    
    // If JSON decoding failed, fall back to POST data
    if ($data === null) {
        return $_POST;
    }
    
    return $data;
}
?>