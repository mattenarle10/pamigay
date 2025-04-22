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

// Sanitize input
$collector_id = mysqli_real_escape_string($conn, $collector_id);

// Verify user is a collector
$check_collector = mysqli_query($conn, "SELECT id FROM users WHERE id = '$collector_id' AND role = 'Organization'");
if (mysqli_num_rows($check_collector) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as an organization', null, 403));
}

// Initialize stats
$stats = [
    'total_pickups' => 0,
    'completed_pickups' => 0,
    'food_saved_kg' => 0, // Estimating food quantity saved
    'recent_activity' => [],
    'top_restaurants' => [],
    'pickup_by_category' => []
];

// Check if food_pickups table exists
$check_table = mysqli_query($conn, "SHOW TABLES LIKE 'food_pickups'");
if (mysqli_num_rows($check_table) > 0) {
    // Total pickups
    $total_pickups_query = "
        SELECT COUNT(*) as count 
        FROM food_pickups 
        WHERE collector_id = '$collector_id'
    ";
    $total_result = mysqli_query($conn, $total_pickups_query);
    if ($total_result) {
        $stats['total_pickups'] = mysqli_fetch_assoc($total_result)['count'];
    }
    
    // Completed pickups
    $completed_pickups_query = "
        SELECT COUNT(*) as count 
        FROM food_pickups 
        WHERE collector_id = '$collector_id' AND status = 'Completed'
    ";
    $completed_result = mysqli_query($conn, $completed_pickups_query);
    if ($completed_result) {
        $stats['completed_pickups'] = mysqli_fetch_assoc($completed_result)['count'];
    }
    
    // Get user stats (if exists)
    $check_stats_table = mysqli_query($conn, "SHOW TABLES LIKE 'user_stats'");
    if (mysqli_num_rows($check_stats_table) > 0) {
        $user_stats_query = "
            SELECT total_collected 
            FROM user_stats 
            WHERE user_id = '$collector_id'
        ";
        $user_stats_result = mysqli_query($conn, $user_stats_query);
        if ($user_stats_result && mysqli_num_rows($user_stats_result) > 0) {
            $user_stats = mysqli_fetch_assoc($user_stats_result);
            $stats['food_saved_kg'] = floatval($user_stats['total_collected']) * 2; // Assuming 2kg per pickup as an estimate
        }
    }
    
    // Recent activity (last 5 pickups)
    $recent_activity_query = "
        SELECT fp.id, fp.status, fp.created_at, fp.updated_at, 
               CONCAT(fd.category, ' (', fd.quantity, ')') as donation_name, u.name as restaurant_name
        FROM food_pickups fp
        JOIN food_donations fd ON fp.donation_id = fd.id
        JOIN users u ON fd.restaurant_id = u.id
        WHERE fp.collector_id = '$collector_id'
        ORDER BY fp.updated_at DESC
        LIMIT 5
    ";
    $recent_result = mysqli_query($conn, $recent_activity_query);
    if ($recent_result) {
        while ($row = mysqli_fetch_assoc($recent_result)) {
            $stats['recent_activity'][] = $row;
        }
    }
    
    // Top restaurants (most pickups from)
    $top_restaurants_query = "
        SELECT u.name as restaurant_name, COUNT(*) as pickup_count
        FROM food_pickups fp
        JOIN food_donations fd ON fp.donation_id = fd.id
        JOIN users u ON fd.restaurant_id = u.id
        WHERE fp.collector_id = '$collector_id' AND fp.status = 'Completed'
        GROUP BY fd.restaurant_id
        ORDER BY pickup_count DESC
        LIMIT 3
    ";
    $top_restaurants_result = mysqli_query($conn, $top_restaurants_query);
    if ($top_restaurants_result) {
        while ($row = mysqli_fetch_assoc($top_restaurants_result)) {
            $stats['top_restaurants'][] = $row;
        }
    }
    
    // Pickups by category
    $by_category_query = "
        SELECT fd.category, COUNT(*) as count
        FROM food_pickups fp
        JOIN food_donations fd ON fp.donation_id = fd.id
        WHERE fp.collector_id = '$collector_id' AND fp.status = 'Completed'
        GROUP BY fd.category
    ";
    $by_category_result = mysqli_query($conn, $by_category_query);
    if ($by_category_result) {
        while ($row = mysqli_fetch_assoc($by_category_result)) {
            $stats['pickup_by_category'][] = $row;
        }
    }
}

// Get pending pickups count
$pending_pickups_query = "
    SELECT COUNT(*) as count 
    FROM food_pickups 
    WHERE collector_id = '$collector_id' AND status IN ('Requested', 'Accepted')
";
$pending_result = mysqli_query($conn, $pending_pickups_query);
if ($pending_result) {
    $stats['pending_pickups'] = mysqli_fetch_assoc($pending_result)['count'];
}

// Get environmental impact estimation
// Rough estimate: 4.5 kg CO2 saved per kg of food rescued
$stats['co2_saved_kg'] = $stats['food_saved_kg'] * 4.5;

ApiResponse::send(ApiResponse::success('Dashboard statistics retrieved successfully', $stats));

mysqli_close($conn);
?>