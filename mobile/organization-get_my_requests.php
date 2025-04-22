<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::send(ApiResponse::error('Only GET method is allowed', null, 405));
}

// Get organization ID from query parameter
$organization_id = isset($_GET['organization_id']) ? $_GET['organization_id'] : null;

if (!$organization_id) {
    ApiResponse::send(ApiResponse::error('Organization ID is required'));
}

// Optional status filter
$status_filter = isset($_GET['status']) ? mysqli_real_escape_string($conn, $_GET['status']) : null;
$status_condition = $status_filter ? "AND fp.status = '$status_filter'" : "";

// Sanitize input
$organization_id = mysqli_real_escape_string($conn, $organization_id);

// Verify user is an organization
$check_organization = mysqli_query($conn, "SELECT id FROM users WHERE id = '$organization_id' AND role = 'Organization'");
if (mysqli_num_rows($check_organization) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as an organization', null, 403));
}

// Get organization's pickup requests with donation and restaurant details
$requests_query = "
    SELECT fp.*, fd.name as donation_name, fd.quantity, fd.condition_status, 
           fd.category, fd.pickup_deadline, fd.pickup_window_start, fd.pickup_window_end,
           fd.photo_url, u.name as restaurant_name, u.phone_number as restaurant_phone
    FROM food_pickups fp
    JOIN food_donations fd ON fp.donation_id = fd.id
    JOIN users u ON fd.restaurant_id = u.id
    WHERE fp.collector_id = '$organization_id'
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

$requests_result = mysqli_query($conn, $requests_query);

if (!$requests_result) {
    ApiResponse::send(ApiResponse::error('Failed to retrieve pickup requests', mysqli_error($conn)));
}

// Prepare response data
$requests = [];
while ($row = mysqli_fetch_assoc($requests_result)) {
    // Calculate time remaining before deadline
    $deadline = new DateTime($row['pickup_deadline']);
    $now = new DateTime();
    $interval = $now->diff($deadline);
    
    $time_remaining = '';
    if ($interval->days > 0) {
        $time_remaining = $interval->format('%d days %h hours');
    } else {
        $time_remaining = $interval->format('%h hours %i minutes');
    }
    
    $row['time_remaining'] = $time_remaining;
    $requests[] = $row;
}

// Group requests by status
$grouped_requests = [
    'pending' => array_filter($requests, function($req) { return $req['status'] === 'Requested' || $req['status'] === 'Accepted'; }),
    'completed' => array_filter($requests, function($req) { return $req['status'] === 'Completed'; }),
    'cancelled' => array_filter($requests, function($req) { return $req['status'] === 'Cancelled'; })
];

// Reindex arrays to be JSON-friendly
foreach ($grouped_requests as $key => $value) {
    $grouped_requests[$key] = array_values($value);
}

ApiResponse::send(ApiResponse::success('Organization pickup requests retrieved successfully', [
    'all_requests' => $requests,
    'grouped_requests' => $grouped_requests,
    'counts' => [
        'total' => count($requests),
        'pending' => count($grouped_requests['pending']),
        'completed' => count($grouped_requests['completed']),
        'cancelled' => count($grouped_requests['cancelled'])
    ]
]));

mysqli_close($conn);
?>
