<?php
// Script to update expired donations
// This can be run as a cron job or called from other endpoints

// Include database connection
require_once 'db_connect.php';
require_once 'api_response.php';

function updateExpiredDonations() {
    global $conn;
    
    // Get current time
    $current_time = date('Y-m-d H:i:s');
    
    // Update donations that have passed their pickup deadline
    $update_query = "
        UPDATE food_donations 
        SET status = 'Cancelled'
        WHERE status = 'Available' 
        AND pickup_deadline < '$current_time'
    ";
    
    $result = mysqli_query($conn, $update_query);
    
    if (!$result) {
        return [
            'success' => false,
            'message' => 'Failed to update expired donations: ' . mysqli_error($conn),
            'affected_rows' => 0
        ];
    }
    
    $affected_rows = mysqli_affected_rows($conn);
    
    return [
        'success' => true,
        'message' => 'Successfully updated expired donations',
        'affected_rows' => $affected_rows
    ];
}

// If this script is called directly, return JSON response
if (basename($_SERVER['PHP_SELF']) == basename(__FILE__)) {
    $result = updateExpiredDonations();
    
    header('Content-Type: application/json');
    echo json_encode($result);
    
    mysqli_close($conn);
}
?>
