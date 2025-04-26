<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Debug logging
error_log('[' . date('d-M-Y H:i:s e') . '] GET data: ' . print_r($_GET, true));

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::send(ApiResponse::error('Only GET method is allowed', null, 405));
}

// Get restaurant ID parameter
$restaurant_id = isset($_GET['restaurant_id']) ? $_GET['restaurant_id'] : null;

// Validate required parameters
if (!$restaurant_id) {
    ApiResponse::send(ApiResponse::error('Restaurant ID is required'));
}

// Sanitize inputs
$restaurant_id = mysqli_real_escape_string($conn, $restaurant_id);

// Verify user is a restaurant
$check_restaurant = mysqli_query($conn, "SELECT id FROM users WHERE id = '$restaurant_id' AND role = 'Restaurant'");
if (mysqli_num_rows($check_restaurant) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as a restaurant', null, 403));
}

try {
    // Get all pickup requests for this restaurant's donations
    $query = "
        SELECT 
            fp.id,
            fp.donation_id,
            fp.collector_id,
            fp.pickup_time,
            fp.status,
            fp.notes,
            fp.rating,
            fp.created_at,
            fp.updated_at,
            fd.name AS donation_name,
            fd.quantity,
            fd.category,
            fd.photo_url,
            u.name AS organization_name,
            u.email AS organization_email,
            u.phone_number AS organization_phone,
            u.profile_image AS organization_profile_image
        FROM food_pickups fp
        JOIN food_donations fd ON fp.donation_id = fd.id
        JOIN users u ON fp.collector_id = u.id
        WHERE fd.restaurant_id = '$restaurant_id'
        ORDER BY fp.updated_at DESC
    ";
    
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        throw new Exception('Database error: ' . mysqli_error($conn));
    }
    
    // Fetch all pickup requests
    $pickups = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $pickups[] = $row;
    }
    
    // Return success response with data
    ApiResponse::send(ApiResponse::success('Pickup requests retrieved successfully', [
        'pickups' => $pickups
    ]));
    
} catch (Exception $e) {
    $code = isset($e->code) ? $e->code : 400;
    ApiResponse::send(ApiResponse::error($e->getMessage(), null, $code));
}
?>
