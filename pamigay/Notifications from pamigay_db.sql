-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Apr 27, 2025 at 09:53 AM
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
(11, 19, 'pickup_requested', 'New Pickup Request', 'thanks has requested to pick up your donation: hehe', 0, 16, '2025-04-27 07:53:12');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
