<?php
/**
 * Mark Notification as Read API
 * 
 * This endpoint marks a notification as read.
 * Required parameters:
 * - notification_id: The ID of the notification to mark as read
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
$notification_id = isset($_POST['notification_id']) ? $_POST['notification_id'] : null;

// Validate required parameters
if (!$notification_id) {
    ApiResponse::send(ApiResponse::error('Notification ID is required'));
}

// Validate notification_id is numeric
if (!is_numeric($notification_id)) {
    ApiResponse::send(ApiResponse::error('Notification ID must be numeric'));
}

try {
    // Verify notification exists
    $notification_query = "SELECT id FROM notifications WHERE id = '$notification_id'";
    $notification_result = mysqli_query($conn, $notification_query);
    
    if (!$notification_result || mysqli_num_rows($notification_result) == 0) {
        ApiResponse::send(ApiResponse::error('Notification not found', null, 404));
    }
    
    // Mark notification as read
    $result = NotificationHelper::markAsRead($notification_id);
    
    if ($result) {
        ApiResponse::send(ApiResponse::success('Notification marked as read'));
    } else {
        throw new Exception('Failed to mark notification as read');
    }
    
} catch (Exception $e) {
    error_log('[' . date('d-M-Y H:i:s e') . '] Mark notification read error: ' . $e->getMessage());
    ApiResponse::send(ApiResponse::error('Failed to mark notification as read: ' . $e->getMessage()));
}
?>
