/**
 * Dashboard API - Handles data fetching and processing for the dashboard
 */

// API endpoints
const API_ENDPOINTS = {
    dashboard: '../admin/dashboard.php',
    users: '../admin/users.php',
    donations: '../admin/donations.php',
    pickups: '../admin/pickups.php'
};

// Dashboard data controller
const DashboardAPI = {
    /**
     * Fetch dashboard statistics
     * @returns {Promise} Promise resolving to dashboard data
     */
    getStats: async function() {
        try {
            const response = await fetch(API_ENDPOINTS.dashboard);
            if (!response.ok) {
                throw new Error('Dashboard API returned ' + response.status);
            }
            const text = await response.text();
            let result;
            try {
                result = JSON.parse(text);
            } catch (e) {
                console.error('Dashboard API non-JSON response:', text);
                throw new Error('Dashboard API returned invalid JSON');
            }
            if (!result.success) {
                // Log backend error details if present
                console.error('Dashboard API error:', result.message, result.error);
                throw new Error(result.message || 'Failed to fetch dashboard statistics');
            }
            return result.data;
        } catch (error) {
            console.error('Error fetching dashboard stats:', error);
            throw error;
        }
    },
    
    /**
     * Update dashboard UI with fetched data
     */
    updateDashboard: async function() {
        try {
            // Show loading state
            document.querySelectorAll('.stat-card .stat-value').forEach(el => {
                el.innerHTML = '<div class="spinner-border spinner-border-sm" role="status"><span class="visually-hidden">Loading...</span></div>';
            });
            
            // Fetch dashboard data
            const stats = await this.getStats();
            
            // Update user stats
            document.getElementById('totalUsersValue').textContent = stats.totalUsers || 0;
            
            // Find restaurant and organization counts
            const restaurantCount = stats.usersByRole?.find(r => r.role === 'Restaurant')?.count || 0;
            const organizationCount = stats.usersByRole?.find(r => r.role === 'Organization')?.count || 0;
            
            document.getElementById('restaurantsValue').textContent = restaurantCount;
            document.getElementById('organizationsValue').textContent = organizationCount;
            document.getElementById('newUsersValue').textContent = stats.newUsersThisMonth || 0;
            
            // Update donation stats
            document.getElementById('totalDonationsValue').textContent = stats.totalDonations || 0;
            
            // Find donation status counts
            const availableDonations = stats.donationsByStatus?.find(d => d.status === 'Available')?.count || 0;
            const pendingDonations = stats.donationsByStatus?.find(d => d.status === 'Pending Pickup')?.count || 0;
            const completedDonations = stats.donationsByStatus?.find(d => d.status === 'Completed')?.count || 0;
            
            document.getElementById('availableDonationsValue').textContent = availableDonations;
            document.getElementById('pendingDonationsValue').textContent = pendingDonations;
            document.getElementById('completedDonationsValue').textContent = completedDonations;
            
            // Update pickup stats
            document.getElementById('totalPickupsValue').textContent = stats.totalPickups || 0;
            
            // Find pickup status counts
            const requestedPickups = stats.pickupsByStatus?.find(p => p.status === 'Requested')?.count || 0;
            const acceptedPickups = stats.pickupsByStatus?.find(p => p.status === 'Accepted')?.count || 0;
            const completedPickups = stats.pickupsByStatus?.find(p => p.status === 'Completed')?.count || 0;
            
            document.getElementById('requestedPickupsValue').textContent = requestedPickups;
            document.getElementById('acceptedPickupsValue').textContent = acceptedPickups;
            document.getElementById('completedPickupsValue').textContent = completedPickups;
            
            // Update recent activity
            this.updateRecentActivity(stats.recentActivity || []);
            
            // Add animation to stats cards
            document.querySelectorAll('.stat-card').forEach((card, index) => {
                setTimeout(() => {
                    card.classList.add('animate__animated', 'animate__fadeIn');
                }, index * 100);
            });
            
            // Update charts if they exist
            if (typeof updateChartsWithData === 'function') {
                updateChartsWithData(stats);
            }
            
        } catch (error) {
            console.error('Error updating dashboard:', error);
            // Show error message
            document.querySelectorAll('.stat-card .stat-value').forEach(el => {
                el.textContent = 'Error';
            });
            
            document.getElementById('recentActivityList').innerHTML = `
                <div class="text-center p-4 text-danger">
                    <i class="bi bi-exclamation-triangle-fill fs-1 mb-3"></i>
                    <p>Failed to load dashboard data. Please try again later.</p>
                </div>
            `;
        }
    },
    
    /**
     * Update recent activity section
     * @param {Array} activities - List of recent activities
     */
    updateRecentActivity: function(activities) {
        const activityList = document.getElementById('recentActivityList');
        if (!activityList) return;
        
        // Clear existing content
        activityList.innerHTML = '';
        
        if (activities.length === 0) {
            activityList.innerHTML = '<div class="text-center p-4 text-muted">No recent activity</div>';
            return;
        }
        
        // Add each activity to the list
        activities.forEach((activity, index) => {
            const activityItem = document.createElement('div');
            activityItem.className = 'activity-item';
            activityItem.setAttribute('data-type', activity.type);
            
            // Add animation delay
            setTimeout(() => {
                activityItem.classList.add('animate__animated', 'animate__fadeInUp');
            }, index * 100);
            
            // Format date
            const date = new Date(activity.created_at);
            const formattedDate = date.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'short', 
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
            
            // Calculate time ago
            const timeAgo = this.getTimeAgo(date);
            
            // Set icon based on activity type
            let icon = 'bi-question-circle';
            let statusClass = '';
            let badgeClass = '';
            
            if (activity.type === 'donation') {
                icon = 'bi-box-seam';
                
                // Set status class and badge
                if (activity.status === 'Available') {
                    statusClass = 'text-success';
                    badgeClass = 'badge-available';
                }
                else if (activity.status === 'Pending Pickup') {
                    statusClass = 'text-warning';
                    badgeClass = 'badge-pending';
                }
                else if (activity.status === 'Completed') {
                    statusClass = 'text-primary';
                    badgeClass = 'badge-completed';
                }
                else if (activity.status === 'Cancelled') {
                    statusClass = 'text-danger';
                    badgeClass = 'badge-cancelled';
                }
                
            } else if (activity.type === 'pickup') {
                icon = 'bi-truck';
                
                // Set status class and badge
                if (activity.status === 'Requested') {
                    statusClass = 'text-success';
                    badgeClass = 'badge-requested';
                }
                else if (activity.status === 'Accepted') {
                    statusClass = 'text-warning';
                    badgeClass = 'badge-accepted';
                }
                else if (activity.status === 'Completed') {
                    statusClass = 'text-primary';
                    badgeClass = 'badge-completed';
                }
                else if (activity.status === 'Cancelled') {
                    statusClass = 'text-danger';
                    badgeClass = 'badge-cancelled';
                }
            }
            
            // Create activity content
            let activityText = '';
            let viewDetailsBtn = '';
            
            if (activity.type === 'donation') {
                activityText = `<strong>${activity.user_name}</strong> added a new donation: <strong>${activity.item_name}</strong>`;
                viewDetailsBtn = `<button class="view-details-btn" data-id="${activity.id}" data-type="donation">View Details</button>`;
            } else if (activity.type === 'pickup') {
                activityText = `<strong>${activity.user_name}</strong> requested pickup for <strong>${activity.item_name}</strong>`;
                viewDetailsBtn = `<button class="view-details-btn" data-id="${activity.id}" data-type="pickup">View Details</button>`;
            }
            
            // Build the activity item HTML
            activityItem.innerHTML = `
                <div class="activity-icon">
                    <i class="bi ${icon}"></i>
                </div>
                <div class="activity-content">
                    <div class="d-flex justify-content-between align-items-start mb-2">
                        <div class="activity-text">${activityText}</div>
                        <span class="status-badge ${badgeClass}">${activity.status}</span>
                    </div>
                    <div class="activity-meta">
                        <div>
                            <span class="activity-time" title="${formattedDate}">${timeAgo}</span>
                        </div>
                        <div>
                            ${viewDetailsBtn}
                        </div>
                    </div>
                </div>
            `;
            
            activityList.appendChild(activityItem);
        });
        
        // Add event listeners to view details buttons
        document.querySelectorAll('.view-details-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const id = this.getAttribute('data-id');
                const type = this.getAttribute('data-type');
                
                if (type === 'donation') {
                    window.location.href = `donations.html?id=${id}`;
                } else if (type === 'pickup') {
                    window.location.href = `pickups.html?id=${id}`;
                }
            });
        });
    },
    
    /**
     * Calculate time ago from date
     * @param {Date} date - Date to calculate time ago from
     * @returns {string} Time ago string (e.g. "2 hours ago")
     */
    getTimeAgo: function(date) {
        const now = new Date();
        const diffMs = now - date;
        const diffSec = Math.floor(diffMs / 1000);
        const diffMin = Math.floor(diffSec / 60);
        const diffHour = Math.floor(diffMin / 60);
        const diffDay = Math.floor(diffHour / 24);
        
        if (diffSec < 60) {
            return 'just now';
        } else if (diffMin < 60) {
            return `${diffMin} minute${diffMin > 1 ? 's' : ''} ago`;
        } else if (diffHour < 24) {
            return `${diffHour} hour${diffHour > 1 ? 's' : ''} ago`;
        } else if (diffDay < 7) {
            return `${diffDay} day${diffDay > 1 ? 's' : ''} ago`;
        } else {
            return date.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'short', 
                day: 'numeric'
            });
        }
    },
    
    /**
     * Initialize dashboard
     */
    init: function() {
        // Load dashboard data when page loads
        document.addEventListener('DOMContentLoaded', () => {
            this.updateDashboard();
            
            // Set up refresh button if it exists
            const refreshBtn = document.getElementById('refreshDashboard');
            if (refreshBtn) {
                refreshBtn.addEventListener('click', () => {
                    // Show loading spinner in button
                    refreshBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Refreshing...';
                    refreshBtn.disabled = true;
                    
                    // Update dashboard
                    this.updateDashboard().finally(() => {
                        // Restore button text
                        setTimeout(() => {
                            refreshBtn.innerHTML = '<i class="bi bi-arrow-clockwise me-2"></i>Refresh';
                            refreshBtn.disabled = false;
                        }, 500);
                    });
                });
            }
            
            // Set up auto-refresh every 5 minutes
            setInterval(() => this.updateDashboard(), 5 * 60 * 1000);
        });
    }
};

// Initialize dashboard
DashboardAPI.init();
