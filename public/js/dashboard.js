// Dashboard JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Toggle Sidebar
    document.getElementById('sidebarCollapse')?.addEventListener('click', function() {
        document.getElementById('sidebar').classList.toggle('active');
        document.getElementById('content').classList.toggle('active');
    });

    // Logout functionality
    const logoutBtn = document.getElementById('logoutBtn');
    const logoutDropdown = document.getElementById('logoutDropdown');
    
    if (logoutBtn) {
        logoutBtn.addEventListener('click', function(e) {
            e.preventDefault();
            handleLogout();
        });
    }
    
    if (logoutDropdown) {
        logoutDropdown.addEventListener('click', function(e) {
            e.preventDefault();
            handleLogout();
        });
    }

    // Initialize charts if on dashboard page
    if (document.getElementById('activityChart')) {
        initActivityChart();
    }

    // Initialize modals for view/delete actions
    initModals();
});

// Handle logout
function handleLogout() {
    // In a real implementation, this would call an API endpoint to invalidate the session
    // For now, just redirect to the login page
    window.location.href = 'index.html';
}

// Initialize Activity Chart
function initActivityChart() {
    const ctx = document.getElementById('activityChart').getContext('2d');
    
    // Sample data - would be replaced with real data from API
    const chartData = {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        datasets: [
            {
                label: 'Donations',
                data: [5, 8, 12, 15, 20, 25],
                backgroundColor: 'rgba(78, 115, 223, 0.2)',
                borderColor: 'rgba(78, 115, 223, 1)',
                borderWidth: 2,
                pointBackgroundColor: 'rgba(78, 115, 223, 1)',
                pointBorderColor: '#fff',
                pointHoverRadius: 5,
                pointHoverBackgroundColor: 'rgba(78, 115, 223, 1)',
                pointHoverBorderColor: '#fff',
                pointHitRadius: 10,
                pointBorderWidth: 2,
                tension: 0.3
            },
            {
                label: 'Pickups',
                data: [3, 6, 9, 12, 15, 16],
                backgroundColor: 'rgba(28, 200, 138, 0.2)',
                borderColor: 'rgba(28, 200, 138, 1)',
                borderWidth: 2,
                pointBackgroundColor: 'rgba(28, 200, 138, 1)',
                pointBorderColor: '#fff',
                pointHoverRadius: 5,
                pointHoverBackgroundColor: 'rgba(28, 200, 138, 1)',
                pointHoverBorderColor: '#fff',
                pointHitRadius: 10,
                pointBorderWidth: 2,
                tension: 0.3
            }
        ]
    };

    new Chart(ctx, {
        type: 'line',
        data: chartData,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        color: 'rgba(0, 0, 0, 0.05)'
                    }
                },
                x: {
                    grid: {
                        display: false
                    }
                }
            },
            plugins: {
                legend: {
                    display: true,
                    position: 'top'
                }
            }
        }
    });
}

// Initialize modals for view/delete actions
function initModals() {
    // View Donation Modal
    const viewDonationModal = document.getElementById('viewDonationModal');
    if (viewDonationModal) {
        viewDonationModal.addEventListener('show.bs.modal', function(event) {
            const button = event.relatedTarget;
            const donationId = button.getAttribute('data-id');
            
            // In a real implementation, this would fetch donation details from an API
            // For now, we'll just set the ID
            document.getElementById('donationId').textContent = donationId;
            
            // The rest of the data would be populated from API response
        });
    }
    
    // Delete Donation Modal
    const deleteDonationModal = document.getElementById('deleteDonationModal');
    if (deleteDonationModal) {
        deleteDonationModal.addEventListener('show.bs.modal', function(event) {
            const button = event.relatedTarget;
            const donationId = button.getAttribute('data-id');
            document.getElementById('deleteId').value = donationId;
        });
        
        // Handle delete confirmation
        document.getElementById('confirmDelete')?.addEventListener('click', function() {
            const donationId = document.getElementById('deleteId').value;
            
            // In a real implementation, this would call an API to delete the donation
            // For now, just close the modal
            const modal = bootstrap.Modal.getInstance(deleteDonationModal);
            modal.hide();
            
            // Show success message (in a real app)
            alert('Donation #' + donationId + ' deleted successfully');
        });
    }
    
    // View User Modal
    const viewUserModal = document.getElementById('viewUserModal');
    if (viewUserModal) {
        viewUserModal.addEventListener('show.bs.modal', function(event) {
            const button = event.relatedTarget;
            const userId = button.getAttribute('data-id');
            
            // In a real implementation, this would fetch user details from an API
            // For now, we'll just set the ID
            document.getElementById('userId').textContent = userId;
            
            // The rest of the data would be populated from API response
        });
    }
    
    // Delete User Modal
    const deleteUserModal = document.getElementById('deleteUserModal');
    if (deleteUserModal) {
        deleteUserModal.addEventListener('show.bs.modal', function(event) {
            const button = event.relatedTarget;
            const userId = button.getAttribute('data-id');
            document.getElementById('deleteUserId').value = userId;
        });
        
        // Handle delete confirmation
        document.getElementById('confirmUserDelete')?.addEventListener('click', function() {
            const userId = document.getElementById('deleteUserId').value;
            
            // In a real implementation, this would call an API to delete the user
            // For now, just close the modal
            const modal = bootstrap.Modal.getInstance(deleteUserModal);
            modal.hide();
            
            // Show success message (in a real app)
            alert('User #' + userId + ' deleted successfully');
        });
    }
}
