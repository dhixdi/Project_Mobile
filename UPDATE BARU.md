# 🏭 Gudang Pintar — Panduan Lengkap Upgrade Sistem

> **Versi Dokumen:** 2.0 | **Dibuat:** Juni 2026
> Dokumen ini mencakup 6 area peningkatan dari sistem lokal XAMPP ke sistem berbasis cloud yang lebih profesional.

---

## 📋 Daftar Isi

1. [Migrasi ke Google Cloud](#1-migrasi-ke-google-cloud)
2. [Peningkatan Panel Admin](#2-peningkatan-panel-admin)
3. [Role Baru — Kurir Transit](#3-role-baru--kurir-transit)
4. [Manajemen User oleh Admin](#4-manajemen-user-oleh-admin)
5. [Admin Login Best Practice](#5-admin-login-best-practice)
6. [Redesign UI & Logo](#6-redesign-ui--logo)
7. [Checklist Implementasi](#7-checklist-implementasi)

---

## 1. Migrasi ke Google Cloud

### Pertanyaan Kamu: Backend + Database, atau cuma Database?

**Jawaban: Pindahkan keduanya.** Kalau hanya database yang dipindah, backend PHP-nya tetap jalan di laptop lokal, yang artinya aplikasi masih tidak bisa diakses orang lain. Intinya, migrasi setengah = tidak ada manfaatnya.

### Arsitektur yang Direkomendasikan

```
[Flutter App] ──────► [Cloud Run: PHP Backend]
                              │
                              ▼
                       [Cloud SQL: MySQL 8.0]
```

| Komponen | Layanan GCP | Kenapa |
|---|---|---|
| PHP API (`/api/*.php`) | **Cloud Run** | Serverless, bayar per request, auto-scale |
| Admin Panel (`/admin/`) | **Cloud Run** (digabung) | Satu service, lebih simpel |
| Database MySQL | **Cloud SQL (MySQL 8.0)** | Managed, auto-backup, aman |

**Estimasi biaya per bulan** untuk proyek mahasiswa dengan traffic rendah: **$5–15/bulan** (Cloud SQL instance terkecil `db-f1-micro` ~$7/bln, Cloud Run gratis untuk ~2 juta request pertama).

---

### 1.1 Persiapan Google Cloud Project

```bash
# Install Google Cloud CLI jika belum ada
# Download dari: https://cloud.google.com/sdk/docs/install

# Login dan set project
gcloud auth login
gcloud config set project [PROJECT_ID_KAMU]

# Aktifkan API yang diperlukan
gcloud services enable \
  sqladmin.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com
```

---

### 1.2 Setup Cloud SQL (MySQL)

```bash
# Buat instance Cloud SQL
gcloud sql instances create gudang-pintar-db \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=asia-southeast2 \
  --root-password=[PASSWORD_ROOT_YANG_KUAT] \
  --storage-auto-increase \
  --backup-start-time=02:00

# Buat database
gcloud sql databases create db_gudangpintar \
  --instance=gudang-pintar-db

# Buat user khusus untuk aplikasi (jangan pakai root)
gcloud sql users create gudang_app \
  --instance=gudang-pintar-db \
  --password=[PASSWORD_APP]
```

---

### 1.3 Migrasi Database

**Di komputer lokal (XAMPP masih jalan):**

```bash
# Export database dari XAMPP
mysqldump -u root -p db_gudangpintar > db_gudangpintar_export.sql

# Import ke Cloud SQL
gcloud sql import sql gudang-pintar-db gs://[NAMA_BUCKET]/db_gudangpintar_export.sql \
  --database=db_gudangpintar
```

> **Alternatif lebih mudah:** Buka Cloud Console → SQL → Instance kamu → Import → Upload file SQL langsung dari browser.

---

### 1.4 Buat Container Docker untuk PHP Backend

Buat file `Dockerfile` di root project (sejajar folder `Backend/`):

```dockerfile
FROM php:8.2-apache

# Install ekstensi MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Aktifkan mod_rewrite Apache
RUN a2enmod rewrite

# Salin seluruh folder Backend ke dalam container
COPY Backend/ /var/www/html/

# Atur hak akses
RUN chown -R www-data:www-data /var/www/html

# Cloud Run menggunakan port 8080
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf && \
    sed -i 's/:80>/:8080>/' /etc/apache2/sites-enabled/000-default.conf

EXPOSE 8080
CMD ["apache2-foreground"]
```

Perbarui `Backend/api/koneksi.php` untuk koneksi Cloud SQL via Unix socket (cara yang direkomendasikan di Cloud Run):

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, DELETE, PUT");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Variabel lingkungan diinjeksi oleh Cloud Run
$db_user = getenv('DB_USER') ?: 'gudang_app';
$db_pass = getenv('DB_PASS') ?: '';
$db_name = getenv('DB_NAME') ?: 'db_gudangpintar';
$cloud_sql_connection = getenv('CLOUD_SQL_CONNECTION_NAME'); // format: project:region:instance

if ($cloud_sql_connection) {
    // Koneksi di Cloud Run menggunakan Unix socket
    $socket = '/cloudsql/' . $cloud_sql_connection;
    $koneksi = new mysqli('localhost', $db_user, $db_pass, $db_name, null, $socket);
} else {
    // Fallback untuk development lokal
    $koneksi = new mysqli('localhost', 'root', '', $db_name);
}

if ($koneksi->connect_error) {
    echo json_encode([
        "status" => "error",
        "message" => "Koneksi gagal: " . $koneksi->connect_error
    ]);
    exit();
}
?>
```

---

### 1.5 Deploy ke Cloud Run

```bash
# Build dan push container ke Google Container Registry
gcloud builds submit --tag gcr.io/[PROJECT_ID]/gudang-pintar-backend

# Deploy ke Cloud Run dengan koneksi ke Cloud SQL
gcloud run deploy gudang-pintar-backend \
  --image gcr.io/[PROJECT_ID]/gudang-pintar-backend \
  --region=asia-southeast2 \
  --platform=managed \
  --allow-unauthenticated \
  --add-cloudsql-instances=[PROJECT_ID]:asia-southeast2:gudang-pintar-db \
  --set-env-vars="DB_USER=gudang_app,DB_NAME=db_gudangpintar,CLOUD_SQL_CONNECTION_NAME=[PROJECT_ID]:asia-southeast2:gudang-pintar-db" \
  --set-secrets="DB_PASS=gudang-db-password:latest"
```

> **Catatan:** Simpan password DB di **Secret Manager** (bukan env var biasa). Buat secret-nya dulu:
> ```bash
> echo -n "[PASSWORD_APP]" | gcloud secrets create gudang-db-password --data-file=-
> ```

Setelah deploy berhasil, kamu akan mendapat URL seperti:
`https://gudang-pintar-backend-xxxx-as.a.run.app`

---

### 1.6 Update Flutter App

Di `Mobile/lib/constants/api_constants.dart`:

```dart
class ApiConstants {
  // Ganti URL ini dengan URL Cloud Run yang kamu dapat
  static const String baseUrl = 'https://gudang-pintar-backend-xxxx-as.a.run.app/api';
  
  static const String login         = '$baseUrl/login.php';
  static const String register      = '$baseUrl/register.php';
  static const String getPaketKurir = '$baseUrl/get_paket_kurir.php';
  static const String getPaket      = '$baseUrl/get_paket.php';
  static const String updateStatus  = '$baseUrl/update_status.php';
  static const String geminiProxy   = '$baseUrl/gemini_proxy.php';
  static const String currencyApi   = 'https://api.exchangerate-api.com/v4/latest/IDR';
}
```

Hapus juga teks `Server: 192.168.18.106` di halaman login karena sudah tidak relevan.

---

### 1.7 Tips Keamanan Tambahan

- Aktifkan **Cloud SQL Auth Proxy** untuk koneksi aman tanpa IP publik
- Set **CORS** di `koneksi.php` agar hanya menerima request dari domain resmi (kalau nanti ada web client)
- Gunakan **HTTPS only** — Cloud Run otomatis memberikan SSL certificate gratis
- Ganti `md5()` di `login.php` dan `register.php` ke `password_hash()` + `password_verify()` untuk keamanan yang lebih baik

---

## 2. Peningkatan Panel Admin

### 2.1 Auto-Generate Nomor Resi

Buat file baru `Backend/api/generate_resi.php`:

```php
<?php
include 'koneksi.php';

function generateNoResi($koneksi): string {
    $prefix = 'GPX';
    $date = date('Ymd');
    
    // Ambil nomor urut terakhir hari ini
    $sql = "SELECT COUNT(*) as total FROM paket WHERE no_resi LIKE ?";
    $pattern = "$prefix-$date-%";
    $stmt = $koneksi->prepare($sql);
    $stmt->bind_param("s", $pattern);
    $stmt->execute();
    $result = $stmt->get_result()->fetch_assoc();
    
    $sequence = str_pad($result['total'] + 1, 4, '0', STR_PAD_LEFT);
    return "$prefix-$date-$sequence";
}

header('Content-Type: application/json');
echo json_encode([
    'status' => 'success',
    'no_resi' => generateNoResi($koneksi)
]);
?>
```

Di admin panel (`admin/index.html` atau `index.php`), tambahkan tombol generate sebelum form submit:

```html
<!-- Ganti field no_resi menjadi: -->
<div class="relative">
  <input id="no_resi" placeholder="No Resi (klik 🔄 untuk generate)" 
         class="border border-slate-200 rounded-xl px-4 py-2.5 text-sm w-full pr-12">
  <button onclick="generateResi()" 
          class="absolute right-2 top-1/2 -translate-y-1/2 text-blue-500 hover:text-blue-700 text-lg">
    🔄
  </button>
</div>
```

```javascript
async function generateResi() {
  try {
    const r = await fetch(`${BASE}/generate_resi.php`);
    const d = await r.json();
    document.getElementById('no_resi').value = d.no_resi;
  } catch(e) {
    alert('Gagal generate resi: ' + e);
  }
}
// Auto-generate saat halaman load
document.addEventListener('DOMContentLoaded', generateResi);
```

---

### 2.2 Auto-Geocoding dari Alamat

**Aktifkan Geocoding API di Google Cloud Console:**
`APIs & Services → Library → Cari "Geocoding API" → Enable`

Buat file `Backend/api/geocode.php` (API key aman di server):

```php
<?php
include 'koneksi.php';

$GEOCODING_API_KEY = getenv('GEOCODING_API_KEY') ?: 'MASUKKAN_API_KEY_KAMU';

$address = $_GET['address'] ?? '';
if (empty($address)) {
    echo json_encode(['status' => 'error', 'message' => 'Alamat kosong']);
    exit;
}

$encoded = urlencode($address);
$url = "https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=$GEOCODING_API_KEY&region=id";

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

$data = json_decode($response, true);

if ($data['status'] === 'OK') {
    $loc = $data['results'][0]['geometry']['location'];
    echo json_encode([
        'status' => 'success',
        'lat'    => $loc['lat'],
        'lng'    => $loc['lng'],
        'alamat_formatted' => $data['results'][0]['formatted_address']
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Alamat tidak ditemukan']);
}
?>
```

Di admin panel, tambahkan tombol geocode di sebelah field alamat:

```html
<div class="col-span-2 flex gap-2">
  <input id="alamat_penerima" placeholder="Alamat lengkap penerima"
         class="flex-1 border border-slate-200 rounded-xl px-4 py-2.5 text-sm">
  <button onclick="geocodeAlamat()" 
          class="bg-blue-600 text-white px-4 py-2.5 rounded-xl text-sm font-medium hover:bg-blue-700 whitespace-nowrap">
    📍 Cari Koordinat
  </button>
</div>
<!-- Tampilkan hasil geocode -->
<div id="geocode-result" class="col-span-2 text-xs text-slate-500 hidden">
  ✅ Koordinat ditemukan: <span id="geocode-coords"></span>
</div>
```

```javascript
async function geocodeAlamat() {
  const alamat = document.getElementById('alamat_penerima').value;
  if (!alamat) { alert('Isi alamat dulu!'); return; }
  
  const btn = event.target;
  btn.textContent = '⏳ Mencari...';
  btn.disabled = true;
  
  try {
    const r = await fetch(`${BASE}/geocode.php?address=${encodeURIComponent(alamat)}`);
    const d = await r.json();
    
    if (d.status === 'success') {
      document.getElementById('lat').value = d.lat;
      document.getElementById('lng').value = d.lng;
      document.getElementById('geocode-coords').textContent = `${d.lat}, ${d.lng}`;
      document.getElementById('geocode-result').classList.remove('hidden');
      // Update field alamat dengan versi terformat dari Google
      document.getElementById('alamat_penerima').value = d.alamat_formatted;
    } else {
      alert('Koordinat tidak ditemukan. Coba perinci alamatnya.');
    }
  } catch(e) {
    alert('Gagal geocoding: ' + e);
  } finally {
    btn.textContent = '📍 Cari Koordinat';
    btn.disabled = false;
  }
}
```

> **Jangan lupa:** Tambahkan `GEOCODING_API_KEY` ke environment variables Cloud Run.

---

## 3. Role Baru — Kurir Transit

### Rekomendasi Nama

| Nama | DB Value | Cocok Untuk |
|---|---|---|
| **Kurir Transit** ✅ *(Rekomendasi)* | `kurir_transit` | Profesional, umum di industri logistik |
| Kurir Antargudang | `kurir_antargudang` | Deskriptif, terlalu panjang |
| Kurir Ekspedisi | `kurir_ekspedisi` | Kesan enterprise, cocok untuk skala besar |

Dokumen ini menggunakan **"Kurir Transit"** (`kurir_transit`).

### Alur Kerja Baru

```
[Admin Tambah Paket]
        │
        ▼
 Tipe: Antargudang? ──── TIDAK ──► Assign Kurir Reguler ──► Delivered
        │
       YA
        │
        ▼
 Assign Kurir Transit
        │
        ▼
 Status: "Transit Antargudang"
        │
        ▼
 Tiba di Gudang Tujuan
 Status: "Di Gudang Tujuan"
        │
        ▼
 Admin Assign Kurir Reguler
        │
        ▼
 Status: "Sedang Diantar" ──► "Selesai"
```

---

### 3.1 Perubahan Database

Jalankan SQL berikut di Cloud SQL (atau phpMyAdmin):

```sql
-- 1. Update ENUM role user untuk menambah kurir_transit
ALTER TABLE `users` 
  MODIFY COLUMN `role` enum('admin','kurir','kurir_transit') NOT NULL;

-- 2. Tambah kolom baru di tabel paket
ALTER TABLE `paket`
  ADD COLUMN `tipe` enum('lokal','antargudang') NOT NULL DEFAULT 'lokal' AFTER `id_warehouse`,
  ADD COLUMN `id_warehouse_tujuan` int(11) DEFAULT NULL AFTER `tipe`,
  ADD COLUMN `id_kurir_transit` int(11) DEFAULT NULL AFTER `id_kurir`,
  MODIFY COLUMN `status` enum(
    'Di Gudang',
    'Transit Antargudang',
    'Di Gudang Tujuan',
    'Sedang Diantar',
    'Selesai'
  ) DEFAULT 'Di Gudang',
  ADD CONSTRAINT `fk_warehouse_tujuan` 
    FOREIGN KEY (`id_warehouse_tujuan`) REFERENCES `warehouse` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_kurir_transit` 
    FOREIGN KEY (`id_kurir_transit`) REFERENCES `users` (`id`) ON DELETE SET NULL;
```

---

### 3.2 API Endpoint Baru

**`Backend/api/get_kurir_transit.php`** — Ambil daftar Kurir Transit:

```php
<?php
include 'koneksi.php';

$sql = "SELECT id, username FROM users WHERE role = 'kurir_transit' ORDER BY username";
$result = mysqli_query($koneksi, $sql);
$data = [];
while ($row = mysqli_fetch_assoc($result)) {
    $data[] = $row;
}
echo json_encode(["status" => "success", "data" => $data]);
?>
```

**`Backend/api/assign_kurir_transit.php`** — Assign Kurir Transit + ubah tipe jadi antargudang:

```php
<?php
include 'koneksi.php';

$id               = $_POST['id'] ?? '';
$id_kurir_transit = $_POST['id_kurir_transit'] ?? '';
$id_warehouse_tujuan = $_POST['id_warehouse_tujuan'] ?? '';

if (empty($id) || empty($id_kurir_transit) || empty($id_warehouse_tujuan)) {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
    exit;
}

$sql = "UPDATE paket 
        SET id_kurir_transit = ?, id_warehouse_tujuan = ?, tipe = 'antargudang', status = 'Di Gudang'
        WHERE id = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("iii", $id_kurir_transit, $id_warehouse_tujuan, $id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Kurir Transit berhasil di-assign"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}
?>
```

**`Backend/api/get_paket_transit.php`** — Ambil paket milik Kurir Transit:

```php
<?php
include 'koneksi.php';

$id_kurir_transit = $_GET['id_kurir_transit'] ?? '';
if (empty($id_kurir_transit)) {
    echo json_encode(["status" => "error", "message" => "ID Kurir Transit kosong"]);
    exit;
}

$sql = "SELECT p.*, 
               w_asal.nama_gudang AS nama_gudang_asal,
               w_tujuan.nama_gudang AS nama_gudang_tujuan,
               w_tujuan.latitude AS lat_gudang_tujuan,
               w_tujuan.longitude AS lng_gudang_tujuan
        FROM paket p
        LEFT JOIN warehouse w_asal   ON p.id_warehouse = w_asal.id
        LEFT JOIN warehouse w_tujuan ON p.id_warehouse_tujuan = w_tujuan.id
        WHERE p.id_kurir_transit = ?
          AND p.tipe = 'antargudang'
          AND p.status IN ('Di Gudang', 'Transit Antargudang', 'Di Gudang Tujuan')";

$stmt = $koneksi->prepare($sql);
$stmt->bind_param("s", $id_kurir_transit);
$stmt->execute();
$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode(["status" => "success", "data" => $data]);
?>
```

**Update `Backend/api/update_status.php`** — Sudah bisa handle status baru, tidak perlu banyak perubahan. Tapi tambahkan validasi status yang diperbolehkan:

```php
<?php
include 'koneksi.php';

$no_resi    = $_POST['no_resi'] ?? '';
$status_baru = $_POST['status'] ?? '';

$status_valid = ['Di Gudang', 'Transit Antargudang', 'Di Gudang Tujuan', 'Sedang Diantar', 'Selesai'];

if (empty($no_resi) || !in_array($status_baru, $status_valid)) {
    echo json_encode(["status" => "error", "message" => "Data tidak valid"]);
    exit;
}

$sql  = "UPDATE paket SET status = ? WHERE no_resi = ?";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("ss", $status_baru, $no_resi);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Status berhasil diupdate ke: $status_baru"]);
} else {
    echo json_encode(["status" => "error", "message" => "Gagal update status"]);
}
?>
```

---

### 3.3 Update Admin Panel

Di `admin/index.html` (atau `index.php`), tambahkan di form assign:

```html
<!-- Tambah di bagian aksi tabel paket -->
<td class="px-4 py-3 flex gap-2">
  <button onclick="assignKurir(${p.id}, '${p.no_resi}')" 
          class="bg-blue-600 text-white px-3 py-1.5 rounded-lg text-xs font-medium">
    Assign Kurir
  </button>
  ${p.tipe === 'lokal' ? `
  <button onclick="assignTransit(${p.id}, '${p.no_resi}')"
          class="bg-purple-600 text-white px-3 py-1.5 rounded-lg text-xs font-medium">
    Antargudang
  </button>` : ''}
</td>
```

```javascript
async function assignTransit(id, resi) {
  // Tampilkan modal sederhana (bisa diperindah dengan modal HTML)
  const kurirId = prompt(`ID Kurir Transit untuk paket ${resi}:`);
  const gudangTujuan = prompt(`ID Gudang Tujuan (1=Pusat, 2=Banguntapan, 3=Sleman):`);
  if (!kurirId || !gudangTujuan) return;

  const body = new FormData();
  body.append('id', id);
  body.append('id_kurir_transit', kurirId);
  body.append('id_warehouse_tujuan', gudangTujuan);

  try {
    const r = await fetch(`${BASE}/assign_kurir_transit.php`, { method: 'POST', body });
    const d = await r.json();
    alert(d.message);
    loadPaket();
  } catch(e) {
    alert('Gagal: ' + e);
  }
}
```

---

### 3.4 Perubahan Flutter

Tambahkan konstanta baru di `api_constants.dart`:

```dart
static const String getPaketTransit  = '$baseUrl/get_paket_transit.php';
static const String updateStatus     = '$baseUrl/update_status.php'; // sudah ada
```

Update `MenuPage` untuk membedakan role:

```dart
// Di menu_page.dart, ubah konstruktor dan logika halaman
class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    required this.username,
    required this.idKurir,
    required this.role, // TAMBAH INI
  });
  final String username;
  final int idKurir;
  final String role; // TAMBAH INI
  ...
}

// Di _MenuPageState.build(), buat pages berdasarkan role:
@override
Widget build(BuildContext context) {
  final isTransit = widget.role == 'kurir_transit';
  
  final pages = [
    isTransit 
      ? KurirTransitPage(idKurir: widget.idKurir)  // Halaman baru
      : PaketSayaPage(idKurir: widget.idKurir),
    const NavigasiPage(),
    const ConversionPage(),
    const AiHelperPage(),
    ProfilePage(username: widget.username),
  ];
  ...
}
```

Buat `Mobile/lib/screen/kurir_transit_page.dart` dengan logika mirip `PaketSayaPage`, tapi:
- Fetch dari `get_paket_transit.php`
- Tombol aksi: `"Mulai Kirim"` → status `"Transit Antargudang"`, `"Tiba di Gudang Tujuan"` → status `"Di Gudang Tujuan"`
- Navigasi menunjukkan rute **Gudang Asal → Gudang Tujuan** (bukan ke alamat penerima)

---

## 4. Manajemen User oleh Admin

### 4.1 Hapus Self-Registration dari Mobile

Di `Mobile/lib/screen/login_page.dart`, hapus/sembunyikan tombol daftar:

```dart
// Hapus atau komen baris ini di _buildLoginForm():
// Row(
//   children: [
//     const Text("Belum punya akun? "),
//     TextButton(
//       onPressed: () => Get.to(() => const RegisterPage()),
//       child: const Text("Daftar Sekarang"),
//     ),
//   ],
// )

// Ganti dengan informasi kontak admin:
const Padding(
  padding: EdgeInsets.only(top: 16),
  child: Text(
    'Butuh akun? Hubungi admin gudang.',
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
  ),
),
```

---

### 4.2 API Manajemen User untuk Admin

**`Backend/api/add_user.php`** — Admin tambah user baru:

```php
<?php
include 'koneksi.php';

// Proteksi: hanya bisa dipanggil dari sesi admin (lihat Bagian 5)
$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';
$role     = $_POST['role']     ?? 'kurir';

$allowed_roles = ['kurir', 'kurir_transit', 'admin'];
if (empty($username) || empty($password) || !in_array($role, $allowed_roles)) {
    echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap atau role tidak valid']);
    exit;
}

// Cek username duplikat
$check = $koneksi->prepare("SELECT id FROM users WHERE username = ?");
$check->bind_param("s", $username);
$check->execute();
if ($check->get_result()->num_rows > 0) {
    echo json_encode(['status' => 'error', 'message' => 'Username sudah digunakan']);
    exit;
}

$hashedPassword = password_hash($password, PASSWORD_BCRYPT);
$stmt = $koneksi->prepare("INSERT INTO users (username, password, role) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $username, $hashedPassword, $role);

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => "User '$username' berhasil dibuat"]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan user']);
}
?>
```

> **Perhatian:** Karena kamu ganti ke `password_hash()`, update juga `login.php` dari `md5()` ke `password_verify()`:
> ```php
> // Di login.php, ganti baris ini:
> // $hashedPassword = md5($password);
> // ... AND password = ?
>
> // Menjadi:
> $sql = "SELECT * FROM users WHERE username = ?";
> $stmt = mysqli_prepare($koneksi, $sql);
> mysqli_stmt_bind_param($stmt, "s", $username);
> mysqli_stmt_execute($stmt);
> $result = mysqli_stmt_get_result($stmt);
>
> if (mysqli_num_rows($result) > 0) {
>     $user = mysqli_fetch_assoc($result);
>     if (password_verify($password, $user['password'])) {
>         // Login berhasil
>     }
> }
> ```

**`Backend/api/get_users.php`** — Ambil semua user:

```php
<?php
include 'koneksi.php';

$role_filter = $_GET['role'] ?? '';
$sql = "SELECT id, username, role, created_at FROM users";
if (!empty($role_filter)) {
    $sql .= " WHERE role = ?";
    $stmt = $koneksi->prepare($sql);
    $stmt->bind_param("s", $role_filter);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = mysqli_query($koneksi, $sql);
}

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}
echo json_encode(["status" => "success", "data" => $data]);
?>
```

**`Backend/api/delete_user.php`** — Hapus user:

```php
<?php
include 'koneksi.php';

$id = $_POST['id'] ?? '';
if (empty($id)) {
    echo json_encode(['status' => 'error', 'message' => 'ID user tidak ada']);
    exit;
}

$sql = "DELETE FROM users WHERE id = ? AND role != 'admin'";
$stmt = $koneksi->prepare($sql);
$stmt->bind_param("i", $id);

if ($stmt->execute() && $stmt->affected_rows > 0) {
    echo json_encode(['status' => 'success', 'message' => 'User berhasil dihapus']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal hapus / tidak bisa hapus admin']);
}
?>
```

---

### 4.3 Tambah Tab Manajemen User di Admin Panel

Tambahkan tab ketiga di sidebar admin dan section form tambah user dengan dropdown role (Admin / Kurir / Kurir Transit).

---

## 5. Admin Login Best Practice

### Masalah Saat Ini
File `admin/index.html` bisa diakses langsung oleh siapapun yang tahu URL-nya. Di dunia nyata ini tidak aman.

### Solusi: PHP Session Auth (Simpel tapi Benar)

**Struktur folder baru:**
```
Backend/
├── admin/
│   ├── login.php        ← Entry point (baru)
│   ├── index.php        ← Diganti dari index.html (dilindungi session)
│   ├── logout.php       ← Baru
│   └── assets/          ← CSS/JS kalau ada
├── api/
│   └── ...
```

**`Backend/admin/login.php`:**

```php
<?php
session_start();

// Kalau sudah login, langsung redirect
if (isset($_SESSION['admin_id'])) {
    header('Location: index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_once '../api/koneksi.php';
    
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    
    if (empty($username) || empty($password)) {
        $error = 'Username dan password wajib diisi';
    } else {
        $stmt = $koneksi->prepare("SELECT id, username, password FROM users WHERE username = ? AND role = 'admin'");
        $stmt->bind_param("s", $username);
        $stmt->execute();
        $user = $stmt->get_result()->fetch_assoc();
        
        // Dukung baik password_hash (baru) maupun md5 (lama - masa transisi)
        $valid = $user && (
            password_verify($password, $user['password']) ||
            $user['password'] === md5($password)
        );
        
        if ($valid) {
            session_regenerate_id(true); // Cegah session fixation attack
            $_SESSION['admin_id']       = $user['id'];
            $_SESSION['admin_username'] = $user['username'];
            $_SESSION['login_time']     = time();
            header('Location: index.php');
            exit;
        } else {
            $error = 'Username atau password salah';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Login Admin — Gudang Pintar</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-slate-900 min-h-screen flex items-center justify-center">
  <div class="bg-white rounded-2xl shadow-2xl p-8 w-full max-w-md">
    <div class="text-center mb-8">
      <div class="text-4xl mb-3">🏭</div>
      <h1 class="text-2xl font-bold text-slate-800">Gudang Pintar</h1>
      <p class="text-slate-500 text-sm mt-1">Panel Admin — Masuk untuk melanjutkan</p>
    </div>
    
    <?php if ($error): ?>
    <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl mb-6 text-sm">
      ⚠️ <?= htmlspecialchars($error) ?>
    </div>
    <?php endif; ?>
    
    <form method="POST" class="space-y-4">
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1.5">Username</label>
        <input type="text" name="username" required autocomplete="username"
               class="w-full border border-slate-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-slate-500">
      </div>
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1.5">Password</label>
        <input type="password" name="password" required autocomplete="current-password"
               class="w-full border border-slate-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-slate-500">
      </div>
      <button type="submit"
              class="w-full bg-slate-700 text-white py-3 rounded-xl font-medium hover:bg-slate-800 transition mt-2">
        Masuk ke Panel Admin
      </button>
    </form>
  </div>
</body>
</html>
```

**`Backend/admin/index.php`** (rename dari `index.html`, tambahkan guard di atas):

```php
<?php
session_start();

// Auto-timeout setelah 2 jam tidak aktif
if (isset($_SESSION['login_time']) && (time() - $_SESSION['login_time']) > 7200) {
    session_destroy();
    header('Location: login.php?reason=timeout');
    exit;
}

if (!isset($_SESSION['admin_id'])) {
    header('Location: login.php');
    exit;
}

// Update waktu aktivitas terakhir
$_SESSION['login_time'] = time();
$admin_username = htmlspecialchars($_SESSION['admin_username']);
?>
<!DOCTYPE html>
<!-- Sisa konten HTML yang sudah ada sebelumnya ... -->
<!-- Tambahkan info admin dan tombol logout di navbar: -->
<!--
<span class="ml-auto text-slate-300 text-sm">
  👤 <?= $admin_username ?> | 
  <a href="logout.php" class="text-red-300 hover:text-red-100">Logout</a>
</span>
-->
```

**`Backend/admin/logout.php`:**

```php
<?php
session_start();
session_destroy();
header('Location: login.php?logout=1');
exit;
?>
```

---

## 6. Redesign UI & Logo

### 6.1 Palet Warna Baru — Tema Warehouse Industrial

Ganti `Mobile/lib/theme/app_color.dart` sepenuhnya:

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary — Dark Navy Industrial
  static const Color primary      = Color(0xFF1E3A5F);
  static const Color primaryDark  = Color(0xFF152D4A);
  static const Color primaryLight = Color(0xFFE8F2FF);

  // Accent — Amber/Orange (Safety & Action)
  static const Color accent      = Color(0xFFF97316);
  static const Color accentLight = Color(0xFFFFF3E8);

  // Logistics Blue (Info & Secondary)
  static const Color logistics = Color(0xFF0EA5E9);

  // Status Paket (5 status baru)
  static const Color statusGudang      = Color(0xFF0EA5E9); // Biru — Di Gudang
  static const Color statusTransit     = Color(0xFF8B5CF6); // Ungu — Transit Antargudang
  static const Color statusGudangTujuan = Color(0xFF6366F1); // Indigo — Di Gudang Tujuan
  static const Color statusAntar       = Color(0xFFF97316); // Oranye — Sedang Diantar
  static const Color statusSelesai     = Color(0xFF10B981); // Hijau — Selesai

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF97316);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF0EA5E9);

  // Neutral
  static const Color bg           = Color(0xFFF1F5F9); // Abu-biru muda
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color textPrimary  = Color(0xFF0F172A);
  static const Color textSecondary= Color(0xFF64748B);
  static const Color border       = Color(0xFFE2E8F0);
  static const Color divider      = Color(0xFFF8FAFC);

  // Navigation
  static const Color navActive = Color(0xFFF97316); // Amber aktif
  static const Color navInactive = Color(0xFF94A3B8);

  // Hyperlink
  static const Color link = Color(0xFF0EA5E9);

  // Gradient untuk header
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF0EA5E9)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  );
}
```

---

### 6.2 Update `app_theme.dart`

```dart
// Di app_theme.dart, ubah beberapa bagian penting:

// NavigationBarTheme — ganti warna aktif ke accent (amber):
navigationBarTheme: NavigationBarThemeData(
  backgroundColor: AppColors.cardBg,
  indicatorColor: AppColors.accent.withValues(alpha: 0.15),
  labelTextStyle: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent);
    }
    return GoogleFonts.poppins(
      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.navInactive);
  }),
  iconTheme: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return const IconThemeData(color: AppColors.accent, size: 24);
    }
    return const IconThemeData(color: AppColors.navInactive, size: 24);
  }),
),

// ElevatedButtonTheme — ganti warna primary ke amber untuk CTA utama:
// Untuk tombol utama seperti "Mulai Antar" dan "Selesai",
// gunakan backgroundColor: AppColors.accent langsung di widget

// ColorScheme — update seed color:
colorScheme: ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  primary: AppColors.primary,
  secondary: AppColors.accent,
  brightness: Brightness.light,
  surface: AppColors.bg,
),
```

---

### 6.3 Custom App Icon & Logo

**Tambahkan package di `pubspec.yaml`:**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.1  # TAMBAH INI

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#1E3A5F"   # Navy background untuk adaptive icon
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
```

**Langkah membuat icon:**

1. Buat folder `Mobile/assets/icons/`

2. Desain icon (1024x1024 px PNG) dengan konsep:
   - Background: Navy `#1E3A5F`
   - Elemen: Ikon gudang/warehouse putih dengan garis bold, ditambah tanda petir/kilat kecil di sudut kanan bawah berwarna amber `#F97316`
   - Tools gratis: Figma (free), Canva, atau Adobe Express

3. Letakkan hasilnya sebagai:
   - `assets/icons/app_icon.png` — icon lengkap (untuk iOS)
   - `assets/icons/app_icon_foreground.png` — hanya elemen tengah tanpa background (untuk Android adaptive icon)

4. Daftarkan folder assets di `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/icons/
   ```

5. Generate icon:
   ```bash
   cd Mobile
   dart run flutter_launcher_icons
   ```

---

### 6.4 Panduan Redesign Per Halaman

| Halaman | Yang Harus Diubah |
|---|---|
| **Login** | Header gradient baru (navy→logistics blue), hapus teks "Server: 192.168.x.x", logo lebih besar |
| **PaketSaya** | Chip filter pakai warna status baru, card paket tambahkan garis kiri berwarna sesuai status |
| **Navigasi** | Bottom card pakai gradient subtle, tombol "Sampai Tujuan" pakai `accentGradient` |
| **Profil** | Header pakai `primaryGradient`, feature cards lebih rounded |
| **StatusBadge** | Update warna untuk 5 status baru (tambah Transit & Di Gudang Tujuan) |

**Contoh update `StatusBadge` untuk 5 status:**

```dart
// Di widget/status_badge.dart, update switch statement:
switch (status) {
  case 'Di Gudang':
    color = AppColors.statusGudang;
    icon = Icons.warehouse_outlined;
    label = 'Di Gudang';
    break;
  case 'Transit Antargudang':
    color = AppColors.statusTransit;
    icon = Icons.local_shipping_outlined;
    label = 'Transit';
    break;
  case 'Di Gudang Tujuan':
    color = AppColors.statusGudangTujuan;
    icon = Icons.store_outlined;
    label = 'Gudang Tujuan';
    break;
  case 'Sedang Diantar':
    color = AppColors.statusAntar;
    icon = Icons.directions_bike;
    label = 'Diantar';
    break;
  case 'Selesai':
    color = AppColors.statusSelesai;
    icon = Icons.check_circle_outline;
    label = 'Selesai';
    break;
  default:
    color = AppColors.textSecondary;
    icon = Icons.help_outline;
    label = status;
}
```

---

## 7. Checklist Implementasi

Urutkan pengerjaan dari yang paling kritikal:

### Fase 1 — Cloud Migration (Prioritas Tinggi)
- [ ] Buat Cloud SQL instance di GCP
- [ ] Export database dari XAMPP dan import ke Cloud SQL
- [ ] Buat `Dockerfile` di root project
- [ ] Update `koneksi.php` untuk Cloud SQL
- [ ] Deploy ke Cloud Run
- [ ] Test semua endpoint API
- [ ] Update `api_constants.dart` di Flutter dengan URL Cloud Run
- [ ] Test login Flutter dengan backend cloud

### Fase 2 — Admin Security & Login
- [ ] Buat `admin/login.php`
- [ ] Rename `admin/index.html` → `admin/index.php` dan tambahkan session guard
- [ ] Buat `admin/logout.php`
- [ ] Test login/logout admin panel

### Fase 3 — Fitur Baru
- [ ] Jalankan SQL migration (ALTER TABLE users + paket)
- [ ] Buat endpoint API baru (generate_resi, geocode, kurir_transit, user management)
- [ ] Update `add_paket.php` / admin panel untuk auto-resi dan geocoding
- [ ] Aktifkan Geocoding API di GCP dan tambahkan ke environment variables
- [ ] Update admin panel dengan tab Manajemen User dan Assign Transit
- [ ] Hapus tombol Daftar dari Flutter mobile

### Fase 4 — UI Redesign
- [ ] Update `app_color.dart` dengan palet baru
- [ ] Update `app_theme.dart`
- [ ] Update `status_badge.dart` untuk 5 status
- [ ] Buat/desain icon app (1024x1024 PNG)
- [ ] Setup `flutter_launcher_icons` dan generate icon
- [ ] Update halaman Login (hapus server IP, update gradient)
- [ ] Review semua halaman dengan warna baru

### Fase 5 — Role Kurir Transit (Flutter)
- [ ] Tambahkan parameter `role` ke `MenuPage`
- [ ] Update `login_page.dart` untuk pass role saat navigasi
- [ ] Buat `KurirTransitPage`
- [ ] Update `NavigasiController` untuk handle rute antar gudang
- [ ] Test full flow: Admin assign transit → Kurir Transit update status → Admin assign kurir → Kurir deliver

---

> **Tips Terakhir:** Kerjakan Fase 1 dan 2 dulu sebelum yang lain — begitu backend sudah di cloud, semua pengembangan berikutnya bisa langsung ditest dari HP fisik tanpa perlu XAMPP menyala.
