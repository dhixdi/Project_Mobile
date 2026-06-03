# 🗄️ Database — Gudang Pintar

## Stack
- **DBMS:** MySQL 8.0+ / MariaDB 10.5+
- **Tool:** phpMyAdmin (via XAMPP) atau CLI
- **Charset:** utf8mb4

## Struktur Folder

```
Database/
└── db_gudangpintar.sql    ← File SQL utama (import ini)
```

## Cara Import

### Via phpMyAdmin
1. Buka `http://localhost/phpmyadmin`
2. Klik **Import** di navbar atas
3. Pilih file `db_gudangpintar.sql`
4. Klik **Go**

### Via CLI
```bash
mysql -u root -p < db_gudangpintar.sql
```

## Tabel

### `users`
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| id | INT AUTO_INCREMENT | Primary key |
| username | VARCHAR(50) UNIQUE | Login identifier |
| password | VARCHAR(255) | Bcrypt hash (`password_hash`) |
| role | ENUM('admin','kurir','kurir_transit') | Hak akses |
| created_at | TIMESTAMP | Waktu dibuat |

### `warehouse`
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| id | INT AUTO_INCREMENT | Primary key |
| nama_gudang | VARCHAR(100) | Nama gudang |
| alamat | TEXT | Alamat lengkap |
| latitude | DOUBLE | Koordinat lat |
| longitude | DOUBLE | Koordinat lng |

### `paket`
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| id | INT AUTO_INCREMENT | Primary key |
| no_resi | VARCHAR(30) UNIQUE | Format: GPX-YYYYMMDD-XXXX |
| deskripsi_barang | TEXT | Deskripsi isi paket |
| nama_pengirim | VARCHAR(100) | Pengirim |
| nama_penerima | VARCHAR(100) | Penerima |
| alamat_penerima | TEXT | Alamat kirim |
| lat_penerima | DOUBLE | Koordinat lat penerima |
| lng_penerima | DOUBLE | Koordinat lng penerima |
| id_warehouse | INT FK | Gudang asal |
| tipe | ENUM('lokal','antargudang') | Jenis pengiriman |
| id_warehouse_tujuan | INT FK | Gudang tujuan (jika antargudang) |
| id_kurir | INT FK | Kurir reguler |
| id_kurir_transit | INT FK | Kurir transit (antargudang) |
| status | ENUM(5 nilai) | Status pengiriman |
| created_at | TIMESTAMP | Waktu dibuat |

### Status Flow
```
Di Gudang → Transit Antargudang → Di Gudang Tujuan → Sedang Diantar → Selesai
     │                                                        ↑
     └────────── (lokal, langsung) ────────────────────────────┘
```

## Data Awal
- **Admin:** username=`admin`, password=`admin123`
- **3 Gudang:** Pusat Yogyakarta, Hub Banguntapan, Sortir Sleman
- **3 Paket contoh** (opsional)

## Keamanan
- Password disimpan dengan **bcrypt** (`password_hash(PASSWORD_BCRYPT)`)
- Semua query menggunakan **prepared statements** (anti SQL injection)
- Admin tidak bisa dihapus via API `delete_user.php`
