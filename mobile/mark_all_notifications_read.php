<?php
/**
 * Mark All Notifications as Read API
 * 
 * This endpoint marks all notifications as read for a specific user.
 * Required parameters:
 * - user_id: The ID of the user to mark all notifications as read for
 */

require_once 'db_connect.php';
require_once 'api_response.php';
require_once 'notification_helper.php';

// Debug logging
error_log('[' . date('d-M-Y H:i:s e') . '] POST data: ' . print_r($_POST, true));

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::send(ApiResponse::error('Only POST method is allowed', null, 405));
}

// Get parameters
$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : null;

// Validate required parameters
if (!$user_id) {
    ApiResponse::send(ApiResponse::error('User ID is required'));
}

// Validate user_id is numeric
if (!is_numeric($user_id)) {
    ApiResponse::send(ApiResponse::error('User ID must be numeric'));
}

try {
    // Verify user exists
    $user_query = "SELECT id FROM users WHERE id = '$user_id'";
    $user_result = mysqli_query($conn, $user_query);
    
    if (!$user_result || mysqli_num_rows($user_result) == 0) {
        ApiResponse::send(ApiResponse::error('User not found', null, 404));
    }
    
    // Mark all notifications as read
    $result = NotificationHelper::markAllAsRead($user_id);
    
    if ($result) {
        ApiResponse::send(ApiResponse::success('All notifications marked as read'));
    } else {
        throw new Exception('Failed to mark all notifications as read');
    }
    
} catch (Exception $e) {
    error_log('[' . date('d-M-Y H:i:s e') . '] Mark all notifications read error: ' . $e->getMessage());
    ApiResponse::send(ApiResponse::error('Failed to mark all notifications as read: ' . $e->getMessage()));
}
?>
