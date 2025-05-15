/**
 * Export Utils - Functions for exporting data to different formats
 */

const ExportUtils = {
    /**
     * Export data to PDF (using HTML-based export)
     * @param {string} type - The type of data to export ('users', 'donations', 'pickups')
     * @param {Object} filters - Filter parameters to apply
     */
    exportToPDF: function(type, filters = {}) {
        // Show loading state
        this.showLoadingState();
        
        // Build URL with parameters (using the html-export.php endpoint instead)
        let url = `../admin/html-export.php?type=${type}`;
        
        // Add filters to URL
        Object.keys(filters).forEach(key => {
            if (filters[key]) {
                url += `&${key}=${encodeURIComponent(filters[key])}`;
            }
        });
        
        // Open the HTML report in a new tab
        const reportWindow = window.open(url, '_blank');
        
        // Hide loading state
        setTimeout(() => {
            this.hideLoadingState();
            
            // Focus on the new window
            if (reportWindow) {
                reportWindow.focus();
            }
        }, 1000);
    },
    
    /**
     * Show loading state
     */
    showLoadingState: function() {
        // Create loading overlay if it doesn't exist
        if (!document.getElementById('exportLoadingOverlay')) {
            const overlay = document.createElement('div');
            overlay.id = 'exportLoadingOverlay';
            overlay.style.position = 'fixed';
            overlay.style.top = '0';
            overlay.style.left = '0';
            overlay.style.width = '100%';
            overlay.style.height = '100%';
            overlay.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
            overlay.style.display = 'flex';
            overlay.style.justifyContent = 'center';
            overlay.style.alignItems = 'center';
            overlay.style.zIndex = '9999';
            
            const spinner = document.createElement('div');
            spinner.className = 'spinner-border text-light';
            spinner.setAttribute('role', 'status');
            
            const text = document.createElement('span');
            text.className = 'ms-3 text-light';
            text.textContent = 'Generating PDF...';
            
            const container = document.createElement('div');
            container.className = 'd-flex flex-column align-items-center';
            container.appendChild(spinner);
            container.appendChild(text);
            
            overlay.appendChild(container);
            document.body.appendChild(overlay);
        } else {
            document.getElementById('exportLoadingOverlay').style.display = 'flex';
        }
    },
    
    /**
     * Hide loading state
     */
    hideLoadingState: function() {
        const overlay = document.getElementById('exportLoadingOverlay');
        if (overlay) {
            overlay.style.display = 'none';
        }
    },
    
    /**
     * Get current filters from the page
     * @param {string} type - The type of data ('users', 'donations', 'pickups')
     * @returns {Object} Filter parameters
     */
    getCurrentFilters: function(type) {
        const filters = {};
        
        switch (type) {
            case 'users':
                // Get user filters
                const roleFilter = document.getElementById('roleFilter');
                const statusFilter = document.getElementById('statusFilter');
                const searchInput = document.getElementById('userSearchInput');
                
                if (roleFilter) filters.role = roleFilter.value;
                if (statusFilter) filters.status = statusFilter.value;
                if (searchInput) filters.search = searchInput.value;
                break;
                
            case 'donations':
                // Get donation filters
                const donationStatusFilter = document.getElementById('statusFilter');
                const categoryFilter = document.getElementById('categoryFilter');
                const conditionFilter = document.getElementById('conditionFilter');
                const donationSearchInput = document.getElementById('searchInput');
                
                if (donationStatusFilter) filters.status = donationStatusFilter.value;
                if (categoryFilter) filters.category = categoryFilter.value;
                if (conditionFilter) filters.condition = conditionFilter.value;
                if (donationSearchInput) filters.search = donationSearchInput.value;
                break;
                
            case 'pickups':
                // Get pickup filters
                const pickupStatusFilter = document.getElementById('statusFilter');
                const organizationFilter = document.getElementById('organizationFilter');
                const pickupSearchInput = document.getElementById('searchInput');
                
                if (pickupStatusFilter) filters.status = pickupStatusFilter.value;
                if (organizationFilter) filters.organization = organizationFilter.value;
                if (pickupSearchInput) filters.search = pickupSearchInput.value;
                break;
        }
        
        return filters;
    },
    
    /**
     * Initialize export buttons
     */
    initExportButtons: function() {
        // Add click event listeners to export buttons
        document.querySelectorAll('.export-pdf-btn').forEach(button => {
            button.addEventListener('click', (e) => {
                e.preventDefault();
                
                try {
                    const type = button.getAttribute('data-type');
                    if (!type) {
                        console.error('Export button missing data-type attribute');
                        alert('Export error: Please refresh the page and try again.');
                        return;
                    }
                    
                    // Get current filters
                    const filters = this.getCurrentFilters(type);
                    
                    // Export to PDF
                    this.exportToPDF(type, filters);
                } catch (error) {
                    console.error('Export error:', error);
                    this.hideLoadingState();
                    alert('An error occurred during export. Please try again later.');
                }
            });
        });
    }
};

// Initialize export buttons when the document is ready
document.addEventListener('DOMContentLoaded', () => {
    ExportUtils.initExportButtons();
}); 