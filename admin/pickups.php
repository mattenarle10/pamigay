<?php
require_once 'db_connect.php';

// Handle GET request to retrieve pickups
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Check if a specific pickup ID is requested
    if (isset($_GET['id'])) {
        $pickupId = mysqli_real_escape_string($conn, $_GET['id']);
        
        // Get pickup details with related information
        $query = "SELECT fp.*, 
                  fd.name as donation_name, fd.quantity, fd.condition_status, fd.category, fd.pickup_deadline,
                  r.name as restaurant_name, r.email as restaurant_email, r.phone_number as restaurant_phone, r.location as restaurant_location,
                  o.name as organization_name, o.email as organization_email, o.phone_number as organization_phone, o.location as organization_location
                  FROM food_pickups fp 
                  JOIN food_donations fd ON fp.donation_id = fd.id
                  JOIN users r ON fd.restaurant_id = r.id
                  JOIN users o ON fp.collector_id = o.id
                  WHERE fp.id = '$pickupId'";
        $result = mysqli_query($conn, $query);
        
        if ($result && mysqli_num_rows($result) > 0) {
            $pickup = mysqli_fetch_assoc($result);
            
            sendResponse([
                'success' => true,
                'message' => 'Pickup details retrieved successfully',
                'data' => $pickup
            ]);
        } else {
            sendResponse([
                'success' => false,
                'message' => 'Pickup not found',
                'error_code' => 404
            ]);
        }
    } else {
        // Get all pickups with optional filtering
        $query = "SELECT fp.*, 
                  fd.name as donation_name, fd.quantity, fd.status as donation_status,
                  r.name as restaurant_name, r.location as restaurant_location,
                  o.name as organization_name, o.location as organization_location
                  FROM food_pickups fp 
                  JOIN food_donations fd ON fp.donation_id = fd.id
                  JOIN users r ON fd.restaurant_id = r.id
                  JOIN users o ON fp.collector_id = o.id
                  WHERE 1=1";
        
        // Apply filters if provided
        if (isset($_GET['status']) && !empty($_GET['status'])) {
            $status = mysqli_real_escape_string($conn, $_GET['status']);
            $query .= " AND fp.status = '$status'";
        }
        
        if (isset($_GET['organization']) && !empty($_GET['organization'])) {
            $organization = mysqli_real_escape_string($conn, $_GET['organization']);
            $query .= " AND o.id = '$organization'";
        }
        
        if (isset($_GET['search']) && !empty($_GET['search'])) {
            $search = mysqli_real_escape_string($conn, $_GET['search']);
            $query .= " AND (fd.name LIKE '%$search%' OR r.name LIKE '%$search%' OR o.name LIKE '%$search%')";
        }
        
        if (isset($_GET['date']) && !empty($_GET['date'])) {
            $date = mysqli_real_escape_string($conn, $_GET['date']);
            
            // Date filtering
            $today = date('Y-m-d');
            $yesterday = date('Y-m-d', strtotime('-1 day'));
            $weekAgo = date('Y-m-d', strtotime('-7 days'));
            $monthAgo = date('Y-m-d', strtotime('-30 days'));
            
            if ($date === 'today') {
                $query .= " AND DATE(fp.created_at) = '$today'";
            } else if ($date === 'yesterday') {
                $query .= " AND DATE(fp.created_at) = '$yesterday'";
            } else if ($date === 'week') {
                $query .= " AND fp.created_at >= '$weekAgo'";
            } else if ($date === 'month') {
                $query .= " AND fp.created_at >= '$monthAgo'";
            }
        }
        
        // Add sorting
        $query .= " ORDER BY fp.created_at DESC";
        
        $result = mysqli_query($conn, $query);
        
        if ($result) {
            $pickups = [];
            while ($row = mysqli_fetch_assoc($result)) {
                $pickups[] = $row;
            }
            
            sendResponse([
                'success' => true,
                'message' => 'Pickups retrieved successfully',
                'data' => $pickups
            ]);
        } else {
            sendResponse([
                'success' => false,
                'message' => 'Failed to retrieve pickups',
                'error' => mysqli_error($conn)
            ]);
        }
    }
}

// Handle PUT request to update a pickup status
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $data = getPostData();
    $pickupId = isset($_GET['id']) ? $_GET['id'] : (isset($data['id']) ? $data['id'] : null);
    $status = isset($data['status']) ? $data['status'] : null;
    
    if (!$pickupId || !$status) {
        sendResponse([
            'success' => false,
            'message' => 'Pickup ID and status are required',
            'error_code' => 400
        ]);
    }
    
    $pickupId = mysqli_real_escape_string($conn, $pickupId);
    $status = mysqli_real_escape_string($conn, $status);
    
    // Check if status is valid
    $validStatuses = ['Requested', 'Accepted', 'Completed', 'Cancelled'];
    if (!in_array($status, $validStatuses)) {
        sendResponse([
            'success' => false,
            'message' => 'Invalid status value',
            'error_code' => 400
        ]);
    }
    
    // Start transaction
    mysqli_begin_transaction($conn);
    
    try {
        // Update the pickup status
        $query = "UPDATE food_pickups SET status = '$status', updated_at = NOW() WHERE id = '$pickupId'";
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            throw new Exception(mysqli_error($conn));
        }
        
        // If status is Completed or Cancelled, update the donation status accordingly
        if ($status === 'Completed' || $status === 'Cancelled') {
            // Get the donation ID for this pickup
            $query = "SELECT donation_id FROM food_pickups WHERE id = '$pickupId'";
            $result = mysqli_query($conn, $query);
            
            if ($result && mysqli_num_rows($result) > 0) {
                $donationId = mysqli_fetch_assoc($result)['donation_id'];
                
                // Update donation status
                $donationStatus = ($status === 'Completed') ? 'Completed' : 'Available';
                $query = "UPDATE food_donations SET status = '$donationStatus', updated_at = NOW() WHERE id = '$donationId'";
                $result = mysqli_query($conn, $query);
                
                if (!$result) {
                    throw new Exception(mysqli_error($conn));
                }
                
                // If Completed, update user stats
                if ($status === 'Completed') {
                    // Get donation quantity and collector ID
                    $query = "SELECT fd.quantity, fp.collector_id, fd.restaurant_id 
                              FROM food_pickups fp 
                              JOIN food_donations fd ON fp.donation_id = fd.id 
                              WHERE fp.id = '$pickupId'";
                    $result = mysqli_query($conn, $query);
                    
                    if ($result && mysqli_num_rows($result) > 0) {
                        $row = mysqli_fetch_assoc($result);
                        $quantity = (float) $row['quantity']; // Convert to number if possible
                        $collectorId = $row['collector_id'];
                        $restaurantId = $row['restaurant_id'];
                        
                        // Update restaurant stats (donor)
                        $query = "INSERT INTO user_stats (user_id, total_donated, total_collected, total_saved, is_top_donor) 
                                  VALUES ('$restaurantId', '$quantity', 0, 0, 0)
                                  ON DUPLICATE KEY UPDATE total_donated = total_donated + '$quantity'";
                        mysqli_query($conn, $query);
                        
                        // Update organization stats (collector)
                        $query = "INSERT INTO user_stats (user_id, total_donated, total_collected, total_saved, is_top_donor) 
                                  VALUES ('$collectorId', 0, '$quantity', 0, 0)
                                  ON DUPLICATE KEY UPDATE total_collected = total_collected + '$quantity'";
                        mysqli_query($conn, $query);
                    }
                }
            }
        }
        
        // If status is Accepted, update the donation status to Pending Pickup
        if ($status === 'Accepted') {
            // Get the donation ID for this pickup
            $query = "SELECT donation_id FROM food_pickups WHERE id = '$pickupId'";
            $result = mysqli_query($conn, $query);
            
            if ($result && mysqli_num_rows($result) > 0) {
                $donationId = mysqli_fetch_assoc($result)['donation_id'];
                
                // Update donation status
                $query = "UPDATE food_donations SET status = 'Pending Pickup', updated_at = NOW() WHERE id = '$donationId'";
                $result = mysqli_query($conn, $query);
                
                if (!$result) {
                    throw new Exception(mysqli_error($conn));
                }
            }
        }
        
        mysqli_commit($conn);
        
        sendResponse([
            'success' => true,
            'message' => 'Pickup status updated successfully'
        ]);
    } catch (Exception $e) {
        mysqli_rollback($conn);
        sendResponse([
            'success' => false,
            'message' => 'Failed to update pickup status',
            'error' => $e->getMessage()
        ]);
    }
}

// Handle DELETE request to delete a pickup
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $data = getPostData();
    $pickupId = isset($_GET['id']) ? $_GET['id'] : (isset($data['id']) ? $data['id'] : null);
    
    if (!$pickupId) {
        sendResponse([
            'success' => false,
            'message' => 'Pickup ID is required',
            'error_code' => 400
        ]);
    }
    
    $pickupId = mysqli_real_escape_string($conn, $pickupId);
    
    // Start transaction
    mysqli_begin_transaction($conn);
    
    try {
        // Get the donation ID for this pickup
        $query = "SELECT donation_id FROM food_pickups WHERE id = '$pickupId'";
        $result = mysqli_query($conn, $query);
        
        if ($result && mysqli_num_rows($result) > 0) {
            $donationId = mysqli_fetch_assoc($result)['donation_id'];
            
            // Delete related notifications
            $query = "DELETE FROM notifications WHERE type LIKE '%pickup%' AND related_id = '$pickupId'";
            mysqli_query($conn, $query);
            
            // Delete the pickup
            $query = "DELETE FROM food_pickups WHERE id = '$pickupId'";
            $result = mysqli_query($conn, $query);
            
            if (!$result) {
                throw new Exception(mysqli_error($conn));
            }
            
            // Update donation status if needed
            $query = "UPDATE food_donations SET status = 'Available', updated_at = NOW() WHERE id = '$donationId'";
            mysqli_query($conn, $query);
        }
        
        mysqli_commit($conn);
        
        sendResponse([
            'success' => true,
            'message' => 'Pickup deleted successfully'
        ]);
    } catch (Exception $e) {
        mysqli_rollback($conn);
        sendResponse([
            'success' => false,
            'message' => 'Failed to delete pickup',
            'error' => $e->getMessage()
        ]);
    }
}
?>
