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

// Get all verification requests
$query = "SELECT id, name, email, role, phone_number, profile_image, verification_document, 
          is_verified, verification_status, verification_notes, created_at, updated_at 
          FROM users 
          WHERE verification_document IS NOT NULL 
          ORDER BY 
            CASE 
                WHEN verification_status = 'Pending' THEN 1
                WHEN verification_status = 'Approved' THEN 2
                WHEN verification_status = 'Rejected' THEN 3
                ELSE 4
            END, 
            created_at DESC";

$result = mysqli_query($conn, $query);

if (!$result) {
    ApiResponse::send(ApiResponse::error('Failed to fetch verification requests: ' . mysqli_error($conn)));
    exit();
}

$verifications = [];
while ($row = mysqli_fetch_assoc($result)) {
    $verifications[] = $row;
}

// Send response
ApiResponse::send(ApiResponse::success('Verification requests fetched successfully', [
    'verifications' => $verifications
]));
?>
