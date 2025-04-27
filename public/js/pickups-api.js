/**
 * Pickups API - Handles data fetching and processing for the pickups page
 */

// API endpoints
const API_ENDPOINTS = {
    pickups: '../admin/pickups.php'
};

// Pickups data controller
const PickupsAPI = {
    /**
     * Fetch pickups with optional filters
     * @param {Object} filters - Filter parameters
     * @returns {Promise} Promise resolving to pickups data
     */
    getPickups: async function(filters = {}) {
        try {
            // Build query string from filters
            const queryParams = new URLSearchParams();
            
            if (filters.status) queryParams.append('status', filters.status);
            if (filters.organization) queryParams.append('organization', filters.organization);
            if (filters.search) queryParams.append('search', filters.search);
            if (filters.date) queryParams.append('date', filters.date);
            
            const url = `${API_ENDPOINTS.pickups}?${queryParams.toString()}`;
            const response = await fetch(url);
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to fetch pickups');
            }
            
            return result.data;
        } catch (error) {
            console.error('Error fetching pickups:', error);
            throw error;
        }
    },
    
    /**
     * Fetch a specific pickup by ID
     * @param {number} pickupId - The pickup ID to fetch
     * @returns {Promise} Promise resolving to pickup data
     */
    getPickupById: async function(pickupId) {
        try {
            const url = `${API_ENDPOINTS.pickups}?id=${pickupId}`;
            const response = await fetch(url);
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to fetch pickup details');
            }
            
            return result.data;
        } catch (error) {
            console.error(`Error fetching pickup ${pickupId}:`, error);
            throw error;
        }
    },
    
    /**
     * Update a pickup's status
     * @param {number} pickupId - The pickup ID to update
     * @param {string} status - The new status
     * @returns {Promise} Promise resolving to success message
     */
    updatePickupStatus: async function(pickupId, status) {
        try {
            const url = `${API_ENDPOINTS.pickups}?id=${pickupId}`;
            const response = await fetch(url, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ status })
            });
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to update pickup status');
            }
            
            return result;
        } catch (error) {
            console.error(`Error updating pickup ${pickupId}:`, error);
            throw error;
        }
    },
    
    /**
     * Delete a pickup
     * @param {number} pickupId - The pickup ID to delete
     * @returns {Promise} Promise resolving to success message
     */
    deletePickup: async function(pickupId) {
        try {
            const url = `${API_ENDPOINTS.pickups}?id=${pickupId}`;
            const response = await fetch(url, {
                method: 'DELETE'
            });
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to delete pickup');
            }
            
            return result;
        } catch (error) {
            console.error(`Error deleting pickup ${pickupId}:`, error);
            throw error;
        }
    },
    
    /**
     * Update pickups table with fetched data
     * @param {Array} pickups - List of pickups to display
     */
    updatePickupsTable: function(pickups) {
        const tableBody = document.querySelector('table.neu-table tbody');
        if (!tableBody) return;
        
        // Clear existing rows
        tableBody.innerHTML = '';
        
        // Check if there are no pickups
        if (!pickups || pickups.length === 0) {
            tableBody.innerHTML = `
                <tr>
                    <td colspan="9" class="text-center py-4">
                        <div class="empty-state">
                            <i class="bi bi-inbox fs-1 text-muted mb-3"></i>
                            <h5 class="text-muted">No pickups found</h5>
                            <p class="text-muted">Try adjusting your filters or check back later</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }
        
        // Helper function to format dates
        const formatDateTime = (dateString) => {
            if (!dateString) return '';
            const date = new Date(dateString);
            return date.toLocaleString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        };
        
        // Add rows for each pickup
        pickups.forEach(pickup => {
            const row = document.createElement('tr');
            row.setAttribute('data-id', pickup.id);
            
            // Set status badge class
            let statusBadgeClass = 'primary';
            if (pickup.status === 'Requested') statusBadgeClass = 'warning';
            else if (pickup.status === 'Accepted') statusBadgeClass = 'primary';
            else if (pickup.status === 'Completed') statusBadgeClass = 'success';
            else if (pickup.status === 'Cancelled') statusBadgeClass = 'danger';
            
            // Format pickup time
            const pickupTime = pickup.pickup_time ? formatDateTime(pickup.pickup_time) : '';
            
            row.innerHTML = `
                <td>${pickup.id}</td>
                <td>${pickup.donation_name || ''}</td>
                <td><span class="neu-badge info" style="color:#222;background:#e0e7ef;">${pickup.quantity || ''}</span></td>
                <td>${pickup.restaurant_name || ''}</td>
                <td>${pickup.organization_name || ''}</td>
                <td>${pickupTime}</td>
                <td><span class="neu-badge ${statusBadgeClass}" style="color:#fff;background:#007bff;">${pickup.status || ''}</span></td>
                <td>${pickup.notes || ''}</td>
                <td>
                    <button class="neu-button danger btn-sm p-1 delete-pickup-btn" data-id="${pickup.id}">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            `;
            
            tableBody.appendChild(row);
        });
        
        // Update displayed counts
        document.getElementById('displayedCount').textContent = pickups.length;
        document.getElementById('totalCount').textContent = pickups.length;
        
        // Attach event listeners to action buttons
        this.attachEventListeners();
    },
    
    /**
     * Populate pickup details in the view modal
     * @param {Object} pickup - Pickup data to display
     */
    populatePickupModal: function(pickup) {
        // Basic information
        document.getElementById('pickupId').textContent = pickup.id;
        document.getElementById('donationName').textContent = pickup.donation_name;
        document.getElementById('donationQuantity').textContent = pickup.quantity;
        document.getElementById('donationCategory').textContent = pickup.category;
        document.getElementById('donationCondition').textContent = pickup.condition_status;
        
        // Format dates
        const createdDate = new Date(pickup.created_at);
        document.getElementById('pickupRequested').textContent = createdDate.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        
        const pickupDate = pickup.pickup_time ? new Date(pickup.pickup_time) : null;
        document.getElementById('pickupScheduled').textContent = pickupDate ? pickupDate.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }) : 'Not scheduled';
        
        const deadlineDate = new Date(pickup.pickup_deadline);
        document.getElementById('pickupDeadline').textContent = deadlineDate.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        
        // Set status badge
        let statusBadgeClass = 'primary';
        if (pickup.status === 'Accepted') statusBadgeClass = 'warning';
        else if (pickup.status === 'Completed') statusBadgeClass = 'success';
        else if (pickup.status === 'Cancelled') statusBadgeClass = 'danger';
        
        document.getElementById('pickupStatus').innerHTML = 
            `<span class="neu-badge ${statusBadgeClass}">${pickup.status}</span>`;
        
        // Notes
        document.getElementById('pickupNotes').textContent = pickup.notes || 'No notes provided';
        
        // Restaurant information
        document.getElementById('restaurantName').textContent = pickup.restaurant_name;
        document.getElementById('restaurantEmail').textContent = pickup.restaurant_email || '-';
        document.getElementById('restaurantPhone').textContent = pickup.restaurant_phone || '-';
        document.getElementById('restaurantLocation').textContent = pickup.restaurant_location || '-';
        
        // Organization information
        document.getElementById('organizationName').textContent = pickup.organization_name;
        document.getElementById('organizationEmail').textContent = pickup.organization_email || '-';
        document.getElementById('organizationPhone').textContent = pickup.organization_phone || '-';
        document.getElementById('organizationLocation').textContent = pickup.organization_location || '-';
    },
    
    /**
     * Attach event listeners to pickup action buttons
     */
    attachEventListeners: function() {
        // View pickup buttons
        document.querySelectorAll('.view-pickup-btn').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const pickupId = e.currentTarget.getAttribute('data-id');
                
                try {
                    // Show loading state in modal
                    document.getElementById('viewPickupModalLabel').textContent = 'Loading pickup details...';
                    
                    // Open the modal
                    const modal = new bootstrap.Modal(document.getElementById('viewPickupModal'));
                    modal.show();
                    
                    // Fetch pickup details
                    const pickup = await this.getPickupById(pickupId);
                    
                    // Update modal title
                    document.getElementById('viewPickupModalLabel').textContent = `Pickup Details - ID: ${pickup.id}`;
                    
                    // Populate modal with pickup data
                    this.populatePickupModal(pickup);
                } catch (error) {
                    console.error('Error viewing pickup:', error);
                    alert('Failed to load pickup details. Please try again.');
                }
            });
        });
        
        // Update status buttons
        document.querySelectorAll('.update-status-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const pickupId = e.currentTarget.getAttribute('data-id');
                document.getElementById('updatePickupId').value = pickupId;
            });
        });
        
        // Confirm status update button
        const confirmStatusUpdateBtn = document.getElementById('confirmStatusUpdate');
        if (confirmStatusUpdateBtn) {
            confirmStatusUpdateBtn.addEventListener('click', async () => {
                const pickupId = document.getElementById('updatePickupId').value;
                const newStatus = document.getElementById('newStatus').value;
                
                try {
                    // Show loading state
                    confirmStatusUpdateBtn.disabled = true;
                    confirmStatusUpdateBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Updating...';
                    
                    // Update the pickup status
                    await this.updatePickupStatus(pickupId, newStatus);
                    
                    // Close the modal
                    const modal = bootstrap.Modal.getInstance(document.getElementById('updateStatusModal'));
                    modal.hide();
                    
                    // Refresh the pickups list
                    this.loadPickups();
                    
                    // Show success message
                    alert('Pickup status updated successfully');
                } catch (error) {
                    console.error('Error updating pickup status:', error);
                    alert('Failed to update pickup status. Please try again.');
                } finally {
                    // Reset button state
                    confirmStatusUpdateBtn.disabled = false;
                    confirmStatusUpdateBtn.innerHTML = 'Update Status';
                }
            });
        }
        
        // Cancel pickup buttons
        document.querySelectorAll('.cancel-pickup-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const pickupId = e.currentTarget.getAttribute('data-id');
                document.getElementById('cancelPickupId').value = pickupId;
            });
        });
        
        // Confirm cancel button
        const confirmCancelBtn = document.getElementById('confirmCancel');
        if (confirmCancelBtn) {
            confirmCancelBtn.addEventListener('click', async () => {
                const pickupId = document.getElementById('cancelPickupId').value;
                
                try {
                    // Show loading state
                    confirmCancelBtn.disabled = true;
                    confirmCancelBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Cancelling...';
                    
                    // Update the pickup status to Cancelled
                    await this.updatePickupStatus(pickupId, 'Cancelled');
                    
                    // Close the modal
                    const modal = bootstrap.Modal.getInstance(document.getElementById('cancelPickupModal'));
                    modal.hide();
                    
                    // Refresh the pickups list
                    this.loadPickups();
                    
                    // Show success message
                    alert('Pickup cancelled successfully');
                } catch (error) {
                    console.error('Error cancelling pickup:', error);
                    alert('Failed to cancel pickup. Please try again.');
                } finally {
                    // Reset button state
                    confirmCancelBtn.disabled = false;
                    confirmCancelBtn.innerHTML = 'Cancel Pickup';
                }
            });
        }
    },
    
    /**
     * Load pickups with current filters
     */
    loadPickups: async function() {
        try {
            // Show loading state
            const tableBody = document.querySelector('table.neu-table tbody');
            if (tableBody) {
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="8" class="text-center py-4">
                            <div class="spinner-border" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                            <p class="mt-2">Loading pickups...</p>
                        </td>
                    </tr>
                `;
            }
            
            // Get filter values
            const statusFilter = document.getElementById('statusFilter')?.value || '';
            const searchInput = document.getElementById('searchInput')?.value || '';
            const dateFilter = document.getElementById('dateRangeFilter')?.value || '';
            
            // Fetch pickups with filters
            const pickups = await this.getPickups({
                status: statusFilter,
                search: searchInput,
                date: dateFilter
            });
            
            // Update the table
            this.updatePickupsTable(pickups);
        } catch (error) {
            console.error('Error loading pickups:', error);
            
            // Show error message in table
            const tableBody = document.querySelector('table.neu-table tbody');
            if (tableBody) {
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="8" class="text-center py-4 text-danger">
                            <i class="bi bi-exclamation-triangle fs-1 mb-3"></i>
                            <h5>Failed to load pickups</h5>
                            <p>Please try refreshing the page</p>
                        </td>
                    </tr>
                `;
            }
        }
    },
    
    /**
     * Initialize pickups page
     */
    init: function() {
        document.addEventListener('DOMContentLoaded', () => {
            // Load initial data
            this.loadPickups();
            
            // Set up filter buttons
            const applyFiltersBtn = document.getElementById('applyFilters');
            if (applyFiltersBtn) {
                applyFiltersBtn.addEventListener('click', () => {
                    this.loadPickups();
                });
            }
            
            // Set up reset filters button
            const resetFiltersBtn = document.getElementById('resetFilters');
            if (resetFiltersBtn) {
                resetFiltersBtn.addEventListener('click', () => {
                    // Clear filter inputs
                    document.getElementById('statusFilter').value = '';
                    document.getElementById('dateRangeFilter').value = '';
                    document.getElementById('searchInput').value = '';
                    
                    // Reload pickups without filters
                    this.loadPickups();
                });
            }
            
            // Set up search on enter key
            const searchInput = document.getElementById('searchInput');
            if (searchInput) {
                searchInput.addEventListener('keyup', (e) => {
                    if (e.key === 'Enter') {
                        this.loadPickups();
                    }
                });
            }
        });
    }
};

// Initialize pickups page
PickupsAPI.init();
