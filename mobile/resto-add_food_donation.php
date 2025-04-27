<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';
require_once 'notification_helper.php';

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::send(ApiResponse::error('Only POST method is allowed', null, 405));
}

// Get POST data
$data = getPostData();

// Check if user is authenticated & is a restaurant
if (!isset($data['restaurant_id']) || empty($data['restaurant_id'])) {
    ApiResponse::send(ApiResponse::error('Restaurant ID is required'));
}

// Validate required fields
$required_fields = ['name', 'quantity', 'condition_status', 'category', 'pickup_deadline'];
$missing_fields = [];

foreach ($required_fields as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
        $missing_fields[] = $field;
    }
}

if (!empty($missing_fields)) {
    ApiResponse::send(ApiResponse::error('Missing required fields', [
        'missing_fields' => $missing_fields
    ]));
}

// Sanitize inputs
$restaurant_id = mysqli_real_escape_string($conn, $data['restaurant_id']);
$name = mysqli_real_escape_string($conn, $data['name']);
$quantity = mysqli_real_escape_string($conn, $data['quantity']);
$condition_status = mysqli_real_escape_string($conn, $data['condition_status']);
$category = mysqli_real_escape_string($conn, $data['category']);
$pickup_deadline = mysqli_real_escape_string($conn, $data['pickup_deadline']);
$photo_url = isset($data['photo_url']) ? mysqli_real_escape_string($conn, $data['photo_url']) : null;

// Pickup window is optional but recommended
$pickup_window_start = isset($data['pickup_window_start']) ? mysqli_real_escape_string($conn, $data['pickup_window_start']) : $pickup_deadline;
$pickup_window_end = isset($data['pickup_window_end']) ? mysqli_real_escape_string($conn, $data['pickup_window_end']) : $pickup_deadline;

// Verify user is a restaurant
$check_restaurant = mysqli_query($conn, "SELECT id FROM users WHERE id = '$restaurant_id' AND role = 'Restaurant'");
if (mysqli_num_rows($check_restaurant) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as a restaurant', null, 403));
}

// Check if food_donations table exists, create if not
$check_table = mysqli_query($conn, "SHOW TABLES LIKE 'food_donations'");
if (mysqli_num_rows($check_table) == 0) {
    // Create the table if it doesn't exist
    $create_table_sql = "
    CREATE TABLE food_donations (
        id INT PRIMARY KEY AUTO_INCREMENT,
        restaurant_id INT NOT NULL,
        name VARCHAR(255) NOT NULL,
        quantity VARCHAR(100) NOT NULL,
        condition_status VARCHAR(50) NOT NULL,
        category VARCHAR(50) NOT NULL,
        pickup_deadline DATETIME NOT NULL,
        pickup_window_start DATETIME NOT NULL,
        pickup_window_end DATETIME NOT NULL,
        photo_url VARCHAR(255),
        status VARCHAR(20) DEFAULT 'Available',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    
    if (!mysqli_query($conn, $create_table_sql)) {
        ApiResponse::send(ApiResponse::error('Failed to create database table', mysqli_error($conn)));
    }
}

// Insert new food donation
$query = "INSERT INTO food_donations 
          (restaurant_id, name, quantity, condition_status, category, pickup_deadline, 
           pickup_window_start, pickup_window_end, photo_url) 
          VALUES ('$restaurant_id', '$name', '$quantity', '$condition_status', '$category', 
                  '$pickup_deadline', '$pickup_window_start', '$pickup_window_end', " . 
                  ($photo_url ? "'$photo_url'" : "NULL") . ")";

if (mysqli_query($conn, $query)) {
    $donation_id = mysqli_insert_id($conn);
    
    // Get restaurant name to include in notification
    $restaurant_query = "SELECT name FROM users WHERE id = '$restaurant_id'";
    $restaurant_result = mysqli_query($conn, $restaurant_query);
    $restaurant_name = "Restaurant";
    
    if ($restaurant_result && mysqli_num_rows($restaurant_result) > 0) {
        $restaurant_data = mysqli_fetch_assoc($restaurant_result);
        $restaurant_name = $restaurant_data['name'];
    }
    
    // Notify all organizations about the new donation
    $orgs_query = "SELECT id FROM users WHERE role = 'Organization'";
    $orgs_result = mysqli_query($conn, $orgs_query);
    
    if ($orgs_result) {
        while ($org = mysqli_fetch_assoc($orgs_result)) {
            NotificationHelper::createNotification(
                $org['id'],
                'donation_created',
                'New Donation Available',
                "{$restaurant_name} has added a new donation: {$name}",
                $donation_id
            );
        }
    }
    
    ApiResponse::send(ApiResponse::success('Food donation added successfully', [
        'donation_id' => $donation_id,
        'name' => $name,
        'status' => 'Available'
    ]));
} else {
    ApiResponse::send(ApiResponse::error('Failed to add food donation', mysqli_error($conn)));
}

mysqli_close($conn);
?>
