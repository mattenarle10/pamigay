// Login JavaScript

document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('loginForm');
    
    if (loginForm) {
        loginForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const errorDiv = document.getElementById('loginError');
            
            // Basic validation
            if (!username || !password) {
                showError('Please enter both username and password');
                return;
            }
            
            // In a real implementation, this would make an AJAX request to the backend
            // For now, we'll simulate a login with hardcoded credentials
            if (username === 'pamigayadmin' && password === 'admin123') {
                // Success - redirect to dashboard
                window.location.href = 'dashboard.html';
            } else {
                // Show error
                showError('Invalid username or password');
            }
        });
    }
    
    function showError(message) {
        const errorDiv = document.getElementById('loginError');
        errorDiv.textContent = message;
        errorDiv.classList.remove('d-none');
        
        // Hide error after 3 seconds
        setTimeout(() => {
            errorDiv.classList.add('d-none');
        }, 3000);
    }
});
