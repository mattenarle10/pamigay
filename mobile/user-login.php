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

// Debug: Log received data
error_log("Received login data: " . print_r($data, true));

// Validate required fields
$email = isset($data['email']) ? mysqli_real_escape_string($conn, $data['email']) : '';
$password = isset($data['password']) ? $data['password'] : '';

if (empty($email) || empty($password)) {
    ApiResponse::send(ApiResponse::error('Email and password are required', [
        'email_provided' => !empty($email),
        'password_provided' => !empty($password)
    ]));
}

// Query to check user credentials
$query = "SELECT id, email, password, name, role, phone_number, profile_image, is_verified, verification_status FROM users WHERE email = '$email'";
$result = mysqli_query($conn, $query);

// Debug: Log query and result
error_log("SQL Query: " . $query);
error_log("Query result: " . print_r($result, true));

if (!$result) {
    ApiResponse::send(ApiResponse::error('Query failed', [
        'sql_error' => mysqli_error($conn),
        'query' => $query
    ]));
}

if (mysqli_num_rows($result) > 0) {
    $user = mysqli_fetch_assoc($result);
    
    if (password_verify($password, $user['password'])) {
        // Check if user is verified
        if ($user['verification_status'] == 'Pending') {
            ApiResponse::send(ApiResponse::error('Your account is pending verification by admin. Please wait for approval.', [
                'verification_status' => 'Pending'
            ]));
        } else if ($user['verification_status'] == 'Rejected') {
            ApiResponse::send(ApiResponse::error('Your account verification was rejected. Please contact support for assistance.', [
                'verification_status' => 'Rejected'
            ]));
        } else if ($user['verification_status'] == 'Approved' && $user['is_verified'] == 1) {
            // Remove password from response
            unset($user['password']);
            
            ApiResponse::send(ApiResponse::success('Login successful', [
                'user' => $user
            ]));
        } else {
            // For backward compatibility with existing accounts
            if ($user['verification_status'] === NULL) {
                // Remove password from response
                unset($user['password']);
                
                ApiResponse::send(ApiResponse::success('Login successful', [
                    'user' => $user
                ]));
            } else {
                ApiResponse::send(ApiResponse::error('Account status issue. Please contact support.', [
                    'verification_status' => $user['verification_status'],
                    'is_verified' => $user['is_verified']
                ]));
            }
        }
    } else {
        ApiResponse::send(ApiResponse::error('Invalid password', [
            'email' => $email,
            'password_verified' => false
        ]));
    }
} else {
    ApiResponse::send(ApiResponse::error('User not found', [
        'email' => $email,
        'rows_found' => mysqli_num_rows($result)
    ]));
}

mysqli_close($conn);
?>