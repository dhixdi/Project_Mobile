# 📦 ANALISIS & PANDUAN PERBAIKAN — GUDANG PINTAR
> Dibuat berdasarkan review kode GitHub + KONSEP_FINAL.pdf

---

## 🔍 RINGKASAN EKSEKUTIF

Proyek **Gudang Pintar** adalah sistem manajemen pengiriman paket berbasis mobile (Flutter) dengan backend PHP+MySQL (XAMPP). Secara struktur, kode yang sudah ada cukup baik sebagai fondasi, namun terdapat **gap signifikan antara kode saat ini dengan KONSEP_FINAL** — terutama pada arsitektur flow aplikasi, peran pengguna, dan beberapa fitur yang salah arah atau belum ada sama sekali.

---

## ✅ CHECKLIST RUBRIK TPM vs KONDISI SAAT INI

| # | Kriteria Wajib | Status | Catatan |
|---|---------------|--------|---------|
| 1 | Konsep projek akhir | ✅ Ada | KONSEP_FINAL.pdf ada |
| 2 | Login dengan enkripsi + session | ⚠️ Partial | Login ke MySQL ✅, tapi ada **bug hash mismatch** SHA256 vs MD5 |
| 3 | Login biometric | ✅ Ada | `biometric_auth_service.dart` sudah jalan |
| 4 | Database/penyimpanan lokal | ✅ Ada | Hive terenkripsi AES sudah ada |
| 5 | Web service / API | ✅ Ada | PHP backend di XAMPP sudah ada |
| 6 | LBS terkait tema | ⚠️ Salah arah | Ada GPS tapi untuk "lacak armada", bukan **navigasi kurir ke tujuan paket** |
| 7 | Bottom Navigation (profil, saran, logout) | ⚠️ Salah struktur | 5 tab ada, tapi **label & isi tidak sesuai KONSEP_FINAL** |
| 8 | Konversi mata uang (min 3) | ✅ Ada | IDR, USD, EUR, GBP, JPY, dll. ✅ |
| 9 | Konversi waktu (WIB/WITA/WIT/London) | ✅ Ada | Semua 4 zona waktu wajib ada ✅ |
| 10 | Min 2 sensor | ✅ Ada | Accelerometer + Gyroscope di `sensor_page.dart` |
| 11 | Fitur AI/ML dan LLM | ⚠️ Belum di Flutter | `gemini_proxy.php` ada tapi **belum ada halaman chatbot di Flutter** |
| 12 | Mini game terkait konsep | ⚠️ Salah konsep | Ada mini game, tapi bukan "Paket Jatuh" sesuai KONSEP_FINAL |
| 13 | Pencarian | ✅ Ada | Search bar di inventory ✅ |
| 14 | Pemilihan/filter | ⚠️ Partial | Filter status ada di database, belum di Flutter |
| 15 | Notifikasi | ✅ Ada | Push notif stok tipis sudah ada |

**Skor sementara: ~9/15 kriteria terpenuhi dengan benar**

---

## 🚨 MASALAH KRITIS (Harus Diperbaiki Dulu)

### MASALAH #1 — Password Hash Mismatch (Bug Fatal)
**File:** `register_page.dart` vs `login.php`

```dart
// register_page.dart — pakai SHA256
var bytes = utf8.encode(password);
var hashedPassword = sha256.convert(bytes).toString();
// Disimpan ke HIVE LOKAL, BUKAN ke MySQL!
```

```php
// login.php — pakai MD5
$hashedPassword = md5($password);
$sql = "SELECT * FROM users WHERE username = ? AND password = ?";
```

**Dampak:**
- User yang daftar lewat Flutter (Register page) → password-nya SHA256 dan disimpan ke Hive, **tidak dikirim ke MySQL sama sekali**
- Login via API MySQL pakai MD5 → akun yang dibuat dari Flutter app **tidak bisa login**
- Hanya akun yang di-insert langsung ke database (`admin_siti`, `kurir_budi`) yang bisa login karena passwordnya MD5

**Solusi:**
```dart
// register_page.dart → ganti jadi kirim ke API backend, jangan simpan ke Hive
Future<void> _register() async {
  final url = Uri.parse('http://192.168.18.106/gudang_pintar/api/register.php');
  final response = await http.post(url, body: {
    'username': username,
    'password': password, // Biarkan PHP yang hash MD5
    'role': 'kurir',      // Default role untuk register mobile
  });
  // Proses response...
}
```

---

### MASALAH #2 — Arsitektur Bottom Navigation Tidak Sesuai KONSEP_FINAL

**KONSEP_FINAL menentukan 5 tab:**
```
1. Paket Saya   → List paket assigned ke kurir login + search + filter status
2. Navigasi     → LBS map ke tujuan paket (koordinat penerima)
3. Konversi     → Mata uang + Waktu
4. AI Helper    → Chatbot LLM (Gemini API)
5. Profil       → Foto, Saran TPM, Mini Game, Logout
```

**Kode saat ini punya 5 tab:**
```
1. Beranda      → InventoryPage (CRUD stok, kelola paket admin-style)
2. Global       → ConversionPage ✅ (sesuai, ini tab Konversi)
3. Armada       → ShippingPage (GPS + cuaca, bukan navigasi ke paket)
4. Sensor       → SensorPage (uji kerapuhan paket, BUKAN seharusnya jadi tab utama)
5. Profil       → ProfilePage ✅ (sesuai)
```

**Yang harus diganti:**
- Tab 1: `InventoryPage` → ganti jadi `PaketSayaPage` (filter paket by kurir login)
- Tab 2: `ShippingPage` → ganti jadi `NavigasiPage` (map ke tujuan paket aktif)
- Tab 4: `SensorPage` → ganti jadi `AiHelperPage` (chatbot Gemini)
- `SensorPage` dipindah ke dalam **Profil** (aksesnya lewat tombol di halaman profil, sama seperti mini game sekarang)

---

### MASALAH #3 — Aplikasi Berperspektif Admin, Bukan Kurir

Kode saat ini menampilkan **semua paket** dari database tanpa filter role. Padahal per KONSEP_FINAL, mobile app adalah untuk **kurir** — yang hanya boleh lihat paket yang di-assign ke dia.

**Endpoint yang ada di backend:**
```php
// get_paket_kurir.php — SUDAH ADA tapi BELUM dipakai di Flutter!
GET /api/get_paket_kurir.php?id_kurir={id}
```

**Masalah:** Saat login sukses, backend mengembalikan data user termasuk `id` dan `role`, tapi Flutter hanya menyimpan `username` dan `role` ke Hive. **ID kurir tidak disimpan**, padahal dibutuhkan untuk filter paket.

**Solusi di `login_page.dart`:**
```dart
// Simpan juga id_kurir ke Hive
await box.put(username, {
  'id': data['data']['id'],          // ← Tambahkan ini
  'username': data['data']['username'],
  'role': data['data']['role'],
});
```

---

## ⚠️ MASALAH PENTING (Perlu Diperbaiki)

### MASALAH #4 — Tidak Ada Flutter Page untuk AI Helper / LLM

`gemini_proxy.php` di backend sudah ada dan menggunakan Gemini API (free tier ✅), tapi **tidak ada halaman chatbot di Flutter sama sekle**.

**Yang harus dibuat:** `ai_helper_page.dart` — chatbot sederhana yang mengirim pesan ke `gemini_proxy.php`.

> **Catatan penting soal `gemini_proxy.php`:** API Key Gemini ter-hardcode di file PHP (`AIzaSyBFgvUR7...`). Ini OK untuk development lokal XAMPP, tapi jangan di-push ke repository publik. Untuk VPS nanti, pindahkan ke environment variable.

---

### MASALAH #5 — Mini Game Tidak Sesuai KONSEP_FINAL

**KONSEP_FINAL menginginkan game "Paket Jatuh":**
- Gameplay: Karakter (kurir) menangkap paket yang jatuh dari atas
- Sensor: **Gyroscope tilt** → geser karakter kiri/kanan
- Sensor: **Accelerometer shake** → game over (paket terjatuh)

**Kode saat ini punya game "Sortir Gudang":**
- Gameplay: Miringkan HP untuk memindahkan barang ke kotak yang benar
- Sensor: Accelerometer → gerak item
- ❌ Tidak ada penggunaan Gyroscope
- ❌ Tidak ada mechanic "shake to game over"

**Saran:** Ganti `MiniGamePage` dengan implementasi "Paket Jatuh" yang menggunakan **kedua sensor** (Accelerometer + Gyroscope) agar sesuai KONSEP_FINAL dan rubrik sensor terpenuhi dengan lebih baik.

---

### MASALAH #6 — LBS Salah Implementasi untuk Konsep

**Saat ini (`ShippingPage`):** Ambil GPS posisi HP → tampilkan koordinat + data cuaca Open-Meteo.

**Yang dibutuhkan KONSEP_FINAL (Tab 2 Navigasi):**
```
1. Ambil koordinat PENERIMA dari paket yang sedang diantar
   (lat_penerima, lng_penerima sudah ada di tabel `paket` MySQL)
2. Ambil GPS posisi KURIR saat ini
3. Tampilkan peta (OpenStreetMap — GRATIS, tidak butuh API key)
4. Hitung jarak/estimasi waktu
5. Tombol [Sampai Tujuan] → POST ke update_status.php dengan status "Selesai"
```

**Package Flutter yang direkomendasikan (semua GRATIS):**
```yaml
flutter_map: ^7.0.0        # OpenStreetMap, tidak perlu API key
latlong2: ^0.9.0           # Koordinat helper untuk flutter_map
geolocator: ^14.0.2        # Sudah ada di pubspec ✅
url_launcher: ^6.3.0       # Buka Google Maps external (opsional)
```

---

### MASALAH #7 — Konversi Mata Uang Hardcoded

**Saat ini:** Kurs mata uang di-hardcode dalam `_exchangeRates` Map di `conversion_page.dart`.

**KONSEP_FINAL menyebut:** gunakan API `https://api.exchangerate-api.com/v4/latest/IDR`

**ExchangeRate-API free tier:** 1.500 request/bulan, tidak perlu registrasi untuk v4/latest.

```dart
// Tambahkan di conversion_page.dart
Future<void> _fetchLiveRates() async {
  final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/IDR');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    setState(() {
      _exchangeRates['USD'] = 1 / data['rates']['USD'];
      _exchangeRates['EUR'] = 1 / data['rates']['EUR'];
      // dst...
    });
  }
}
```

---

### MASALAH #8 — Tidak Ada Tombol "Mulai Antar" & "Sampai Tujuan"

Per flow KONSEP_FINAL, kurir harus bisa update status paket:
- **[Mulai Antar]** → status `Di Gudang` → `Sedang Diantar`
- **[Sampai Tujuan]** → status `Sedang Diantar` → `Selesai`

`update_status.php` di backend **sudah ada**, tapi belum dipanggil dari Flutter.

---

### MASALAH #9 — Register Page Tidak Konsisten dengan Konsep Sistem

Per KONSEP_FINAL, pembagian platform adalah:
- **Web Admin** → admin registrasi kurir (dari panel HTML)
- **Mobile Kurir** → kurir **login** dengan akun yang dibuat admin, **tidak register sendiri**

Artinya, Register page di Flutter sebenarnya **opsional/tidak perlu** per konsep ini. Jika tetap ingin dipertahankan, harus diperbaiki agar mengirim data ke MySQL via API (bukan simpan ke Hive).

---

## 📐 ARSITEKTUR YANG SEHARUSNYA

```
┌─────────────────────────────────────────────────────┐
│            WEB ADMIN (HTML/CSS/JS)                   │
│  Login → CRUD Paket → Assign Kurir → Lihat Status   │
└──────────────────────┬──────────────────────────────┘
                       │ REST API (PHP)
┌──────────────────────▼──────────────────────────────┐
│         BACKEND XAMPP/VPS (PHP + MySQL)              │
│  login.php · register.php · get_paket_kurir.php      │
│  update_status.php · add_paket.php · gemini_proxy.php│
└──────────────────────┬──────────────────────────────┘
                       │ HTTP JSON
┌──────────────────────▼──────────────────────────────┐
│           FLUTTER APP (Role: Kurir)                  │
│                                                      │
│  LoginPage → biometric/password → simpan session     │
│                     ↓                                │
│        MenuPage (Bottom Navigation 5 tab)            │
│  ┌──────────────────────────────────────────────┐    │
│  │ 1. PaketSayaPage                             │    │
│  │    GET /get_paket_kurir.php?id_kurir={id}    │    │
│  │    → List paket + Search + Filter status     │    │
│  │    → Tap paket → Detail + [Mulai Antar]      │    │
│  ├──────────────────────────────────────────────┤    │
│  │ 2. NavigasiPage                              │    │
│  │    GPS kurir + koordinat penerima            │    │
│  │    → flutter_map (OpenStreetMap, GRATIS)     │    │
│  │    → [Sampai Tujuan] → update_status.php     │    │
│  ├──────────────────────────────────────────────┤    │
│  │ 3. ConversionPage ✅ (sudah OK)              │    │
│  │    Mata uang (live API) + Waktu (WIB dst)    │    │
│  ├──────────────────────────────────────────────┤    │
│  │ 4. AiHelperPage (BARU)                       │    │
│  │    → POST ke gemini_proxy.php (Gemini free)  │    │
│  │    → Chat UI tanya cuaca/rute/estimasi       │    │
│  ├──────────────────────────────────────────────┤    │
│  │ 5. ProfilePage (sebagian sudah ✅)           │    │
│  │    Foto + Saran TPM + Mini Game (diperbarui) │    │
│  │    + Sensor Page (pindah ke sini)            │    │
│  │    + Logout                                  │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  Local: Hive (encrypted AES) → cache paket kurir    │
│  untuk offline mode saat tidak ada koneksi           │
└─────────────────────────────────────────────────────┘
```

---

## 📋 RENCANA PERBAIKAN PRIORITAS

### 🔴 PRIORITAS 1 — Wajib Dikerjakan (Rubrik Langsung Kena)

| No | File/Komponen | Aksi | Estimasi |
|----|--------------|------|----------|
| P1 | `login_page.dart` | Simpan `id` kurir dari response API ke Hive | 30 menit |
| P2 | `register_page.dart` | Ubah: kirim ke `register.php` (bukan simpan Hive) | 1 jam |
| P3 | `menu_page.dart` | Ganti 5 tab sesuai KONSEP_FINAL | 1 jam |
| P4 | Buat `paket_saya_page.dart` | Ambil dari `get_paket_kurir.php`, search, filter, [Mulai Antar] | 3-4 jam |
| P5 | Buat `navigasi_page.dart` | flutter_map + GPS + [Sampai Tujuan] | 3-4 jam |
| P6 | Buat `ai_helper_page.dart` | Chat UI + hit `gemini_proxy.php` | 2-3 jam |
| P7 | Perbarui `mini_game_page.dart` | "Paket Jatuh" — Gyroscope tilt + Accel shake | 2-3 jam |

### 🟡 PRIORITAS 2 — Penting (Kualitas & Kelengkapan)

| No | File/Komponen | Aksi | Estimasi |
|----|--------------|------|----------|
| P8 | `conversion_page.dart` | Integrasikan live currency API | 1 jam |
| P9 | `profile_page.dart` | Tambah tombol akses `SensorPage` | 30 menit |
| P10 | `sensor_page.dart` | Pindah dari tab utama ke aksesori di Profil | 30 menit |
| P11 | Backend: notifikasi | Tambah notifikasi saat paket di-assign ke kurir | 2 jam |

### 🟢 PRIORITAS 3 — Nice to Have

| No | Komponen | Aksi |
|----|----------|------|
| P12 | Offline mode | Cache paket di Hive, sync indicator |
| P13 | Web Admin | Perbaiki panel HTML supaya bisa assign kurir dari dropdown |
| P14 | Migrasi VPS | Siapkan `.env` untuk API key Gemini (jangan hardcode) |

---

## 📂 STRUKTUR FOLDER YANG DIREKOMENDASIKAN

```
mobile_final-main/
└── lib/
    ├── main.dart
    ├── constants/
    │   ├── string_constants.dart
    │   └── api_constants.dart         ← BARU: simpan base URL di satu tempat
    ├── models/
    │   ├── user_model.dart
    │   └── paket_model.dart           ← BARU: model untuk data paket
    ├── services/
    │   ├── biometric_auth_service.dart ✅
    │   ├── notification_services.dart ✅
    │   ├── api_service.dart            ← BARU: semua HTTP call terpusat
    │   └── hive_service.dart           ← BARU (opsional): helper Hive
    ├── controller/
    │   └── controller.dart ✅
    ├── screen/
    │   ├── login_page.dart            ✅ (perlu fix P1)
    │   ├── register_page.dart         ⚠️ (perlu fix P2)
    │   ├── menu_page.dart             ⚠️ (perlu fix P3)
    │   ├── paket_saya_page.dart       ← BARU (P4)
    │   ├── navigasi_page.dart         ← BARU (P5) — gantikan shipping_page
    │   ├── conversion_page.dart       ✅ (minor fix P8)
    │   ├── ai_helper_page.dart        ← BARU (P6)
    │   ├── profile_page.dart          ✅ (minor fix P9)
    │   ├── sensor_page.dart           ✅ (pindah akses ke profil P10)
    │   └── mini_game_page.dart        ⚠️ (perlu redesign P7)
    ├── widget/
    │   └── bottom_menu_navigation.dart (tidak dipakai lagi — sudah di menu_page)
    └── theme/
        └── app_color.dart ✅

Backend/
├── api/
│   ├── koneksi.php ✅
│   ├── login.php ✅
│   ├── register.php ✅
│   ├── get_paket.php ✅
│   ├── get_paket_kurir.php ✅
│   ├── add_paket.php ✅
│   ├── update_status.php ✅
│   ├── assign_kurir.php ✅
│   ├── get_couriers.php ✅
│   └── gemini_proxy.php ✅ (API key jangan di-push ke GitHub publik!)
└── admin/
    └── index.html ✅
```

---

## 💡 DETAIL IMPLEMENTASI FITUR BARU

### A. `api_constants.dart` — Satu Titik Konfigurasi URL

```dart
class ApiConstants {
  // Ganti ini saat migrasi ke VPS
  static const String baseUrl = 'http://192.168.18.106/gudang_pintar/api';
  
  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
  static const String getPaketKurir = '$baseUrl/get_paket_kurir.php';
  static const String updateStatus = '$baseUrl/update_status.php';
  static const String geminiProxy = '$baseUrl/gemini_proxy.php';
}
```

---

### B. `paket_saya_page.dart` — Tab 1 (Inti Aplikasi)

**Fitur yang harus ada:**
- Fetch dari `GET /get_paket_kurir.php?id_kurir={id}` saat buka halaman
- Simpan hasil ke Hive untuk offline mode
- `ValueListenableBuilder` untuk reactivity
- Search bar (cari by no_resi atau nama penerima)
- Filter chip untuk status: `Semua` | `Di Gudang` | `Sedang Diantar` | `Selesai`
- Card paket dengan status badge berwarna
- Tap paket → bottom sheet detail (no resi, penerima, alamat, gudang)
- Tombol **[Mulai Antar]** muncul jika status `Di Gudang`
- Notifikasi lokal saat status berhasil diupdate

```dart
// Contoh kerangka filter
List<Map> _getFilteredPaket(Box box) {
  var allPaket = box.values.cast<Map>().toList();
  
  // Filter by status
  if (_selectedFilter != 'Semua') {
    allPaket = allPaket.where((p) => p['status'] == _selectedFilter).toList();
  }
  
  // Filter by search query
  if (_searchQuery.isNotEmpty) {
    allPaket = allPaket.where((p) {
      return p['no_resi'].toString().contains(_searchQuery) ||
             p['nama_penerima'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  return allPaket;
}
```

---

### C. `navigasi_page.dart` — Tab 2 (LBS)

**Packages yang dibutuhkan (semua gratis):**
```yaml
# Tambahkan ke pubspec.yaml
flutter_map: ^7.0.0
latlong2: ^0.9.0
```

**Logika:**
```dart
// 1. Ambil paket aktif (status "Sedang Diantar") dari Hive
// 2. Dapatkan koordinat penerima dari Hive (lat_penerima, lng_penerima)
// 3. Dapatkan GPS kurir via geolocator (sudah ada)
// 4. Tampilkan di flutter_map dengan 2 marker:
//    - Marker merah = posisi kurir
//    - Marker biru = lokasi penerima
// 5. Tombol [Sampai Tujuan] → POST ke update_status.php

// Contoh FlutterMap widget
FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(kurirLat, kurirLng),
    initialZoom: 14,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      // OpenStreetMap = GRATIS, tidak perlu API key
    ),
    MarkerLayer(markers: [kurirMarker, penerimMarker]),
  ],
)
```

---

### D. `ai_helper_page.dart` — Tab 4 (LLM Chatbot)

**Teknologi: Gemini API via PHP Proxy (GRATIS)**
- Gemini 2.0 Flash: 15 RPM, 1 juta token/hari gratis
- `gemini_proxy.php` sudah ada di backend ✅

```dart
// Struktur data pesan
class ChatMessage {
  final String role; // 'user' atau 'model'
  final String text;
}

// Kirim pesan ke proxy
Future<String> _sendMessage(String userText) async {
  _messages.add({'role': 'user', 'parts': [{'text': userText}]});
  
  final response = await http.post(
    Uri.parse(ApiConstants.geminiProxy),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'contents': _messages}),
  );
  
  final data = jsonDecode(response.body);
  final reply = data['candidates'][0]['content']['parts'][0]['text'];
  _messages.add({'role': 'model', 'parts': [{'text': reply}]});
  return reply;
}
```

**Prompt sistem di `gemini_proxy.php` sudah bagus** ("Kamu adalah asisten kurir bernama Pintar..."). Bisa ditambahkan konteks cuaca:
```php
'system_instruction' => ['parts' => [['text' => 
  'Kamu adalah asisten kurir pengiriman paket bernama "Pintar". ' .
  'Bantu kurir dengan pertanyaan seputar rute, cuaca, estimasi waktu, dan tips pengiriman. ' .
  'Jawab singkat, praktis, ramah, dalam Bahasa Indonesia.'
]]]
```

---

### E. Mini Game "Paket Jatuh" — Versi Baru

**Mekanisme sesuai KONSEP_FINAL:**

```
┌─────────────────────────────────┐
│    [📦] [📦]    [📦]   [📦]     │  ← Paket jatuh dari atas
│                                 │
│                                 │
│                                 │
│         [🧍 KURIR]              │  ← Karakter di bawah
└─────────────────────────────────┘

Gyroscope.y  → geser kurir kiri/kanan
Accelerometer shake (magnitude > 20) → GAME OVER
Tangkap paket → +10 poin
Miss paket → -1 nyawa (3 nyawa)
```

**Implementasi sensor:**
```dart
// Gyroscope → gerak kurir
gyroscopeEventStream().listen((event) {
  if (_isPlaying) {
    setState(() {
      _kurirX += event.y * 0.05; // tilt phone = geser kurir
      _kurirX = _kurirX.clamp(-1.0, 1.0);
    });
  }
});

// Accelerometer → deteksi shake (game over)
accelerometerEventStream().listen((event) {
  double magnitude = sqrt(pow(event.x,2) + pow(event.y,2) + pow(event.z,2));
  if (magnitude > 20.0 && _isPlaying) {
    _triggerGameOver(); // Shake = paket jatuh semua
  }
});
```

---

## 🗄️ DATABASE — Sudah Baik, Minor Tambahan

Schema MySQL saat ini sudah solid. Satu-satunya yang perlu dipertimbangkan:

```sql
-- Tabel sessions (opsional tapi lebih proper untuk "session" requirement)
CREATE TABLE sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  token VARCHAR(255) NOT NULL,  -- random UUID/token
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

Saat ini "session" diimplementasikan dengan menyimpan `username` ke `FlutterSecureStorage` (ok untuk mobile), tapi jika dosen melihat kode backend, `login.php` tidak generate/return token — hanya return `id`, `username`, `role`. Untuk rubrik "session", cukup tunjukkan bahwa data tersimpan di secure storage dan digunakan untuk biometrik.

---

## 🔐 SECURITY CHECKLIST

- [x] Password di-hash sebelum disimpan di database (MD5 — cukup untuk tugas, tapi bcrypt lebih baik)
- [x] Hive terenkripsi dengan AES-256, kunci disimpan di Keystore/Keychain via FlutterSecureStorage
- [x] Biometric auth menggunakan native OS (tidak expose data ke app)
- [ ] **FIX:** API key Gemini jangan hardcode di file PHP yang di-push ke GitHub publik
- [ ] **FIX:** HTTPS saat deploy ke VPS (saat ini HTTP lokal = OK untuk dev)
- [x] Parameterized query di semua PHP (mencegah SQL injection) ✅
- [x] CORS header sudah di-set di `koneksi.php` ✅

---

## 🔄 STRATEGI OFFLINE MODE (Jawaban untuk Pertanyaan di KONSEP_FINAL)

> *"kurir ambil dari API juga dan kesimpan di hive lokal mobile jadi bisa offline kalo assigned terakhir sudah sinkron (aneh nggak?)"*

**Pendapat:** Strategi ini masuk akal dan umum dipakai (disebut *offline-first*). Cara kerjanya:

```
1. Buka app → coba fetch dari API → simpan ke Hive
2. Jika ada koneksi: tampilkan data fresh dari API + update Hive
3. Jika tidak ada koneksi: tampilkan data dari Hive (cache terakhir)
4. Saat ada koneksi lagi: sync perubahan status yang dilakukan offline
```

Untuk kesederhanaan tugas, cukup implementasikan:
- Fetch → simpan Hive → tampilkan dari Hive (ValueListenableBuilder)
- Tambahkan indikator "terakhir sync: [waktu]"
- Tombol refresh manual

Tidak perlu implementasi full offline sync dua arah — terlalu kompleks untuk scope tugas akhir.

---

## 📱 DEPENDENCY YANG PERLU DITAMBAHKAN KE `pubspec.yaml`

```yaml
dependencies:
  # Yang sudah ada ✅
  flutter_custom_clippers: ^2.1.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^10.0.0
  local_auth: ^3.0.1
  crypto: ^3.0.7
  flutter_local_notifications: ^21.0.0
  geolocator: ^14.0.2
  http: ^1.6.0
  sensors_plus: ^7.0.0
  
  # Yang perlu DITAMBAHKAN 🆕
  flutter_map: ^7.0.0        # OpenStreetMap (gratis, tidak perlu API key)
  latlong2: ^0.9.0           # Helper koordinat untuk flutter_map
  intl: ^0.19.0              # Format tanggal/waktu
  cached_network_image: ^3.4.0  # Foto profil dengan cache
```

> **Semua package di atas GRATIS dan open source** — tidak ada yang berbayar.

---

## 🌐 CATATAN MIGRASI KE VPS (Google Cloud / yang lain)

Saat ini IP di-hardcode ke `192.168.18.106` (XAMPP lokal). Saat migrasi:

1. Ubah semua URL di `ApiConstants` (setelah kamu buat file ini)
2. Pastikan VPS sudah setup HTTPS (pakai Certbot/Let's Encrypt — gratis)
3. Pindahkan Gemini API key dari hardcode PHP ke environment variable server
4. Update `http` → `https` di semua API call Flutter

---

## 📊 RINGKASAN PERUBAHAN

| Komponen | Status | Aksi |
|----------|--------|------|
| Login (Flutter) | 🔧 Fix minor | Simpan `id` dari response |
| Register (Flutter) | 🔧 Fix besar | Kirim ke MySQL via API |
| Menu (Bottom Nav) | 🔧 Redesign | Sesuaikan dengan KONSEP_FINAL |
| Tab 1 - Paket Saya | 🆕 Buat baru | Filter by kurir ID |
| Tab 2 - Navigasi | 🆕 Buat baru | flutter_map + GPS |
| Tab 3 - Konversi | ✅ Sudah OK | Minor: live currency API |
| Tab 4 - AI Helper | 🆕 Buat baru | Chat UI + Gemini proxy |
| Tab 5 - Profil | ✅ Sudah OK | Minor: tambah akses sensor |
| Mini Game | 🔧 Redesign | "Paket Jatuh" dengan Gyroscope |
| Sensor Page | ✅ Sudah OK | Pindah akses ke Profil |
| Backend PHP | ✅ Sudah OK | Semua endpoint sudah ada |
| Database MySQL | ✅ Sudah OK | Schema bagus |
| Web Admin | ✅ Sudah OK | Fungsional untuk CRUD |

**Estimasi total waktu pengerjaan perbaikan: ±20-25 jam kerja**

---

*Dokumen ini dibuat berdasarkan review kode di `mobile_final-main/` dan `Backend/` serta KONSEP_FINAL.pdf per Juni 2026.*
