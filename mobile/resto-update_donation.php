<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::send(ApiResponse::error('Only POST method is allowed', null, 405));
}

// Get POST data
$data = getPostData();

// Check if required fields are present
if (!isset($data['restaurant_id']) || empty($data['restaurant_id'])) {
    ApiResponse::send(ApiResponse::error('Restaurant ID is required'));
}

if (!isset($data['donation_id']) || empty($data['donation_id'])) {
    ApiResponse::send(ApiResponse::error('Donation ID is required'));
}

// Sanitize inputs
$restaurant_id = mysqli_real_escape_string($conn, $data['restaurant_id']);
$donation_id = mysqli_real_escape_string($conn, $data['donation_id']);

// Verify user is a restaurant
$check_restaurant = mysqli_query($conn, "SELECT id FROM users WHERE id = '$restaurant_id' AND role = 'Restaurant'");
if (mysqli_num_rows($check_restaurant) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as a restaurant', null, 403));
}

// Check if the donation exists and belongs to this restaurant
$check_donation = mysqli_query($conn, "SELECT id FROM food_donations WHERE id = '$donation_id' AND restaurant_id = '$restaurant_id'");
if (mysqli_num_rows($check_donation) == 0) {
    ApiResponse::send(ApiResponse::error('Donation not found or does not belong to this restaurant', null, 404));
}

// Prepare update data
$update_fields = [];

// Updatable fields
$allowed_fields = [
    'quantity', 'condition_status', 'category', 'pickup_deadline', 
    'pickup_window_start', 'pickup_window_end', 'photo_url', 'status'
];

foreach ($allowed_fields as $field) {
    if (isset($data[$field]) && !empty($data[$field])) {
        $value = mysqli_real_escape_string($conn, $data[$field]);
        $update_fields[] = "$field = '$value'";
    }
}

// If no fields to update
if (empty($update_fields)) {
    ApiResponse::send(ApiResponse::error('No fields to update'));
}

// Update donation in database
$update_query = "UPDATE food_donations SET " . implode(', ', $update_fields) . " WHERE id = '$donation_id' AND restaurant_id = '$restaurant_id'";
$result = mysqli_query($conn, $update_query);

if ($result) {
    // Get updated donation data
    $get_updated = mysqli_query($conn, "SELECT * FROM food_donations WHERE id = '$donation_id'");
    $updated_donation = mysqli_fetch_assoc($get_updated);
    
    ApiResponse::send(ApiResponse::success('Donation updated successfully', [
        'donation' => $updated_donation
    ]));
} else {
    ApiResponse::send(ApiResponse::error('Failed to update donation', mysqli_error($conn)));
}

mysqli_close($conn);
?>
