/**
 * Donations API - Handles data fetching and processing for the donations page
 */

// API endpoints
const API_ENDPOINTS = {
    donations: '../admin/donations.php'
};

// Donations data controller
const DonationsAPI = {
    /**
     * Fetch donations with optional filters
     * @param {Object} filters - Filter parameters
     * @returns {Promise} Promise resolving to donations data
     */
    getDonations: async function(filters = {}) {
        try {
            console.log('Fetching donations with filters:', filters);
            
            // Build query string from filters
            const queryParams = new URLSearchParams();
            
            if (filters.status) queryParams.append('status', filters.status);
            if (filters.category) queryParams.append('category', filters.category);
            if (filters.condition) queryParams.append('condition', filters.condition);
            if (filters.search) queryParams.append('search', filters.search);
            if (filters.date) queryParams.append('date', filters.date);
            
            const url = `${API_ENDPOINTS.donations}?${queryParams.toString()}`;
            console.log('Fetching from URL:', url);
            const response = await fetch(url);
            const result = await response.json();
            
            console.log('API Response:', result);
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to fetch donations');
            }
            
            return result.data;
        } catch (error) {
            console.error('Error fetching donations:', error);
            throw error;
        }
    },
    
    /**
     * Fetch a specific donation by ID
     * @param {number} donationId - The donation ID to fetch
     * @returns {Promise} Promise resolving to donation data
     */
    getDonationById: async function(donationId) {
        try {
            const url = `${API_ENDPOINTS.donations}?id=${donationId}`;
            console.log('Fetching donation by ID from URL:', url);
            const response = await fetch(url);
            const result = await response.json();
            
            console.log('API Response:', result);
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to fetch donation details');
            }
            
            return result.data;
        } catch (error) {
            console.error(`Error fetching donation ${donationId}:`, error);
            throw error;
        }
    },
    
    /**
     * Delete a donation
     * @param {number} donationId - The donation ID to delete
     * @returns {Promise} Promise resolving to success message
     */
    deleteDonation: async function(donationId) {
        try {
            const url = `${API_ENDPOINTS.donations}?id=${donationId}`;
            console.log('Deleting donation from URL:', url);
            const response = await fetch(url, {
                method: 'DELETE'
            });
            const result = await response.json();
            
            console.log('API Response:', result);
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to delete donation');
            }
            
            return result;
        } catch (error) {
            console.error(`Error deleting donation ${donationId}:`, error);
            throw error;
        }
    },
    
    /**
     * Update a donation's status
     * @param {number} donationId - The donation ID to update
     * @param {string} status - The new status
     * @returns {Promise} Promise resolving to success message
     */
    updateDonationStatus: async function(donationId, status) {
        try {
            const url = `${API_ENDPOINTS.donations}?id=${donationId}`;
            console.log('Updating donation status from URL:', url);
            const response = await fetch(url, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ status })
            });
            const result = await response.json();
            
            console.log('API Response:', result);
            
            if (!result.success) {
                throw new Error(result.message || 'Failed to update donation status');
            }
            
            return result;
        } catch (error) {
            console.error(`Error updating donation ${donationId}:`, error);
            throw error;
        }
    },
    
    /**
     * Update donations table with fetched data
     * @param {Array} donations - List of donations to display
     */
    updateDonationsTable: function(donations) {
        console.log('Updating donations table with data:', donations);
        
        const tableBody = document.querySelector('table.neu-table tbody');
        if (!tableBody) {
            console.error('Table body element not found!');
            return;
        }
        
        // Clear existing content
        tableBody.innerHTML = '';
        
        if (donations.length === 0) {
            console.log('No donations to display, showing empty state');
            const emptyRow = document.createElement('tr');
            emptyRow.innerHTML = `
                <td colspan="8" class="text-center py-4">
                    <div class="empty-state">
                        <i class="bi bi-search fs-1 text-muted mb-3"></i>
                        <h5 class="text-muted">No donations found</h5>
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
        console.log('Updating counts - displayed:', donations.length);
        document.getElementById('displayedCount').textContent = donations.length;
        document.getElementById('totalCount').textContent = donations.length;
        
        // Count donations by status
        const availableCount = donations.filter(d => d.status === 'Available').length;
        const pendingCount = donations.filter(d => d.status === 'Pending Pickup').length;
        const completedCount = donations.filter(d => d.status === 'Completed').length;
        const cancelledCount = donations.filter(d => d.status === 'Cancelled').length;
        
        console.log('Status counts:', { availableCount, pendingCount, completedCount, cancelledCount });
        
        // Update status counts in stat cards if they exist
        if (document.getElementById('availableCount')) {
            document.getElementById('availableCount').textContent = availableCount;
        }
        if (document.getElementById('pendingCount')) {
            document.getElementById('pendingCount').textContent = pendingCount;
        }
        if (document.getElementById('completedCount')) {
            document.getElementById('completedCount').textContent = completedCount;
        }
        if (document.getElementById('cancelledCount')) {
            document.getElementById('cancelledCount').textContent = cancelledCount;
        }
        
        // Add each donation to the table
        console.log('Adding donation rows to table');
        donations.forEach((donation, index) => {
            console.log(`Processing donation ${index}:`, donation);
            const row = document.createElement('tr');
            row.setAttribute('data-id', donation.id);
            
            // Format dates
            const createdDate = new Date(donation.created_at);
            const formattedCreatedDate = createdDate.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'short', 
                day: 'numeric'
            });
            
            const deadlineDate = new Date(donation.pickup_deadline);
            const formattedDeadlineDate = deadlineDate.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'short', 
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
            
            // Set badge classes for condition and status
            let conditionBadgeClass = 'success';
            if (donation.condition_status === 'Near Expiry') conditionBadgeClass = 'warning';
            else if (donation.condition_status === 'Expired') conditionBadgeClass = 'danger';

            let statusBadgeClass = 'primary';
            if (donation.status === 'Pending') statusBadgeClass = 'warning';
            else if (donation.status === 'Completed') statusBadgeClass = 'success';
            else if (donation.status === 'Cancelled') statusBadgeClass = 'danger';

            row.innerHTML = `
    <td>${donation.id}</td>
    <td>${donation.restaurant_name || 'Unknown'}</td>
    <td>${donation.name}</td>
    <td>${donation.category}</td>
    <td><span class="neu-badge info" style="color:#222;background:#e0e7ef;">${donation.quantity}</span></td>
    <td><span class="neu-badge ${conditionBadgeClass}" style="color:#222;background:#ffeeba;">${donation.condition_status}</span></td>
    <td><span class="neu-badge ${statusBadgeClass}" style="color:#fff;background:#007bff;">${donation.status}</span></td>
    <td>${formattedDeadlineDate}</td>
    <td>
        <button class="neu-button danger btn-sm p-1 delete-donation-btn" data-id="${donation.id}">
            <i class="bi bi-trash"></i>
        </button>
    </td>
`;
            
            tableBody.appendChild(row);
        });
        
        console.log('Table updated successfully, attaching event listeners');
        // Attach event listeners to the new buttons
        this.attachEventListeners();
    },
    
    /**
     * Populate donation details in the view modal
     * @param {Object} donation - Donation data to display
     */
    populateDonationModal: function(donation) {
        console.log('Populating donation modal with data:', donation);
        
        // Basic information
        document.getElementById('donationId').textContent = donation.id;
        document.getElementById('donationName').textContent = donation.name;
        document.getElementById('donationQuantity').textContent = donation.quantity;
        document.getElementById('donationCategory').textContent = donation.category;
        
        // Format dates
        const createdDate = new Date(donation.created_at);
        document.getElementById('donationCreated').textContent = createdDate.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        
        const deadlineDate = new Date(donation.pickup_deadline);
        document.getElementById('donationDeadline').textContent = deadlineDate.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        
        // Pickup window
        const pickupStartDate = new Date(donation.pickup_window_start);
        const pickupEndDate = new Date(donation.pickup_window_end);
        document.getElementById('donationPickupWindow').textContent = `${pickupStartDate.toLocaleTimeString('en-US', { 
            hour: '2-digit',
            minute: '2-digit'
        })} - ${pickupEndDate.toLocaleTimeString('en-US', { 
            hour: '2-digit',
            minute: '2-digit'
        })}`;
        
        // Set condition badge
        let conditionBadgeClass = 'success';
        if (donation.condition_status === 'Near Expiry') conditionBadgeClass = 'warning';
        else if (donation.condition_status === 'Expired') conditionBadgeClass = 'danger';
        
        document.getElementById('donationCondition').innerHTML = 
            `<span class="neu-badge ${conditionBadgeClass}">${donation.condition_status}</span>`;
        
        // Set status badge
        let statusBadgeClass = 'primary';
        if (donation.status === 'Pending Pickup') statusBadgeClass = 'warning';
        else if (donation.status === 'Completed') statusBadgeClass = 'success';
        else if (donation.status === 'Cancelled') statusBadgeClass = 'danger';
        
        document.getElementById('donationStatus').innerHTML = 
            `<span class="neu-badge ${statusBadgeClass}">${donation.status}</span>`;
        
        // Restaurant information
        document.getElementById('restaurantName').textContent = donation.restaurant_name || 'Unknown';
        document.getElementById('restaurantEmail').textContent = donation.restaurant_email || '-';
        document.getElementById('restaurantPhone').textContent = donation.restaurant_phone || '-';
        document.getElementById('restaurantLocation').textContent = donation.restaurant_location || '-';
        
        // Donation image
        const imageElement = document.getElementById('donationImage');
        if (imageElement) {
            if (donation.photo_url) {
                imageElement.src = `/${donation.photo_url}`;
                imageElement.style.display = 'block';
            } else {
                imageElement.src = 'https://via.placeholder.com/300?text=No+Image';
                imageElement.style.display = 'block';
            }
        }
        
        // Pickup requests
        const pickupsList = document.getElementById('pickupRequestsList');
        if (pickupsList) {
            pickupsList.innerHTML = '';
            
            if (!donation.pickup_requests || donation.pickup_requests.length === 0) {
                pickupsList.innerHTML = '<li class="list-group-item">No pickup requests yet</li>';
            } else {
                donation.pickup_requests.forEach(pickup => {
                    const li = document.createElement('li');
                    li.className = 'list-group-item';
                    
                    // Format date
                    const requestDate = new Date(pickup.created_at);
                    const formattedDate = requestDate.toLocaleDateString('en-US', { 
                        year: 'numeric', 
                        month: 'short', 
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                    });
                    
                    // Set status badge
                    let pickupStatusClass = 'primary';
                    if (pickup.status === 'Accepted') pickupStatusClass = 'warning';
                    else if (pickup.status === 'Completed') pickupStatusClass = 'success';
                    else if (pickup.status === 'Cancelled') pickupStatusClass = 'danger';
                    
                    li.innerHTML = `
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <strong>${pickup.collector_name}</strong>
                                <p class="mb-0 text-muted small">${formattedDate}</p>
                                <p class="mb-0 small">${pickup.notes || 'No notes'}</p>
                            </div>
                            <span class="neu-badge ${pickupStatusClass}">${pickup.status}</span>
                        </div>
                    `;
                    
                    pickupsList.appendChild(li);
                });
            }
        }
    },
    
    /**
     * Attach event listeners to donation action buttons
     */
    attachEventListeners: function() {
        console.log('Attaching event listeners to donation buttons');
        
        // View donation buttons
        document.querySelectorAll('.view-donation-btn').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const donationId = e.currentTarget.getAttribute('data-id');
                
                try {
                    // Show loading state in modal
                    document.getElementById('viewDonationModalLabel').textContent = 'Loading donation details...';
                    
                    // Open the modal
                    const modal = new bootstrap.Modal(document.getElementById('viewDonationModal'));
                    modal.show();
                    
                    // Fetch donation details
                    const donation = await this.getDonationById(donationId);
                    
                    // Update modal title
                    document.getElementById('viewDonationModalLabel').textContent = `Donation Details - ${donation.name}`;
                    
                    // Populate modal with donation data
                    this.populateDonationModal(donation);
                } catch (error) {
                    console.error('Error viewing donation:', error);
                    alert('Failed to load donation details. Please try again.');
                }
            });
        });
        
        // Delete donation buttons
        document.querySelectorAll('.delete-donation-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const donationId = e.currentTarget.getAttribute('data-id');
                document.getElementById('deleteId').value = donationId;
                
                // Open the delete confirmation modal
                const modal = new bootstrap.Modal(document.getElementById('deleteDonationModal'));
                modal.show();
            });
        });
        
        // Confirm delete button
        const confirmDeleteBtn = document.getElementById('confirmDelete');
        if (confirmDeleteBtn) {
            confirmDeleteBtn.addEventListener('click', async () => {
                const donationId = document.getElementById('deleteId').value;
                
                try {
                    // Show loading state
                    confirmDeleteBtn.disabled = true;
                    confirmDeleteBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Deleting...';
                    
                    // Delete the donation
                    await this.deleteDonation(donationId);
                    
                    // Close the modal
                    const modal = bootstrap.Modal.getInstance(document.getElementById('deleteDonationModal'));
                    modal.hide();
                    
                    // Refresh the donations list
                    this.loadDonations();
                    
                    // Show success message
                    alert('Donation deleted successfully');
                } catch (error) {
                    console.error('Error deleting donation:', error);
                    alert('Failed to delete donation. Please try again.');
                } finally {
                    // Reset button state
                    confirmDeleteBtn.disabled = false;
                    confirmDeleteBtn.innerHTML = 'Delete';
                }
            });
        }
    },
    
    /**
     * Load donations with current filters
     */
    loadDonations: async function() {
        try {
            console.log('Loading donations with current filters');
            
            // Show loading state
            const tableBody = document.querySelector('table.neu-table tbody');
            if (tableBody) {
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="8" class="text-center py-4">
                            <div class="spinner-border" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                            <p class="mt-2">Loading donations...</p>
                        </td>
                    </tr>
                `;
            }
            
            // Get filter values
            const statusFilter = document.getElementById('statusFilter')?.value || '';
            const categoryFilter = document.getElementById('categoryFilter')?.value || '';
            const conditionFilter = document.getElementById('conditionFilter')?.value || '';
            const searchInput = document.getElementById('searchInput')?.value || '';
            const dateFilter = document.getElementById('dateFilter')?.value || '';
            
            // Fetch donations with filters
            const donations = await this.getDonations({
                status: statusFilter,
                category: categoryFilter,
                condition: conditionFilter,
                search: searchInput,
                date: dateFilter
            });
            
            console.log('Fetched donations:', donations);
            
            // Update the table
            this.updateDonationsTable(donations);
        } catch (error) {
            console.error('Error loading donations:', error);
            
            // Show error message in table
            const tableBody = document.querySelector('table.neu-table tbody');
            if (tableBody) {
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="8" class="text-center py-4 text-danger">
                            <i class="bi bi-exclamation-triangle fs-1 mb-3"></i>
                            <h5>Failed to load donations</h5>
                            <p>Please try refreshing the page</p>
                        </td>
                    </tr>
                `;
            }
        }
    },
    
    /**
     * Initialize donations page
     */
    init: function() {
        document.addEventListener('DOMContentLoaded', () => {
            console.log('Initializing donations page');
            
            // Load initial data
            this.loadDonations();
            
            // Set up filter buttons
            const applyFiltersBtn = document.getElementById('applyFilters');
            if (applyFiltersBtn) {
                applyFiltersBtn.addEventListener('click', () => {
                    this.loadDonations();
                });
            }
            
            // Set up reset filters button
            const resetFiltersBtn = document.getElementById('resetFilters');
            if (resetFiltersBtn) {
                resetFiltersBtn.addEventListener('click', () => {
                    // Clear filter inputs
                    document.getElementById('statusFilter').value = '';
                    document.getElementById('categoryFilter').value = '';
                    document.getElementById('conditionFilter').value = '';
                    document.getElementById('searchInput').value = '';
                    document.getElementById('dateFilter').value = '';
                    
                    // Reload donations without filters
                    this.loadDonations();
                });
            }
            
            // Set up search on enter key
            const searchInput = document.getElementById('searchInput');
            if (searchInput) {
                searchInput.addEventListener('keyup', (e) => {
                    if (e.key === 'Enter') {
                        this.loadDonations();
                    }
                });
            }
        });
    }
};

// Initialize donations page
DonationsAPI.init();
