<?php
// Show all errors for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'db_connect.php';

// Handle GET request to retrieve dashboard statistics
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $stats = [];
        
        // Total users count
        $query = "SELECT COUNT(*) as total FROM users";
        $result = mysqli_query($conn, $query);
        if (!$result) {
            throw new Exception('Error counting users: ' . mysqli_error($conn));
        }
        $stats['totalUsers'] = mysqli_fetch_assoc($result)['total'];
        
        // Users by role
        $query = "SELECT role, COUNT(*) as count FROM users GROUP BY role";
        $result = mysqli_query($conn, $query);
        if (!$result) {
            throw new Exception('Error counting users by role: ' . mysqli_error($conn));
        }
        $stats['usersByRole'] = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $stats['usersByRole'][] = $row;
        }
        
        // New users this month
        $query = "SELECT COUNT(*) as count FROM users WHERE created_at >= DATE_FORMAT(NOW() ,'%Y-%m-01')";
        $result = mysqli_query($conn, $query);
        if (!$result) {
            throw new Exception('Error counting new users: ' . mysqli_error($conn));
        }
        $stats['newUsersThisMonth'] = mysqli_fetch_assoc($result)['count'];
        
        // Total donations
        $query = "SELECT COUNT(*) as total FROM food_donations";
        $result = mysqli_query($conn, $query);
        if (!$result) {
            throw new Exception('Error counting donations: ' . mysqli_error($conn));
        }
        $stats['totalDonations'] = mysqli_fetch_assoc($result)['total'];
        
        // Donations by status
        $query = "SELECT status, COUNT(*) as count FROM food_donations GROUP BY status";
        $result = mysqli_query($conn, $query);
        if (!$result) {
            throw new Exception('Error counting donations by status: ' . mysqli_error($conn));
        }
        $stats['donationsByStatus'] = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $stats['donationsByStatus'][] = $row;
        }
        
        // Total pickups
        $query = "SELECT COUNT(*) as total FROM food_pickups";
        $result = mysqli_query($conn, $query);
        if (!$result) {
            throw new Exception('Error counting pickups: ' . mysqli_error($conn));
        }
        $stats['totalPickups'] = mysqli_fetch_assoc($result)['total'];
        
        // Pickups by status
        $query = "SELECT status, COUNT(*) as count FROM food_pickups GROUP BY status";
        $result = mysqli_query($conn, $query);
        if (!$result) {
            throw new Exception('Error counting pickups by status: ' . mysqli_error($conn));
        }
        $stats['pickupsByStatus'] = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $stats['pickupsByStatus'][] = $row;
        }
        
        // Recent activity (combined donations and pickups)
        $query = "
            (SELECT 
                'donation' as type,
                fd.id,
                u.name as user_name,
                fd.name as item_name,
                fd.status,
                fd.created_at
            FROM food_donations fd
            JOIN users u ON fd.restaurant_id = u.id
            ORDER BY fd.created_at DESC
            LIMIT 5)
            
            UNION
            
            (SELECT 
                'pickup' as type,
                fp.id,
                u.name as user_name,
                fd.name as item_name,
                fp.status,
                fp.created_at
            FROM food_pickups fp
            JOIN users u ON fp.collector_id = u.id
            JOIN food_donations fd ON fp.donation_id = fd.id
            ORDER BY fp.created_at DESC
            LIMIT 5)
            
            ORDER BY created_at DESC
            LIMIT 10
        ";
        $result = mysqli_query($conn, $query);
        if (!$result) {
            throw new Exception('Error fetching recent activity: ' . mysqli_error($conn));
        }
        $stats['recentActivity'] = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $stats['recentActivity'][] = $row;
        }
        
        // Send success response
        sendResponse([
            'success' => true,
            'message' => 'Dashboard statistics retrieved successfully',
            'data' => $stats
        ]);
        
    } catch (Exception $e) {
        // Send error response
        sendResponse([
            'success' => false,
            'message' => 'Failed to retrieve dashboard statistics',
            'error' => $e->getMessage()
        ]);
    }
}
?>
