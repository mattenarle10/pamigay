-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 04, 2025 at 03:07 PM
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
(16, 19, 'dd', '1 kg', 'Expired', 'Human Intake', '2025-04-25 09:50:49', '2025-04-25 09:50:00', '2025-04-25 11:50:00', 'uploads/donation_images/donation_19_1745459463.jpg', 'Completed', '2025-04-24 01:51:03', '2025-04-25 03:39:11', 10),
(23, 19, 'Chocs', '111 kg', 'Near Expiry', 'Human Intake', '2025-04-26 13:40:10', '2025-04-26 13:40:00', '2025-04-26 15:40:00', 'uploads/donation_images/donation_19_1745559641.jpg', 'Completed', '2025-04-25 05:40:41', '2025-04-26 16:18:55', 15),
(24, 19, 'spilled', '1111 kg', 'Expired', 'Human Intake', '2025-04-26 13:40:36', '2025-04-26 13:40:00', '2025-04-26 15:40:00', 'uploads/donation_images/donation_19_1745559666.jpg', 'Cancelled', '2025-04-25 05:41:06', '2025-04-26 15:52:41', NULL),
(25, 19, 'hehe', '100 kg', 'Fresh', 'Human Intake', '2025-04-28 15:51:45', '2025-04-28 15:51:00', '2025-04-28 17:51:00', 'uploads/donation_images/donation_19_1745740325.jpg', 'Pending Pickup', '2025-04-27 07:52:05', '2025-04-27 07:55:36', 16),
(26, 19, 'from hersh', '900 kg', 'Fresh', 'Human Intake', '2025-04-28 22:49:53', '2025-04-28 22:49:00', '2025-04-28 00:49:00', 'uploads/donation_images/donation_19_1745765574.jpg', 'Cancelled', '2025-04-27 14:52:54', '2025-04-29 00:02:51', NULL),
(27, 27, 'snack', '2 kg', 'Fresh', 'Human Intake', '2025-04-29 14:06:17', '2025-04-29 14:06:00', '2025-04-29 16:06:00', NULL, 'Cancelled', '2025-04-28 06:06:27', '2025-05-04 12:55:56', NULL),
(28, 28, 'piza bilin', '10  pieces', 'Fresh', 'Human Intake', '2025-04-29 19:59:16', '2025-04-29 16:59:00', '2025-04-29 23:59:00', 'uploads/donation_images/donation_28_1745841639.jpg', 'Pending Pickup', '2025-04-28 12:00:39', '2025-04-28 12:05:24', 17),
(29, 28, 'damo ni ma kwa', '1000 kg', 'Fresh', 'Animal Intake', '2025-04-29 20:06:18', '2025-04-29 20:06:00', '2025-04-29 22:06:00', NULL, 'Completed', '2025-04-28 12:06:38', '2025-04-28 12:11:01', 19),
(30, 28, 'baho manok', '100 g', 'Fresh', 'Animal Intake', '2025-04-29 20:55:40', '2025-04-29 16:55:00', '2025-04-29 22:55:00', 'uploads/donation_images/donation_28_1745844996.jpg', 'Cancelled', '2025-04-28 12:56:36', '2025-05-04 12:55:56', NULL),
(31, 30, 'hotdog', '8 g', 'Fresh', 'Human Intake', '2025-04-29 21:00:45', '2025-04-29 21:00:00', '2025-04-29 23:00:00', 'uploads/donation_images/donation_30_1745845313.jpg', 'Pending Pickup', '2025-04-28 13:01:53', '2025-04-28 13:04:21', 21),
(32, 30, 'damo', '12222 kg', 'Fresh', 'Human Intake', '2025-04-29 21:05:24', '2025-04-29 21:05:00', '2025-04-29 23:05:00', 'uploads/donation_images/donation_30_1745845541.jpg', 'Completed', '2025-04-28 13:05:41', '2025-04-28 13:08:28', 23),
(33, 30, 'Hotdog', '2 kg', 'Near Expiry', 'Human Intake', '2025-04-30 08:15:43', '2025-04-30 08:15:00', '2025-04-30 10:15:00', 'uploads/donation_images/donation_30_1745885932.jpg', 'Completed', '2025-04-29 00:18:52', '2025-05-04 12:58:27', 25),
(34, 19, 'waaa', '112 kg', 'Fresh', 'Human Intake', '2025-05-05 20:57:10', '2025-05-05 20:57:00', '2025-05-05 22:57:00', NULL, 'Available', '2025-05-04 12:57:26', '2025-05-04 12:57:26', NULL);

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
(8, 16, 21, '2025-04-25 09:50:00', 'Cancelled', 'eee', NULL, '2025-04-24 14:39:01', '2025-04-25 03:32:36'),
(10, 16, 22, '2025-04-25 09:50:00', 'Completed', 'pls hatag nana sakon man', NULL, '2025-04-25 01:43:32', '2025-04-25 05:33:51'),
(15, 23, 18, '2025-04-26 13:40:00', 'Completed', 'mine!', NULL, '2025-04-25 05:53:47', '2025-04-26 16:18:55'),
(16, 25, 18, '2025-04-28 16:51:00', 'Accepted', 'akon lang na bos!', NULL, '2025-04-27 07:53:12', '2025-04-27 07:55:36'),
(17, 28, 29, '2025-04-29 17:59:00', 'Accepted', '', NULL, '2025-04-28 12:04:43', '2025-04-28 12:05:24'),
(18, 29, 29, '2025-04-29 20:06:00', 'Cancelled', 'akon lg pls', NULL, '2025-04-28 12:07:21', '2025-04-28 12:08:53'),
(19, 29, 18, '2025-04-29 20:06:00', 'Completed', 'akon lg ha', NULL, '2025-04-28 12:08:07', '2025-04-28 12:11:01'),
(20, 27, 29, '2025-04-29 14:06:00', 'Requested', 'nnnnnn', NULL, '2025-04-28 12:55:20', '2025-04-28 12:55:20'),
(21, 31, 29, '2025-04-29 21:30:00', 'Accepted', 'akon kg nu ha', NULL, '2025-04-28 13:03:32', '2025-04-28 13:04:21'),
(22, 32, 18, '2025-04-29 21:05:00', 'Cancelled', 'aaako lgg', NULL, '2025-04-28 13:06:08', '2025-04-28 13:07:12'),
(23, 32, 29, '2025-04-29 21:05:00', 'Completed', 'aaaa', NULL, '2025-04-28 13:06:31', '2025-04-28 13:08:28'),
(24, 33, 31, '2025-04-30 09:15:00', 'Cancelled', 'otw', NULL, '2025-04-29 00:20:00', '2025-04-29 00:23:13'),
(25, 33, 29, '2025-04-30 09:15:00', 'Completed', '', NULL, '2025-04-29 00:21:57', '2025-05-04 12:58:27');

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
(11, 19, 'pickup_requested', 'New Pickup Request', 'thanks has requested to pick up your donation: hehe', 1, 16, '2025-04-27 07:53:12'),
(12, 18, 'pickup_accepted', 'Pickup Request Accepted', 'hersheys has accepted your pickup request for hehe', 1, 16, '2025-04-27 07:55:36'),
(13, 4, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(14, 5, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(15, 11, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(16, 17, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(17, 18, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 1, 26, '2025-04-27 14:52:54'),
(18, 21, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(19, 22, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(20, 23, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(21, 24, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(22, 25, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: from hersh', 0, 26, '2025-04-27 14:52:54'),
(23, 4, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(24, 5, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(25, 11, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(26, 17, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(27, 18, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 1, 27, '2025-04-28 06:06:27'),
(28, 21, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(29, 22, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(30, 23, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(31, 24, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(32, 25, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(33, 26, 'donation_created', 'New Donation Available', 'hlj has added a new donation: snack', 0, 27, '2025-04-28 06:06:27'),
(34, 4, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(35, 5, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(36, 11, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(37, 17, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(38, 18, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 1, 28, '2025-04-28 12:00:39'),
(39, 21, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(40, 22, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(41, 23, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(42, 24, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(43, 25, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(44, 26, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: piza bilin', 0, 28, '2025-04-28 12:00:39'),
(45, 28, 'pickup_requested', 'New Pickup Request', 'hershhh has requested to pick up your donation: piza bilin', 1, 17, '2025-04-28 12:04:43'),
(46, 29, 'pickup_accepted', 'Pickup Request Accepted', 'Jannele Pizza has accepted your pickup request for piza bilin', 1, 17, '2025-04-28 12:05:24'),
(47, 4, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(48, 5, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(49, 11, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(50, 17, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(51, 18, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 1, 29, '2025-04-28 12:06:38'),
(52, 21, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(53, 22, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(54, 23, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(55, 24, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(56, 25, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(57, 26, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(58, 29, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: damo ni ma kwa', 0, 29, '2025-04-28 12:06:38'),
(59, 28, 'pickup_requested', 'New Pickup Request', 'hershhh has requested to pick up your donation: damo ni ma kwa', 0, 18, '2025-04-28 12:07:21'),
(60, 28, 'pickup_requested', 'New Pickup Request', 'thanks has requested to pick up your donation: damo ni ma kwa', 1, 19, '2025-04-28 12:08:07'),
(61, 18, 'pickup_accepted', 'Pickup Request Accepted', 'Jannele Pizza has accepted your pickup request for damo ni ma kwa', 1, 19, '2025-04-28 12:08:53'),
(62, 18, 'pickup_completed', 'Pickup Completed', 'Your pickup for damo ni ma kwa has been marked as completed!', 1, 19, '2025-04-28 12:11:01'),
(63, 28, 'pickup_completed', 'Pickup Completed', 'Pickup by thanks for damo ni ma kwa has been completed!', 0, 19, '2025-04-28 12:11:01'),
(64, 27, 'pickup_requested', 'New Pickup Request', 'hershhh has requested to pick up your donation: snack', 0, 20, '2025-04-28 12:55:20'),
(65, 4, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(66, 5, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(67, 11, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(68, 17, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(69, 18, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(70, 21, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(71, 22, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(72, 23, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(73, 24, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(74, 25, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(75, 26, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(76, 29, 'donation_created', 'New Donation Available', 'Jannele Pizza has added a new donation: baho manok', 0, 30, '2025-04-28 12:56:36'),
(77, 4, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(78, 5, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(79, 11, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(80, 17, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(81, 18, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(82, 21, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(83, 22, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(84, 23, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(85, 24, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(86, 25, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(87, 26, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(88, 29, 'donation_created', 'New Donation Available', 'ica has added a new donation: hotdog', 0, 31, '2025-04-28 13:01:53'),
(89, 30, 'pickup_requested', 'New Pickup Request', 'hershhh has requested to pick up your donation: hotdog', 1, 21, '2025-04-28 13:03:32'),
(90, 29, 'pickup_accepted', 'Pickup Request Accepted', 'ica has accepted your pickup request for hotdog', 1, 21, '2025-04-28 13:04:21'),
(91, 4, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(92, 5, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(93, 11, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(94, 17, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(95, 18, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(96, 21, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(97, 22, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(98, 23, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(99, 24, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(100, 25, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(101, 26, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(102, 29, 'donation_created', 'New Donation Available', 'ica has added a new donation: damo', 0, 32, '2025-04-28 13:05:41'),
(103, 30, 'pickup_requested', 'New Pickup Request', 'thanks has requested to pick up your donation: damo', 1, 22, '2025-04-28 13:06:08'),
(104, 30, 'pickup_requested', 'New Pickup Request', 'hershhh has requested to pick up your donation: damo', 1, 23, '2025-04-28 13:06:31'),
(105, 29, 'pickup_accepted', 'Pickup Request Accepted', 'ica has accepted your pickup request for damo', 0, 23, '2025-04-28 13:07:12'),
(106, 29, 'pickup_completed', 'Pickup Completed', 'Your pickup for damo has been marked as completed!', 0, 23, '2025-04-28 13:08:28'),
(107, 30, 'pickup_completed', 'Pickup Completed', 'Pickup by hershhh for damo has been completed!', 1, 23, '2025-04-28 13:08:28'),
(108, 4, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(109, 5, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(110, 11, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(111, 17, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(112, 18, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(113, 21, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(114, 22, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(115, 23, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(116, 24, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(117, 25, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(118, 26, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(119, 29, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(120, 31, 'donation_created', 'New Donation Available', 'ica has added a new donation: Hotdog', 0, 33, '2025-04-29 00:18:52'),
(121, 30, 'pickup_requested', 'New Pickup Request', 'brix has requested to pick up your donation: Hotdog', 1, 24, '2025-04-29 00:20:00'),
(122, 30, 'pickup_requested', 'New Pickup Request', 'hershhh has requested to pick up your donation: Hotdog', 1, 25, '2025-04-29 00:21:57'),
(123, 29, 'pickup_accepted', 'Pickup Request Accepted', 'ica has accepted your pickup request for Hotdog', 0, 25, '2025-04-29 00:23:13'),
(124, 4, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(125, 5, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(126, 11, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(127, 17, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(128, 18, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(129, 21, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(130, 22, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(131, 23, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(132, 24, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(133, 25, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(134, 26, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(135, 29, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(136, 31, 'donation_created', 'New Donation Available', 'hersheys has added a new donation: waaa', 0, 34, '2025-05-04 12:57:26'),
(137, 29, 'pickup_completed', 'Pickup Completed', 'Your pickup for Hotdog has been marked as completed!', 0, 25, '2025-05-04 12:58:27'),
(138, 30, 'pickup_completed', 'Pickup Completed', 'Pickup by hershhh for Hotdog has been completed!', 1, 25, '2025-05-04 12:58:27');

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
(18, 'thanks', 'orgy@106.com', '$2y$10$Uaw2S81wBXH0VKTv2zG8tOueAOFyplwGzwBYTOZjCcQS6K3b0YvEG', 'Organization', '098865421', 'uploads/profile_images/18_1745842462.jpg', '2025-04-22 00:53:05', '2025-04-28 12:14:22', 'bccc'),
(19, 'hersheys', 'hershey@123.com', '$2y$10$bn.l.VUsI3nZoUjl/dCG5OZaGLglbsUUYg6rnYkhJeYRnkMn40XZ.', 'Restaurant', '0912345653', 'uploads/profile_images/19_1745765592.jpg', '2025-04-22 11:18:08', '2025-04-27 14:53:12', 'bacolod'),
(20, 'aaaaaaaa', 'enarlee@123.com', '$2y$10$EO6PrFbl.7OG0Yi15NzVMuVyaPQ.HROP5ep6kqGBOOnYl.2XodVAq', 'Restaurant', 'aaaaaa', 'uploads/profile_images/1745497346_scaled_dayne-topkin-GS_iQCc7WoE-unsplash.jpg', '2025-04-24 12:22:26', '2025-04-24 12:22:26', NULL),
(21, 'aaa', 'orgy@107.com', '$2y$10$geEM/srMVog9EI3TXpoIOuldOKKyP8G8xGamA/lSJEuQffmyN/WGC', 'Organization', '09773189400', NULL, '2025-04-24 14:38:14', '2025-04-25 01:42:20', 'bcccc'),
(22, 'bosslot', 'orgy@108.com', '$2y$10$AQX/PyExF1zh6j8o.exY2.06B4rmhJAIvbODK1X0B6dkRo8kwLArS', 'Organization', '09876554311', 'uploads/profile_images/1745545382_scaled_0ef52548-48fa-4715-bcb2-155324b360637446656628347754057.jpg', '2025-04-25 01:43:02', '2025-04-25 01:43:02', NULL),
(23, 'orgy109', 'orgy@109.com', '$2y$10$vYB.nWgoj5a1/ynDCVpEQegGhftudHnbHEk.HU42Sjv006GY4VA4W', 'Organization', 'orgyyy1201202', NULL, '2025-04-25 03:37:37', '2025-04-25 03:37:37', NULL),
(24, 'aaadsdss', 'rey@123com', '$2y$10$lVkw.5cPBKXrDKsf8MBtE.S0k93.R3lux8PJDtp/FNwZDG/v8lS0e', 'Organization', 'dsads', NULL, '2025-04-25 03:45:11', '2025-04-25 03:46:23', 'ddddd'),
(25, 'gb12309773189440', 'gb@123.com', '$2y$10$08epcLzThmBEwuhMaksIyez07/sPo4fqZmTXukE8JyDdbr6mdvini', 'Organization', 'dasdsadsa', NULL, '2025-04-25 03:50:08', '2025-04-25 03:50:08', NULL),
(26, 'hersh', 'hjarme@gmail.com', '$2y$10$apvKImYWdPndi6ilF7l4/u.JITMmEjtpOhItu1IWRa35Ldh02cYH.', 'Organization', '09611', NULL, '2025-04-27 17:04:30', '2025-04-27 17:04:30', NULL),
(27, 'hlj', 'hlj@gmail.com', '$2y$10$RKLX2aLx8a4V1zCo1xM7A.1NEuuMW7qChbjWy/HIfmShw26t70DvG', 'Restaurant', '123', NULL, '2025-04-27 17:08:24', '2025-04-28 08:20:39', 'Bacolod City'),
(28, 'Jannele Pizza', 'janelle@123.com', '$2y$10$BrWV9S/ZRhFIxZHnj49iYun9VQvAJCXa51RaYs9TOwstKM21COZhK', 'Restaurant', '09773189440', 'uploads/profile_images/1745841209_scaled_ce8c6588-d868-4456-8e8d-30c4eea2f8f43259680518343477672.jpg', '2025-04-28 11:53:29', '2025-04-28 12:25:29', 'aaaaaa'),
(29, 'hershhh', 'hersh@123.com', '$2y$10$hK0BfEhIDIFZ4.Lw/xDmu.a7R3Qixl1Bs.2Nttb0ELzJSnMUYHlxq', 'Organization', '2324565', NULL, '2025-04-28 12:03:57', '2025-04-28 12:03:57', NULL),
(30, 'ica', 'niel@gmail.com', '$2y$10$WN8Z90paVyvalKlfFbpK5ej/AouCHOVVmHgdXI9KZQF4EOw/ui/ZS', 'Restaurant', '09105667995', 'uploads/profile_images/1745845221_scaled_5dbd7a76-525b-44c9-9418-01bf26092ded1823904097401646068.jpg', '2025-04-28 13:00:21', '2025-04-28 13:00:21', NULL),
(31, 'brix', 'brix', '$2y$10$ec5hcN8lHr97K2hJas82MetPETevg4QZs4KsC/joUU115WLkjAlNe', 'Organization', '12345', NULL, '2025-04-29 00:05:46', '2025-04-29 00:05:46', NULL);

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
(18, 0, 2, 0, 0, '2025-04-28 12:11:01'),
(19, 8, 0, 0, 0, '2025-04-26 16:18:55'),
(20, 0, 0, 0, 0, '2025-04-24 12:22:26'),
(21, 0, 0, 0, 0, '2025-04-24 14:38:14'),
(22, 0, 7, 0, 0, '2025-04-25 05:33:51'),
(23, 0, 0, 0, 0, '2025-04-25 03:37:37'),
(24, 0, 0, 0, 0, '2025-04-25 03:45:11'),
(25, 0, 0, 0, 0, '2025-04-25 03:50:08'),
(26, 0, 0, 0, 0, '2025-04-27 17:04:30'),
(27, 0, 0, 0, 0, '2025-04-27 17:08:24'),
(28, 1, 0, 0, 0, '2025-04-28 12:11:01'),
(29, 0, 2, 0, 0, '2025-05-04 12:58:27'),
(30, 2, 0, 0, 0, '2025-05-04 12:58:27'),
(31, 0, 0, 0, 0, '2025-04-29 00:05:46');

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `food_pickups`
--
ALTER TABLE `food_pickups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=139;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

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
