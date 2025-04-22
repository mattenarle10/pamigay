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

// Check if user_id is provided
if (!isset($data['user_id']) || empty($data['user_id'])) {
    ApiResponse::send(ApiResponse::error('User ID is required'));
}

// Sanitize input
$user_id = mysqli_real_escape_string($conn, $data['user_id']);

// Check if user exists
$check_user = mysqli_query($conn, "SELECT id, role FROM users WHERE id = '$user_id'");
if (mysqli_num_rows($check_user) == 0) {
    ApiResponse::send(ApiResponse::error('User not found', null, 404));
}

// Get the user's current role
$user = mysqli_fetch_assoc($check_user);
$current_role = $user['role'];

// Fields that can be updated
$updatable_fields = ['name', 'phone_number', 'location'];
$update_fields = [];

// Build update query
foreach ($updatable_fields as $field) {
    if (isset($data[$field]) && !empty($data[$field])) {
        $value = mysqli_real_escape_string($conn, $data[$field]);
        $update_fields[] = "$field = '$value'";
    }
}

// Email requires special validation
if (isset($data['email']) && !empty($data['email'])) {
    $email = mysqli_real_escape_string($conn, $data['email']);
    
    // Check if email already exists for another user
    $check_email = mysqli_query($conn, "SELECT id FROM users WHERE email = '$email' AND id != '$user_id'");
    if (mysqli_num_rows($check_email) > 0) {
        ApiResponse::send(ApiResponse::error('Email already in use by another account'));
    }
    
    $update_fields[] = "email = '$email'";
}

// Password update (optional)
if (isset($data['password']) && !empty($data['password'])) {
    $password = $data['password'];
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);
    $update_fields[] = "password = '$hashed_password'";
}

// If no fields to update
if (empty($update_fields)) {
    ApiResponse::send(ApiResponse::error('No fields to update'));
}

// Update user in database
$update_query = "UPDATE users SET " . implode(', ', $update_fields) . " WHERE id = '$user_id'";
$result = mysqli_query($conn, $update_query);

if ($result) {
    // Get updated user data (excluding password)
    $get_updated = mysqli_query($conn, "SELECT id, name, email, role, phone_number, location, profile_image FROM users WHERE id = '$user_id'");
    $updated_user = mysqli_fetch_assoc($get_updated);
    
    ApiResponse::send(ApiResponse::success('Profile updated successfully', [
        'user' => $updated_user
    ]));
} else {
    ApiResponse::send(ApiResponse::error('Failed to update profile', mysqli_error($conn)));
}

mysqli_close($conn);
?>
