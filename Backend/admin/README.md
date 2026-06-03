# 🖥️ Admin Panel — Gudang Pintar

## Stack
- **Frontend:** HTML + JavaScript + Tailwind CSS (CDN)
- **Backend:** PHP (session-based authentication)
- **Server:** Apache (XAMPP) — akses via `http://localhost/gudang_pintar/admin/`

## Struktur Folder

```
Backend/admin/
├── login.php      ← Halaman login admin (entry point)
├── index.php      ← Dashboard utama (dilindungi session)
└── logout.php     ← Logout + destroy session
```

## Cara Akses

### Prasyarat
1. XAMPP → Apache & MySQL **ON**
2. Database `db_gudangpintar` sudah diimport
3. Folder `Backend/` ada di `C:\xampp\htdocs\gudang_pintar\`

### URL
```
http://localhost/gudang_pintar/admin/login.php
```

### Login
- **Username:** `admin`
- **Password:** `admin123`

## Fitur

### 🔐 Autentikasi
- Login khusus user dengan `role = 'admin'`
- PHP Session dengan auto-timeout 2 jam
- `session_regenerate_id()` untuk cegah session fixation
- Redirect otomatis ke login jika session expired

### 📦 Tab 1: Manajemen Paket
- **Dashboard stats** — Total paket, sedang diantar, selesai
- **Form Tambah Paket:**
  - 🔄 Auto-generate nomor resi (GPX-YYYYMMDD-XXXX)
  - 📍 Geocoding alamat → koordinat otomatis
  - Pilih gudang asal, tipe (lokal/antargudang), gudang tujuan
  - Assign kurir langsung saat tambah
- **Tabel Paket:**
  - Status badge berwarna (5 status)
  - Tombol "Assign Kurir" (kurir reguler)
  - Tombol "Antargudang" (assign kurir transit + gudang tujuan)

### 👤 Tab 2: Data Kurir
- Tabel semua kurir dan kurir transit
- Menampilkan: ID, Username, Role

### ⚙️ Tab 3: Manajemen User
- **Form Tambah User:** username, password, role (kurir/kurir_transit/admin)
- **Tabel User:** ID, Username, Role, Tanggal Dibuat, Hapus
- Admin tidak bisa dihapus (tombol disabled)

## Status Badge Warna

| Status | Warna |
|--------|-------|
| Di Gudang | 🔵 Biru |
| Transit Antargudang | 🟣 Ungu |
| Di Gudang Tujuan | 🟤 Indigo |
| Sedang Diantar | 🟠 Amber |
| Selesai | 🟢 Hijau |

## Keamanan
- ✅ Session-based auth (bukan open access)
- ✅ Hanya role `admin` yang bisa login
- ✅ Auto-timeout 2 jam
- ✅ CSRF-safe (menggunakan PHP native session)
