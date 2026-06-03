# 📱 Mobile App — Gudang Pintar

## Stack
- **Framework:** Flutter 3.x (Dart)
- **State Management:** GetX
- **Local Storage:** Hive (session), Flutter Secure Storage (biometrik)
- **HTTP:** `http` package
- **Auth:** Biometrik (fingerprint/face) via `local_auth`
- **UI:** Google Fonts (Poppins), Material Design 3
- **Maps:** Google Maps Flutter + Geolocator
- **AI:** Google Gemini API (via PHP proxy)
- **Image Cache:** `cached_network_image`

## Struktur Folder

```
Mobile/lib/
├── main.dart                          ← Entry point + Hive init
├── constants/
│   └── api_constants.dart             ← Base URL + semua endpoint API
├── controller/
│   ├── paket_controller.dart          ← GetX controller paket kurir
│   ├── kurir_transit_controller.dart   ← GetX controller paket transit
│   ├── navigasi_controller.dart       ← GetX controller navigasi/maps
│   ├── ai_controller.dart             ← GetX controller Gemini AI
│   └── conversion_controller.dart     ← GetX controller konversi mata uang
├── screen/
│   ├── login_page.dart                ← Login (password + biometrik)
│   ├── register_page.dart             ← Register (tersembunyi dari UI)
│   ├── menu_page.dart                 ← Bottom navigation (5 tab)
│   ├── paket_saya_page.dart           ← Daftar paket kurir reguler
│   ├── kurir_transit_page.dart        ← Daftar paket kurir transit
│   ├── navigasi_page.dart             ← Google Maps + navigasi
│   ├── conversion_page.dart           ← Konversi mata uang
│   ├── ai_helper_page.dart            ← Chat AI Gemini
│   ├── profile_page.dart              ← Profil user + settings
│   └── mini_game_page.dart            ← Mini game sensor (gyro+accel)
├── services/
│   └── biometric_auth_service.dart    ← Autentikasi biometrik
├── theme/
│   ├── app_color.dart                 ← Palet warna (Navy + Amber)
│   └── app_theme.dart                 ← ThemeData Material 3
└── widget/
    ├── status_badge.dart              ← Badge status paket (5 warna)
    └── section_header.dart            ← Header section reusable
```

## Fitur Utama

### 🔐 Login
- Login password → API `/login.php`
- Login biometrik (fingerprint/face ID) via Hive cache
- Session tersimpan di Hive encrypted box
- Tombol "Daftar" dihapus → hanya admin yang bisa buat akun

### 📦 Paket Saya (Kurir Reguler)
- List paket yang di-assign ke kurir
- Update status: Di Gudang → Sedang Diantar → Selesai
- Pull-to-refresh

### 🚚 Paket Transit (Kurir Transit)
- List paket antargudang yang di-assign
- Visualisasi rute: Gudang Asal → Gudang Tujuan
- Update status: Di Gudang → Transit Antargudang → Di Gudang Tujuan
- Otomatis muncul jika role = `kurir_transit`

### 🗺️ Navigasi
- Google Maps + rute ke alamat penerima
- Geolocator untuk posisi kurir real-time

### 💱 Konversi Mata Uang
- API exchangerate untuk kurs real-time
- Support banyak mata uang

### 🤖 AI Pintar
- Chat dengan Google Gemini AI
- Proxy via `gemini_proxy.php` (API key aman di server)

### 👤 Profil
- Info user, foto profil (CachedNetworkImage)
- Pengaturan biometrik
- Mini game (sensor accelerometer + gyroscope)

## Role System

| Role | Tab Pertama | Akses |
|------|-------------|-------|
| `kurir` | Paket Saya | Paket reguler, navigasi, AI, profil |
| `kurir_transit` | Paket Transit | Paket antargudang, navigasi, AI, profil |

## Palet Warna

| Warna | Hex | Penggunaan |
|-------|-----|------------|
| Navy | `#1E3A5F` | Primary, header, gradient |
| Amber | `#F97316` | Accent, CTA, nav active |
| Sky Blue | `#0EA5E9` | Info, logistics, links |
| White | `#FFFFFF` | Card background |
| Slate | `#F1F5F9` | Page background |

## Setup Development

### Prasyarat
- Flutter SDK 3.x
- Android Studio / VS Code
- XAMPP (Apache + MySQL) running
- Database sudah diimport

### Jalankan
```bash
cd Mobile
flutter pub get
flutter run
```

### Konfigurasi API
Edit `lib/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://IP_LAPTOP_KAMU/gudang_pintar/api';
```
> Ganti `IP_LAPTOP_KAMU` dengan IP lokal (cek via `ipconfig`). HP dan laptop harus satu WiFi.

## Dependencies (pubspec.yaml)

| Package | Versi | Fungsi |
|---------|-------|--------|
| get | ^4.x | State management + routing |
| http | ^1.x | HTTP requests |
| hive / hive_flutter | ^2.x | Local encrypted storage |
| flutter_secure_storage | ^9.x | Secure key storage |
| local_auth | ^3.0.1 | Biometrik (fingerprint/face) |
| google_maps_flutter | ^2.x | Google Maps widget |
| geolocator | ^13.x | GPS location |
| google_fonts | ^6.x | Font Poppins |
| cached_network_image | ^3.x | Image caching + placeholder |
| sensors_plus | ^6.x | Accelerometer + Gyroscope |
| flutter_custom_clippers | ^2.x | Wave clipper login page |
| flutter_launcher_icons | ^0.14.1 | App icon generator |
