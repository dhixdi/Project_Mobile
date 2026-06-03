import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tugas_akhir/controller/navigasi_controller.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class NavigasiPage extends StatelessWidget {
  const NavigasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NavigasiController>();

    return Scaffold(
      body: Obx(() {
        // Empty state
        if (ctrl.paketAktif.value == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Belum ada paket aktif',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Mulai antarkan paket untuk melihat navigasi',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    ctrl.loadPaketAktif();
                    ctrl.getCurrentLocation();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        final paket = ctrl.paketAktif.value!;
        final defaultCenter =
            ctrl.kurirPosition.value ?? const LatLng(-7.7956, 110.3695);

        return Stack(
          children: [
            // MAP
            FlutterMap(
              mapController: ctrl.mapController,
              options: MapOptions(
                initialCenter: defaultCenter,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tugas_akhir',
                ),
                // Polyline
                if (ctrl.kurirPosition.value != null &&
                    ctrl.penerimaPosition.value != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          ctrl.kurirPosition.value!,
                          ctrl.penerimaPosition.value!,
                        ],
                        strokeWidth: 3,
                        color: AppColors.accent,
                        pattern: StrokePattern.dotted(),
                      ),
                    ],
                  ),
                // Markers
                MarkerLayer(
                  markers: [
                    if (ctrl.kurirPosition.value != null)
                      Marker(
                        point: ctrl.kurirPosition.value!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.navigation,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    if (ctrl.penerimaPosition.value != null)
                      Marker(
                        point: ctrl.penerimaPosition.value!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.location_pin,
                              color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // BACK BUTTON
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Get.back(),
                ),
              ),
            ),

            // FAB center to kurir
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: AppColors.accent),
                  onPressed: () => ctrl.centerToKurir(),
                ),
              ),
            ),

            // BOTTOM INFO CARD
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Resi
                    Text(paket['no_resi'] ?? '-',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    // Penerima
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(paket['nama_penerima'] ?? '-',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 4),
                    // Distance
                    Row(children: [
                      const Icon(Icons.straighten,
                          size: 15, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Obx(() => Text(
                            'Jarak: ${ctrl.distance.value.toStringAsFixed(1)} km',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent),
                          )),
                    ]),
                    const SizedBox(height: 16),
                    // Buttons
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ctrl.openGoogleMaps(),
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Google Maps'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ctrl
                              .selesaikanPaket(paket['no_resi'] ?? ''),
                          icon:
                              const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Sampai Tujuan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // Loading indicator
            if (ctrl.isLoadingLocation.value)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text('Mencari lokasi...',
                          style: GoogleFonts.poppins(fontSize: 12)),
                    ]),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
