-- phpMyAdmin SQL Dump
-- version 4.7.9
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jun 13, 2018 at 08:54 AM
-- Server version: 5.7.21
-- PHP Version: 7.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `test`
--

-- --------------------------------------------------------

--
-- Table structure for table `houses`
--

DROP TABLE IF EXISTS `houses`;
CREATE TABLE IF NOT EXISTS `houses` (
  `ID` int(11) NOT NULL,
  `Address` varchar(35) DEFAULT '0,Los Santos',
  `Description` varchar(128) DEFAULT 'House',
  `Owner` varchar(25) DEFAULT 'The State',
  `Owned` tinyint(1) DEFAULT '0',
  `Locked` tinyint(1) DEFAULT '0',
  `Price` int(11) DEFAULT '0',
  `InteriorE` int(11) DEFAULT '0',
  `InteriorI` int(11) NOT NULL DEFAULT '0',
  `ExteriorX` float DEFAULT '0',
  `ExteriorY` float DEFAULT '0',
  `ExteriorZ` float DEFAULT '0',
  `InteriorX` float DEFAULT '0',
  `InteriorY` float DEFAULT '0',
  `InteriorZ` float DEFAULT '0',
  `Custom_Interior` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
