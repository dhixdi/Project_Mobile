import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tugas_akhir/controller/kurir_transit_controller.dart';
import 'package:tugas_akhir/widget/status_badge.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class KurirTransitPage extends StatelessWidget {
  final int idKurir;
  const KurirTransitPage({super.key, required this.idKurir});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KurirTransitController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Paket Transit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchPaketTransit(idKurir),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(controller.errorMessage.value, style: GoogleFonts.poppins(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => controller.fetchPaketTransit(idKurir), child: const Text('Coba Lagi')),
            ]),
          );
        }
        if (controller.paketList.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.border),
              const SizedBox(height: 16),
              Text('Belum ada paket transit', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
            ]),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchPaketTransit(idKurir),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.paketList.length,
            itemBuilder: (context, index) {
              final paket = controller.paketList[index];
              return _TransitCard(
                paket: paket,
                onAction: (status) async {
                  final success = await controller.updateStatus(paket['no_resi'], status);
                  if (success) {
                    Get.snackbar('Berhasil', 'Status diupdate ke: $status',
                        backgroundColor: AppColors.success, colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM);
                    controller.fetchPaketTransit(idKurir);
                  } else {
                    Get.snackbar('Gagal', 'Gagal update status',
                        backgroundColor: AppColors.error, colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM);
                  }
                },
              );
            },
          ),
        );
      }),
    );
  }
}

class _TransitCard extends StatelessWidget {
  final Map<String, dynamic> paket;
  final Function(String) onAction;

  const _TransitCard({required this.paket, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final status = paket['status'] ?? '';
    final gudangAsal = paket['nama_gudang_asal'] ?? 'Gudang Asal';
    final gudangTujuan = paket['nama_gudang_tujuan'] ?? 'Gudang Tujuan';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(paket['no_resi'] ?? '',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            if (paket['deskripsi_barang'] != null && paket['deskripsi_barang'].toString().isNotEmpty)
              Text(paket['deskripsi_barang'], style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            // Route visualization
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warehouse_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(gudangAsal, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500))),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.statusTransit),
                  const SizedBox(width: 8),
                  const Icon(Icons.store_outlined, size: 18, color: AppColors.statusGudangTujuan),
                  const SizedBox(width: 8),
                  Expanded(child: Text(gudangTujuan, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action button based on status
            if (status == 'Di Gudang')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onAction('Transit Antargudang'),
                  icon: const Icon(Icons.local_shipping, size: 18),
                  label: Text('Mulai Kirim', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusTransit,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            if (status == 'Transit Antargudang')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onAction('Di Gudang Tujuan'),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text('Tiba di Gudang', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusGudangTujuan,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
