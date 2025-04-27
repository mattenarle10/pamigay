<?php
/**
 * Get Notifications API
 * 
 * This endpoint retrieves notifications for a specific user.
 * Required parameters:
 * - user_id: The ID of the user to get notifications for
 * 
 * Optional parameters:
 * - limit: Maximum number of notifications to retrieve (default: 50)
 * - offset: Offset for pagination (default: 0)
 */

require_once 'db_connect.php';
require_once 'api_response.php';
require_once 'notification_helper.php';

// Debug logging
error_log('[' . date('d-M-Y H:i:s e') . '] GET data: ' . print_r($_GET, true));

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::send(ApiResponse::error('Only GET method is allowed', null, 405));
}

// Get parameters
$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
$offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

// Validate required parameters
if (!$user_id) {
    ApiResponse::send(ApiResponse::error('User ID is required'));
}

// Validate user_id is numeric
if (!is_numeric($user_id)) {
    ApiResponse::send(ApiResponse::error('User ID must be numeric'));
}

// Ensure reasonable limits
if ($limit <= 0 || $limit > 100) {
    $limit = 50;
}

if ($offset < 0) {
    $offset = 0;
}

try {
    // Verify user exists
    $user_query = "SELECT id FROM users WHERE id = '$user_id'";
    $user_result = mysqli_query($conn, $user_query);
    
    if (!$user_result || mysqli_num_rows($user_result) == 0) {
        ApiResponse::send(ApiResponse::error('User not found', null, 404));
    }
    
    // Get notifications
    $notifications = NotificationHelper::getNotifications($user_id, $limit, $offset);
    
    // Get unread count
    $unread_count = NotificationHelper::getUnreadCount($user_id);
    
    // Return success response
    ApiResponse::send(ApiResponse::success('Notifications retrieved successfully', [
        'notifications' => $notifications,
        'unread_count' => $unread_count,
        'total' => count($notifications),
        'has_more' => count($notifications) == $limit
    ]));
    
} catch (Exception $e) {
    error_log('[' . date('d-M-Y H:i:s e') . '] Get notifications error: ' . $e->getMessage());
    ApiResponse::send(ApiResponse::error('Failed to retrieve notifications: ' . $e->getMessage()));
}
?>
