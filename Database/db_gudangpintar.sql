-- =====================================================
-- 🏭 Gudang Pintar — Database Schema v2.0
-- =====================================================
-- Dibuat: Juni 2026
-- Engine: MySQL 8.0+ / MariaDB 10.5+
-- Gunakan: Import via phpMyAdmin atau CLI
-- =====================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+07:00";

-- Hapus database lama jika ada, lalu buat baru
DROP DATABASE IF EXISTS `db_gudangpintar`;
CREATE DATABASE `db_gudangpintar` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `db_gudangpintar`;

-- =====================================================
-- Tabel: users
-- Role: admin, kurir, kurir_transit
-- Password: menggunakan password_hash (bcrypt)
-- =====================================================
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','kurir','kurir_transit') NOT NULL DEFAULT 'kurir',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- Tabel: warehouse (Gudang)
-- =====================================================
CREATE TABLE `warehouse` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nama_gudang` varchar(100) NOT NULL,
  `alamat` text DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- Tabel: paket
-- Status: Di Gudang → Transit Antargudang → Di Gudang Tujuan → Sedang Diantar → Selesai
-- Tipe: lokal (kirim langsung) atau antargudang (transit dulu)
-- =====================================================
CREATE TABLE `paket` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `no_resi` varchar(30) NOT NULL,
  `deskripsi_barang` text DEFAULT NULL,
  `nama_pengirim` varchar(100) DEFAULT NULL,
  `nama_penerima` varchar(100) NOT NULL,
  `alamat_penerima` text NOT NULL,
  `lat_penerima` double DEFAULT NULL,
  `lng_penerima` double DEFAULT NULL,
  `id_warehouse` int(11) DEFAULT NULL,
  `tipe` enum('lokal','antargudang') NOT NULL DEFAULT 'lokal',
  `id_warehouse_tujuan` int(11) DEFAULT NULL,
  `id_kurir` int(11) DEFAULT NULL,
  `id_kurir_transit` int(11) DEFAULT NULL,
  `status` enum('Di Gudang','Transit Antargudang','Di Gudang Tujuan','Sedang Diantar','Selesai') NOT NULL DEFAULT 'Di Gudang',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_resi` (`no_resi`),
  KEY `fk_warehouse` (`id_warehouse`),
  KEY `fk_warehouse_tujuan` (`id_warehouse_tujuan`),
  KEY `fk_kurir` (`id_kurir`),
  KEY `fk_kurir_transit` (`id_kurir_transit`),
  CONSTRAINT `fk_warehouse` FOREIGN KEY (`id_warehouse`) REFERENCES `warehouse` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_warehouse_tujuan` FOREIGN KEY (`id_warehouse_tujuan`) REFERENCES `warehouse` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_kurir` FOREIGN KEY (`id_kurir`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_kurir_transit` FOREIGN KEY (`id_kurir_transit`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- Data Awal: Admin (username=admin, password=admin123)
-- =====================================================
INSERT INTO `users` (`username`, `password`, `role`) VALUES
('admin', '$2y$10$O8ubUdZM15zYWdYCgdM5uugjOr1IZa9pUASVrzV1dSzmEHlSMspYO', 'admin');
-- Password: admin123 (bcrypt hash generated via PHP password_hash)

-- =====================================================
-- Data Awal: Warehouse
-- =====================================================
INSERT INTO `warehouse` (`id`, `nama_gudang`, `alamat`, `latitude`, `longitude`) VALUES
(1, 'Gudang Pusat Yogyakarta', 'Jl. Malioboro No. 52, Yogyakarta', -7.7928, 110.3608),
(2, 'Gudang Hub Banguntapan', 'Jl. Ringroad Selatan, Banguntapan, Bantul', -7.8252, 110.4103),
(3, 'Gudang Sortir Sleman', 'Jl. Kaliurang Km 12, Sleman', -7.7065, 110.3930);

-- =====================================================
-- Data Contoh: Paket (opsional, bisa dihapus)
-- =====================================================
INSERT INTO `paket` (`no_resi`, `deskripsi_barang`, `nama_pengirim`, `nama_penerima`, `alamat_penerima`, `lat_penerima`, `lng_penerima`, `id_warehouse`, `tipe`, `status`) VALUES
('GPX-20260601-0001', 'Laptop ASUS ROG', 'Toko Komputer Jaya', 'Budi Santoso', 'Jl. Affandi No. 12, Yogyakarta', -7.7713, 110.3862, 1, 'lokal', 'Di Gudang'),
('GPX-20260601-0002', 'Sepatu Nike Air Max', 'Sneakers ID', 'Rina Wati', 'Jl. Parangtritis Km 5, Bantul', -7.8563, 110.3521, 1, 'lokal', 'Sedang Diantar'),
('GPX-20260601-0003', 'Buku Kuliah Semester 6', 'Gramedia Yogya', 'Ahmad Fauzi', 'Jl. Gejayan No. 45, Yogyakarta', -7.7752, 110.3876, 2, 'antargudang', 'Di Gudang');

COMMIT;
