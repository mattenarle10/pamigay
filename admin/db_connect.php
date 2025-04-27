<?php
// Common database connection file
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database connection details
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'pamigay_db';

// Create connection
$conn = mysqli_connect($host, $username, $password, $database);

// Check connection
if (!$conn) {
    die(json_encode([
        'success' => false,
        'message' => 'Connection failed: ' . mysqli_connect_error(),
        'debug_info' => [
            'host' => $host,
            'database' => $database,
            'error' => mysqli_connect_error()
        ]
    ]));
}

// Function to safely get POST data
function getPostData() {
    $contentType = isset($_SERVER['CONTENT_TYPE']) ? $_SERVER['CONTENT_TYPE'] : '';
    
    // Debug: Log content type
    error_log("Content-Type: " . $contentType);
    error_log("POST data: " . print_r($_POST, true));
    error_log("FILES data: " . print_r($_FILES, true));
    
    // If it's multipart form data, use $_POST
    if (strpos($contentType, 'multipart/form-data') !== false) {
        return $_POST;
    }
    
    // If it's JSON, use php://input
    if (strpos($contentType, 'application/json') !== false) {
        return json_decode(file_get_contents('php://input'), true);
    }
    
    // Default: try to use $_POST first, then php://input
    if (!empty($_POST)) {
        return $_POST;
    }
    
    // Fallback to php://input
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    // If json_decode fails, return raw $_POST
    return $data !== null ? $data : $_POST;
}

// Function to send JSON response
function sendResponse($data) {
    header('Content-Type: application/json');
    echo json_encode($data);
    exit();
}
?>
