<?php
// Admin Authentication Endpoint

// Database connection parameters
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'pamigay_db');

// Start session
session_start();

// Function to connect to database
function connectDB() {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }
    
    return $conn;
}

// Function to sanitize input data
function sanitizeInput($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}

// Handle login request
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $username = sanitizeInput($_POST['username']);
    $password = sanitizeInput($_POST['password']);
    
    // For now, use hardcoded admin credentials
    // In a real implementation, this would check against a database
    if ($username === 'pamigayadmin' && $password === 'admin123') {
        // Set session variables
        $_SESSION['admin_logged_in'] = true;
        $_SESSION['admin_username'] = $username;
        
        // Return success response
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'message' => 'Login successful']);
        exit;
    } else {
        // Return error response
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Invalid username or password']);
        exit;
    }
}

// Check if user is logged in
function isAdminLoggedIn() {
    return isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
}

// Logout function
function logoutAdmin() {
    // Unset all session variables
    $_SESSION = array();
    
    // Destroy the session
    session_destroy();
    
    // Redirect to login page
    header("Location: ../public/index.html");
    exit;
}

// Handle logout request
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    logoutAdmin();
}

// If this file is accessed directly for session check
if ($_SERVER['REQUEST_METHOD'] === 'GET' && !isset($_GET['action'])) {
    header('Content-Type: application/json');
    echo json_encode(['logged_in' => isAdminLoggedIn()]);
    exit;
}
?>
