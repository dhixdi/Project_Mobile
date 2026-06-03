import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tugas_akhir/screen/login_page.dart';
import 'package:tugas_akhir/screen/mini_game_page.dart';
import 'package:tugas_akhir/screen/sensor_page.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER WITH GRADIENT
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(children: [
                CachedNetworkImage(
                  imageUrl:
                      'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 48,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.border,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.border,
                    child: Icon(Icons.person, size: 48, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Ilham Cesario Putra Wippri',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Kurir · $username',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white70)),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // SARAN & KESAN TPM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: AppColors.info, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saran & Kesan',
                                style: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            Text('Teknologi & Pemrograman Mobile',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Tuliskan kesan dan saran Anda selama mengikuti mata kuliah ini...',
                          hintStyle: GoogleFonts.poppins(fontSize: 13),
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Saran berhasil dikirim! Terima kasih.'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text('Kirim Saran'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FEATURE CARDS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.videogame_asset_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Mini Game',
                    subtitle: 'Paket Jatuh',
                    onTap: () => Get.to(() => const MiniGamePage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.sensors_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'Sensor',
                    subtitle: 'Uji Kerapuhan',
                    onTap: () => Get.to(() => const SensorPage()),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: Text('Logout',
                      style: GoogleFonts.poppins(
                          color: AppColors.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.offAll(() => const LoginPage());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(0, 40)),
            child:
                const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}