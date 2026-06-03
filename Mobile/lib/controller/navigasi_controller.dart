import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tugas_akhir/controller/paket_controller.dart';
import 'package:tugas_akhir/widget/info_snackbar.dart';

class NavigasiController extends GetxController {
  final mapController = MapController();
  final kurirPosition = Rxn<LatLng>();
  final penerimaPosition = Rxn<LatLng>();
  final paketAktif = Rxn<Map<String, dynamic>>();
  final distance = 0.0.obs;
  final isLoadingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPaketAktif();
    getCurrentLocation();
  }

  void loadPaketAktif() {
    try {
      final paketCtrl = Get.find<PaketController>();
      final aktif = paketCtrl.paketList.firstWhereOrNull(
        (p) => p['status'] == 'Sedang Diantar',
      );
      if (aktif != null) {
        paketAktif.value = aktif;
        final lat = double.tryParse(aktif['lat_penerima']?.toString() ?? '');
        final lng = double.tryParse(aktif['lng_penerima']?.toString() ?? '');
        if (lat != null && lng != null) {
          penerimaPosition.value = LatLng(lat, lng);
        }
      }
    } catch (_) {}
  }

  Future<void> getCurrentLocation() async {
    isLoadingLocation.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppSnackbar.error('Izin lokasi diperlukan untuk navigasi');
        isLoadingLocation.value = false;
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      kurirPosition.value = LatLng(position.latitude, position.longitude);
      calculateDistance();
    } catch (e) {
      debugPrint('GPS Error: $e');
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void calculateDistance() {
    if (kurirPosition.value != null && penerimaPosition.value != null) {
      const Distance d = Distance();
      final km = d.as(
        LengthUnit.Kilometer,
        kurirPosition.value!,
        penerimaPosition.value!,
      );
      distance.value = km;
    }
  }

  void centerToKurir() {
    if (kurirPosition.value != null) {
      mapController.move(kurirPosition.value!, 15);
    }
  }

  Future<void> openGoogleMaps() async {
    if (penerimaPosition.value == null) return;
    final lat = penerimaPosition.value!.latitude;
    final lng = penerimaPosition.value!.longitude;
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> selesaikanPaket(String noResi) async {
    final paketCtrl = Get.find<PaketController>();
    await paketCtrl.updateStatus(noResi, 'Selesai');
    paketAktif.value = null;
    penerimaPosition.value = null;
    distance.value = 0.0;
    loadPaketAktif();
  }
}
