<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';
require_once 'update_expired_donations.php'; // Include the expired donations handler

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::send(ApiResponse::error('Only GET method is allowed', null, 405));
}

// Get restaurant ID from query parameter
$restaurant_id = isset($_GET['restaurant_id']) ? $_GET['restaurant_id'] : null;

if (!$restaurant_id) {
    ApiResponse::send(ApiResponse::error('Restaurant ID is required'));
}

// Sanitize input
$restaurant_id = mysqli_real_escape_string($conn, $restaurant_id);

// Verify user is a restaurant
$check_restaurant = mysqli_query($conn, "SELECT id FROM users WHERE id = '$restaurant_id' AND role = 'Restaurant'");
if (mysqli_num_rows($check_restaurant) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as a restaurant', null, 403));
}

// First, update any expired donations
updateExpiredDonations();

// Check if the table exists
$check_table = mysqli_query($conn, "SHOW TABLES LIKE 'food_donations'");
if (mysqli_num_rows($check_table) == 0) {
    // If table doesn't exist, return empty array
    ApiResponse::send(ApiResponse::success('No donations found', ['donations' => []]));
}

// Get current time for pickup window calculations
$current_time = date('Y-m-d H:i:s');

// Query to get all donations for the restaurant with pickup window status
$query = "
    SELECT fd.*, 
           CASE 
               WHEN fd.status = 'Available' AND '$current_time' BETWEEN fd.pickup_window_start AND fd.pickup_window_end THEN 'active'
               WHEN fd.status = 'Available' AND '$current_time' < fd.pickup_window_start THEN 'upcoming'
               WHEN fd.status = 'Available' AND '$current_time' > fd.pickup_window_end THEN 'expired'
               ELSE 'not_applicable'
           END as pickup_window_status
    FROM food_donations fd 
    WHERE fd.restaurant_id = '$restaurant_id' 
    ORDER BY fd.created_at DESC
";

$result = mysqli_query($conn, $query);

if (!$result) {
    ApiResponse::send(ApiResponse::error('Failed to retrieve donations', mysqli_error($conn)));
}

// Fetch all donations and store in array
$donations = [];
while ($row = mysqli_fetch_assoc($result)) {
    // For available donations, calculate time remaining
    if ($row['status'] == 'Available') {
        $deadline = new DateTime($row['pickup_deadline']);
        $now = new DateTime();
        
        // If deadline has passed but status wasn't updated, mark it
        if ($deadline < $now) {
            // This is a fallback - the updateExpiredDonations should have caught this
            $row['status_note'] = 'Deadline has passed but status not updated';
            $row['needs_update'] = true;
        } else {
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
        }
    }
    
    $donations[] = $row;
}

ApiResponse::send(ApiResponse::success('Donations retrieved successfully', [
    'count' => count($donations),
    'donations' => $donations,
    'current_time' => $current_time
]));

mysqli_close($conn);
?>
