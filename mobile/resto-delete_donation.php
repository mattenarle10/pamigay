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
$check_donation = mysqli_query($conn, "SELECT id, status FROM food_donations WHERE id = '$donation_id' AND restaurant_id = '$restaurant_id'");
if (mysqli_num_rows($check_donation) == 0) {
    ApiResponse::send(ApiResponse::error('Donation not found or does not belong to this restaurant', null, 404));
}

// Get the current status
$donation = mysqli_fetch_assoc($check_donation);
if ($donation['status'] !== 'Available' && $donation['status'] !== 'Cancelled') {
    // If the donation is already picked up or in progress, don't allow deletion
    ApiResponse::send(ApiResponse::error('Cannot delete donation that is already in progress or completed', null, 400));
}

// Delete the donation from the database
$delete_query = "DELETE FROM food_donations WHERE id = '$donation_id' AND restaurant_id = '$restaurant_id' AND (status = 'Available' OR status = 'Cancelled')";
$result = mysqli_query($conn, $delete_query);

if ($result && mysqli_affected_rows($conn) > 0) {
    ApiResponse::send(ApiResponse::success('Donation deleted successfully'));
} else {
    ApiResponse::send(ApiResponse::error('Failed to delete donation or donation is no longer available', mysqli_error($conn)));
}

mysqli_close($conn);
?>
