-- phpMyAdmin SQL Dump
-- version 4.2.10.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: 2015-04-09 18:35:53
-- 服务器版本： 5.6.23-1~dotdeb.3
-- PHP Version: 5.4.39-1~dotdeb.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `shadowsocks`
--

-- --------------------------------------------------------

--
-- 表的结构 `invite_code`
--

CREATE TABLE IF NOT EXISTS `invite_code` (
`id` int(32) NOT NULL,
  `code` varchar(32) NOT NULL,
  `user` int(32) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3645 DEFAULT CHARSET=latin1;

--
-- 转存表中的数据 `invite_code`
--

INSERT INTO `invite_code` (`id`, `code`, `user`) VALUES
(3643, '134201a5b85900', 1);

-- --------------------------------------------------------

--
-- 表的结构 `ss_admin`
--

CREATE TABLE IF NOT EXISTS `ss_admin` (
`uid` int(11) NOT NULL,
  `admin_name` varchar(128) CHARACTER SET utf8mb4 NOT NULL,
  `email` varchar(32) NOT NULL,
  `pass` varchar(32) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `ss_admin`
--

INSERT INTO `ss_admin` (`uid`, `admin_name`, `email`, `pass`) VALUES
(1, 'Our_Private_Panel', 'admin@gmail.com', '25d55ad283aa400af464c76d713c07ad');

-- --------------------------------------------------------

--
-- 表的结构 `ss_node`
--

CREATE TABLE IF NOT EXISTS `ss_node` (
`id` int(11) NOT NULL,
  `node_name` varchar(128) NOT NULL,
  `node_type` int(3) NOT NULL,
  `node_server` varchar(128) NOT NULL,
  `node_method` varchar(64) NOT NULL,
  `node_info` varchar(128) NOT NULL,
  `node_status` varchar(128) NOT NULL,
  `node_order` int(3) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

--
-- 转存表中的数据 `ss_node`
--

INSERT INTO `ss_node` (`id`, `node_name`, `node_type`, `node_server`, `node_method`, `node_info`, `node_status`, `node_order`) VALUES
(1, 'Our Private Server', 0, 'Our_Private_Panel_Domain', 'aes-128-cfb', 'Our Private Server', '可用', 0);

-- --------------------------------------------------------

--
-- 表的结构 `ss_reset_pwd`
--

CREATE TABLE IF NOT EXISTS `ss_reset_pwd` (
`id` int(11) NOT NULL,
  `init_time` int(11) NOT NULL,
  `expire_time` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `uni_char` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- 转存表中的数据 `ss_reset_pwd`
--

INSERT INTO `ss_reset_pwd` (`id`, `init_time`, `expire_time`, `user_id`, `uni_char`) VALUES
(0, 1424448190, 1424534590, 1, '2MzU5ODFkYzM4MmVkZTM2ZTdjNGNhNDI');

-- --------------------------------------------------------

--
-- 表的结构 `user`
--

CREATE TABLE IF NOT EXISTS `user` (
`uid` int(11) NOT NULL,
  `user_name` varchar(128) CHARACTER SET utf8mb4 NOT NULL,
  `email` varchar(32) NOT NULL,
  `pass` varchar(32) NOT NULL,
  `passwd` varchar(16) NOT NULL,
  `t` int(11) NOT NULL DEFAULT '0',
  `u` bigint(20) NOT NULL,
  `d` bigint(20) NOT NULL,
  `plan` varchar(2) CHARACTER SET utf8mb4 NOT NULL,
  `transfer_enable` bigint(20) NOT NULL,
  `port` int(11) NOT NULL,
  `switch` tinyint(4) NOT NULL DEFAULT '1',
  `enable` tinyint(4) NOT NULL DEFAULT '1',
  `type` tinyint(4) NOT NULL DEFAULT '1',
  `last_get_gift_time` int(11) NOT NULL DEFAULT '0',
  `last_check_in_time` int(11) NOT NULL DEFAULT '0',
  `last_rest_pass_time` int(11) NOT NULL DEFAULT '0',
  `reg_date` datetime NOT NULL,
  `invite_num` int(8) NOT NULL,
  `money` decimal(12,2) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;

--
-- 转存表中的数据 `user`
--

INSERT INTO `user` (`uid`, `user_name`, `email`, `pass`, `passwd`, `t`, `u`, `d`, `plan`, `transfer_enable`, `port`, `switch`, `enable`, `type`, `last_get_gift_time`, `last_check_in_time`, `last_rest_pass_time`, `reg_date`, `invite_num`, `money`) VALUES
(11, 'Our_Private_Panel', 'admin@gmail.com', '25d55ad283aa400af464c76d713c07ad', 'My_Passwd', 1428602646, 2241725, 10548923, 'A', 32212254720, 9999, 1, 1, 7, 0, 1428602847, 0, '2015-04-09 21:57:54', 0, 0.00);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `invite_code`
--
ALTER TABLE `invite_code`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ss_admin`
--
ALTER TABLE `ss_admin`
 ADD PRIMARY KEY (`uid`);

--
-- Indexes for table `ss_node`
--
ALTER TABLE `ss_node`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ss_reset_pwd`
--
ALTER TABLE `ss_reset_pwd`
 ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
 ADD PRIMARY KEY (`uid`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `invite_code`
--
ALTER TABLE `invite_code`
MODIFY `id` int(32) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3645;
--
-- AUTO_INCREMENT for table `ss_admin`
--
ALTER TABLE `ss_admin`
MODIFY `uid` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `ss_node`
--
ALTER TABLE `ss_node`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `ss_reset_pwd`
--
ALTER TABLE `ss_reset_pwd`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
MODIFY `uid` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=14;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

