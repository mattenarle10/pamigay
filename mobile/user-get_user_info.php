<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::send(ApiResponse::error('Only GET method is allowed', null, 405));
}

// Get user_id from query parameter
$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if (!$user_id) {
    ApiResponse::send(ApiResponse::error('User ID is required'));
}

// Sanitize input
$user_id = mysqli_real_escape_string($conn, $user_id);

// Get user information from database
$query = "SELECT id, name, email, role, phone_number, profile_image, location FROM users WHERE id = '$user_id'";
$result = mysqli_query($conn, $query);

if (!$result) {
    ApiResponse::send(ApiResponse::error('Failed to fetch user information', mysqli_error($conn)));
}

if (mysqli_num_rows($result) > 0) {
    $user = mysqli_fetch_assoc($result);
    ApiResponse::send(ApiResponse::success('User information retrieved successfully', [
        'user' => $user
    ]));
} else {
    ApiResponse::send(ApiResponse::error('User not found'));
}

mysqli_close($conn);
?>
