# 🎨 PANDUAN FRONTEND — GUDANG PINTAR
### Mobile Flutter + Web Admin | UI Revamp Guide

---

## DAFTAR ISI
1. [Diagnosis UI Saat Ini](#diagnosis)
2. [Stack Decision: State Management](#stack)
3. [Setup Package & Theme](#setup)
4. [Design System (Warna, Font, Komponen)](#design-system)
5. [Bottom Navigation — Rekomendasi Struktur](#bottom-nav)
6. [Di mana Mini Game?](#game-placement)
7. [Panduan UI Per Halaman — Mobile](#screens-mobile)
8. [Panduan UI — Web Admin](#screens-web)
9. [Reusable Widget Library](#widgets)

---

## 1. DIAGNOSIS UI SAAT INI {#diagnosis}

| Screen | Masalah UI |
|--------|-----------|
| `login_page.dart` | Wave clipper OK tapi form field terlalu plain, warna tombol monoton |
| `inventory_page.dart` | ListTile terlalu rapat, status badge tidak mencolok, trailing button terlalu kecil |
| `conversion_page.dart` | Grid card waktu terlalu kecil, dropdown tidak konsisten padding |
| `shipping_page.dart` | Layout terlalu banyak whitespace kosong, card kurang depth |
| `sensor_page.dart` | Kartu data sensor terlalu kaku, FAB warna tidak konsisten |
| `mini_game_page.dart` | Area bermain monoton, tidak ada animasi reward, feedback visual minim |
| `profile_page.dart` | Foto profil terlalu besar, tombol-tombol terlalu "blocky", tidak ada visual hierarchy |
| `menu_page.dart` | `BottomNavigationBar` lama — tidak ada label aktif yang menonjol, ikon terlalu kecil |

**Root cause utama:**
- Tidak pakai Material 3 (masih default M2)
- Font sistem default tanpa hierarchy
- Warna accent dipakai tidak konsisten
- Tidak ada design token terpusat yang dipakai ulang
- Tidak ada state management → UI logic dan business logic campur di widget

---

## 2. STACK DECISION: STATE MANAGEMENT {#stack}

### Kondisi Saat Ini
```
Semua screen: StatefulWidget + setState
Tidak ada: GetX, Provider, Riverpod, BLoC
```

### Perbandingan Pilihan

| Opsi | Kompleksitas | Cocok Untuk | Alasan |
|------|-------------|-------------|--------|
| `setState` saja | ⭐ Paling mudah | Prototyping | Sudah ada, tapi tidak scalable |
| **GetX** ⭐ REKOMENDASI | ⭐⭐ Mudah | Tugas Akhir | 1 package = routing + state + DI. Boilerplate minimal. |
| Provider | ⭐⭐ Mudah | Menengah | Lebih verbose dari GetX untuk project ini |
| Riverpod | ⭐⭐⭐ Menengah | Production | Bagus tapi overengineering untuk tugas |
| BLoC | ⭐⭐⭐⭐ Sulit | Enterprise | Terlalu banyak file, kurang cocok untuk deadline |

### ✅ REKOMENDASI: GetX

**Kenapa GetX untuk project ini:**
- 1 package handle routing + state + dependency injection
- Tidak perlu `BuildContext` untuk navigate (`Get.to(...)`)
- Controller dipisah dari UI → kode lebih bersih
- Sangat mudah dipelajari dalam 1-2 hari
- `Obx(() => ...)` reactive, lebih efisien dari `setState`

```yaml
# pubspec.yaml — tambahkan:
get: ^4.6.6
google_fonts: ^6.2.1
flutter_map: ^7.0.0
latlong2: ^0.9.0
cached_network_image: ^3.4.0
intl: ^0.19.0
```

### Struktur GetX yang Dipakai

```
Untuk TIAP tab/fitur:
├── controller/
│   ├── auth_controller.dart        ← login, session, biometric
│   ├── paket_controller.dart       ← fetch, filter, update status paket
│   ├── conversion_controller.dart  ← currency + time logic
│   └── ai_controller.dart          ← chat history, send message
└── screen/
    ├── paket_saya_page.dart        ← hanya UI, pakai Get.find<PaketController>()
    └── ...
```

### Contoh Migrasi: setState → GetX

**Sebelum (setState):**
```dart
class _InventoryPageState extends State<InventoryPage> {
  bool _isLoading = false;
  String _searchQuery = '';

  void _fetchData() async {
    setState(() => _isLoading = true);
    // fetch...
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? CircularProgressIndicator() : ListView(...);
  }
}
```

**Sesudah (GetX):**
```dart
// paket_controller.dart
class PaketController extends GetxController {
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final paketList = <Map<String, dynamic>>[].obs;

  Future<void> fetchPaket(int idKurir) async {
    isLoading.value = true;
    // fetch...
    isLoading.value = false;
  }
}

// paket_saya_page.dart
class PaketSayaPage extends StatelessWidget { // ← StateLESS sekarang
  final c = Get.find<PaketController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => c.isLoading.value
      ? CircularProgressIndicator()
      : ListView(...)
    );
  }
}
```

---

## 3. SETUP PACKAGE & THEME {#setup}

### `main.dart` — Setup Material 3 + GetX

```dart
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... hive init, notif init (sama seperti sebelumnya)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(                    // ← ganti MaterialApp → GetMaterialApp
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,            // ← theme terpusat
      home: const LoginPage(),
    );
  }
}
```

### `theme/app_theme.dart` — Theme Terpusat (BARU)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,                           // ← AKTIFKAN M3
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      // --- TYPOGRAPHY ---
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        labelSmall: GoogleFonts.poppins(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),

      // --- CARDS ---
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // --- ELEVATED BUTTON ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // --- INPUT FIELD ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 14),
      ),

      // --- CHIP ---
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // --- APP BAR ---
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}
```

### `theme/app_color.dart` — Update Warna

```dart
class AppColors {
  // Primary — Slate Blue (tetap, ini bagus)
  static const Color primary     = Color(0xFF475569);
  static const Color primaryDark = Color(0xFF334155);
  static const Color primaryLight= Color(0xFFEFF6FF);

  // Accent — Lebih hidup untuk CTA
  static const Color accent      = Color(0xFF3B82F6);   // blue-500

  // Status paket — lebih vivid
  static const Color statusGudang  = Color(0xFF3B82F6); // biru
  static const Color statusAntar   = Color(0xFFF59E0B); // amber
  static const Color statusSelesai = Color(0xFF10B981); // hijau

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Neutral
  static const Color bg            = Color(0xFFF8FAFC);
  static const Color cardBg        = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border        = Color(0xFFE2E8F0);
  static const Color divider       = Color(0xFFF1F5F9);

  // Nav bar active tab color
  static const Color navActive = Color(0xFF3B82F6);
}
```

---

## 4. DESIGN SYSTEM {#design-system}

### Prinsip Visual

```
Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40, 48px
Border radius: 8 (kecil), 12 (medium), 16 (card), 20 (bottom sheet), 28+ (modal)
Shadow: elevation 0 + border OR elevation 2 (jangan mix)
Typography: Poppins — 28/24/20/18/16/14/12/11
```

### Status Badge Pattern

```dart
// lib/widget/status_badge.dart — dipakai di mana-mana
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      'Di Gudang'      => (AppColors.statusGudang,  Icons.warehouse_outlined,   'Di Gudang'),
      'Sedang Diantar' => (AppColors.statusAntar,   Icons.directions_bike,      'Diantar'),
      'Selesai'        => (AppColors.statusSelesai, Icons.check_circle_outline, 'Selesai'),
      _                => (AppColors.textSecondary, Icons.help_outline,         status),
    };

    final (color, icon, label) = config;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
          style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
```

---

## 5. BOTTOM NAVIGATION — REKOMENDASI STRUKTUR {#bottom-nav}

### Gunakan `NavigationBar` (Material 3), bukan `BottomNavigationBar`

```
BottomNavigationBar (M2)  →  NavigationBar (M3)
- label selalu muncul kecil   - label muncul di tab aktif saja (lebih clean)
- selectedItemColor manual    - ikutin ColorScheme otomatis
- tidak ada background blur   - ada animasi indikator pill
```

### Struktur 5 Tab (sesuai KONSEP_FINAL)

```
╔══════════════════════════════════════════════════════╗
║  📦 Paket   🗺️ Navigasi  💱 Konversi  🤖 AI  👤 Profil ║
╚══════════════════════════════════════════════════════╝
    Tab 1       Tab 2        Tab 3      Tab 4    Tab 5
```

```dart
// menu_page.dart — VERSI BARU
import 'package:get/get.dart';

class MenuPage extends StatelessWidget {
  MenuPage({super.key});

  final _selectedIndex = 0.obs;

  // Username & id dari argument GetX
  final String username = Get.arguments?['username'] ?? '';
  final int    idKurir  = Get.arguments?['id'] ?? 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PaketSayaPage(idKurir: idKurir),
      const NavigasiPage(),
      const ConversionPage(),
      const AiHelperPage(),
      ProfilePage(username: username),
    ];

    return Obx(() => Scaffold(
      body: pages[_selectedIndex.value],
      bottomNavigationBar: NavigationBar(
        // Styling
        backgroundColor: Colors.white,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.accent.withOpacity(0.12),
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,

        // State
        selectedIndex: _selectedIndex.value,
        onDestinationSelected: (i) => _selectedIndex.value = i,

        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,

        destinations: const [
          NavigationDestination(
            icon:          Icon(Icons.inventory_2_outlined),
            selectedIcon:  Icon(Icons.inventory_2),
            label: 'Paket',
          ),
          NavigationDestination(
            icon:          Icon(Icons.map_outlined),
            selectedIcon:  Icon(Icons.map),
            label: 'Navigasi',
          ),
          NavigationDestination(
            icon:          Icon(Icons.currency_exchange_outlined),
            selectedIcon:  Icon(Icons.currency_exchange),
            label: 'Konversi',
          ),
          NavigationDestination(
            icon:          Icon(Icons.smart_toy_outlined),
            selectedIcon:  Icon(Icons.smart_toy),
            label: 'AI Pintar',
          ),
          NavigationDestination(
            icon:          Icon(Icons.person_outline),
            selectedIcon:  Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    ));
  }
}
```

---

## 6. DI MANA MINI GAME? {#game-placement}

### ❌ Jangan bikin tab sendiri untuk game
5 tab sudah penuh dengan fitur inti. Game bukan core feature, jadi tidak perlu tab sendiri.

### ✅ Rekomendasi: Feature Cards di halaman Profil

```
╔═══════════════════════════════════════╗
║  👤  Ilham Cesario                    ║
║      Kurir · UPN Veteran Yogyakarta   ║
╠═══════════════════════════════════════╣
║  ✏️ Saran & Kesan TPM                 ║
╠═══════════════════════════════════════╣
║  🎮  Mini Game          📡 Sensor     ║ ← 2 kartu
║  Paket Jatuh            Uji Paket     ║
╠═══════════════════════════════════════╣
║  [LOGOUT]                             ║
╚═══════════════════════════════════════╝
```

**Kenapa ini bagus:**
- Game tetap mudah diakses (prominent card, bukan tombol kecil)
- Sensor page juga accessible
- Bottom nav tetap bersih
- 2 kolom card berdampingan — terasa seperti "bonus features"

```dart
// Bagian feature cards di profile_page.dart
Widget _buildFeatureSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fitur Tambahan',
          style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _FeatureCard(
            icon: Icons.videogame_asset_rounded,
            iconBg: Colors.purple.shade50,
            iconColor: Colors.purple,
            title: 'Mini Game',
            subtitle: 'Paket Jatuh',
            onTap: () => Get.to(() => const MiniGamePage()),
          )),
          const SizedBox(width: 12),
          Expanded(child: _FeatureCard(
            icon: Icons.sensors,
            iconBg: Colors.orange.shade50,
            iconColor: Colors.orange,
            title: 'Sensor',
            subtitle: 'Uji Kerapuhan',
            onTap: () => Get.to(() => const SensorPage()),
          )),
        ]),
      ],
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ]),
      ),
    );
  }
}
```

---

## 7. PANDUAN UI PER HALAMAN — MOBILE {#screens-mobile}

---

### 7.1 LOGIN PAGE

**Masalah saat ini:** Header terlalu basic, form field plain, tidak ada micro-interaction.

**Desain baru:**
```
╔═════════════════════════════╗
║  [warna primary solid]      ║  ← Tidak perlu SafeArea header besar
║  📦  Gudang Pintar          ║     Cukup compact, ratio 30:70
║  "Sistem Kurir Digital"     ║
╠═════════════════════════════╣ ← Wave clipper (pertahankan)
║                             ║
║  Selamat Datang 👋          ║  ← Greeting text, lebih personal
║  Masuk ke akun Anda         ║
║                             ║
║  ┌─────────────────────┐    ║
║  │ 👤 Username         │    ║
║  └─────────────────────┘    ║
║  ┌─────────────────────┐    ║
║  │ 🔒 Password     👁  │    ║
║  └─────────────────────┘    ║
║                             ║
║  [    MASUK    ]            ║  ← Full width, 52px height
║  [🖐 Masuk Biometrik]       ║  ← OutlinedButton, muncul kondisional
║                             ║
║  Belum punya akun? Daftar   ║
╚═════════════════════════════╝
```

```dart
// Perubahan utama di login_page.dart:

// 1. Header lebih compact
Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text('Gudang Pintar',
          style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
        Text('Sistem Kurir Digital',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.75), fontSize: 13)),
      ],
    ),
  );
}

// 2. Greeting di form
const Text('Selamat Datang 👋',
  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
const SizedBox(height: 4),
const Text('Masuk ke akun Anda untuk melanjutkan'),
const SizedBox(height: 28),

// 3. TextField pakai dekorasi dari theme (otomatis dari AppTheme)
// Tidak perlu dekorasi manual lagi
TextField(
  controller: _usernameController,
  decoration: const InputDecoration(
    labelText: 'Username',
    prefixIcon: Icon(Icons.person_outline),
  ),
),
```

---

### 7.2 PAKET SAYA PAGE (Tab 1 — Inti App)

**Layout:**
```
╔═════════════════════════════════╗
║ Paket Saya     [🔄]            ║  ← App bar simple
║ kurir_budi · 3 paket aktif     ║
╠═════════════════════════════════╣
║ 🔍 Cari resi atau penerima...  ║  ← Search bar
╠═════════════════════════════════╣
║ [Semua 5] [Di Gudang 2] [Diantar 2] [Selesai 1] ║  ← Filter chips
╠═════════════════════════════════╣
║ ┌─────────────────────────────┐ ║
║ │ GPX-20260501          [●Di Gudang]│
║ │ 📦 Laptop Asus              │ ║
║ │ 👤 Dhimas Rizky             │ ║
║ │ 📍 Banguntapan, Bantul      │ ║
║ │              [Mulai Antar →] │ ║
║ └─────────────────────────────┘ ║
║ ┌─────────────────────────────┐ ║
║ │ GPX-20260502      [●Diantar]│ ║
║ │ ...                         │ ║
║ │              [Lihat Peta →] │ ║
║ └─────────────────────────────┘ ║
╚═════════════════════════════════╝
```

```dart
// Kerangka paket_saya_page.dart

class PaketSayaPage extends StatelessWidget {
  final int idKurir;
  const PaketSayaPage({super.key, required this.idKurir});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PaketController>();
    // ↑ panggil controller yg sudah di-init di main / menu_page

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // --- SLIVER APP BAR ---
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.white,
            title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paket Saya',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                Text('${c.paketList.length} paket ditugaskan',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            )),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => c.fetchPaket(idKurir),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Column(children: [
                // SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Obx(() => TextField(
                    onChanged: (v) => c.searchQuery.value = v,
                    decoration: InputDecoration(
                      hintText: 'Cari resi atau nama penerima...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: c.searchQuery.value.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close, size: 18),
                            onPressed: () => c.searchQuery.value = '')
                        : null,
                    ),
                  )),
                ),
                // FILTER CHIPS
                Obx(() => SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ['Semua', 'Di Gudang', 'Sedang Diantar', 'Selesai']
                      .map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: c.selectedFilter.value == status,
                          onSelected: (_) => c.selectedFilter.value = status,
                          selectedColor: AppColors.accent.withOpacity(0.15),
                          checkmarkColor: AppColors.accent,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: c.selectedFilter.value == status
                              ? AppColors.accent : AppColors.border),
                          labelStyle: TextStyle(
                            color: c.selectedFilter.value == status
                              ? AppColors.accent : AppColors.textSecondary,
                            fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      )).toList(),
                  ),
                )),
              ]),
            ),
          ),
        ],
        body: Obx(() {
          if (c.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c.filteredPaket.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: c.filteredPaket.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (_, i) => _PaketCard(paket: c.filteredPaket[i]),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Tidak ada paket', style: GoogleFonts.poppins(
          color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Paket yang ditugaskan akan muncul di sini',
          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

// Card paket
class _PaketCard extends StatelessWidget {
  final Map<String, dynamic> paket;
  const _PaketCard({required this.paket});

  @override
  Widget build(BuildContext context) {
    final status = paket['status'] ?? 'Di Gudang';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // HEADER: resi + badge
          Row(children: [
            Expanded(child: Text(paket['no_resi'] ?? '-',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 13,
                color: AppColors.primary, letterSpacing: 0.5))),
            StatusBadge(status: status),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // INFO ROWS
          _InfoRow(Icons.inventory_2_outlined,
            paket['deskripsi_barang'] ?? 'Tanpa deskripsi'),
          const SizedBox(height: 6),
          _InfoRow(Icons.person_outline, paket['nama_penerima'] ?? '-'),
          const SizedBox(height: 6),
          _InfoRow(Icons.location_on_outlined,
            paket['alamat_penerima'] ?? '-', maxLines: 2),
          const SizedBox(height: 12),
          // ACTION BUTTON
          if (status == 'Di Gudang')
            SizedBox(width: double.infinity, height: 40,
              child: ElevatedButton.icon(
                onPressed: () => Get.find<PaketController>()
                  .updateStatus(paket['no_resi'], 'Sedang Diantar'),
                icon: const Icon(Icons.delivery_dining, size: 16),
                label: const Text('Mulai Antar', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  backgroundColor: AppColors.statusAntar,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
              ))
          else if (status == 'Sedang Diantar')
            Row(children: [
              Expanded(child: SizedBox(height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(() => const NavigasiPage(),
                    arguments: paket),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Lihat Peta', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                ))),
              const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => Get.find<PaketController>()
                    .updateStatus(paket['no_resi'], 'Selesai'),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Selesai', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    backgroundColor: AppColors.statusSelesai,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                ))),
            ])
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  const _InfoRow(this.icon, this.text, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
        maxLines: maxLines, overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary))),
    ]);
  }
}
```

---

### 7.3 NAVIGASI PAGE (Tab 2 — LBS)

**Layout:**
```
╔═════════════════════════════════╗
║ ← Navigasi    [📍 Posisi Saya] ║
╠═════════════════════════════════╣
║                                 ║
║      [  PETA OPENSTREETMAP  ]   ║  ← Memakan 65% layar
║      📍 Kurir (biru)            ║
║      📌 Penerima (merah)        ║
║                                 ║
╠═════════════════════════════════╣
║ ┌─────────────────────────────┐ ║
║ │ 📦 GPX-20260502             │ ║
║ │ 👤 Andiya                   │ ║  ← Info card paket aktif
║ │ 📍 3.2 km · ~15 menit      │ ║
║ │   [BUKA DI GOOGLE MAPS] [✅ SAMPAI TUJUAN] │ ║
║ └─────────────────────────────┘ ║
╚═════════════════════════════════╝
```

```dart
// Kerangka navigasi_page.dart

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NavigasiPage extends StatelessWidget {
  const NavigasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<NavigasiController>();

    return Scaffold(
      body: Obx(() {
        final paket = c.paketAktif.value;

        return Stack(children: [
          // --- PETA (full screen) ---
          FlutterMap(
            mapController: c.mapController,
            options: MapOptions(
              initialCenter: c.kurirPosition.value ??
                const LatLng(-7.797068, 110.370529), // Yogya center default
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gudangpintar.app',
              ),
              if (c.kurirPosition.value != null && c.penerimPosition.value != null)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [c.kurirPosition.value!, c.penerimPosition.value!],
                    color: AppColors.accent.withOpacity(0.6),
                    strokeWidth: 3,
                  ),
                ]),
              MarkerLayer(markers: [
                if (c.kurirPosition.value != null)
                  Marker(
                    point: c.kurirPosition.value!,
                    child: const Icon(Icons.navigation, color: AppColors.accent, size: 32),
                  ),
                if (c.penerimPosition.value != null)
                  Marker(
                    point: c.penerimPosition.value!,
                    child: const Icon(Icons.location_pin, color: AppColors.error, size: 36),
                  ),
              ]),
            ],
          ),

          // --- INFO CARD DI BAWAH ---
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              padding: const EdgeInsets.all(20),
              child: paket == null
                ? _buildNoPaketState()
                : _buildPaketInfo(paket, c),
            ),
          ),

          // --- FAB KIRI ATAS: Kembali ke posisi kurir ---
          Positioned(
            top: 52, right: 16,
            child: FloatingActionButton.small(
              heroTag: 'centerBtn',
              backgroundColor: Colors.white,
              onPressed: c.centerToKurir,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _buildPaketInfo(Map paket, NavigasiController c) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Handle drag indicator
      Center(child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      )),
      const SizedBox(height: 16),
      // Paket info
      Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.statusAntar.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2_outlined,
            color: AppColors.statusAntar, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(paket['no_resi'] ?? '-',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
          Text('${paket['nama_penerima']} · ${paket['alamat_penerima']}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        ])),
      ]),
      const SizedBox(height: 8),
      // Jarak info
      Obx(() => c.distance.value > 0
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.route, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${c.distance.toStringAsFixed(1)} km · '
                '~${(c.distance.value * 3).round()} menit',
                style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
            ]),
          )
        : const SizedBox()),
      const SizedBox(height: 16),
      // Action buttons
      Row(children: [
        Expanded(child: SizedBox(height: 46,
          child: OutlinedButton.icon(
            onPressed: c.openGoogleMaps,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Google Maps'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textSecondary,
            ),
          ))),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 46,
          child: ElevatedButton.icon(
            onPressed: () => c.selesaikanPaket(paket['no_resi']),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Sampai Tujuan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusSelesai,
            ),
          ))),
      ]),
    ]);
  }

  Widget _buildNoPaketState() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.done_all, size: 48, color: AppColors.statusSelesai),
      const SizedBox(height: 8),
      Text('Tidak ada paket aktif',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      Text('Semua paket sudah selesai diantar 🎉',
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
    ]);
  }
}
```

---

### 7.4 AI HELPER PAGE (Tab 4 — LLM Chatbot)

**Layout:**
```
╔═════════════════════════════════╗
║ 🤖 AI Pintar                   ║
║ Asisten Kurir Digital          ║
╠═════════════════════════════════╣
║                                 ║
║  ┌───────────────────────────┐  ║
║  │ 🤖 Halo! Saya Pintar,    │  ║  ← Bubble AI (kiri)
║  │ asisten kurir digitalmu. │  ║
║  └───────────────────────────┘  ║
║                                 ║
║         ┌──────────────────┐    ║
║         │ Cuaca hari ini?  │    ║  ← Bubble User (kanan)
║         └──────────────────┘    ║
║  ┌───────────────────────────┐  ║
║  │ 🤖 Berdasarkan data      │  ║
║  │ cuaca terkini di ...      │  ║
║  └───────────────────────────┘  ║
║                                 ║
╠═════════════════════════════════╣
║ [Cuaca?] [Estimasi?] [Rute?]   ║  ← Quick reply chips
╠═════════════════════════════════╣
║ ┌──────────────────────┐  [▶]  ║  ← Input + send button
║ │ Tanya sesuatu...     │       ║
║ └──────────────────────┘       ║
╚═════════════════════════════════╝
```

```dart
// Kerangka ai_helper_page.dart

class AiHelperPage extends StatelessWidget {
  const AiHelperPage({super.key});

  static const _quickReplies = [
    '☁️ Cuaca hari ini?',
    '🕐 Estimasi waktu ke tujuan?',
    '💡 Tips pengiriman aman?',
    '🛣️ Kondisi lalu lintas?',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AiController>();
    final inputController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI Pintar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Obx(() => Text(
              c.isTyping.value ? 'sedang mengetik...' : 'Asisten Kurir Digital',
              style: TextStyle(
                fontSize: 11, color: AppColors.textSecondary,
                fontStyle: c.isTyping.value ? FontStyle.italic : FontStyle.normal),
            )),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: c.clearChat,
            tooltip: 'Hapus chat',
          ),
        ],
      ),
      body: Column(children: [
        // CHAT LIST
        Expanded(child: Obx(() => ListView.builder(
          controller: c.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: c.messages.length,
          itemBuilder: (_, i) => _ChatBubble(message: c.messages[i]),
        ))),

        // QUICK REPLIES
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickReplies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ActionChip(
              label: Text(_quickReplies[i],
                style: GoogleFonts.poppins(fontSize: 12)),
              onPressed: () => c.sendMessage(_quickReplies[i]),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // INPUT AREA
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(children: [
            Expanded(child: TextField(
              controller: inputController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Tanya sesuatu...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )),
            const SizedBox(width: 10),
            Obx(() => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton.small(
                heroTag: 'sendBtn',
                onPressed: c.isTyping.value
                  ? null
                  : () {
                    final text = inputController.text.trim();
                    if (text.isNotEmpty) {
                      c.sendMessage(text);
                      inputController.clear();
                    }
                  },
                backgroundColor: c.isTyping.value
                  ? AppColors.border : const Color(0xFF6366F1),
                child: Icon(
                  c.isTyping.value ? Icons.hourglass_empty : Icons.send_rounded,
                  color: Colors.white, size: 18),
              ),
            )),
          ]),
        ),
      ]),
    );
  }
}

// Chat Bubble
class _ChatBubble extends StatelessWidget {
  final Map<String, String> message; // {'role': 'user'/'model', 'text': '...'}
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
          boxShadow: isUser ? null : [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: Text(message['text'] ?? '',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.5,
          )),
      ),
    );
  }
}
```

---

### 7.5 PROFIL PAGE

**Layout:**
```
╔═════════════════════════════════╗
║  [header gradient background]   ║
║  ⊙ [foto profil 80px]           ║
║    Ilham Cesario Putra Wippri   ║
║    Kurir · ID #2                ║
╠═════════════════════════════════╣
║  ✏️ Saran & Kesan TPM           ║
║  [text area]      [Kirim →]     ║
╠═════════════════════════════════╣
║  Fitur Tambahan                 ║
║  ┌──────────────┐ ┌──────────┐  ║
║  │ 🎮 Mini Game │ │ 📡 Sensor │  ║
║  │ Paket Jatuh  │ │ Uji Paket │  ║
║  └──────────────┘ └──────────┘  ║
╠═════════════════════════════════╣
║  [🚪 Logout]                    ║
╚═════════════════════════════════╝
```

**Catatan penting untuk foto profil:**
- Gunakan `cached_network_image` (bukan `NetworkImage` langsung) agar ada placeholder loading
- Atau: simpan foto lokal, tampilkan dari asset/file
- Untuk tugas: foto statis dari URL/asset sudah cukup

---

### 7.6 MINI GAME PAGE — "Paket Jatuh"

**Layout:**
```
╔═════════════════════════════════╗
║ Paket Jatuh   SKOR: 50  ❤️❤️❤️  ║
║               ⏱️ 25s            ║
╠═════════════════════════════════╣
║                                 ║
║  [📦]    [📦]         [📦]     ║  ← Paket jatuh animasi
║                                 ║
║                                 ║
║                                 ║
║              [🏃]               ║  ← Kurir (gerak dgn gyroscope)
╠═════════════════════════════════╣
║  ↔️ Miringkan HP untuk bergerak ║
║  📳 Jangan shake keras!         ║
╚═════════════════════════════════╝
```

**Mekanisme sensor (sesuai KONSEP_FINAL):**
- **Gyroscope Y-axis** → geser kurir kiri/kanan
- **Accelerometer magnitude > 20** → SHAKE = game over / nyawa berkurang

---

## 8. PANDUAN UI — WEB ADMIN {#screens-web}

Web admin sudah ada di `Backend/admin/index.html` tapi perlu dipercantik.

### Stack Rekomendasi Web Admin
```
Tetap: HTML + CSS + Vanilla JS (sesuai KONSEP_FINAL — "Simple saja gausah ribet")
Tambahkan: Tailwind CSS via CDN (tidak perlu build step, GRATIS)
```

### Setup Tailwind via CDN
```html
<!-- Tambahkan di <head> -->
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    theme: {
      extend: {
        colors: {
          primary: '#475569',
          accent: '#3B82F6',
        }
      }
    }
  }
</script>
```

### Layout Web Admin Baru
```
╔═════════════════════════════════════════════════════╗
║ 🏭 Gudang Pintar — Admin Panel                     ║  ← navbar fixed top
╠══════════════╦══════════════════════════════════════╣
║ SIDEBAR      ║  KONTEN UTAMA                        ║
║ ─────────    ║                                      ║
║ 📦 Paket     ║  ┌──────┐ ┌──────┐ ┌──────┐         ║
║ 👤 Kurir     ║  │ 5    │ │ 2    │ │ 1    │         ║  ← stat cards
║ 🏪 Gudang    ║  │Total │ │Antar │ │Selesai│        ║
║              ║  └──────┘ └──────┘ └──────┘         ║
║              ║                                      ║
║              ║  [+ Tambah Paket]                    ║
║              ║                                      ║
║              ║  Tabel paket dengan status badge      ║
╚══════════════╩══════════════════════════════════════╝
```

### `index.html` Versi Baru (Struktur)

```html
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Gudang Pintar Admin</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-slate-50 font-sans">

  <!-- NAVBAR -->
  <nav class="fixed top-0 left-0 right-0 bg-slate-700 text-white h-14 flex items-center px-6 z-50 shadow">
    <span class="text-lg font-bold">🏭 Gudang Pintar</span>
    <span class="ml-3 text-slate-300 text-sm">Panel Admin</span>
  </nav>

  <div class="flex pt-14 min-h-screen">
    <!-- SIDEBAR -->
    <aside class="w-52 bg-white border-r border-slate-200 fixed top-14 bottom-0">
      <nav class="p-4 space-y-1">
        <a href="#paket" onclick="showTab('paket')"
           class="sidebar-link flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-100 transition">
          📦 Manajemen Paket
        </a>
        <a href="#kurir" onclick="showTab('kurir')"
           class="sidebar-link flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-100 transition">
          👤 Data Kurir
        </a>
        <a href="#gudang" onclick="showTab('gudang')"
           class="sidebar-link flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-100 transition">
          🏪 Gudang
        </a>
      </nav>
    </aside>

    <!-- MAIN CONTENT -->
    <main class="ml-52 flex-1 p-6">

      <!-- STAT CARDS -->
      <div class="grid grid-cols-3 gap-4 mb-6" id="stats">
        <!-- diisi JS -->
      </div>

      <!-- TAB: PAKET -->
      <div id="tab-paket">
        <!-- Form tambah paket -->
        <div class="bg-white rounded-2xl border border-slate-200 p-6 mb-6">
          <h2 class="font-semibold text-slate-700 mb-4">➕ Tambah Paket Baru</h2>
          <div class="grid grid-cols-2 gap-4">
            <input id="no_resi" placeholder="No Resi"
              class="border border-slate-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
            <!-- ... input lainnya ... -->
          </div>
          <button onclick="tambahPaket()"
            class="mt-4 bg-slate-700 text-white px-6 py-2.5 rounded-xl text-sm font-medium hover:bg-slate-800 transition">
            Simpan Paket
          </button>
        </div>

        <!-- Tabel paket -->
        <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden">
          <div class="flex items-center justify-between p-4 border-b border-slate-100">
            <h2 class="font-semibold text-slate-700">📦 Daftar Paket</h2>
            <button onclick="loadPaket()"
              class="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1">
              🔄 Refresh
            </button>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-slate-50 text-slate-500 uppercase text-xs">
                <tr>
                  <th class="px-4 py-3 text-left">Resi</th>
                  <th class="px-4 py-3 text-left">Barang</th>
                  <th class="px-4 py-3 text-left">Penerima</th>
                  <th class="px-4 py-3 text-left">Kurir</th>
                  <th class="px-4 py-3 text-left">Status</th>
                  <th class="px-4 py-3 text-left">Aksi</th>
                </tr>
              </thead>
              <tbody id="tabel-paket" class="divide-y divide-slate-100">
                <tr><td colspan="6" class="text-center py-8 text-slate-400">Memuat...</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

    </main>
  </div>

  <script>
    // Badge HTML helper
    function statusBadge(status) {
      const map = {
        'Di Gudang':      'bg-blue-100 text-blue-700',
        'Sedang Diantar': 'bg-amber-100 text-amber-700',
        'Selesai':        'bg-emerald-100 text-emerald-700',
      };
      const cls = map[status] || 'bg-gray-100 text-gray-600';
      return `<span class="px-2.5 py-1 rounded-full text-xs font-semibold ${cls}">${status}</span>`;
    }

    async function loadPaket() {
      const r = await fetch('../api/get_paket.php');
      const d = await r.json();
      const tbody = document.getElementById('tabel-paket');

      if (!d.data.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center py-8 text-slate-400">Belum ada paket</td></tr>';
        return;
      }

      tbody.innerHTML = d.data.map(p => `
        <tr class="hover:bg-slate-50 transition">
          <td class="px-4 py-3 font-mono font-medium text-slate-800">${p.no_resi}</td>
          <td class="px-4 py-3 text-slate-600">${p.deskripsi_barang || '-'}</td>
          <td class="px-4 py-3">
            <div class="font-medium text-slate-800">${p.nama_penerima}</div>
            <div class="text-xs text-slate-400 truncate max-w-40">${p.alamat_penerima}</div>
          </td>
          <td class="px-4 py-3 text-slate-600">${p.id_kurir ? 'Kurir #' + p.id_kurir : '<span class="text-amber-500">Belum</span>'}</td>
          <td class="px-4 py-3">${statusBadge(p.status)}</td>
          <td class="px-4 py-3">
            <button onclick="assignKurir(${p.id}, '${p.no_resi}')"
              class="bg-blue-600 text-white px-3 py-1.5 rounded-lg text-xs font-medium hover:bg-blue-700 transition">
              Assign
            </button>
          </td>
        </tr>`).join('');

      // Update stat cards
      const total  = d.data.length;
      const antar  = d.data.filter(p => p.status === 'Sedang Diantar').length;
      const selesai = d.data.filter(p => p.status === 'Selesai').length;
      renderStats(total, antar, selesai);
    }

    function renderStats(total, antar, selesai) {
      document.getElementById('stats').innerHTML = `
        ${statCard('📦', 'Total Paket', total, 'slate')}
        ${statCard('🚴', 'Sedang Diantar', antar, 'amber')}
        ${statCard('✅', 'Selesai', selesai, 'emerald')}
      `;
    }

    function statCard(icon, label, value, color) {
      return `
        <div class="bg-white rounded-2xl border border-slate-200 p-5">
          <div class="text-2xl mb-2">${icon}</div>
          <div class="text-2xl font-bold text-${color}-600">${value}</div>
          <div class="text-sm text-slate-500 mt-1">${label}</div>
        </div>`;
    }

    loadPaket();
  </script>
</body>
</html>
```

---

## 9. REUSABLE WIDGET LIBRARY {#widgets}

Buat folder `lib/widget/` dengan file-file ini:

```
lib/widget/
├── status_badge.dart          ← ✅ sudah dijelaskan di atas
├── app_card.dart              ← wrapper card standar
├── section_header.dart        ← judul section dengan optional action button
├── empty_state.dart           ← tampilan kosong yang konsisten
├── loading_overlay.dart       ← full screen loading semi-transparent
└── info_snackbar.dart         ← helper snackbar success/error/warning
```

```dart
// lib/widget/info_snackbar.dart
class AppSnackbar {
  static void success(String message) => Get.snackbar(
    'Berhasil', message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.success,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    duration: const Duration(seconds: 2),
  );

  static void error(String message) => Get.snackbar(
    'Error', message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.error,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
    icon: const Icon(Icons.error_outline, color: Colors.white),
  );
}

// Pakai di controller:
// AppSnackbar.success('Status paket berhasil diupdate!');
// AppSnackbar.error('Gagal terhubung ke server');
```

```dart
// lib/widget/section_header.dart
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ])),
        if (action != null) action!,
      ]),
    );
  }
}
```

---

## CHECKLIST IMPLEMENTASI UI

```
SETUP
[ ] Tambah get, google_fonts, flutter_map, latlong2, cached_network_image ke pubspec.yaml
[ ] Buat app_theme.dart dengan Material 3 + Poppins
[ ] Update app_color.dart
[ ] Ganti MaterialApp → GetMaterialApp di main.dart

NAVIGATION
[ ] Ganti BottomNavigationBar → NavigationBar (M3) di menu_page.dart
[ ] Sesuaikan 5 tab dengan KONSEP_FINAL

MOBILE SCREENS
[ ] Revamp login_page.dart (header compact, M3 form)
[ ] Buat paket_saya_page.dart + PaketController
[ ] Buat navigasi_page.dart + NavigasiController
[ ] Revamp conversion_page.dart (live API)
[ ] Buat ai_helper_page.dart + AiController
[ ] Revamp profile_page.dart (2-column feature cards)
[ ] Rebuild mini_game_page.dart (Paket Jatuh + Gyroscope)

WIDGETS
[ ] StatusBadge
[ ] AppSnackbar
[ ] SectionHeader
[ ] EmptyState

WEB ADMIN
[ ] Tambah Tailwind CDN ke index.html
[ ] Redesign layout dengan sidebar + stat cards
[ ] Perbaiki tabel dengan status badge berwarna
```

---

*Guide ini mencakup semua perubahan UI frontend yang dibutuhkan untuk membuat Gudang Pintar terlihat modern, konsisten, dan sesuai KONSEP_FINAL. Semua tools yang disebutkan (GetX, Google Fonts, flutter_map, Tailwind CDN) adalah gratis dan open source.*
