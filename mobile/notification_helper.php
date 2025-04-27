<?php
/**
 * Notification Helper
 * 
 * This file provides helper functions for creating, retrieving, and managing notifications.
 */

require_once 'db_connect.php';

class NotificationHelper {
    /**
     * Create a new notification
     * 
     * @param int $userId - The ID of the user to notify
     * @param string $type - The notification type (donation_created, pickup_requested, pickup_accepted, pickup_rejected, pickup_completed)
     * @param string $title - The notification title
     * @param string $message - The notification message
     * @param int|null $relatedId - Optional related ID (pickup_id, donation_id)
     * @return bool - True if successful, false otherwise
     */
    public static function createNotification($userId, $type, $title, $message, $relatedId = null) {
        global $conn;
        
        // Input validation
        if (!$userId || !is_numeric($userId)) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Notification Error: Invalid user ID');
            return false;
        }
        
        if (empty($type) || empty($title) || empty($message)) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Notification Error: Missing required fields');
            return false;
        }
        
        // Sanitize inputs
        $userId = mysqli_real_escape_string($conn, $userId);
        $type = mysqli_real_escape_string($conn, $type);
        $title = mysqli_real_escape_string($conn, $title);
        $message = mysqli_real_escape_string($conn, $message);
        
        // Handle related ID (can be null)
        if ($relatedId !== null && is_numeric($relatedId)) {
            $relatedId = mysqli_real_escape_string($conn, $relatedId);
            $relatedIdSql = "'$relatedId'";
        } else {
            $relatedIdSql = "NULL";
        }
        
        // Debug logging
        error_log('[' . date('d-M-Y H:i:s e') . '] Creating notification: User=' . $userId . ', Type=' . $type . ', Title=' . $title);
        
        // Insert notification
        $query = "INSERT INTO notifications (user_id, type, title, message, related_id) 
                  VALUES ('$userId', '$type', '$title', '$message', $relatedIdSql)";
        
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Failed to create notification: ' . mysqli_error($conn));
            return false;
        }
        
        return true;
    }
    
    /**
     * Get notifications for a user
     * 
     * @param int $userId - The user ID
     * @param int $limit - Maximum number of notifications to retrieve (default: 50)
     * @param int $offset - Offset for pagination (default: 0)
     * @return array - Array of notifications
     */
    public static function getNotifications($userId, $limit = 50, $offset = 0) {
        global $conn;
        
        // Input validation
        if (!$userId || !is_numeric($userId)) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Get Notifications Error: Invalid user ID');
            return [];
        }
        
        // Sanitize inputs
        $userId = mysqli_real_escape_string($conn, $userId);
        $limit = (int)$limit;
        $offset = (int)$offset;
        
        // Ensure reasonable limits
        if ($limit <= 0 || $limit > 100) {
            $limit = 50;
        }
        
        if ($offset < 0) {
            $offset = 0;
        }
        
        // Query notifications
        $query = "SELECT * FROM notifications 
                  WHERE user_id = '$userId' 
                  ORDER BY created_at DESC 
                  LIMIT $offset, $limit";
        
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Failed to get notifications: ' . mysqli_error($conn));
            return [];
        }
        
        $notifications = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $notifications[] = $row;
        }
        
        return $notifications;
    }
    
    /**
     * Mark a notification as read
     * 
     * @param int $notificationId - The notification ID
     * @return bool - True if successful, false otherwise
     */
    public static function markAsRead($notificationId) {
        global $conn;
        
        // Input validation
        if (!$notificationId || !is_numeric($notificationId)) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Mark As Read Error: Invalid notification ID');
            return false;
        }
        
        // Sanitize input
        $notificationId = mysqli_real_escape_string($conn, $notificationId);
        
        // Update notification
        $query = "UPDATE notifications SET `read` = 1 WHERE id = '$notificationId'";
        
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Failed to mark notification as read: ' . mysqli_error($conn));
            return false;
        }
        
        return true;
    }
    
    /**
     * Mark all notifications as read for a user
     * 
     * @param int $userId - The user ID
     * @return bool - True if successful, false otherwise
     */
    public static function markAllAsRead($userId) {
        global $conn;
        
        // Input validation
        if (!$userId || !is_numeric($userId)) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Mark All As Read Error: Invalid user ID');
            return false;
        }
        
        // Sanitize input
        $userId = mysqli_real_escape_string($conn, $userId);
        
        // Update notifications
        $query = "UPDATE notifications SET `read` = 1 WHERE user_id = '$userId' AND `read` = 0";
        
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Failed to mark all notifications as read: ' . mysqli_error($conn));
            return false;
        }
        
        return true;
    }
    
    /**
     * Get unread notification count for a user
     * 
     * @param int $userId - The user ID
     * @return int - Number of unread notifications
     */
    public static function getUnreadCount($userId) {
        global $conn;
        
        // Input validation
        if (!$userId || !is_numeric($userId)) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Get Unread Count Error: Invalid user ID');
            return 0;
        }
        
        // Sanitize input
        $userId = mysqli_real_escape_string($conn, $userId);
        
        // Query unread count
        $query = "SELECT COUNT(*) as count FROM notifications 
                  WHERE user_id = '$userId' AND `read` = 0";
        
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Failed to get unread count: ' . mysqli_error($conn));
            return 0;
        }
        
        $row = mysqli_fetch_assoc($result);
        
        return (int)$row['count'];
    }
    
    /**
     * Delete old notifications (for maintenance)
     * 
     * @param int $daysOld - Delete notifications older than this many days (default: 30)
     * @return bool - True if successful, false otherwise
     */
    public static function deleteOldNotifications($daysOld = 30) {
        global $conn;
        
        // Input validation
        $daysOld = (int)$daysOld;
        
        if ($daysOld <= 0) {
            $daysOld = 30;
        }
        
        // Delete old notifications
        $query = "DELETE FROM notifications 
                  WHERE created_at < DATE_SUB(NOW(), INTERVAL $daysOld DAY)";
        
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            error_log('[' . date('d-M-Y H:i:s e') . '] Failed to delete old notifications: ' . mysqli_error($conn));
            return false;
        }
        
        $deletedCount = mysqli_affected_rows($conn);
        error_log('[' . date('d-M-Y H:i:s e') . '] Deleted ' . $deletedCount . ' old notifications');
        
        return true;
    }
}
?>
