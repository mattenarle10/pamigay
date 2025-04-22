-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Apr 22, 2025 at 10:54 AM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pamigay_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `food_donations`
--

CREATE TABLE `food_donations` (
  `id` int(11) NOT NULL,
  `restaurant_id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `quantity` varchar(100) NOT NULL,
  `condition_status` enum('Fresh','Near Expiry','Expired') NOT NULL,
  `category` enum('Human Intake','Animal Intake') NOT NULL,
  `pickup_deadline` datetime NOT NULL,
  `pickup_window_start` datetime NOT NULL,
  `pickup_window_end` datetime NOT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `status` enum('Available','Pending Pickup','Completed','Cancelled') DEFAULT 'Available',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `pickup_request_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `food_donations`
--

INSERT INTO `food_donations` (`id`, `restaurant_id`, `name`, `quantity`, `condition_status`, `category`, `pickup_deadline`, `pickup_window_start`, `pickup_window_end`, `photo_url`, `status`, `created_at`, `updated_at`, `pickup_request_id`) VALUES
(10, 10, 'Rey', '100', 'Fresh', 'Human Intake', '2025-04-15 16:00:39', '2025-04-15 16:00:00', '2025-04-15 18:00:00', 'uploads/donation_images/donation_10_1744617659.jpg', 'Cancelled', '2025-04-14 08:00:59', '2025-04-22 01:47:35', NULL),
(11, 16, 'chocs', '1', 'Near Expiry', 'Human Intake', '2025-04-18 16:03:58', '2025-04-18 16:03:00', '2025-04-18 18:03:00', 'uploads/donation_images/donation_16_1744877060.jpg', 'Cancelled', '2025-04-17 08:04:20', '2025-04-22 01:47:35', NULL),
(13, 10, 'ambooot', '1122 kg', 'Near Expiry', 'Animal Intake', '2025-04-23 09:59:14', '2025-04-23 07:59:00', '2025-04-23 11:59:00', 'uploads/donation_images/donation_10_1745287203.jpg', 'Available', '2025-04-22 02:00:03', '2025-04-22 08:50:40', NULL),
(14, 10, 'ansss', '100 pcs', 'Near Expiry', 'Animal Intake', '2025-04-23 10:02:43', '2025-04-23 10:02:00', '2025-04-23 12:02:00', 'uploads/donation_images/donation_10_1745287382.jpg', 'Available', '2025-04-22 02:03:02', '2025-04-22 08:53:14', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `food_pickups`
--

CREATE TABLE `food_pickups` (
  `id` int(11) NOT NULL,
  `donation_id` int(11) NOT NULL,
  `collector_id` int(11) NOT NULL COMMENT 'References organization_id from users table',
  `pickup_time` datetime DEFAULT NULL,
  `status` enum('Requested','Accepted','Completed','Cancelled') DEFAULT 'Requested',
  `notes` text DEFAULT NULL,
  `rating` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Tracks pickup requests from organizations (previously collectors)';

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('Restaurant','Organization') NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `profile_image` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `location` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `phone_number`, `profile_image`, `created_at`, `updated_at`, `location`) VALUES
(1, 'Chongs', 'enarlem10@gmail.com', '$2y$10$giVImO1IIxhwZ8pDRGekTehyhUng.L15gcgqbnlwInRYZ0E5krx/C', 'Restaurant', '123-456-7890', NULL, '2025-03-26 12:37:27', '2025-03-31 06:50:46', NULL),
(3, 'Imays', 'restaurant@test.com', '$2y$10$zRTrnU9NQ8IB3rS1VL2UHepn81dDahkVBFZhXrKZNW/6gZsIZL5ey', 'Restaurant', '123-456-7890', NULL, '2025-03-26 13:07:16', '2025-03-31 06:50:53', NULL),
(4, 'Garbage', 'collector@test.com', '$2y$10$zRTrnU9NQ8IB3rS1VL2UHepn81dDahkVBFZhXrKZNW/6gZsIZL5ey', 'Organization', '123-456-7891', NULL, '2025-03-26 13:07:16', '2025-04-22 00:42:39', NULL),
(5, 'Handom', 'org@test.com', '$2y$10$zRTrnU9NQ8IB3rS1VL2UHepn81dDahkVBFZhXrKZNW/6gZsIZL5ey', 'Organization', '123-456-7892', NULL, '2025-03-26 13:07:16', '2025-03-31 06:51:04', NULL),
(6, 'Mcdonalds', 'mcdo@gmail.com', '$2y$10$HSkB2TWPCxGZnMq8fdg.2ulM4zuVVWJZULtEc.qH28AH/ydGskDzK', 'Restaurant', NULL, NULL, '2025-03-31 06:41:25', '2025-03-31 06:41:25', NULL),
(7, 'mcdo', 'enarlem101@gmail.com', '$2y$10$gdaDeJ6011vvJvTLxoJhZeFkNk/j3ZNPuFGvKDIQAt/2baGVfuLN6', 'Restaurant', '09773189440', NULL, '2025-04-02 01:12:17', '2025-04-02 01:12:17', NULL),
(8, 'mcdo', 'enarlem102@gmail.com', '$2y$10$D9YLGebAO8HW14VOuFUXsek0lBxSfExkdW6GQMQBwTme2IzGQ15aK', 'Restaurant', '09773189440', NULL, '2025-04-02 01:14:45', '2025-04-02 01:14:45', NULL),
(9, 'mcdo app', 'enarlem104@gmail.com', '$2y$10$pU6hZN2tKFliCSLTnNzeXOKrGIFr6yB3Fnsap4vmuPVex8hRCUOWu', 'Restaurant', '09773189440', NULL, '2025-04-02 02:17:48', '2025-04-02 02:17:48', NULL),
(10, 'mcdo bago', 'enarlem105@gmail.com', '$2y$10$mZsMf.nagCogYWxacC.MguBGAP6k26k0XITshILbOueonJ.XK8Nqu', 'Restaurant', '09773189412', 'uploads/profile_images/10_1744618359.jpg', '2025-04-02 02:18:34', '2025-04-14 08:12:39', 'bago city near highway'),
(11, 'Matt Enarle', 'enarlem106@gmail.com', '$2y$10$NlMvnjV4CaKKwN33XGCnbe5xk6wvk0qSfdOwS9VdDhazd05seKlo.', 'Organization', '09773189440', 'uploads/profile_images/1743560580_scaled_McDonalds-Logo.png', '2025-04-02 02:23:00', '2025-04-22 00:42:39', NULL),
(12, 'jil mcdo', 'jillanne@gmail.com', '$2y$10$1SX2vKkoA0YgMzLnuMEpQuJjIGRZ4U8q1wZuzY1Gau4CUNsZzum9e', 'Restaurant', '09123456789', 'uploads/profile_images/1743562681_scaled_McDonalds-Logo.png', '2025-04-02 02:58:01', '2025-04-02 02:58:01', NULL),
(13, 'Jude mcdo', 'jude@gmail.com', '$2y$10$i1m2Ft6hgBYLmJETOIWoRufQFhknYxyZDtpF1xoqFmog4rykkS8le', 'Restaurant', '09773189440', 'uploads/profile_images/1743563629_scaled_McDonalds-Logo.png', '2025-04-02 03:13:49', '2025-04-02 03:13:49', NULL),
(14, 'wow', 'test@me.com', '$2y$10$mLsODtr/QjQvKUqljgERSO/BHs37MKTS//kNnOJdSyhUSAfzvy4Oi', 'Restaurant', '09883123633', 'uploads/profile_images/14_1744618209.jpg', '2025-04-14 08:07:21', '2025-04-14 08:10:09', NULL),
(15, 'rey', 'reylongno2002@gmail.com', '$2y$10$qYUnP1Ep8kl9DLF2pv8OveF2JeBKO9emaynLPRW8OBga5goAp2Ce.', 'Restaurant', '09123456789', 'uploads/profile_images/1744618497_scaled_1000145826.jpg', '2025-04-14 08:14:57', '2025-04-14 08:14:57', NULL),
(16, 'judd', 'judd.nut@gmail.com', '$2y$10$HdX6plWiH4jcrUN5tmFiMOQBwg5uJE5tm8OH42O01H3F64f7o9xH.', 'Restaurant', '09158903191', 'uploads/profile_images/16_1744876938.jpg', '2025-04-17 08:01:25', '2025-04-17 08:03:38', NULL),
(17, 'ddd', 'orgy@123.com', '$2y$10$uAtKRDZJ6UVu0M7USZ/ubeXYuCfKQ6ApWzAU5MoHHrrjGBI5.aCU2', 'Organization', '11223', 'uploads/profile_images/1745282889_scaled_szabo-viktor-rDO_GVlOZh4-unsplash.jpg', '2025-04-22 00:48:09', '2025-04-22 00:48:09', NULL),
(18, 'thanks', 'orgy@106.com', '$2y$10$Uaw2S81wBXH0VKTv2zG8tOueAOFyplwGzwBYTOZjCcQS6K3b0YvEG', 'Organization', '098865421', 'uploads/profile_images/18_1745283240.jpg', '2025-04-22 00:53:05', '2025-04-22 00:54:00', 'bccc');

-- --------------------------------------------------------

--
-- Table structure for table `user_stats`
--

CREATE TABLE `user_stats` (
  `user_id` int(11) NOT NULL,
  `total_donated` float DEFAULT 0,
  `total_collected` float DEFAULT 0,
  `total_saved` float DEFAULT 0,
  `is_top_donor` tinyint(1) DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_stats`
--

INSERT INTO `user_stats` (`user_id`, `total_donated`, `total_collected`, `total_saved`, `is_top_donor`, `last_updated`) VALUES
(1, 1, 0, 0, 0, '2025-03-26 13:47:00'),
(4, 0, 1, 0, 0, '2025-03-26 13:47:00'),
(5, 0, 1, 0, 0, '2025-03-31 07:11:14'),
(7, 0, 0, 0, 0, '2025-04-02 01:12:17'),
(8, 0, 0, 0, 0, '2025-04-02 01:14:45'),
(9, 0, 0, 0, 0, '2025-04-02 02:17:48'),
(10, 0, 0, 0, 0, '2025-04-02 02:18:34'),
(11, 0, 0, 0, 0, '2025-04-02 02:23:00'),
(12, 0, 0, 0, 0, '2025-04-02 02:58:01'),
(13, 0, 0, 0, 0, '2025-04-02 03:13:49'),
(14, 0, 0, 0, 0, '2025-04-14 08:07:21'),
(15, 0, 0, 0, 0, '2025-04-14 08:14:57'),
(16, 0, 0, 0, 0, '2025-04-17 08:01:25'),
(17, 0, 0, 0, 0, '2025-04-22 00:48:09'),
(18, 0, 0, 0, 0, '2025-04-22 00:53:05');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `food_donations`
--
ALTER TABLE `food_donations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `restaurant_id` (`restaurant_id`),
  ADD KEY `idx_food_donations_pickup_request_id` (`pickup_request_id`);

--
-- Indexes for table `food_pickups`
--
ALTER TABLE `food_pickups`
  ADD PRIMARY KEY (`id`),
  ADD KEY `collector_id` (`collector_id`),
  ADD KEY `food_pickups_ibfk_1` (`donation_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `user_stats`
--
ALTER TABLE `user_stats`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `food_donations`
--
ALTER TABLE `food_donations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `food_pickups`
--
ALTER TABLE `food_pickups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `food_donations`
--
ALTER TABLE `food_donations`
  ADD CONSTRAINT `fk_food_donations_pickup_request` FOREIGN KEY (`pickup_request_id`) REFERENCES `food_pickups` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `food_donations_ibfk_1` FOREIGN KEY (`restaurant_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `food_pickups`
--
ALTER TABLE `food_pickups`
  ADD CONSTRAINT `food_pickups_ibfk_1` FOREIGN KEY (`donation_id`) REFERENCES `food_donations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `food_pickups_ibfk_2` FOREIGN KEY (`collector_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `user_stats`
--
ALTER TABLE `user_stats`
  ADD CONSTRAINT `user_stats_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
