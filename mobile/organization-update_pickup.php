<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::send(ApiResponse::error('Only POST method is allowed', null, 405));
}

// Get POST data
$data = getPostData();

// Check if required fields are present
if (!isset($data['collector_id']) || empty($data['collector_id'])) {
    ApiResponse::send(ApiResponse::error('Organization ID is required'));
}

if (!isset($data['pickup_id']) || empty($data['pickup_id'])) {
    ApiResponse::send(ApiResponse::error('Pickup ID is required'));
}

if (!isset($data['status']) || empty($data['status'])) {
    ApiResponse::send(ApiResponse::error('Status is required'));
}

// Sanitize inputs
$collector_id = mysqli_real_escape_string($conn, $data['collector_id']);
$pickup_id = mysqli_real_escape_string($conn, $data['pickup_id']);
$status = mysqli_real_escape_string($conn, $data['status']);
$notes = isset($data['notes']) ? mysqli_real_escape_string($conn, $data['notes']) : null;
$rating = isset($data['rating']) ? intval($data['rating']) : null;

// Verify status is valid
if (!in_array($status, ['Completed', 'Cancelled'])) {
    ApiResponse::send(ApiResponse::error('Invalid status. Must be Completed or Cancelled'));
}

// Verify user is a collector
$check_collector = mysqli_query($conn, "SELECT id FROM users WHERE id = '$collector_id' AND role = 'Organization'");
if (mysqli_num_rows($check_collector) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as an organization', null, 403));
}

// Check if the pickup exists and belongs to this collector
$check_pickup = mysqli_query($conn, "
    SELECT fp.*, fd.restaurant_id, fd.id as donation_id 
    FROM food_pickups fp
    JOIN food_donations fd ON fp.donation_id = fd.id
    WHERE fp.id = '$pickup_id' AND fp.collector_id = '$collector_id'
");

if (mysqli_num_rows($check_pickup) == 0) {
    ApiResponse::send(ApiResponse::error('Pickup not found or does not belong to this collector', null, 404));
}

$pickup = mysqli_fetch_assoc($check_pickup);

// Check if the pickup can be updated (only if it's in Requested or Accepted state)
if (!in_array($pickup['status'], ['Requested', 'Accepted'])) {
    ApiResponse::send(ApiResponse::error('Cannot update pickup that is already completed or cancelled', null, 400));
}

// Begin transaction
mysqli_begin_transaction($conn);

try {
    // Update pickup
    $update_fields = ["status = '$status'"];
    
    if ($notes !== null) {
        $update_fields[] = "notes = '$notes'";
    }
    
    if ($rating !== null && $rating >= 1 && $rating <= 5) {
        $update_fields[] = "rating = $rating";
    }
    
    $update_query = "
        UPDATE food_pickups 
        SET " . implode(', ', $update_fields) . "
        WHERE id = '$pickup_id' AND collector_id = '$collector_id'
    ";
    
    if (!mysqli_query($conn, $update_query)) {
        throw new Exception(mysqli_error($conn));
    }
    
    // Update donation status
    $donation_status = ($status === 'Completed') ? 'Completed' : 'Available';
    $update_donation = "
        UPDATE food_donations 
        SET status = '$donation_status' 
        WHERE id = '{$pickup['donation_id']}'
    ";
    
    if (!mysqli_query($conn, $update_donation)) {
        throw new Exception(mysqli_error($conn));
    }
    
    // If completed, update user stats
    if ($status === 'Completed') {
        // Check if user_stats table exists, create if not
        $check_stats_table = mysqli_query($conn, "SHOW TABLES LIKE 'user_stats'");
        if (mysqli_num_rows($check_stats_table) == 0) {
            // Create table if it doesn't exist
            $create_stats_table = "
            CREATE TABLE user_stats (
                user_id INT PRIMARY KEY,
                total_donated FLOAT DEFAULT 0,
                total_collected FLOAT DEFAULT 0,
                total_saved FLOAT DEFAULT 0,
                is_top_donor BOOLEAN DEFAULT FALSE,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
            ";
            
            if (!mysqli_query($conn, $create_stats_table)) {
                throw new Exception("Failed to create user_stats table: " . mysqli_error($conn));
            }
        }

        // Update restaurant stats
        $update_restaurant_stats = "
            INSERT INTO user_stats (user_id, total_donated) 
            VALUES ('{$pickup['restaurant_id']}', 1) 
            ON DUPLICATE KEY UPDATE 
            total_donated = total_donated + 1
        ";
        if (!mysqli_query($conn, $update_restaurant_stats)) {
            throw new Exception(mysqli_error($conn));
        }
        
        // Update collector stats
        $update_collector_stats = "
            INSERT INTO user_stats (user_id, total_collected) 
            VALUES ('$collector_id', 1) 
            ON DUPLICATE KEY UPDATE 
            total_collected = total_collected + 1
        ";
        if (!mysqli_query($conn, $update_collector_stats)) {
            throw new Exception(mysqli_error($conn));
        }
    }
    
    // Commit transaction
    mysqli_commit($conn);
    
    ApiResponse::send(ApiResponse::success('Pickup updated successfully', [
        'pickup_id' => $pickup_id,
        'status' => $status
    ]));
}
catch (Exception $e) {
    // Roll back transaction on error
    mysqli_rollback($conn);
    ApiResponse::send(ApiResponse::error('Failed to update pickup', $e->getMessage()));
}

mysqli_close($conn);
?>