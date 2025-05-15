<?php
/**
 * HTML-based PDF Export for Pamigay Web Admin
 * This script generates a PDF using HTML instead of FPDF to avoid font issues
 */

require_once 'db_connect.php';

// Main export function
function exportAsHTML($type, $title) {
    // Set headers to display in browser instead of downloading
    header('Content-Type: text/html');
    
    // Get data based on export type
    $data = [];
    switch ($type) {
        case 'users':
            $data = getUsersData($GLOBALS['conn']);
            break;
        case 'donations':
            $data = getDonationsData($GLOBALS['conn']);
            break;
        case 'pickups':
            $data = getPickupsData($GLOBALS['conn']);
            break;
        default:
            $data = [
                ['ID' => 1, 'Name' => 'Test Item', 'Status' => 'Active'],
                ['ID' => 2, 'Name' => 'Another Item', 'Status' => 'Inactive']
            ];
    }
    
    // Generate HTML
    outputHTML($title, $data);
}

// Output HTML with embedded styles for printing
function outputHTML($title, $data) {
    ?>
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><?php echo htmlspecialchars($title); ?></title>
        <style>
            body {
                font-family: Arial, Helvetica, sans-serif;
                margin: 20px;
                color: #333;
            }
            .header {
                text-align: center;
                margin-bottom: 20px;
                padding-bottom: 10px;
                border-bottom: 1px solid #ddd;
            }
            .title {
                font-size: 24px;
                font-weight: bold;
                margin: 0;
                padding: 0;
            }
            .subtitle {
                font-size: 14px;
                color: #777;
                margin: 5px 0 0 0;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 20px;
            }
            th {
                background-color: #f2f2f2;
                text-align: left;
                padding: 8px;
                border: 1px solid #ddd;
                font-weight: bold;
                cursor: pointer;
            }
            th:hover {
                background-color: #e2e2e2;
            }
            th::after {
                content: "↕";
                margin-left: 5px;
                font-size: 12px;
                opacity: 0.5;
            }
            th.sorted-asc::after {
                content: "↓";
                opacity: 1;
            }
            th.sorted-desc::after {
                content: "↑";
                opacity: 1;
            }
            td {
                padding: 8px;
                border: 1px solid #ddd;
            }
            tr:nth-child(even) {
                background-color: #f9f9f9;
            }
            .footer {
                text-align: center;
                margin-top: 20px;
                font-size: 12px;
                color: #777;
            }
            .info {
                font-size: 12px;
                margin: 10px 0;
            }
            .filter-section {
                margin-bottom: 20px;
                padding: 15px;
                background-color: #f9f9f9;
                border-radius: 5px;
                border: 1px solid #ddd;
            }
            .filter-row {
                display: flex;
                flex-wrap: wrap;
                gap: 10px;
                margin-bottom: 10px;
            }
            .filter-item {
                display: flex;
                flex-direction: column;
                min-width: 150px;
            }
            label {
                font-size: 12px;
                font-weight: bold;
                margin-bottom: 5px;
            }
            select, input {
                padding: 5px;
                border: 1px solid #ddd;
                border-radius: 3px;
            }
            button {
                background-color: #4CAF50;
                color: white;
                padding: 8px 15px;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 14px;
            }
            button:hover {
                background-color: #45a049;
            }
            @media print {
                .no-print {
                    display: none;
                }
                body {
                    margin: 0;
                    padding: 10px;
                }
            }
            .print-button {
                background-color: #4CAF50;
                color: white;
                padding: 10px 20px;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 16px;
                margin-bottom: 20px;
            }
            .print-button:hover {
                background-color: #45a049;
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1 class="title">Pamigay Admin - <?php echo htmlspecialchars($title); ?></h1>
            <p class="subtitle">Generated on: <?php echo date('Y-m-d H:i:s'); ?></p>
        </div>
        
        <div class="no-print" style="text-align: center; margin-bottom: 20px;">
            <button class="print-button" onclick="window.print()">Print / Save as PDF</button>
            <p class="info">To save as PDF, select "Print" and choose "Save as PDF" option in your browser.</p>
        </div>
        
        <div class="no-print filter-section">
            <h3>Adjust Report</h3>
            <div class="filter-row">
                <div class="filter-item">
                    <label for="dateSortSelect">Sort By Date</label>
                    <select id="dateSortSelect" onchange="sortTable()">
                        <option value="">Default Order</option>
                        <option value="newest">Newest First</option>
                        <option value="oldest">Oldest First</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="monthFilter">Filter by Month</label>
                    <select id="monthFilter" onchange="filterByMonth()">
                        <option value="">All Months</option>
                        <option value="January">January</option>
                        <option value="February">February</option>
                        <option value="March">March</option>
                        <option value="April">April</option>
                        <option value="May">May</option>
                        <option value="June">June</option>
                        <option value="July">July</option>
                        <option value="August">August</option>
                        <option value="September">September</option>
                        <option value="October">October</option>
                        <option value="November">November</option>
                        <option value="December">December</option>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="restaurantFilter">Filter by Restaurant</label>
                    <select id="restaurantFilter" onchange="filterByRestaurant()">
                        <option value="">All Restaurants</option>
                        <?php 
                        // Add restaurant options if this data has restaurants
                        if (!empty($data)) {
                            $restaurants = [];
                            foreach ($data as $row) {
                                if (isset($row['Restaurant'])) {
                                    $restaurants[$row['Restaurant']] = true;
                                }
                            }
                            
                            // Output unique restaurant options
                            foreach (array_keys($restaurants) as $restaurant) {
                                if (!empty($restaurant)) {
                                    echo '<option value="' . htmlspecialchars($restaurant) . '">' . 
                                         htmlspecialchars($restaurant) . '</option>';
                                }
                            }
                        }
                        ?>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="roleFilter">Filter by Role</label>
                    <select id="roleFilter" onchange="filterByRole()">
                        <option value="">All Roles</option>
                        <?php 
                        // Add role options if this data has roles
                        if (!empty($data)) {
                            $roles = [];
                            foreach ($data as $row) {
                                if (isset($row['Role'])) {
                                    $roles[$row['Role']] = true;
                                }
                            }
                            
                            // Output unique role options
                            foreach (array_keys($roles) as $role) {
                                if (!empty($role)) {
                                    echo '<option value="' . htmlspecialchars($role) . '">' . 
                                         htmlspecialchars($role) . '</option>';
                                }
                            }
                        }
                        ?>
                    </select>
                </div>
                <div class="filter-item">
                    <label for="statusFilter">Filter by Status</label>
                    <select id="statusFilter" onchange="filterByStatus()">
                        <option value="">All Statuses</option>
                        <?php 
                        // Add status options if this data has status
                        if (!empty($data)) {
                            $statuses = [];
                            foreach ($data as $row) {
                                if (isset($row['Status'])) {
                                    $statuses[$row['Status']] = true;
                                }
                            }
                            
                            // Output unique status options
                            foreach (array_keys($statuses) as $status) {
                                if (!empty($status)) {
                                    echo '<option value="' . htmlspecialchars($status) . '">' . 
                                         htmlspecialchars($status) . '</option>';
                                }
                            }
                        }
                        ?>
                    </select>
                </div>
            </div>
        </div>
        
        <?php if (!empty($data)): ?>
            <table id="dataTable">
                <thead>
                    <tr>
                        <?php foreach (array_keys($data[0]) as $header): ?>
                            <th onclick="sortTableByColumn(this)"><?php echo htmlspecialchars($header); ?></th>
                        <?php endforeach; ?>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($data as $row): ?>
                        <tr>
                            <?php foreach ($row as $value): ?>
                                <td><?php echo htmlspecialchars($value); ?></td>
                            <?php endforeach; ?>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        <?php else: ?>
            <p>No data available.</p>
        <?php endif; ?>
        
        <div class="footer">
            <p>© <?php echo date('Y'); ?> Pamigay Admin System</p>
        </div>
        
        <script>
            // Table sorting functionality
            let lastSortedColumn = null;
            let sortDirection = 'asc';
            
            function sortTableByColumn(headerElement) {
                const table = document.getElementById('dataTable');
                const columnIndex = headerElement.cellIndex;
                
                // Reset all headers
                document.querySelectorAll('th').forEach(th => {
                    th.classList.remove('sorted-asc', 'sorted-desc');
                });
                
                // Set sort direction
                if (lastSortedColumn === columnIndex) {
                    sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
                } else {
                    sortDirection = 'asc';
                }
                
                // Mark header as sorted
                headerElement.classList.add(sortDirection === 'asc' ? 'sorted-asc' : 'sorted-desc');
                
                // Remember last sorted column
                lastSortedColumn = columnIndex;
                
                // Sort rows
                const rows = Array.from(table.querySelectorAll('tbody tr'));
                
                rows.sort((a, b) => {
                    const aValue = a.cells[columnIndex].textContent.trim();
                    const bValue = b.cells[columnIndex].textContent.trim();
                    
                    // Try to parse dates first
                    const aDate = parseDate(aValue);
                    const bDate = parseDate(bValue);
                    
                    if (aDate && bDate) {
                        return sortDirection === 'asc' ? aDate - bDate : bDate - aDate;
                    }
                    
                    // Check if values are numbers
                    const aNum = parseFloat(aValue);
                    const bNum = parseFloat(bValue);
                    
                    if (!isNaN(aNum) && !isNaN(bNum)) {
                        return sortDirection === 'asc' ? aNum - bNum : bNum - aNum;
                    }
                    
                    // Fall back to string comparison
                    return sortDirection === 'asc' 
                        ? aValue.localeCompare(bValue) 
                        : bValue.localeCompare(aValue);
                });
                
                // Reorder the table
                table.querySelector('tbody').append(...rows);
            }
            
            function parseDate(dateStr) {
                // Try various date formats
                const formats = [
                    /(\w{3}) (\d{1,2}), (\d{4})/, // Jan 01, 2023
                    /(\d{4})-(\d{2})-(\d{2})/, // 2023-01-01
                    /(\d{2})\/(\d{2})\/(\d{4})/ // 01/01/2023
                ];
                
                for (let format of formats) {
                    if (format.test(dateStr)) {
                        return new Date(dateStr).getTime();
                    }
                }
                
                return null;
            }
            
            function sortTable() {
                const sortSelect = document.getElementById('dateSortSelect');
                const value = sortSelect.value;
                
                if (!value) return;
                
                // Find date column
                const table = document.getElementById('dataTable');
                const headers = table.querySelectorAll('th');
                
                let dateColumnIndex = -1;
                for (let i = 0; i < headers.length; i++) {
                    const headerText = headers[i].textContent.toLowerCase();
                    if (headerText.includes('date') || headerText.includes('created') || 
                        headerText.includes('time') || headerText.includes('pickup time')) {
                        dateColumnIndex = i;
                        break;
                    }
                }
                
                if (dateColumnIndex >= 0) {
                    // Reset all headers
                    document.querySelectorAll('th').forEach(th => {
                        th.classList.remove('sorted-asc', 'sorted-desc');
                    });
                    
                    // Sort by date
                    const dateHeader = headers[dateColumnIndex];
                    
                    if (value === 'newest') {
                        sortDirection = 'desc';
                        dateHeader.classList.add('sorted-desc');
                    } else {
                        sortDirection = 'asc';
                        dateHeader.classList.add('sorted-asc');
                    }
                    
                    lastSortedColumn = dateColumnIndex;
                    
                    // Sort rows
                    const rows = Array.from(table.querySelectorAll('tbody tr'));
                    
                    rows.sort((a, b) => {
                        const aValue = a.cells[dateColumnIndex].textContent.trim();
                        const bValue = b.cells[dateColumnIndex].textContent.trim();
                        
                        const aDate = parseDate(aValue) || 0;
                        const bDate = parseDate(bValue) || 0;
                        
                        return sortDirection === 'asc' ? aDate - bDate : bDate - aDate;
                    });
                    
                    // Reorder the table
                    table.querySelector('tbody').append(...rows);
                }
            }
            
            function filterByMonth() {
                const monthFilter = document.getElementById('monthFilter');
                const selectedMonth = monthFilter.value;
                
                if (!selectedMonth) {
                    // Show all rows
                    document.querySelectorAll('#dataTable tbody tr').forEach(row => {
                        row.style.display = '';
                    });
                    return;
                }
                
                // Find date column
                const table = document.getElementById('dataTable');
                const headers = table.querySelectorAll('th');
                
                let dateColumnIndex = -1;
                for (let i = 0; i < headers.length; i++) {
                    const headerText = headers[i].textContent.toLowerCase();
                    if (headerText.includes('date') || headerText.includes('created') || 
                        headerText.includes('time') || headerText.includes('pickup time')) {
                        dateColumnIndex = i;
                        break;
                    }
                }
                
                if (dateColumnIndex >= 0) {
                    // Filter rows by month
                    document.querySelectorAll('#dataTable tbody tr').forEach(row => {
                        const cellValue = row.cells[dateColumnIndex].textContent.trim();
                        
                        // Skip if cell doesn't contain a valid date
                        if (!parseDate(cellValue)) {
                            row.style.display = '';
                            return;
                        }
                        
                        const date = new Date(cellValue);
                        const monthName = date.toLocaleString('en-US', { month: 'long' });
                        
                        if (monthName === selectedMonth) {
                            row.style.display = '';
                        } else {
                            row.style.display = 'none';
                        }
                    });
                }
            }
            
            function filterByRestaurant() {
                const restaurantFilter = document.getElementById('restaurantFilter');
                const selectedRestaurant = restaurantFilter.value;
                
                if (!selectedRestaurant) {
                    // Show all rows
                    document.querySelectorAll('#dataTable tbody tr').forEach(row => {
                        row.style.display = '';
                    });
                    return;
                }
                
                // Find restaurant column
                const table = document.getElementById('dataTable');
                const headers = table.querySelectorAll('th');
                
                let restaurantColumnIndex = -1;
                for (let i = 0; i < headers.length; i++) {
                    const headerText = headers[i].textContent.toLowerCase();
                    if (headerText.includes('restaurant')) {
                        restaurantColumnIndex = i;
                        break;
                    }
                }
                
                if (restaurantColumnIndex >= 0) {
                    // Filter rows by restaurant
                    document.querySelectorAll('#dataTable tbody tr').forEach(row => {
                        const cellValue = row.cells[restaurantColumnIndex].textContent.trim();
                        
                        if (cellValue === selectedRestaurant) {
                            row.style.display = '';
                        } else {
                            row.style.display = 'none';
                        }
                    });
                }
            }
            
            function filterByRole() {
                const roleFilter = document.getElementById('roleFilter');
                const selectedRole = roleFilter.value;
                
                if (!selectedRole) {
                    // Show all rows
                    document.querySelectorAll('#dataTable tbody tr').forEach(row => {
                        row.style.display = '';
                    });
                    return;
                }
                
                // Find role column
                const table = document.getElementById('dataTable');
                const headers = table.querySelectorAll('th');
                
                let roleColumnIndex = -1;
                for (let i = 0; i < headers.length; i++) {
                    const headerText = headers[i].textContent.toLowerCase();
                    if (headerText === 'role') {
                        roleColumnIndex = i;
                        break;
                    }
                }
                
                if (roleColumnIndex >= 0) {
                    // Filter rows by role
                    document.querySelectorAll('#dataTable tbody tr').forEach(row => {
                        const cellValue = row.cells[roleColumnIndex].textContent.trim();
                        
                        if (cellValue === selectedRole) {
                            row.style.display = '';
                        } else {
                            row.style.display = 'none';
                        }
                    });
                }
            }
            
            function filterByStatus() {
                const statusFilter = document.getElementById('statusFilter');
                const selectedStatus = statusFilter.value;
                
                if (!selectedStatus) {
                    // Show all rows
                    document.querySelectorAll('#dataTable tbody tr').forEach(row => {
                        row.style.display = '';
                    });
                    return;
                }
                
                // Find status column
                const table = document.getElementById('dataTable');
                const headers = table.querySelectorAll('th');
                
                let statusColumnIndex = -1;
                for (let i = 0; i < headers.length; i++) {
                    const headerText = headers[i].textContent.toLowerCase();
                    if (headerText === 'status') {
                        statusColumnIndex = i;
                        break;
                    }
                }
                
                if (statusColumnIndex >= 0) {
                    // Filter rows by status
                    document.querySelectorAll('#dataTable tbody tr').forEach(row => {
                        const cellValue = row.cells[statusColumnIndex].textContent.trim();
                        
                        if (cellValue === selectedStatus) {
                            row.style.display = '';
                        } else {
                            row.style.display = 'none';
                        }
                    });
                }
            }
            
            // Automatically open print dialog when page loads
            window.onload = function() {
                // Delay printing slightly to ensure page is fully loaded
                setTimeout(function() {
                    // Uncomment this to automatically print when page loads
                    // window.print();
                }, 1000);
            };
        </script>
    </body>
    </html>
    <?php
}

// Get Users data
function getUsersData($conn) {
    $data = [];
    
    // Build query with filters
    $whereClause = "";
    $params = [];
    
    if (isset($_GET['role']) && !empty($_GET['role'])) {
        $whereClause .= " WHERE role = ?";
        $params[] = $_GET['role'];
    }
    
    if (isset($_GET['search']) && !empty($_GET['search'])) {
        $prefix = empty($whereClause) ? " WHERE" : " AND";
        $whereClause .= "$prefix (name LIKE ? OR email LIKE ?)";
        $searchTerm = "%" . $_GET['search'] . "%";
        $params[] = $searchTerm;
        $params[] = $searchTerm;
    }
    
    // Build query
    $query = "SELECT id, name, email, role, phone_number, created_at FROM users" . $whereClause . " ORDER BY id DESC LIMIT 100";
    
    // Prepare and execute query
    $stmt = mysqli_prepare($conn, $query);
    
    if (!empty($params)) {
        $types = str_repeat('s', count($params));
        mysqli_stmt_bind_param($stmt, $types, ...$params);
    }
    
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
    
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = [
            'ID' => $row['id'],
            'Name' => $row['name'],
            'Email' => $row['email'],
            'Role' => $row['role'],
            'Phone' => $row['phone_number'] ?: 'N/A',
            'Created' => date('M d, Y', strtotime($row['created_at']))
        ];
    }
    
    return $data;
}

// Get Donations data
function getDonationsData($conn) {
    $data = [];
    
    // Build query with filters
    $whereClause = "";
    $params = [];
    
    if (isset($_GET['status']) && !empty($_GET['status'])) {
        $whereClause .= " WHERE fd.status = ?";
        $params[] = $_GET['status'];
    }
    
    if (isset($_GET['search']) && !empty($_GET['search'])) {
        $prefix = empty($whereClause) ? " WHERE" : " AND";
        $whereClause .= "$prefix (fd.name LIKE ? OR u.name LIKE ?)";
        $searchTerm = "%" . $_GET['search'] . "%";
        $params[] = $searchTerm;
        $params[] = $searchTerm;
    }
    
    // Build query
    $query = "SELECT fd.id, fd.name, u.name as restaurant, fd.category, fd.quantity, fd.status
              FROM food_donations fd
              LEFT JOIN users u ON fd.restaurant_id = u.id" . $whereClause . " ORDER BY fd.id DESC LIMIT 100";
    
    // Prepare and execute query
    $stmt = mysqli_prepare($conn, $query);
    
    if (!empty($params)) {
        $types = str_repeat('s', count($params));
        mysqli_stmt_bind_param($stmt, $types, ...$params);
    }
    
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
    
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = [
            'ID' => $row['id'],
            'Name' => $row['name'],
            'Restaurant' => $row['restaurant'],
            'Category' => $row['category'],
            'Quantity' => $row['quantity'],
            'Status' => $row['status']
        ];
    }
    
    return $data;
}

// Get Pickups data
function getPickupsData($conn) {
    $data = [];
    
    // Build query with filters
    $whereClause = "";
    $params = [];
    
    if (isset($_GET['status']) && !empty($_GET['status'])) {
        $whereClause .= " WHERE fp.status = ?";
        $params[] = $_GET['status'];
    }
    
    if (isset($_GET['search']) && !empty($_GET['search'])) {
        $prefix = empty($whereClause) ? " WHERE" : " AND";
        $whereClause .= "$prefix (fd.name LIKE ? OR restaurant.name LIKE ?)";
        $searchTerm = "%" . $_GET['search'] . "%";
        $params[] = $searchTerm;
        $params[] = $searchTerm;
    }
    
    // Build query
    $query = "SELECT fp.id, fd.name as donation, restaurant.name as restaurant,
              organization.name as organization, fp.pickup_time, fp.status
              FROM food_pickups fp
              LEFT JOIN food_donations fd ON fp.donation_id = fd.id
              LEFT JOIN users restaurant ON fd.restaurant_id = restaurant.id
              LEFT JOIN users organization ON fp.collector_id = organization.id" . $whereClause . " ORDER BY fp.id DESC LIMIT 100";
    
    // Prepare and execute query
    $stmt = mysqli_prepare($conn, $query);
    
    if (!empty($params)) {
        $types = str_repeat('s', count($params));
        mysqli_stmt_bind_param($stmt, $types, ...$params);
    }
    
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
    
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = [
            'ID' => $row['id'],
            'Donation' => $row['donation'],
            'Restaurant' => $row['restaurant'],
            'Organization' => $row['organization'],
            'Pickup Time' => $row['pickup_time'],
            'Status' => $row['status']
        ];
    }
    
    return $data;
}

// If file is accessed directly
if (basename($_SERVER['SCRIPT_FILENAME']) === basename(__FILE__)) {
    $type = isset($_GET['type']) ? $_GET['type'] : 'test';
    $title = ucfirst($type) . " Report";
    exportAsHTML($type, $title);
}
?> 