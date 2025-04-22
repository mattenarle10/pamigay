-- Create database
CREATE DATABASE IF NOT EXISTS pamigay_db;
USE pamigay_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('Restaurant', 'Organization') NOT NULL,
    phone_number VARCHAR(20) DEFAULT NULL,
    profile_image VARCHAR(255) DEFAULT NULL,
    location VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Food Donations Table - Stores food waste listings from restaurants
CREATE TABLE IF NOT EXISTS food_donations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    restaurant_id INT NOT NULL,
    name VARCHAR(255)NOT NULL, /* Added name field */
    quantity VARCHAR(100) NOT NULL,
    condition_status ENUM('Fresh', 'Near Expiry', 'Expired') NOT NULL,
    category ENUM('Human Intake', 'Animal Intake') NOT NULL,
    pickup_deadline DATETIME NOT NULL,
    pickup_window_start DATETIME NOT NULL,
    pickup_window_end DATETIME NOT NULL,
    photo_url VARCHAR(255),
    status ENUM('Available', 'Pending Pickup', 'Completed', 'Cancelled') DEFAULT 'Available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (restaurant_id) REFERENCES users(id)
);

-- User Stats Table - Stores aggregate statistics for users
CREATE TABLE IF NOT EXISTS user_stats (
    user_id INT PRIMARY KEY,
    total_donated FLOAT DEFAULT 0,
    total_collected FLOAT DEFAULT 0,
    total_saved FLOAT DEFAULT 0,
    is_top_donor BOOLEAN DEFAULT FALSE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Food Pickups Table - Tracks pickup requests from organizations
CREATE TABLE IF NOT EXISTS food_pickups (
    id INT PRIMARY KEY AUTO_INCREMENT,
    donation_id INT NOT NULL,
    collector_id INT NOT NULL COMMENT 'References organization_id from users table',
    pickup_time DATETIME,
    status ENUM('Requested', 'Accepted', 'Completed', 'Cancelled') DEFAULT 'Requested',
    notes TEXT,
    rating INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (donation_id) REFERENCES food_donations(id),
    FOREIGN KEY (collector_id) REFERENCES users(id)
);

-- Insert test data (only if users table is empty)
INSERT INTO users (name, email, password, role, phone_number)
SELECT 'Test Restaurant', 'restaurant@test.com', '$2y$10$zRTrnU9NQ8IB3rS1VL2UHepn81dDahkVBFZhXrKZNW/6gZsIZL5ey', 'Restaurant', '123-456-7890'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'restaurant@test.com');
-- Password is 'password123'

INSERT INTO users (name, email, password, role, phone_number)
SELECT 'Test Charity Organization', 'collector@test.com', '$2y$10$zRTrnU9NQ8IB3rS1VL2UHepn81dDahkVBFZhXrKZNW/6gZsIZL5ey', 'Organization', '123-456-7891'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'collector@test.com');
-- Password is 'password123'

INSERT INTO users (name, email, password, role, phone_number)
SELECT 'Test Organization', 'org@test.com', '$2y$10$zRTrnU9NQ8IB3rS1VL2UHepn81dDahkVBFZhXrKZNW/6gZsIZL5ey', 'Organization', '123-456-7892'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'org@test.com');
-- Password is 'password123'