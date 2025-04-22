<?php
/**
 * Cron job script to update expired donations
 * 
 * This script should be set up to run at regular intervals (e.g., every 5 minutes)
 * using a cron job or scheduled task.
 * 
 * Example cron entry (runs every 5 minutes):
 * Minutes: 0,5,10,15,20,25,30,35,40,45,50,55
 * Hours: *
 * Day of month: *
 * Month: *
 * Day of week: *
 * Command: php /path/to/pamigay-web/mobile/cron_update_donations.php
 */

// Disable direct web access to this script
if (isset($_SERVER['REMOTE_ADDR'])) {
    die('This script is meant to be run as a cron job');
}

// Include required files
require_once 'db_connect.php';
require_once 'api_response.php';
require_once 'update_expired_donations.php';

// Log file for tracking updates
$log_file = __DIR__ . '/logs/donation_updates.log';

// Ensure log directory exists
if (!file_exists(dirname($log_file))) {
    mkdir(dirname($log_file), 0755, true);
}

// Get current time
$current_time = date('Y-m-d H:i:s');

// Log start of process
file_put_contents($log_file, "[{$current_time}] Starting donation status update process\n", FILE_APPEND);

// Update expired donations
$result = updateExpiredDonations();

// Log results
$message = "[{$current_time}] Update completed: {$result['message']}. Affected rows: {$result['affected_rows']}\n";
file_put_contents($log_file, $message, FILE_APPEND);

// Close database connection
mysqli_close($conn);

// Exit with success code
exit(0);
?>
