<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

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

// Initialize stats object
$stats = [
    'total_donated' => 0,
    'total_collected' => 0,
    'total_saved' => 0,
    'available_donations' => 0,
    'pending_pickups' => 0,
    'completed_donations' => 0,
    'is_top_donor' => false
];

// Check if food_donations table exists
$check_table = mysqli_query($conn, "SHOW TABLES LIKE 'food_donations'");
if (mysqli_num_rows($check_table) > 0) {
    // Count available donations
    $available_query = "SELECT COUNT(*) as count FROM food_donations 
                        WHERE restaurant_id = '$restaurant_id' AND status = 'Available'";
    $available_result = mysqli_query($conn, $available_query);
    if ($available_result) {
        $stats['available_donations'] = (int)mysqli_fetch_assoc($available_result)['count'];
    }
    
    // Count completed donations
    $completed_query = "SELECT COUNT(*) as count FROM food_donations 
                        WHERE restaurant_id = '$restaurant_id' AND status = 'Completed'";
    $completed_result = mysqli_query($conn, $completed_query);
    if ($completed_result) {
        $stats['completed_donations'] = (int)mysqli_fetch_assoc($completed_result)['count'];
    }
    
    // Count pending pickups
    $pending_query = "SELECT COUNT(*) as count FROM food_donations 
                    WHERE restaurant_id = '$restaurant_id' AND status = 'Pending Pickup'";
    $pending_result = mysqli_query($conn, $pending_query);
    if ($pending_result) {
        $stats['pending_pickups'] = (int)mysqli_fetch_assoc($pending_result)['count'];
    }
}

// Check if user_stats table exists
$check_stats_table = mysqli_query($conn, "SHOW TABLES LIKE 'user_stats'");
if (mysqli_num_rows($check_stats_table) > 0) {
    // Get user stats
    $stats_query = "SELECT * FROM user_stats WHERE user_id = '$restaurant_id'";
    $stats_result = mysqli_query($conn, $stats_query);
    
    if ($stats_result && mysqli_num_rows($stats_result) > 0) {
        $user_stats = mysqli_fetch_assoc($stats_result);
        $stats['total_donated'] = (float)$user_stats['total_donated'];
        $stats['total_collected'] = (float)$user_stats['total_collected'];
        $stats['total_saved'] = (float)$user_stats['total_saved'];
        $stats['is_top_donor'] = (bool)$user_stats['is_top_donor'];
    }
    
    // If they don't have stats, create entry in user_stats
    else {
        // Create table if it doesn't exist
        $create_stats_table = "
        CREATE TABLE IF NOT EXISTS user_stats (
            user_id INT PRIMARY KEY,
            total_donated FLOAT DEFAULT 0,
            total_collected FLOAT DEFAULT 0,
            total_saved FLOAT DEFAULT 0,
            is_top_donor BOOLEAN DEFAULT FALSE,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )";
        mysqli_query($conn, $create_stats_table);
        
        // Insert default stats
        $insert_stats = "INSERT INTO user_stats (user_id, total_donated, total_collected, total_saved) 
                        VALUES ('$restaurant_id', 0, 0, 0)";
        mysqli_query($conn, $insert_stats);
    }
}

// Get recent activities
$activities = [];

// Check if food_donations table exists
if (mysqli_num_rows($check_table) > 0) {
    // Get recent donations (limit to 5)
    $activities_query = "SELECT id, status, created_at 
                         FROM food_donations 
                         WHERE restaurant_id = '$restaurant_id' 
                         ORDER BY created_at DESC 
                         LIMIT 5";
    $activities_result = mysqli_query($conn, $activities_query);
    
    if ($activities_result) {
        while ($row = mysqli_fetch_assoc($activities_result)) {
            $status_message = '';
            
            switch ($row['status']) {
                case 'Available':
                    $status_message = 'Food donation listing created';
                    break;
                case 'Pending Pickup':
                    $status_message = 'Food pickup scheduled';
                    break;
                case 'Completed':
                    $status_message = 'Food donation completed';
                    break;
                default:
                    $status_message = 'Food donation status: ' . $row['status'];
            }
            
            $activities[] = [
                'id' => $row['id'],
                'message' => $status_message,
                'timestamp' => $row['created_at']
            ];
        }
    }
}

// Return all stats
ApiResponse::send(ApiResponse::success('Dashboard statistics retrieved successfully', [
    'stats' => $stats,
    'recent_activities' => $activities
]));

mysqli_close($conn);
?>
