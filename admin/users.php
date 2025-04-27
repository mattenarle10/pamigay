<?php
require_once 'db_connect.php';

// Handle GET request to retrieve users
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Check if a specific user ID is requested
    if (isset($_GET['id'])) {
        $userId = mysqli_real_escape_string($conn, $_GET['id']);
        
        // Get user details
        $query = "SELECT u.*, us.total_donated, us.total_collected, us.total_saved, us.is_top_donor 
                  FROM users u 
                  LEFT JOIN user_stats us ON u.id = us.user_id 
                  WHERE u.id = '$userId'";
        $result = mysqli_query($conn, $query);
        
        if ($result && mysqli_num_rows($result) > 0) {
            $user = mysqli_fetch_assoc($result);
            
            // Get recent activity for this user
            $recentActivityQuery = "
                (SELECT 
                    'donation' as type,
                    fd.id,
                    fd.name as item_name,
                    fd.status,
                    fd.created_at
                FROM food_donations fd
                WHERE fd.restaurant_id = '$userId'
                ORDER BY fd.created_at DESC
                LIMIT 5)
                
                UNION
                
                (SELECT 
                    'pickup' as type,
                    fp.id,
                    fd.name as item_name,
                    fp.status,
                    fp.created_at
                FROM food_pickups fp
                JOIN food_donations fd ON fp.donation_id = fd.id
                WHERE fp.collector_id = '$userId'
                ORDER BY fp.created_at DESC
                LIMIT 5)
                
                ORDER BY created_at DESC
                LIMIT 10
            ";
            
            $activityResult = mysqli_query($conn, $recentActivityQuery);
            $recentActivity = [];
            
            if ($activityResult) {
                while ($row = mysqli_fetch_assoc($activityResult)) {
                    $recentActivity[] = $row;
                }
            }
            
            $user['recent_activity'] = $recentActivity;
            
            sendResponse([
                'success' => true,
                'message' => 'User details retrieved successfully',
                'data' => $user
            ]);
        } else {
            sendResponse([
                'success' => false,
                'message' => 'User not found',
                'error_code' => 404
            ]);
        }
    } else {
        // Get all users with optional filtering
        $query = "SELECT u.*, us.total_donated, us.total_collected 
                  FROM users u 
                  LEFT JOIN user_stats us ON u.id = us.user_id 
                  WHERE 1=1";
        
        // Apply filters if provided
        if (isset($_GET['role']) && !empty($_GET['role'])) {
            $role = mysqli_real_escape_string($conn, $_GET['role']);
            $query .= " AND u.role = '$role'";
        }
        
        if (isset($_GET['search']) && !empty($_GET['search'])) {
            $search = mysqli_real_escape_string($conn, $_GET['search']);
            $query .= " AND (u.name LIKE '%$search%' OR u.email LIKE '%$search%')";
        }
        
        if (isset($_GET['status']) && !empty($_GET['status'])) {
            $status = mysqli_real_escape_string($conn, $_GET['status']);
            // Assuming you have a status field or derive it somehow
            // This is a placeholder - adjust based on your actual data structure
            if ($status === 'Active') {
                $query .= " AND u.id IN (SELECT DISTINCT restaurant_id FROM food_donations UNION SELECT DISTINCT collector_id FROM food_pickups)";
            } else if ($status === 'Inactive') {
                $query .= " AND u.id NOT IN (SELECT DISTINCT restaurant_id FROM food_donations UNION SELECT DISTINCT collector_id FROM food_pickups)";
            }
        }
        
        // Add sorting
        $query .= " ORDER BY u.created_at DESC";
        
        $result = mysqli_query($conn, $query);
        
        if ($result) {
            $users = [];
            while ($row = mysqli_fetch_assoc($result)) {
                $users[] = $row;
            }
            
            sendResponse([
                'success' => true,
                'message' => 'Users retrieved successfully',
                'data' => $users
            ]);
        } else {
            sendResponse([
                'success' => false,
                'message' => 'Failed to retrieve users',
                'error' => mysqli_error($conn)
            ]);
        }
    }
}

// Handle DELETE request to delete a user
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $data = getPostData();
    $userId = isset($_GET['id']) ? $_GET['id'] : (isset($data['id']) ? $data['id'] : null);
    
    if (!$userId) {
        sendResponse([
            'success' => false,
            'message' => 'User ID is required',
            'error_code' => 400
        ]);
    }
    
    $userId = mysqli_real_escape_string($conn, $userId);
    
    // Start transaction
    mysqli_begin_transaction($conn);
    
    try {
        // Delete user stats
        $query = "DELETE FROM user_stats WHERE user_id = '$userId'";
        mysqli_query($conn, $query);
        
        // Delete user's notifications
        $query = "DELETE FROM notifications WHERE user_id = '$userId'";
        mysqli_query($conn, $query);
        
        // Update food_donations to set restaurant_id to NULL where it matches this user
        // Note: This depends on your business logic - you might want to delete the donations instead
        $query = "UPDATE food_donations SET restaurant_id = NULL WHERE restaurant_id = '$userId'";
        mysqli_query($conn, $query);
        
        // Update food_pickups to set collector_id to NULL where it matches this user
        // Note: This depends on your business logic - you might want to delete the pickups instead
        $query = "UPDATE food_pickups SET collector_id = NULL WHERE collector_id = '$userId'";
        mysqli_query($conn, $query);
        
        // Finally delete the user
        $query = "DELETE FROM users WHERE id = '$userId'";
        $result = mysqli_query($conn, $query);
        
        if ($result) {
            mysqli_commit($conn);
            sendResponse([
                'success' => true,
                'message' => 'User deleted successfully'
            ]);
        } else {
            throw new Exception(mysqli_error($conn));
        }
    } catch (Exception $e) {
        mysqli_rollback($conn);
        sendResponse([
            'success' => false,
            'message' => 'Failed to delete user',
            'error' => $e->getMessage()
        ]);
    }
}
?>
