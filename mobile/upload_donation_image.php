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

// Enable error reporting for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Log the request data for debugging
error_log("Received files: " . print_r($_FILES, true));
error_log("Received POST data: " . print_r($_POST, true));

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::send(ApiResponse::error('Only POST method is allowed', null, 405));
}

// Check if user_id is provided
if (!isset($_POST['user_id']) || empty($_POST['user_id'])) {
    ApiResponse::send(ApiResponse::error('User ID is required'));
}

// Sanitize user_id
$user_id = mysqli_real_escape_string($conn, $_POST['user_id']);

// Check if user exists
$check_user = mysqli_query($conn, "SELECT id FROM users WHERE id = '$user_id'");
if (mysqli_num_rows($check_user) == 0) {
    ApiResponse::send(ApiResponse::error('User not found'));
}

// Check if file was uploaded
if (!isset($_FILES['donation_image']) || $_FILES['donation_image']['error'] != 0) {
    $error_message = isset($_FILES['donation_image']) ? 'Upload error: ' . $_FILES['donation_image']['error'] : 'No file uploaded';
    ApiResponse::send(ApiResponse::error($error_message));
}

// Create uploads directory if it doesn't exist
$upload_dir = '../uploads/donation_images/';
// Use absolute path instead of relative path
//$upload_dir = '/Applications/XAMPP/xamppfiles/htdocs/pamigay-web/uploads/donation_images/';
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0777, true);
}

// Get file info
$file_name = $_FILES['donation_image']['name'];
$file_tmp = $_FILES['donation_image']['tmp_name'];
$file_size = $_FILES['donation_image']['size'];
$file_ext = strtolower(pathinfo($file_name, PATHINFO_EXTENSION));

// Set allowed file extensions
$allowed_extensions = array('jpg', 'jpeg', 'png', 'gif');

// Validate file extension
if (!in_array($file_ext, $allowed_extensions)) {
    ApiResponse::send(ApiResponse::error('Invalid file type. Only JPG, JPEG, PNG, and GIF files are allowed.'));
}

// Validate file size (max 5MB)
$max_size = 5 * 1024 * 1024; // 5MB in bytes
if ($file_size > $max_size) {
    ApiResponse::send(ApiResponse::error('File is too large. Maximum size is 5MB.'));
}

// Generate a unique filename
$new_file_name = 'donation_' . $user_id . '_' . time() . '.' . $file_ext;
$upload_path = $upload_dir . $new_file_name;

// Log file paths for debugging
error_log("Temporary file: $file_tmp");
error_log("Upload path: $upload_path");
error_log("Upload directory exists: " . (file_exists($upload_dir) ? 'Yes' : 'No'));
error_log("Upload directory is writable: " . (is_writable($upload_dir) ? 'Yes' : 'No'));

// Try to move the uploaded file
if (move_uploaded_file($file_tmp, $upload_path)) {
    // Generate the relative path for storing in database
    $relative_path = 'uploads/donation_images/' . $new_file_name;
    
    ApiResponse::send(ApiResponse::success('Donation image uploaded successfully', [
        'image_url' => $relative_path
    ]));
} else {
    // Log the error for debugging
    error_log("Failed to move uploaded file from $file_tmp to $upload_path");
    error_log("Error: " . error_get_last()['message']);
    
    // Try using copy instead
    if (copy($file_tmp, $upload_path)) {
        $relative_path = 'uploads/donation_images/' . $new_file_name;
        ApiResponse::send(ApiResponse::success('Donation image uploaded successfully (using copy)', [
            'image_url' => $relative_path
        ]));
    } else {
        // Try one more approach - create the directory with full permissions
        system('mkdir -p ' . escapeshellarg($upload_dir) . ' && chmod -R 777 ' . escapeshellarg($upload_dir));
        
        // Try again after setting permissions
        if (copy($file_tmp, $upload_path)) {
            $relative_path = 'uploads/donation_images/' . $new_file_name;
            ApiResponse::send(ApiResponse::success('Donation image uploaded successfully (after permission fix)', [
                'image_url' => $relative_path
            ]));
        } else {
            ApiResponse::send(ApiResponse::error('Failed to upload file: ' . error_get_last()['message']));
        }
    }
}
?>
