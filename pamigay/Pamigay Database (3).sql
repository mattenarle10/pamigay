-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Apr 27, 2025 at 10:14 AM
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
(11, 16, 'chocs', '1', 'Near Expiry', 'Human Intake', '2025-04-18 16:03:58', '2025-04-18 16:03:00', '2025-04-18 18:03:00', 'uploads/donation_images/donation_16_1744877060.jpg', 'Cancelled', '2025-04-17 08:04:20', '2025-04-22 01:47:35', NULL),
(16, 19, 'dd', '1 kg', 'Expired', 'Human Intake', '2025-04-25 09:50:49', '2025-04-25 09:50:00', '2025-04-25 11:50:00', 'uploads/donation_images/donation_19_1745459463.jpg', 'Completed', '2025-04-24 01:51:03', '2025-04-25 03:39:11', 10),
(17, 10, 'aaaaa', '11 kg', 'Near Expiry', 'Human Intake', '2025-04-25 11:44:51', '2025-04-25 11:44:00', '2025-04-25 16:44:00', 'uploads/donation_images/donation_10_1745466304.jpg', 'Cancelled', '2025-04-24 03:45:04', '2025-04-26 15:52:41', NULL),
(19, 10, 'okayy', '100 kg', 'Fresh', 'Human Intake', '2025-04-25 21:12:40', '2025-04-25 21:12:00', '2025-04-25 23:12:00', 'uploads/donation_images/donation_10_1745500382.jpg', 'Cancelled', '2025-04-24 13:13:03', '2025-04-26 15:52:41', NULL),
(23, 19, 'Chocs', '111 kg', 'Near Expiry', 'Human Intake', '2025-04-26 13:40:10', '2025-04-26 13:40:00', '2025-04-26 15:40:00', 'uploads/donation_images/donation_19_1745559641.jpg', 'Completed', '2025-04-25 05:40:41', '2025-04-26 16:18:55', 15),
(24, 19, 'spilled', '1111 kg', 'Expired', 'Human Intake', '2025-04-26 13:40:36', '2025-04-26 13:40:00', '2025-04-26 15:40:00', 'uploads/donation_images/donation_19_1745559666.jpg', 'Cancelled', '2025-04-25 05:41:06', '2025-04-26 15:52:41', NULL),
(25, 19, 'hehe', '100 kg', 'Fresh', 'Human Intake', '2025-04-28 15:51:45', '2025-04-28 15:51:00', '2025-04-28 17:51:00', 'uploads/donation_images/donation_19_1745740325.jpg', 'Pending Pickup', '2025-04-27 07:52:05', '2025-04-27 07:55:36', 16);

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

--
-- Dumping data for table `food_pickups`
--

INSERT INTO `food_pickups` (`id`, `donation_id`, `collector_id`, `pickup_time`, `status`, `notes`, `rating`, `created_at`, `updated_at`) VALUES
(5, 16, 18, '2025-04-25 10:50:00', 'Cancelled', 'pls', NULL, '2025-04-24 13:44:06', '2025-04-24 14:27:48'),
(6, 19, 18, '2025-04-25 21:12:00', 'Requested', 'pls', NULL, '2025-04-24 13:58:38', '2025-04-24 13:58:38'),
(7, 17, 18, '2025-04-25 11:44:00', 'Requested', 'zzzz', NULL, '2025-04-24 14:28:55', '2025-04-24 14:28:55'),
(8, 16, 21, '2025-04-25 09:50:00', 'Cancelled', 'eee', NULL, '2025-04-24 14:39:01', '2025-04-25 03:32:36'),
(9, 17, 21, '2025-04-25 11:44:00', 'Requested', 'sss', NULL, '2025-04-24 14:42:59', '2025-04-24 14:42:59'),
(10, 16, 22, '2025-04-25 09:50:00', 'Completed', 'pls hatag nana sakon man', NULL, '2025-04-25 01:43:32', '2025-04-25 05:33:51'),
(12, 17, 22, '2025-04-25 11:44:00', 'Requested', 'ddd', NULL, '2025-04-25 03:42:52', '2025-04-25 03:42:52'),
(15, 23, 18, '2025-04-26 13:40:00', 'Completed', 'mine!', NULL, '2025-04-25 05:53:47', '2025-04-26 16:18:55'),
(16, 25, 18, '2025-04-28 16:51:00', 'Accepted', 'akon lang na bos!', NULL, '2025-04-27 07:53:12', '2025-04-27 07:55:36');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `read` tinyint(1) DEFAULT 0,
  `related_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `type`, `title`, `message`, `read`, `related_id`, `created_at`) VALUES
(1, 4, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(2, 5, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(3, 11, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(4, 17, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(5, 18, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 1, 25, '2025-04-27 07:52:05'),
(6, 21, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(7, 22, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(8, 23, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(9, 24, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(10, 25, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: hehe', 0, 25, '2025-04-27 07:52:05'),
(11, 19, 'pickup_requested', 'New Pickup Request', 'thanks has requested to pick up your donation: hehe', 0, 16, '2025-04-27 07:53:12'),
(12, 18, 'pickup_accepted', 'Pickup Request Accepted', 'hersheys has accepted your pickup request for hehe', 1, 16, '2025-04-27 07:55:36');

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
(4, 'Garbage', 'collector@test.com', 'enarlem10', 'Organization', '123-456-7891', NULL, '2025-03-26 13:07:16', '2025-04-25 03:48:17', NULL),
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
(18, 'thanks', 'orgy@106.com', '$2y$10$Uaw2S81wBXH0VKTv2zG8tOueAOFyplwGzwBYTOZjCcQS6K3b0YvEG', 'Organization', '098865421', 'uploads/profile_images/18_1745283240.jpg', '2025-04-22 00:53:05', '2025-04-22 00:54:00', 'bccc'),
(19, 'hersheys', 'hershey@123.com', '$2y$10$bn.l.VUsI3nZoUjl/dCG5OZaGLglbsUUYg6rnYkhJeYRnkMn40XZ.', 'Restaurant', '0912345653', 'uploads/profile_images/1745320688_scaled_szabo-viktor-rDO_GVlOZh4-unsplash.jpg', '2025-04-22 11:18:08', '2025-04-22 11:18:35', 'bacolod'),
(20, 'aaaaaaaa', 'enarlee@123.com', '$2y$10$EO6PrFbl.7OG0Yi15NzVMuVyaPQ.HROP5ep6kqGBOOnYl.2XodVAq', 'Restaurant', 'aaaaaa', 'uploads/profile_images/1745497346_scaled_dayne-topkin-GS_iQCc7WoE-unsplash.jpg', '2025-04-24 12:22:26', '2025-04-24 12:22:26', NULL),
(21, 'aaa', 'orgy@107.com', '$2y$10$geEM/srMVog9EI3TXpoIOuldOKKyP8G8xGamA/lSJEuQffmyN/WGC', 'Organization', '09773189400', NULL, '2025-04-24 14:38:14', '2025-04-25 01:42:20', 'bcccc'),
(22, 'bosslot', 'orgy@108.com', '$2y$10$AQX/PyExF1zh6j8o.exY2.06B4rmhJAIvbODK1X0B6dkRo8kwLArS', 'Organization', '09876554311', 'uploads/profile_images/1745545382_scaled_0ef52548-48fa-4715-bcb2-155324b360637446656628347754057.jpg', '2025-04-25 01:43:02', '2025-04-25 01:43:02', NULL),
(23, 'orgy109', 'orgy@109.com', '$2y$10$vYB.nWgoj5a1/ynDCVpEQegGhftudHnbHEk.HU42Sjv006GY4VA4W', 'Organization', 'orgyyy1201202', NULL, '2025-04-25 03:37:37', '2025-04-25 03:37:37', NULL),
(24, 'aaadsdss', 'rey@123com', '$2y$10$lVkw.5cPBKXrDKsf8MBtE.S0k93.R3lux8PJDtp/FNwZDG/v8lS0e', 'Organization', 'dsads', NULL, '2025-04-25 03:45:11', '2025-04-25 03:46:23', 'ddddd'),
(25, 'gb12309773189440', 'gb@123.com', '$2y$10$08epcLzThmBEwuhMaksIyez07/sPo4fqZmTXukE8JyDdbr6mdvini', 'Organization', 'dasdsadsa', NULL, '2025-04-25 03:50:08', '2025-04-25 03:50:08', NULL);

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
(18, 0, 1, 0, 0, '2025-04-26 16:18:55'),
(19, 8, 0, 0, 0, '2025-04-26 16:18:55'),
(20, 0, 0, 0, 0, '2025-04-24 12:22:26'),
(21, 0, 0, 0, 0, '2025-04-24 14:38:14'),
(22, 0, 7, 0, 0, '2025-04-25 05:33:51'),
(23, 0, 0, 0, 0, '2025-04-25 03:37:37'),
(24, 0, 0, 0, 0, '2025-04-25 03:45:11'),
(25, 0, 0, 0, 0, '2025-04-25 03:50:08');

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
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `food_pickups`
--
ALTER TABLE `food_pickups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

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
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_stats`
--
ALTER TABLE `user_stats`
  ADD CONSTRAINT `user_stats_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
