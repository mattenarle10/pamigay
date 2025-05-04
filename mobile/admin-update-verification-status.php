<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Add CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::send(ApiResponse::error('Only POST method is allowed', null, 405));
    exit();
}

// Get POST data
$user_id = isset($_POST['user_id']) ? mysqli_real_escape_string($conn, $_POST['user_id']) : '';
$status = isset($_POST['status']) ? mysqli_real_escape_string($conn, $_POST['status']) : '';
$notes = isset($_POST['notes']) ? mysqli_real_escape_string($conn, $_POST['notes']) : '';

// Validate required fields
if (empty($user_id) || empty($status)) {
    ApiResponse::send(ApiResponse::error('User ID and status are required'));
    exit();
}

// Validate status
$valid_statuses = ['Pending', 'Approved', 'Rejected'];
if (!in_array($status, $valid_statuses)) {
    ApiResponse::send(ApiResponse::error('Invalid status. Must be one of: ' . implode(', ', $valid_statuses)));
    exit();
}

// Set is_verified based on status
$is_verified = ($status === 'Approved') ? 1 : 0;

// Update user verification status
$query = "UPDATE users SET 
          verification_status = '$status', 
          is_verified = $is_verified, 
          verification_notes = '$notes',
          updated_at = NOW()
          WHERE id = '$user_id'";

$result = mysqli_query($conn, $query);

if (!$result) {
    ApiResponse::send(ApiResponse::error('Failed to update verification status: ' . mysqli_error($conn)));
    exit();
}

// Send response
ApiResponse::send(ApiResponse::success('Verification status updated successfully'));
?>
