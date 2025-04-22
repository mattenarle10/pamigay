<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';
require_once 'update_expired_donations.php'; // Include the expired donations handler

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::send(ApiResponse::error('Only GET method is allowed', null, 405));
}

// Get collector ID from query parameter
$collector_id = isset($_GET['collector_id']) ? $_GET['collector_id'] : null;

if (!$collector_id) {
    ApiResponse::send(ApiResponse::error('Organization ID is required'));
}

// Sanitize input
$collector_id = mysqli_real_escape_string($conn, $collector_id);

// Verify user is a collector
$check_collector = mysqli_query($conn, "SELECT id FROM users WHERE id = '$collector_id' AND role = 'Organization'");
if (mysqli_num_rows($check_collector) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as an organization', null, 403));
}

// First, update any expired donations
updateExpiredDonations();

// Optional category filter
$category_filter = isset($_GET['category']) ? mysqli_real_escape_string($conn, $_GET['category']) : null;
$category_condition = $category_filter ? "AND fd.category = '$category_filter'" : "";

// Optional condition status filter
$condition_filter = isset($_GET['condition_status']) ? mysqli_real_escape_string($conn, $_GET['condition_status']) : null;
$condition_condition = $condition_filter ? "AND fd.condition_status = '$condition_filter'" : "";

// Get current time for pickup window calculations
$current_time = date('Y-m-d H:i:s');

// Get available donations sorted by deadline (soonest first)
$donations_query = "
    SELECT fd.*, u.name as restaurant_name, u.phone_number as restaurant_phone, u.location as restaurant_location,
           CASE 
               WHEN '$current_time' BETWEEN fd.pickup_window_start AND fd.pickup_window_end THEN 'active'
               WHEN '$current_time' < fd.pickup_window_start THEN 'upcoming'
               ELSE 'expired'
           END as pickup_window_status
    FROM food_donations fd
    JOIN users u ON fd.restaurant_id = u.id
    WHERE (fd.status = 'Available' OR fd.status = 'Pending Pickup')
    $category_condition
    $condition_condition
    AND fd.pickup_deadline > '$current_time'
    AND NOT EXISTS (
        -- Hide donations that this organization has already requested
        SELECT 1 FROM food_pickups fp 
        WHERE fp.donation_id = fd.id 
        AND fp.collector_id = '$collector_id'
        AND fp.status != 'Cancelled'
    )
    AND NOT EXISTS (
        -- Hide donations that have already been accepted for pickup by any organization
        SELECT 1 FROM food_pickups fp 
        WHERE fp.donation_id = fd.id 
        AND fp.status = 'Accepted'
    )
    ORDER BY fd.pickup_deadline ASC
";

$donations_result = mysqli_query($conn, $donations_query);

if (!$donations_result) {
    ApiResponse::send(ApiResponse::error('Failed to retrieve donations', mysqli_error($conn)));
}

// Prepare response data
$donations = [];
while ($row = mysqli_fetch_assoc($donations_result)) {
    // Calculate time remaining before deadline
    $deadline = new DateTime($row['pickup_deadline']);
    $now = new DateTime();
    
    // Skip if deadline has already passed (double-check)
    if ($deadline < $now) {
        continue;
    }
    
    $interval = $now->diff($deadline);
    
    // Format time remaining
    $time_remaining = '';
    if ($interval->days > 0) {
        $time_remaining = $interval->format('%d days %h hours');
    } else if ($interval->h > 0) {
        $time_remaining = $interval->format('%h hours %i minutes');
    } else {
        $time_remaining = $interval->format('%i minutes');
    }
    
    $row['time_remaining'] = $time_remaining;
    
    // Add urgency level based on time remaining
    if ($interval->days == 0 && $interval->h < 3) {
        $row['urgency'] = 'high';
    } else if ($interval->days == 0 && $interval->h < 12) {
        $row['urgency'] = 'medium';
    } else {
        $row['urgency'] = 'low';
    }
    
    // Check if donation has pending requests (for UI indication)
    $pending_requests_query = "
        SELECT COUNT(*) as request_count 
        FROM food_pickups 
        WHERE donation_id = '{$row['id']}' 
        AND status = 'Requested'
    ";
    
    $pending_result = mysqli_query($conn, $pending_requests_query);
    if ($pending_result && $pending_row = mysqli_fetch_assoc($pending_result)) {
        $row['pending_requests'] = (int)$pending_row['request_count'];
    } else {
        $row['pending_requests'] = 0;
    }
    
    $donations[] = $row;
}

ApiResponse::send(ApiResponse::success('Available donations retrieved successfully', [
    'count' => count($donations),
    'donations' => $donations,
    'current_time' => $current_time
]));

mysqli_close($conn);
?>