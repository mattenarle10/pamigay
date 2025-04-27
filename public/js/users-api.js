/**
 * Users API - Handles data fetching and processing for the users page
 */

// API endpoints
const API_ENDPOINTS = {
    users: '../admin/users.php'
};

// Users data controller
const UsersAPI = {
    /**
     * Fetch users with optional filters
     * @param {Object} filters - Filter parameters
     * @returns {Promise} Promise resolving to users data
     */
    getUsers: async function(filters = {}) {
        try {
            // Build query string from filters
            const queryParams = new URLSearchParams();
            
            if (filters.role) queryParams.append('role', filters.role);
            if (filters.search) queryParams.append('search', filters.search);
            if (filters.status) queryParams.append('status', filters.status);
            
            const url = `${API_ENDPOINTS.users}?${queryParams.toString()}`;
            const response = await fetch(url);
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to fetch users');
            }
            
            return result.data;
        } catch (error) {
            console.error('Error fetching users:', error);
            throw error;
        }
    },
    
    /**
     * Fetch a specific user by ID
     * @param {number} userId - The user ID to fetch
     * @returns {Promise} Promise resolving to user data
     */
    getUserById: async function(userId) {
        try {
            const url = `${API_ENDPOINTS.users}?id=${userId}`;
            const response = await fetch(url);
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to fetch user details');
            }
            
            return result.data;
        } catch (error) {
            console.error(`Error fetching user ${userId}:`, error);
            throw error;
        }
    },
    
    /**
     * Delete a user
     * @param {number} userId - The user ID to delete
     * @returns {Promise} Promise resolving to success message
     */
    deleteUser: async function(userId) {
        try {
            const url = `${API_ENDPOINTS.users}?id=${userId}`;
            const response = await fetch(url, {
                method: 'DELETE'
            });
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to delete user');
            }
            
            return result;
        } catch (error) {
            console.error(`Error deleting user ${userId}:`, error);
            throw error;
        }
    },
    
    /**
     * Update users table with fetched data
     * @param {Array} users - List of users to display
     */
    updateUsersTable: function(users) {
        const tableBody = document.querySelector('table.neu-table tbody');
        if (!tableBody) return;
        
        // Clear existing content
        tableBody.innerHTML = '';
        
        if (!users || users.length === 0) {
            const emptyRow = document.createElement('tr');
            emptyRow.innerHTML = `
                <td colspan="9" class="text-center py-4">
                    <div class="empty-state">
                        <i class="bi bi-search fs-1 text-muted mb-3"></i>
                        <h5 class="text-muted">No users found</h5>
                        <p class="text-muted">Try adjusting your filters or search criteria</p>
                    </div>
                </td>
            `;
            tableBody.appendChild(emptyRow);
            
            // Update displayed count
            document.getElementById('displayedCount').textContent = '0';
            document.getElementById('totalCount').textContent = '0';
            return;
        }
        
        // Update displayed count
        document.getElementById('displayedCount').textContent = users.length;
        document.getElementById('totalCount').textContent = users.length;
        
        // Count users by role
        const restaurantCount = users.filter(user => user.role === 'Restaurant').length;
        const organizationCount = users.filter(user => user.role === 'Organization').length;
        
        // Update role counts in stat cards
        document.getElementById('restaurantsCount').textContent = restaurantCount;
        document.getElementById('organizationsCount').textContent = organizationCount;
        
        // Count new users this month
        const currentDate = new Date();
        const firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
        const newUsersThisMonth = users.filter(user => {
            const createdDate = new Date(user.created_at);
            return createdDate >= firstDayOfMonth;
        }).length;
        
        // Update new users count
        document.getElementById('newUsersCount').textContent = newUsersThisMonth;
        
        // Add each user to the table
        users.forEach(user => {
            const row = document.createElement('tr');
            row.setAttribute('data-id', user.id);
            
            // Format date
            const createdDate = new Date(user.created_at);
            const formattedDate = createdDate.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'short', 
                day: 'numeric'
            });
            
            // Format role with badge
            let roleBadgeClass = 'primary';
            let roleTextColor = '#fff';
            let roleBgColor = '#007bff';
            
            if (user.role === 'Restaurant') {
                roleBadgeClass = 'success';
                roleTextColor = '#222';
                roleBgColor = '#d4edda';
            } else if (user.role === 'Organization') {
                roleBadgeClass = 'info';
                roleTextColor = '#222';
                roleBgColor = '#d1ecf1';
            }
            
            // Calculate activity status
            const hasActivity = (user.total_donated > 0 || user.total_collected > 0);
            const activityStatus = hasActivity ? 'Active' : 'Inactive';
            let activityBadgeClass = hasActivity ? 'success' : 'secondary';
            let activityTextColor = hasActivity ? '#222' : '#fff';
            let activityBgColor = hasActivity ? '#d4edda' : '#6c757d';
            
            row.innerHTML = `
                <td>${user.id}</td>
                <td>${user.name}</td>
                <td>${user.email}</td>
                <td><span class="neu-badge ${roleBadgeClass}" style="color:${roleTextColor};background:${roleBgColor};">${user.role}</span></td>
                <td><span class="neu-badge ${activityBadgeClass}" style="color:${activityTextColor};background:${activityBgColor};">${activityStatus}</span></td>
                <td>${user.phone_number || 'N/A'}</td>
                <td>${user.location || 'N/A'}</td>
                <td>${formattedDate}</td>
                <td>
                    <button class="neu-button danger btn-sm p-1 delete-user-btn" data-id="${user.id}" data-bs-toggle="modal" data-bs-target="#deleteUserModal">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            `;
            
            tableBody.appendChild(row);
        });
        
        // Attach event listeners to the new buttons
        this.attachEventListeners();
    },
    
    /**
     * Populate user details in the view modal
     * @param {Object} user - User data to display
     */
    populateUserModal: function(user) {
        // Basic information
        document.getElementById('userName').textContent = user.name;
        document.getElementById('userEmail').textContent = user.email;
        document.getElementById('userRole').textContent = user.role;
        document.getElementById('userLocation').textContent = user.location || '-';
        document.getElementById('userPhone').textContent = user.phone_number || '-';
        
        // Status badge
        const isActive = user.total_donated > 0 || user.total_collected > 0;
        document.getElementById('userStatus').innerHTML = isActive ? 
            '<span class="neu-badge primary">Active</span>' : 
            '<span class="neu-badge secondary">Inactive</span>';
        
        // Last updated
        const updatedDate = new Date(user.updated_at);
        document.getElementById('userUpdated').textContent = updatedDate.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric'
        });
        
        // User stats
        document.getElementById('userTotalDonated').textContent = user.total_donated || '0';
        document.getElementById('userTotalCollected').textContent = user.total_collected || '0';
        document.getElementById('userTotalSaved').textContent = user.total_saved || '0';
        document.getElementById('userIsTopDonor').textContent = user.is_top_donor ? 'Yes' : 'No';
        
        // Recent activity
        const activityList = document.getElementById('userRecentActivity');
        activityList.innerHTML = '';
        
        if (!user.recent_activity || user.recent_activity.length === 0) {
            activityList.innerHTML = '<li class="list-group-item bg-transparent">No recent activity</li>';
            return;
        }
        
        user.recent_activity.forEach(activity => {
            const activityDate = new Date(activity.created_at);
            const formattedDate = activityDate.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'short', 
                day: 'numeric'
            });
            
            let activityText = '';
            if (activity.type === 'donation') {
                activityText = `Added donation: ${activity.item_name} (${activity.status})`;
            } else if (activity.type === 'pickup') {
                activityText = `${activity.status} pickup for donation: ${activity.item_name}`;
            }
            
            const li = document.createElement('li');
            li.className = 'list-group-item bg-transparent';
            li.textContent = `${activityText} (${formattedDate})`;
            
            activityList.appendChild(li);
        });
    },
    
    /**
     * Attach event listeners to user action buttons
     */
    attachEventListeners: function() {
        // Delete user buttons
        const deleteButtons = document.querySelectorAll('.delete-user-btn');
        deleteButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                const userId = e.currentTarget.getAttribute('data-id');
                document.getElementById('deleteUserId').value = userId;
            });
        });
        
        // Confirm delete button in modal
        const confirmDeleteBtn = document.getElementById('confirmUserDelete');
        if (confirmDeleteBtn) {
            confirmDeleteBtn.addEventListener('click', async () => {
                const userId = document.getElementById('deleteUserId').value;
                if (!userId) return;
                
                // Disable button and show loading state
                confirmDeleteBtn.disabled = true;
                confirmDeleteBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Deleting...';
                
                try {
                    // Delete the user
                    await this.deleteUser(userId);
                    
                    // Close the modal
                    const modal = bootstrap.Modal.getInstance(document.getElementById('deleteUserModal'));
                    modal.hide();
                    
                    // Reload users to update the table
                    this.loadUsers();
                    
                    // Show success message
                    alert('User deleted successfully');
                } catch (error) {
                    console.error('Error deleting user:', error);
                    alert('Failed to delete user. Please try again.');
                } finally {
                    // Reset button state
                    confirmDeleteBtn.disabled = false;
                    confirmDeleteBtn.innerHTML = 'Delete';
                }
            });
        }
    },
    
    /**
     * Load users with current filters
     */
    loadUsers: async function() {
        try {
            // Show loading state
            const tableBody = document.querySelector('table.neu-table tbody');
            if (tableBody) {
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="9" class="text-center py-4">
                            <div class="spinner-border" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                            <p class="mt-2">Loading users...</p>
                        </td>
                    </tr>
                `;
            }
            
            // Get filter values
            const roleFilter = document.getElementById('roleFilter')?.value || '';
            const searchInput = document.getElementById('userSearchInput')?.value || '';
            const statusFilter = document.getElementById('statusFilter')?.value || '';
            
            // Fetch users with filters
            const users = await this.getUsers({
                role: roleFilter,
                search: searchInput,
                status: statusFilter
            });
            
            // Update the table
            this.updateUsersTable(users);
        } catch (error) {
            console.error('Error loading users:', error);
            
            // Show error message in table
            const tableBody = document.querySelector('table.neu-table tbody');
            if (tableBody) {
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="9" class="text-center py-4 text-danger">
                            <i class="bi bi-exclamation-triangle fs-1 mb-3"></i>
                            <h5>Failed to load users</h5>
                            <p>Please try refreshing the page</p>
                        </td>
                    </tr>
                `;
            }
        }
    },
    
    /**
     * Initialize users page
     */
    init: function() {
        document.addEventListener('DOMContentLoaded', () => {
            // Load initial data
            this.loadUsers();
            
            // Set up filter buttons
            const applyFiltersBtn = document.getElementById('applyFilters');
            if (applyFiltersBtn) {
                applyFiltersBtn.addEventListener('click', () => {
                    this.loadUsers();
                });
            }
            
            // Set up reset filters button
            const resetFiltersBtn = document.getElementById('resetFilters');
            if (resetFiltersBtn) {
                resetFiltersBtn.addEventListener('click', () => {
                    // Clear filter inputs
                    document.getElementById('roleFilter').value = '';
                    document.getElementById('userSearchInput').value = '';
                    document.getElementById('statusFilter').value = '';
                    
                    // Reload users without filters
                    this.loadUsers();
                });
            }
            
            // Set up search on enter key
            const searchInput = document.getElementById('userSearchInput');
            if (searchInput) {
                searchInput.addEventListener('keyup', (e) => {
                    if (e.key === 'Enter') {
                        this.loadUsers();
                    }
                });
            }
        });
    }
};

// Initialize users page
UsersAPI.init();
