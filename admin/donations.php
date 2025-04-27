<?php
require_once 'db_connect.php';

// Debug function
function debug_log($message, $data = null) {
    error_log("DONATIONS API: " . $message);
    if ($data !== null) {
        error_log("DATA: " . print_r($data, true));
    }
}

// Handle GET request to retrieve donations
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        debug_log("GET request received");
        
        // Check if a specific donation ID is requested
        if (isset($_GET['id'])) {
            $donationId = mysqli_real_escape_string($conn, $_GET['id']);
            debug_log("Fetching donation with ID: $donationId");
            
            $query = "SELECT fd.*, u.name as restaurant_name, u.email as restaurant_email, u.phone_number as restaurant_phone, u.location as restaurant_location 
                      FROM food_donations fd 
                      LEFT JOIN users u ON fd.restaurant_id = u.id 
                      WHERE fd.id = '$donationId'";
            debug_log("Query: $query");
            $result = mysqli_query($conn, $query);
            
            if (!$result) {
                debug_log("Query error: " . mysqli_error($conn));
                throw new Exception("Database query failed: " . mysqli_error($conn));
            }
            
            if ($result && mysqli_num_rows($result) > 0) {
                $donation = mysqli_fetch_assoc($result);
                debug_log("Donation found", $donation);
                
                // Get pickup requests for this donation
                $pickupQuery = "SELECT fp.*, u.name as collector_name, u.email as collector_email, u.phone_number as collector_phone
                                FROM food_pickups fp
                                LEFT JOIN users u ON fp.collector_id = u.id
                                WHERE fp.donation_id = '$donationId'
                                ORDER BY fp.created_at DESC";
                debug_log("Pickup query: $pickupQuery");
                $pickupResult = mysqli_query($conn, $pickupQuery);
                
                if (!$pickupResult) {
                    debug_log("Pickup query error: " . mysqli_error($conn));
                    throw new Exception("Database query failed: " . mysqli_error($conn));
                }
                
                $pickupRequests = [];
                if ($pickupResult) {
                    while ($row = mysqli_fetch_assoc($pickupResult)) {
                        $pickupRequests[] = $row;
                    }
                }
                
                $donation['pickup_requests'] = $pickupRequests;
                
                sendResponse([
                    'success' => true,
                    'message' => 'Donation details retrieved successfully',
                    'data' => $donation
                ]);
            } else {
                debug_log("Donation not found");
                sendResponse([
                    'success' => false,
                    'message' => 'Donation not found',
                    'error_code' => 404
                ]);
            }
        } else {
            // Get all donations with optional filtering
            $query = "SELECT fd.*, u.name as restaurant_name 
                      FROM food_donations fd 
                      LEFT JOIN users u ON fd.restaurant_id = u.id 
                      WHERE 1=1";
            
            // Apply filters if provided
            if (isset($_GET['status']) && !empty($_GET['status'])) {
                $status = mysqli_real_escape_string($conn, $_GET['status']);
                $query .= " AND fd.status = '$status'";
            }
            
            if (isset($_GET['category']) && !empty($_GET['category'])) {
                $category = mysqli_real_escape_string($conn, $_GET['category']);
                $query .= " AND fd.category = '$category'";
            }
            
            if (isset($_GET['condition']) && !empty($_GET['condition'])) {
                $condition = mysqli_real_escape_string($conn, $_GET['condition']);
                $query .= " AND fd.condition_status = '$condition'";
            }
            
            if (isset($_GET['search']) && !empty($_GET['search'])) {
                $search = mysqli_real_escape_string($conn, $_GET['search']);
                $query .= " AND (fd.name LIKE '%$search%' OR u.name LIKE '%$search%')";
            }
            
            if (isset($_GET['date']) && !empty($_GET['date'])) {
                $date = mysqli_real_escape_string($conn, $_GET['date']);
                
                // Date filtering
                $today = date('Y-m-d');
                $yesterday = date('Y-m-d', strtotime('-1 day'));
                $weekAgo = date('Y-m-d', strtotime('-7 days'));
                $monthAgo = date('Y-m-d', strtotime('-30 days'));
                
                if ($date === 'today') {
                    $query .= " AND DATE(fd.created_at) = '$today'";
                } else if ($date === 'yesterday') {
                    $query .= " AND DATE(fd.created_at) = '$yesterday'";
                } else if ($date === 'week') {
                    $query .= " AND fd.created_at >= '$weekAgo'";
                } else if ($date === 'month') {
                    $query .= " AND fd.created_at >= '$monthAgo'";
                }
            }
            
            // Add sorting
            $query .= " ORDER BY fd.created_at DESC";
            debug_log("Final query: $query");
            $result = mysqli_query($conn, $query);
            
            if (!$result) {
                debug_log("Query error: " . mysqli_error($conn));
                throw new Exception("Database query failed: " . mysqli_error($conn));
            }
            
            $donations = [];
            while ($row = mysqli_fetch_assoc($result)) {
                $donations[] = $row;
            }
            
            debug_log("Found " . count($donations) . " donations");
            
            sendResponse([
                'success' => true,
                'message' => 'Donations retrieved successfully',
                'data' => $donations
            ]);
        }
    } catch (Exception $e) {
        debug_log("Error: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Failed to fetch donations: ' . $e->getMessage()
        ]);
    }
}

// Handle DELETE request to delete a donation
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    try {
        debug_log("DELETE request received");
        
        $data = getPostData();
        $donationId = isset($_GET['id']) ? $_GET['id'] : (isset($data['id']) ? $data['id'] : null);
        
        if (!$donationId) {
            debug_log("Donation ID is required");
            sendResponse([
                'success' => false,
                'message' => 'Donation ID is required',
                'error_code' => 400
            ]);
        }
        
        $donationId = mysqli_real_escape_string($conn, $donationId);
        
        // Start transaction
        mysqli_begin_transaction($conn);
        
        try {
            // Delete related pickup requests
            $query = "DELETE FROM food_pickups WHERE donation_id = '$donationId'";
            debug_log("Delete pickup query: $query");
            mysqli_query($conn, $query);
            
            // Delete related notifications
            $query = "DELETE FROM notifications WHERE type LIKE '%donation%' AND related_id = '$donationId'";
            debug_log("Delete notification query: $query");
            mysqli_query($conn, $query);
            
            // Delete the donation
            $query = "DELETE FROM food_donations WHERE id = '$donationId'";
            debug_log("Delete donation query: $query");
            $result = mysqli_query($conn, $query);
            
            if ($result) {
                mysqli_commit($conn);
                debug_log("Donation deleted successfully");
                sendResponse([
                    'success' => true,
                    'message' => 'Donation deleted successfully'
                ]);
            } else {
                throw new Exception(mysqli_error($conn));
            }
        } catch (Exception $e) {
            mysqli_rollback($conn);
            debug_log("Error deleting donation: " . $e->getMessage());
            sendResponse([
                'success' => false,
                'message' => 'Failed to delete donation',
                'error' => $e->getMessage()
            ]);
        }
    } catch (Exception $e) {
        debug_log("Error: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Failed to delete donation: ' . $e->getMessage()
        ]);
    }
}

// Handle PUT request to update a donation status
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    try {
        debug_log("PUT request received");
        
        $data = getPostData();
        $donationId = isset($_GET['id']) ? $_GET['id'] : (isset($data['id']) ? $data['id'] : null);
        $status = isset($data['status']) ? $data['status'] : null;
        
        if (!$donationId || !$status) {
            debug_log("Donation ID and status are required");
            sendResponse([
                'success' => false,
                'message' => 'Donation ID and status are required',
                'error_code' => 400
            ]);
        }
        
        $donationId = mysqli_real_escape_string($conn, $donationId);
        $status = mysqli_real_escape_string($conn, $status);
        
        // Check if status is valid
        $validStatuses = ['Available', 'Pending Pickup', 'Completed', 'Cancelled'];
        if (!in_array($status, $validStatuses)) {
            debug_log("Invalid status value");
            sendResponse([
                'success' => false,
                'message' => 'Invalid status value',
                'error_code' => 400
            ]);
        }
        
        // Update the donation status
        $query = "UPDATE food_donations SET status = '$status', updated_at = NOW() WHERE id = '$donationId'";
        debug_log("Update donation query: $query");
        $result = mysqli_query($conn, $query);
        
        if ($result) {
            // If status is changed to Cancelled, update any pending pickup requests
            if ($status === 'Cancelled') {
                $updatePickupsQuery = "UPDATE food_pickups SET status = 'Cancelled', updated_at = NOW() 
                                       WHERE donation_id = '$donationId' AND status = 'Requested'";
                debug_log("Update pickup query: $updatePickupsQuery");
                mysqli_query($conn, $updatePickupsQuery);
            }
            
            debug_log("Donation status updated successfully");
            sendResponse([
                'success' => true,
                'message' => 'Donation status updated successfully'
            ]);
        } else {
            throw new Exception(mysqli_error($conn));
        }
    } catch (Exception $e) {
        debug_log("Error updating donation status: " . $e->getMessage());
        sendResponse([
            'success' => false,
            'message' => 'Failed to update donation status',
            'error' => $e->getMessage()
        ]);
    }
}
?>
