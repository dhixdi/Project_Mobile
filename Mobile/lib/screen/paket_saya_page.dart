import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tugas_akhir/controller/paket_controller.dart';
import 'package:tugas_akhir/screen/navigasi_page.dart';
import 'package:tugas_akhir/theme/app_color.dart';
import 'package:tugas_akhir/widget/status_badge.dart';

class PaketSayaPage extends StatelessWidget {
  final int idKurir;
  const PaketSayaPage({super.key, required this.idKurir});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PaketController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ctrl.fetchPaket(idKurir),
        child: CustomScrollView(
          slivers: [
            // APP BAR
            SliverAppBar(
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.inventory_2_rounded,
                            size: 28, color: AppColors.accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paket Saya',
                                style: GoogleFonts.poppins(
                                    fontSize: 22, fontWeight: FontWeight.w700)),
                            Obx(() => Text(
                                  '${ctrl.paketList.length} paket ditugaskan',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                )),
                          ],
                        ),
                      ),
                      Obx(() => ctrl.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.refresh_rounded,
                                  color: AppColors.accent),
                              onPressed: () => ctrl.fetchPaket(idKurir),
                            )),
                    ],
                  ),
                ),
              ),
            ),

            // SEARCH BAR
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  onChanged: (v) => ctrl.searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: 'Cari resi atau nama penerima...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ),

            // FILTER CHIPS
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: Obx(() => ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: ['Semua', 'Di Gudang', 'Sedang Diantar', 'Selesai']
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(f),
                                  selected: ctrl.selectedFilter.value == f,
                                  onSelected: (_) =>
                                      ctrl.selectedFilter.value = f,
                                  selectedColor:
                                      AppColors.accent.withValues(alpha: 0.15),
                                  checkmarkColor: AppColors.accent,
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: ctrl.selectedFilter.value == f
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ))
                          .toList(),
                    )),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // PAKET LIST
            Obx(() {
              final pakets = ctrl.filteredPaket;
              if (ctrl.isLoading.value && pakets.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (pakets.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Belum ada paket',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Tarik ke bawah untuk refresh',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _PaketCard(paket: pakets[index], ctrl: ctrl),
                  childCount: pakets.length,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ===== PAKET CARD =====
class _PaketCard extends StatelessWidget {
  final Map<String, dynamic> paket;
  final PaketController ctrl;
  const _PaketCard({required this.paket, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final status = paket['status'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Resi + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    paket['no_resi'] ?? '-',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            // Info rows
            _InfoRow(
                icon: Icons.description_outlined,
                text: paket['deskripsi_barang'] ?? 'Tanpa Deskripsi'),
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.person_outline,
                text: paket['nama_penerima'] ?? '-'),
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.location_on_outlined,
                text: paket['alamat_penerima'] ?? '-'),

            // Action buttons
            if (status == 'Di Gudang') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ctrl.updateStatus(paket['no_resi'], 'Sedang Diantar'),
                  icon: const Icon(Icons.directions_bike, size: 18),
                  label: const Text('Mulai Antar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (status == 'Sedang Diantar') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Get.to(() => const NavigasiPage(), arguments: paket),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Lihat Peta'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          ctrl.updateStatus(paket['no_resi'], 'Selesai'),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
      ),
    ]);
  }
}
