<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Prevent PHP errors from being displayed in the response
ini_set('display_errors', 0);
error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING);

// Set content type to JSON
header('Content-Type: application/json');

// Log request for debugging
error_log("GET_DONATION_BY_ID: Received request with params: " . json_encode($_GET));

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::send(ApiResponse::error('Only GET method is allowed', null, 405));
}

// Get donation ID from query parameters
if (!isset($_GET['donation_id']) || empty($_GET['donation_id'])) {
    ApiResponse::send(ApiResponse::error('Donation ID is required'));
}

// Sanitize input
$donation_id = mysqli_real_escape_string($conn, $_GET['donation_id']);
error_log("GET_DONATION_BY_ID: Looking for donation with ID: $donation_id");

// Query to get donation details with restaurant info
$query = "
    SELECT 
        fd.*,
        u.name as restaurant_name,
        u.phone_number as restaurant_phone,
        u.location as restaurant_location
    FROM 
        food_donations fd
    JOIN 
        users u ON fd.restaurant_id = u.id
    WHERE 
        fd.id = '$donation_id'
";

try {
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        error_log("GET_DONATION_BY_ID: Database error: " . mysqli_error($conn));
        ApiResponse::send(ApiResponse::error('Database error: ' . mysqli_error($conn)));
    }
    
    if (mysqli_num_rows($result) == 0) {
        error_log("GET_DONATION_BY_ID: Donation not found with ID: $donation_id");
        ApiResponse::send(ApiResponse::error('Donation not found', null, 404));
    }
    
    // Get donation data
    $donation = mysqli_fetch_assoc($result);
    
    // Format the response
    ApiResponse::send(ApiResponse::success('Donation retrieved successfully', [
        'donation' => $donation
    ]));
} catch (Exception $e) {
    error_log("GET_DONATION_BY_ID: Exception: " . $e->getMessage());
    ApiResponse::send(ApiResponse::error('Server error: ' . $e->getMessage(), null, 500));
}

mysqli_close($conn);
?>
