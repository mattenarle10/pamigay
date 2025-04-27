/**
 * Components utility for Pamigay Admin
 * Handles loading shared components like the navbar
 */

// Load the navbar component into the specified container
async function loadNavbar(containerId = 'navbarContainer', activePage = '') {
    try {
        const response = await fetch('components/navbar.html');
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        
        const html = await response.text();
        const container = document.getElementById(containerId);
        
        if (container) {
            container.innerHTML = html;
            
            // Set up navbar functionality after loading
            setupNavbar();
            
            // Set active page if specified
            if (activePage) {
                const navLink = document.getElementById(`nav-${activePage}`);
                if (navLink) {
                    navLink.classList.add('active');
                }
            }
        }
    } catch (error) {
        console.error('Error loading navbar:', error);
    }
}

// Set up navbar event listeners
function setupNavbar() {
    // Mobile menu toggle
    const menuToggle = document.getElementById('menuToggle');
    if (menuToggle) {
        menuToggle.addEventListener('click', function() {
            document.getElementById('mainNav').classList.toggle('show');
        });
    }
    
    // User profile dropdown
    const profileButton = document.getElementById('profileButton');
    if (profileButton) {
        profileButton.addEventListener('click', function(e) {
            e.preventDefault();
            document.getElementById('userProfile').classList.toggle('open');
        });
    }
    
    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
        const profile = document.getElementById('userProfile');
        const profileBtn = document.getElementById('profileButton');
        
        if (profile && profileBtn && !profile.contains(e.target) && !profileBtn.contains(e.target)) {
            profile.classList.remove('open');
        }
        
        // Also handle closing the mobile menu when clicking outside
        const mainNav = document.getElementById('mainNav');
        const menuToggleBtn = document.getElementById('menuToggle');
        
        if (mainNav && menuToggleBtn && 
            window.innerWidth <= 991 && 
            !mainNav.contains(e.target) && 
            !menuToggleBtn.contains(e.target) &&
            mainNav.classList.contains('show')) {
            mainNav.classList.remove('show');
        }
    });
    
    // Logout functionality
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', function(e) {
            e.preventDefault();
            // Implement logout logic here
            window.location.href = 'index.html';
        });
    }
}
