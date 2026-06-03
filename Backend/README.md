# 🔧 Backend API — Gudang Pintar

## Stack
- **Bahasa:** PHP 8.x
- **Database:** MySQL via `mysqli` (prepared statements)
- **Server:** Apache (XAMPP lokal) atau Cloud Run (production)
- **Auth:** Bcrypt (`password_hash` / `password_verify`)
- **Format:** Semua response JSON (`Content-Type: application/json`)

## Struktur Folder

```
Backend/
├── api/
│   ├── koneksi.php              ← Koneksi database + CORS headers
│   ├── login.php                ← Login user (password_verify)
│   ├── register.php             ← Register user (password_hash)
│   ├── get_paket.php            ← List semua paket + info gudang
│   ├── get_paket_kurir.php      ← Paket milik kurir tertentu
│   ├── get_paket_transit.php    ← Paket milik kurir transit
│   ├── add_paket.php            ← Tambah paket baru
│   ├── update_status.php        ← Update status paket (5 status)
│   ├── assign_kurir.php         ← Assign kurir reguler ke paket
│   ├── assign_kurir_transit.php ← Assign kurir transit + gudang tujuan
│   ├── get_couriers.php         ← List kurir reguler
│   ├── get_kurir_transit.php    ← List kurir transit
│   ├── generate_resi.php        ← Auto-generate no resi GPX-YYYYMMDD-XXXX
│   ├── geocode.php              ← Proxy ke Google Geocoding API
│   ├── add_user.php             ← Admin tambah user (bcrypt)
│   ├── get_users.php            ← List semua user (filter by role)
│   ├── delete_user.php          ← Hapus user (lindungi admin)
│   └── gemini_proxy.php         ← Proxy ke Gemini AI API
└── admin/
    └── (lihat Backend/admin/README.md)
```

## API Endpoints

### Auth
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/api/login.php` | Login (username + password) → return id, username, role |
| POST | `/api/register.php` | Register user baru (bcrypt) |

### Paket
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/get_paket.php` | Semua paket + nama gudang asal & tujuan |
| GET | `/api/get_paket_kurir.php?id_kurir=X` | Paket milik kurir X |
| GET | `/api/get_paket_transit.php?id_kurir_transit=X` | Paket transit milik kurir X |
| POST | `/api/add_paket.php` | Tambah paket (no_resi, tipe, warehouse, dll) |
| POST | `/api/update_status.php` | Update status (5 status valid) |
| POST | `/api/assign_kurir.php` | Assign kurir reguler |
| POST | `/api/assign_kurir_transit.php` | Assign kurir transit + gudang tujuan |

### User Management (Admin)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/api/add_user.php` | Tambah user (role: kurir/kurir_transit/admin) |
| GET | `/api/get_users.php` | List user (opsional filter `?role=kurir`) |
| POST | `/api/delete_user.php` | Hapus user (admin dilindungi) |

### Utility
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/api/generate_resi.php` | Auto-generate GPX-YYYYMMDD-XXXX |
| GET | `/api/geocode.php?address=X` | Geocoding alamat → lat,lng |
| GET | `/api/get_couriers.php` | List kurir reguler |
| GET | `/api/get_kurir_transit.php` | List kurir transit |
| POST | `/api/gemini_proxy.php` | Proxy ke Google Gemini AI |

## Response Format

Semua API return JSON:
```json
{
  "status": "success" | "error",
  "message": "...",
  "data": [...] | {...}
}
```

## Konfigurasi

### `koneksi.php`
- **Lokal (XAMPP):** Otomatis connect ke `localhost:3306` dengan user `root`
- **Cloud Run:** Baca env vars `DB_USER`, `DB_PASS`, `DB_NAME`, `CLOUD_SQL_CONNECTION_NAME`
- **CORS:** Allow all origins (`*`)

### `geocode.php`
- Set API key di env var `GEOCODING_API_KEY` atau langsung di file
- Cara dapat (gratis): Google Cloud Console → APIs → Geocoding API → Enable → Create API Key
- Free tier: $200 credit/bulan

## Keamanan
- ✅ Semua query pakai **prepared statements** (anti SQL injection)
- ✅ Password pakai **bcrypt** (bukan md5)
- ✅ Admin tidak bisa dihapus via `delete_user.php`
- ⚠️ `gemini_proxy.php` berisi API key — jangan push ke GitHub publik!
