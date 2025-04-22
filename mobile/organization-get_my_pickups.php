<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::send(ApiResponse::error('Only GET method is allowed', null, 405));
}

// Get collector ID from query parameter
$collector_id = isset($_GET['collector_id']) ? $_GET['collector_id'] : null;

if (!$collector_id) {
    ApiResponse::send(ApiResponse::error('Organization ID is required'));
}

// Optional status filter
$status_filter = isset($_GET['status']) ? mysqli_real_escape_string($conn, $_GET['status']) : null;

// Sanitize input
$collector_id = mysqli_real_escape_string($conn, $collector_id);

// Verify user is a collector
$check_collector = mysqli_query($conn, "SELECT id FROM users WHERE id = '$collector_id' AND role = 'Organization'");
if (mysqli_num_rows($check_collector) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as an organization', null, 403));
}

// Check if food_pickups table exists
$check_table = mysqli_query($conn, "SHOW TABLES LIKE 'food_pickups'");
if (mysqli_num_rows($check_table) == 0) {
    // Return empty result if table doesn't exist yet
    ApiResponse::send(ApiResponse::success('No pickups found', [
        'count' => 0,
        'pickups' => []
    ]));
}

// Build query with optional status filter
$status_condition = "";
if ($status_filter) {
    $status_condition = "AND fp.status = '$status_filter'";
}

// Get pickups
$pickups_query = "
    SELECT fp.*, fd.quantity, fd.condition_status, fd.category, 
           fd.pickup_deadline, fd.pickup_window_start, fd.pickup_window_end,
           u.name as restaurant_name, u.phone_number as restaurant_phone
    FROM food_pickups fp
    JOIN food_donations fd ON fp.donation_id = fd.id
    JOIN users u ON fd.restaurant_id = u.id
    WHERE fp.collector_id = '$collector_id'
    $status_condition
    ORDER BY 
        CASE 
            WHEN fp.status = 'Requested' THEN 1
            WHEN fp.status = 'Accepted' THEN 2
            WHEN fp.status = 'Completed' THEN 3
            WHEN fp.status = 'Cancelled' THEN 4
        END,
        fp.created_at DESC
";

$pickups_result = mysqli_query($conn, $pickups_query);

if (!$pickups_result) {
    ApiResponse::send(ApiResponse::error('Failed to retrieve pickups', mysqli_error($conn)));
}

// Prepare response data
$pickups = [];
while ($row = mysqli_fetch_assoc($pickups_result)) {
    $pickups[] = $row;
}

ApiResponse::send(ApiResponse::success('Pickups retrieved successfully', [
    'count' => count($pickups),
    'pickups' => $pickups
]));

mysqli_close($conn);
?>