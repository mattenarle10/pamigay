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
}

// Get POST data
$data = getPostData();

// Debug: Log received data
error_log("Received registration data: " . print_r($data, true));

// Validate required fields
$required_fields = ['name', 'email', 'password', 'role'];
$missing_fields = [];

foreach ($required_fields as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
        $missing_fields[] = $field;
    }
}

if (!empty($missing_fields)) {
    ApiResponse::send(ApiResponse::error('Required fields are missing', [
        'missing_fields' => $missing_fields,
        'received_data' => $data
    ]));
}

// Sanitize and validate input
$name = mysqli_real_escape_string($conn, $data['name']);
$email = mysqli_real_escape_string($conn, $data['email']);

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    ApiResponse::send(ApiResponse::error('Invalid email format', [
        'field' => 'email',
        'value' => $email
    ]));
}

// Check for common disposable email domains
$email_parts = explode('@', $email);
$domain = end($email_parts);
$invalid_domains = ['example.com', 'test.com', '123.com', 'temp-mail.org', 'tempmail.com', 'fakeinbox.com', 'mailinator.com'];
if (in_array(strtolower($domain), $invalid_domains)) {
    ApiResponse::send(ApiResponse::error('Please use a valid email address from a legitimate provider', [
        'field' => 'email',
        'value' => $email
    ]));
}

$password = $data['password'];
$role = mysqli_real_escape_string($conn, $data['role']);
$phone_number = isset($data['phone_number']) ? mysqli_real_escape_string($conn, $data['phone_number']) : null;

// Validate role
$valid_roles = ['Restaurant', 'Organization'];
if (!in_array($role, $valid_roles)) {
    ApiResponse::send(ApiResponse::error('Invalid role', [
        'provided_role' => $role,
        'valid_roles' => $valid_roles
    ]));
}

// Check if email already exists
$check_email = mysqli_query($conn, "SELECT id FROM users WHERE email = '$email'");
if (mysqli_num_rows($check_email) > 0) {
    ApiResponse::send(ApiResponse::error('Email already exists', [
        'email' => $email
    ]));
}

// Hash password
$hashed_password = password_hash($password, PASSWORD_DEFAULT);

// Set default profile image path
$profile_image = null;
$verification_document = null;

// Handle profile image if it's included in the request
if (isset($_FILES['profile_image']) && $_FILES['profile_image']['error'] == 0) {
    // Create uploads directory if it doesn't exist
    $upload_dir = '../uploads/profile_images/';
    
    // Use document root for absolute path
    $absolute_upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/pamigay/uploads/profile_images/';
    
    error_log("Attempting to use directory: $absolute_upload_dir");
    
    // Create parent directory first
    $parent_dir = dirname($absolute_upload_dir);
    if (!file_exists($parent_dir)) {
        if (!@mkdir($parent_dir, 0777, true)) {
            error_log("Failed to create parent directory: $parent_dir - " . error_get_last()['message']);
        } else {
            @chmod($parent_dir, 0777);
            error_log("Created parent directory: $parent_dir");
        }
    }
    
    // Now try to create the profile_images directory
    if (!file_exists($absolute_upload_dir)) {
        if (!@mkdir($absolute_upload_dir, 0777, true)) {
            error_log("Failed to create directory: $absolute_upload_dir - " . error_get_last()['message']);
            ApiResponse::send(ApiResponse::error('Failed to create upload directory'));
            exit();
        }
        @chmod($absolute_upload_dir, 0777);
        error_log("Created directory: $absolute_upload_dir");
    }
    
    // Check if the directory is writable
    if (!is_writable($absolute_upload_dir)) {
        error_log("Directory is not writable: $absolute_upload_dir");
        ApiResponse::send(ApiResponse::error('Upload directory is not writable'));
        exit();
    }
    
    // Get file info
    $file_name = $_FILES['profile_image']['name'];
    $file_tmp = $_FILES['profile_image']['tmp_name'];
    $file_size = $_FILES['profile_image']['size'];
    $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));
    
    // Set allowed file extensions
    $allowed_extensions = array('jpg', 'jpeg', 'png', 'gif');
    
    // Validate file extension
    if (!in_array($file_ext, $allowed_extensions)) {
        ApiResponse::send(ApiResponse::error('Invalid file type. Only JPG, JPEG, PNG, and GIF files are allowed.'));
        exit();
    }
    
    // Validate file size (max 5MB)
    $max_size = 5 * 1024 * 1024; // 5MB in bytes
    if ($file_size > $max_size) {
        ApiResponse::send(ApiResponse::error('File is too large. Maximum size is 5MB.'));
        exit();
    }
    
    // Generate a unique filename
    $new_file_name = time() . '_scaled_' . basename($file_name);
    $upload_path = $absolute_upload_dir . $new_file_name;
    
    // Move the uploaded file
    if (move_uploaded_file($file_tmp, $upload_path)) {
        $profile_image = 'uploads/profile_images/' . $new_file_name;
        error_log("Profile image uploaded successfully: $profile_image");
    } else {
        $error = error_get_last();
        error_log("Failed to move uploaded file: " . ($error ? $error['message'] : 'Unknown error'));
        ApiResponse::send(ApiResponse::error('Failed to upload profile image'));
        exit();
    }
}

// Handle verification document if it's included in the request
if (isset($_FILES['verification_document']) && $_FILES['verification_document']['error'] == 0) {
    // Create uploads directory if it doesn't exist
    $upload_dir = '../uploads/documents_images/';
    
    // Use document root for absolute path
    $absolute_upload_dir = $_SERVER['DOCUMENT_ROOT'] . '/pamigay/uploads/documents_images/';
    
    error_log("Attempting to use directory for verification document: $absolute_upload_dir");
    
    // Create parent directory first
    $parent_dir = dirname($absolute_upload_dir);
    if (!file_exists($parent_dir)) {
        if (!@mkdir($parent_dir, 0777, true)) {
            error_log("Failed to create parent directory: $parent_dir - " . error_get_last()['message']);
        } else {
            @chmod($parent_dir, 0777);
            error_log("Created parent directory: $parent_dir");
        }
    }
    
    // Now try to create the documents_images directory
    if (!file_exists($absolute_upload_dir)) {
        if (!@mkdir($absolute_upload_dir, 0777, true)) {
            error_log("Failed to create directory: $absolute_upload_dir - " . error_get_last()['message']);
            ApiResponse::send(ApiResponse::error('Failed to create verification document upload directory'));
            exit();
        }
        @chmod($absolute_upload_dir, 0777);
        error_log("Created directory: $absolute_upload_dir");
    }
    
    // Check if the directory is writable
    if (!is_writable($absolute_upload_dir)) {
        error_log("Directory is not writable: $absolute_upload_dir");
        ApiResponse::send(ApiResponse::error('Verification document upload directory is not writable'));
        exit();
    }
    
    // Get file info
    $file_name = $_FILES['verification_document']['name'];
    $file_tmp = $_FILES['verification_document']['tmp_name'];
    $file_size = $_FILES['verification_document']['size'];
    $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));
    
    // Set allowed file extensions
    $allowed_extensions = array('jpg', 'jpeg', 'png', 'gif', 'pdf');
    
    // Validate file extension
    if (!in_array($file_ext, $allowed_extensions)) {
        ApiResponse::send(ApiResponse::error('Invalid file type for verification document. Only JPG, JPEG, PNG, GIF, and PDF files are allowed.'));
        exit();
    }
    
    // Validate file size (max 10MB)
    $max_size = 10 * 1024 * 1024; // 10MB in bytes
    if ($file_size > $max_size) {
        ApiResponse::send(ApiResponse::error('Verification document is too large. Maximum size is 10MB.'));
        exit();
    }
    
    // Generate a unique filename
    $new_file_name = 'verification_' . time() . '.' . $file_ext;
    $upload_path = $absolute_upload_dir . $new_file_name;
    
    // Move the uploaded file
    if (move_uploaded_file($file_tmp, $upload_path)) {
        $verification_document = 'uploads/documents_images/' . $new_file_name;
        error_log("Verification document uploaded successfully: $verification_document");
    } else {
        $error = error_get_last();
        error_log("Failed to move uploaded verification document: " . ($error ? $error['message'] : 'Unknown error'));
        ApiResponse::send(ApiResponse::error('Failed to upload verification document'));
        exit();
    }
}

// Insert user data into database with verification status as pending
$insert_query = "INSERT INTO users (name, email, password, role, phone_number, profile_image, verification_document, is_verified, verification_status) 
                VALUES ('$name', '$email', '$hashed_password', '$role', '$phone_number', '$profile_image', '$verification_document', 0, 'Pending')";

if (mysqli_query($conn, $insert_query)) {
    $user_id = mysqli_insert_id($conn);
    
    // Create user stats entry
    $stats_query = "INSERT INTO user_stats (user_id) VALUES ('$user_id')";
    mysqli_query($conn, $stats_query);
    
    // Get the inserted user data
    $user_query = "SELECT * FROM users WHERE id = '$user_id'";
    $user_result = mysqli_query($conn, $user_query);
    $user_data = mysqli_fetch_assoc($user_result);
    
    // Send success response
    ApiResponse::send(ApiResponse::success('Registration successful! Your account is pending verification by admin.', [
        'user' => $user_data
    ]));
} else {
    error_log("SQL Error: " . mysqli_error($conn));
    ApiResponse::send(ApiResponse::error('Registration failed: ' . mysqli_error($conn)));
}

mysqli_close($conn);
?>