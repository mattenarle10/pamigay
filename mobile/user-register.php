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
        error_log("Successfully created directory: $absolute_upload_dir");
    }
    
    // Verify directory is writable
    if (!is_writable($absolute_upload_dir)) {
        error_log("Upload directory is not writable: $absolute_upload_dir");
        ApiResponse::send(ApiResponse::error('Upload directory is not writable'));
        exit();
    }
    
    // Get file info
    $file_name = $_FILES['profile_image']['name'];
    $file_tmp = $_FILES['profile_image']['tmp_name'];
    $file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));
    
    error_log("File info: name=$file_name, tmp=$file_tmp, ext=$file_ext");
    
    // Validate file extension
    $allowed_extensions = array('jpg', 'jpeg', 'png', 'gif');
    if (in_array($file_ext, $allowed_extensions)) {
        // Generate a unique filename
        $new_file_name = time() . '_' . $file_name;
        $upload_path = $absolute_upload_dir . $new_file_name;
        
        error_log("Attempting to move file from $file_tmp to $upload_path");
        
        // Move the uploaded file
        if (move_uploaded_file($file_tmp, $upload_path)) {
            $profile_image = 'uploads/profile_images/' . $new_file_name;
            error_log("Profile image uploaded: $profile_image");
        } else {
            $error = error_get_last();
            error_log("Failed to move uploaded file: " . ($error ? $error['message'] : 'Unknown error'));
            
            // Try to create directory with system command as fallback
            exec("mkdir -p " . escapeshellarg($absolute_upload_dir) . " 2>&1", $output, $return_var);
            error_log("mkdir command result: " . implode(", ", $output) . " (return code: $return_var)");
            
            if ($return_var === 0 && @move_uploaded_file($file_tmp, $upload_path)) {
                $profile_image = 'uploads/profile_images/' . $new_file_name;
                error_log("Profile image uploaded after mkdir command: $profile_image");
            } else {
                ApiResponse::send(ApiResponse::error('Failed to upload profile image'));
                exit();
            }
        }
    } else {
        error_log("Invalid file extension: $file_ext");
        $profile_image = null;
    }
} else {
    error_log("No file uploaded or error in upload: " . ($_FILES['profile_image']['error'] ?? 'No file'));
    $profile_image = null;
}

// Prepare SQL query with profile_image field
$query = "INSERT INTO users (name, email, password, role, phone_number, profile_image) 
          VALUES ('$name', '$email', '$hashed_password', '$role', " . 
          ($phone_number ? "'$phone_number'" : "NULL") . ", " .
          (isset($profile_image) && $profile_image ? "'$profile_image'" : "NULL") . ")";

error_log("SQL Query: $query");

// Execute query
if (mysqli_query($conn, $query)) {
    $user_id = mysqli_insert_id($conn);
    error_log("User registered successfully with ID: $user_id");
    
    // Create user stats record if it doesn't exist
    $stats_check = mysqli_query($conn, "SELECT user_id FROM user_stats WHERE user_id = '$user_id'");
    if (mysqli_num_rows($stats_check) == 0) {
        $stats_query = "INSERT INTO user_stats (user_id, total_donated, total_collected, total_saved) 
                       VALUES ('$user_id', 0, 0, 0)";
        mysqli_query($conn, $stats_query);
    }
    
    ApiResponse::send(ApiResponse::success('Registration successful', [
        'user' => [
            'id' => $user_id,
            'name' => $name,
            'email' => $email,
            'role' => $role,
            'phone_number' => $phone_number,
            'profile_image' => $profile_image
        ]
    ]));
} else {
    error_log("SQL Error: " . mysqli_error($conn));
    ApiResponse::send(ApiResponse::error('Registration failed: ' . mysqli_error($conn)));
}

mysqli_close($conn);
?>