<?php
// Include database connection and API response helper
require_once 'db_connect.php';
require_once 'api_response.php';
require_once 'notification_helper.php';

// Debug logging
error_log('[' . date('d-M-Y H:i:s e') . '] POST data: ' . print_r($_POST, true));
error_log('[' . date('d-M-Y H:i:s e') . '] FILES data: ' . print_r($_FILES, true));

// Check the database schema for the status column
$schema_query = "SHOW COLUMNS FROM food_pickups LIKE 'status'";
$schema_result = mysqli_query($conn, $schema_query);
$schema_data = mysqli_fetch_assoc($schema_result);
error_log('[' . date('d-M-Y H:i:s e') . '] Status column schema: ' . print_r($schema_data, true));

// Check for existing pickup with this ID
$check_pickup_query = "SELECT id, status FROM food_pickups WHERE id = " . (isset($_POST['pickup_id']) ? intval($_POST['pickup_id']) : 0);
$check_pickup_result = mysqli_query($conn, $check_pickup_query);
if ($check_pickup_result) {
    $check_pickup_data = mysqli_fetch_assoc($check_pickup_result);
    error_log('[' . date('d-M-Y H:i:s e') . '] Existing pickup data: ' . print_r($check_pickup_data, true));
} else {
    error_log('[' . date('d-M-Y H:i:s e') . '] Error checking existing pickup: ' . mysqli_error($conn));
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::send(ApiResponse::error('Only POST method is allowed', null, 405));
}

// Get parameters
$pickup_id = isset($_POST['pickup_id']) ? $_POST['pickup_id'] : null;
$status = isset($_POST['status']) ? $_POST['status'] : null;
$restaurant_id = isset($_POST['restaurant_id']) ? $_POST['restaurant_id'] : null;

// Validate required parameters
if (!$pickup_id || !$status || !$restaurant_id) {
    ApiResponse::send(ApiResponse::error('Pickup ID, status, and restaurant ID are required'));
}

// Sanitize inputs
$pickup_id = mysqli_real_escape_string($conn, $pickup_id);
$status = mysqli_real_escape_string($conn, $status);
$restaurant_id = mysqli_real_escape_string($conn, $restaurant_id);

// Ensure pickup_id is an integer
$pickup_id = intval($pickup_id);

// Verify valid status value
$valid_statuses = ['Accepted', 'Rejected', 'Completed'];
if (!in_array($status, $valid_statuses)) {
    ApiResponse::send(ApiResponse::error('Invalid status. Must be one of: ' . implode(', ', $valid_statuses)));
}

// Verify user is a restaurant
$check_restaurant = mysqli_query($conn, "SELECT id FROM users WHERE id = '$restaurant_id' AND role = 'Restaurant'");
if (mysqli_num_rows($check_restaurant) == 0) {
    ApiResponse::send(ApiResponse::error('User is not registered as a restaurant', null, 403));
}

// Start a transaction
mysqli_begin_transaction($conn);

try {
    // Check if the pickup exists and is associated with this restaurant
    $pickup_query = "
        SELECT fp.*, fd.restaurant_id, fd.id as donation_id, fd.status as donation_status
        FROM food_pickups fp
        JOIN food_donations fd ON fp.donation_id = fd.id
        WHERE fp.id = '$pickup_id'
        FOR UPDATE
    ";
    
    $pickup_result = mysqli_query($conn, $pickup_query);
    
    if (!$pickup_result || mysqli_num_rows($pickup_result) == 0) {
        throw new Exception('Pickup request not found');
    }
    
    $pickup = mysqli_fetch_assoc($pickup_result);
    
    // Verify pickup belongs to this restaurant
    if ($pickup['restaurant_id'] != $restaurant_id) {
        throw new Exception('This pickup does not belong to your restaurant', 403);
    }
    
    // Check if donation is already in pending pickup or completed state
    if ($pickup['donation_status'] == 'Pending Pickup' && $status == 'Accepted') {
        throw new Exception('This donation has already been assigned to another organization');
    }
    
    // Handle different status updates
    if ($status == 'Accepted') {
        // If accepting, update all other pending requests for this donation to "Rejected"
        if ($pickup['status'] == 'Requested') {
            // First check if donation is still available
            if ($pickup['donation_status'] != 'Available') {
                throw new Exception('This donation is no longer available for pickup');
            }
            
            $update_other_pickups = "
                UPDATE food_pickups
                SET status = 'Cancelled'
                WHERE donation_id = '{$pickup['donation_id']}'
                  AND id != '$pickup_id'
                  AND status = 'Requested'
            ";
            
            if (!mysqli_query($conn, $update_other_pickups)) {
                throw new Exception('Failed to update other pickup requests: ' . mysqli_error($conn));
            }
            
            // Update the donation status to "Pending Pickup"
            $update_donation = "
                UPDATE food_donations
                SET status = 'Pending Pickup',
                    pickup_request_id = '$pickup_id'
                WHERE id = '{$pickup['donation_id']}'
            ";
            
            if (!mysqli_query($conn, $update_donation)) {
                throw new Exception('Failed to update donation status: ' . mysqli_error($conn));
            }
        } else {
            throw new Exception('This pickup request has already been processed');
        }
    } elseif ($status == 'Rejected') {
        // If rejecting, simply update the pickup status
        if ($pickup['status'] != 'Requested') {
            throw new Exception('Cannot reject a pickup that is not in Requested state');
        }
        
        // Check if this is the last pending request for this donation
        $check_other_requests = "
            SELECT COUNT(*) as count
            FROM food_pickups
            WHERE donation_id = '{$pickup['donation_id']}'
              AND status = 'Requested'
              AND id != '$pickup_id'
        ";
        
        $other_requests_result = mysqli_query($conn, $check_other_requests);
        $other_requests = mysqli_fetch_assoc($other_requests_result);
        
        // If no other pending requests and donation is not already assigned, update donation status back to Available
        if ($other_requests['count'] == 0 && $pickup['donation_status'] == 'Pending Pickup') {
            $update_donation = "
                UPDATE food_donations
                SET status = 'Available'
                WHERE id = '{$pickup['donation_id']}'
            ";
            
            if (!mysqli_query($conn, $update_donation)) {
                throw new Exception('Failed to update donation status: ' . mysqli_error($conn));
            }
        }
    } elseif ($status == 'Completed') {
        // If completing, update both pickup and donation
        if ($pickup['status'] != 'Accepted') {
            throw new Exception('Only accepted pickups can be marked as completed');
        }
        
        // Update the donation status to "Completed"
        $update_donation = "
            UPDATE food_donations
            SET status = 'Completed'
            WHERE id = '{$pickup['donation_id']}'
        ";
        
        if (!mysqli_query($conn, $update_donation)) {
            throw new Exception('Failed to update donation status: ' . mysqli_error($conn));
        }
        
        // Update user stats for the organization (collector)
        $update_collector_stats = "
            UPDATE user_stats
            SET total_collected = total_collected + 1,
                last_updated = NOW()
            WHERE user_id = '{$pickup['collector_id']}'
        ";
        
        if (!mysqli_query($conn, $update_collector_stats)) {
            throw new Exception('Failed to update collector stats: ' . mysqli_error($conn));
        }
        
        // Update user stats for the restaurant
        $update_restaurant_stats = "
            UPDATE user_stats
            SET total_donated = total_donated + 1,
                last_updated = NOW()
            WHERE user_id = '$restaurant_id'
        ";
        
        if (!mysqli_query($conn, $update_restaurant_stats)) {
            throw new Exception('Failed to update restaurant stats: ' . mysqli_error($conn));
        }
    }
    
    // Update pickup status (for all cases)
    // Use hardcoded values to avoid any encoding issues
    if ($status == 'Accepted') {
        $db_status = 'Accepted';
    } else if ($status == 'Rejected') {
        $db_status = 'Cancelled';
    } else if ($status == 'Completed') {
        $db_status = 'Completed';
    } else {
        $db_status = 'Requested';
    }
    
    // Debug the status value
    error_log('[' . date('d-M-Y H:i:s e') . '] Original status value: ' . $status);
    error_log('[' . date('d-M-Y H:i:s e') . '] DB status value: ' . $db_status);
    error_log('[' . date('d-M-Y H:i:s e') . '] Status value length: ' . strlen($db_status));
    error_log('[' . date('d-M-Y H:i:s e') . '] Status value hex: ' . bin2hex($db_status));
    error_log('[' . date('d-M-Y H:i:s e') . '] Pickup ID value: ' . $pickup_id . ' (type: ' . gettype($pickup_id) . ')');
    
    // Get donation and user names for notifications
    $donation_name_query = "SELECT name FROM food_donations WHERE id = '{$pickup['donation_id']}'";
    $donation_result = mysqli_query($conn, $donation_name_query);
    $donation_name = "donation";
    
    if ($donation_result && mysqli_num_rows($donation_result) > 0) {
        $donation_data = mysqli_fetch_assoc($donation_result);
        $donation_name = $donation_data['name'];
    }
    
    $org_query = "SELECT name FROM users WHERE id = '{$pickup['collector_id']}'";
    $org_result = mysqli_query($conn, $org_query);
    $org_name = "Organization";
    
    if ($org_result && mysqli_num_rows($org_result) > 0) {
        $org_data = mysqli_fetch_assoc($org_result);
        $org_name = $org_data['name'];
    }
    
    $restaurant_query = "SELECT name FROM users WHERE id = '$restaurant_id'";
    $restaurant_result = mysqli_query($conn, $restaurant_query);
    $restaurant_name = "Restaurant";
    
    if ($restaurant_result && mysqli_num_rows($restaurant_result) > 0) {
        $restaurant_data = mysqli_fetch_assoc($restaurant_result);
        $restaurant_name = $restaurant_data['name'];
    }
    
    // Send notifications based on status
    if ($status == 'Accepted') {
        // Notify organization about acceptance
        NotificationHelper::createNotification(
            $pickup['collector_id'],
            'pickup_accepted',
            'Pickup Request Accepted',
            "{$restaurant_name} has accepted your pickup request for {$donation_name}",
            $pickup_id
        );
    } elseif ($status == 'Rejected') {
        // Notify organization about rejection
        NotificationHelper::createNotification(
            $pickup['collector_id'],
            'pickup_rejected',
            'Pickup Request Rejected',
            "{$restaurant_name} has rejected your pickup request for {$donation_name}",
            $pickup_id
        );
    } elseif ($status == 'Completed') {
        // Notify organization about completion
        NotificationHelper::createNotification(
            $pickup['collector_id'],
            'pickup_completed',
            'Pickup Completed',
            "Your pickup for {$donation_name} has been marked as completed!",
            $pickup_id
        );
        
        // Notify restaurant about completion
        NotificationHelper::createNotification(
            $restaurant_id,
            'pickup_completed',
            'Pickup Completed',
            "Pickup by {$org_name} for {$donation_name} has been completed!",
            $pickup_id
        );
    }
    
    // Try a direct update with variables
    $direct_update_query = "UPDATE food_pickups SET status = '$db_status', updated_at = NOW() WHERE id = $pickup_id";
    error_log('[' . date('d-M-Y H:i:s e') . '] Direct update query: ' . $direct_update_query);
    $direct_update_result = mysqli_query($conn, $direct_update_query);
    if ($direct_update_result) {
        error_log('[' . date('d-M-Y H:i:s e') . '] Direct update successful');
        
        // Commit transaction
        mysqli_commit($conn);
        
        // Return success response
        ApiResponse::send(ApiResponse::success("Pickup request $db_status successfully", [
            'pickup_id' => $pickup_id,
            'status' => $db_status
        ]));
        exit;
    } else {
        error_log('[' . date('d-M-Y H:i:s e') . '] Direct update error: ' . mysqli_error($conn));
    }
    
    // If direct update failed, try prepared statement as fallback
    // Use a prepared statement to update the status
    $stmt = mysqli_prepare($conn, "UPDATE food_pickups SET status = ?, updated_at = NOW() WHERE id = ?");
    mysqli_stmt_bind_param($stmt, "si", $db_status, $pickup_id);
    
    if (!mysqli_stmt_execute($stmt)) {
        $error_msg = mysqli_stmt_error($stmt);
        error_log('[' . date('d-M-Y H:i:s e') . '] Update error: ' . $error_msg);
        throw new Exception('Failed to update pickup status: ' . $error_msg);
    }
    
    mysqli_stmt_close($stmt);
    
    // Commit transaction
    mysqli_commit($conn);
    
    // Return success response
    ApiResponse::send(ApiResponse::success("Pickup request $db_status successfully", [
        'pickup_id' => $pickup_id,
        'status' => $db_status
    ]));
    
} catch (Exception $e) {
    // Rollback transaction on error
    mysqli_rollback($conn);
    
    $code = isset($e->code) ? $e->code : 400;
    ApiResponse::send(ApiResponse::error($e->getMessage(), null, $code));
}
?>