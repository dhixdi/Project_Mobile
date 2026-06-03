import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:tugas_akhir/constants/api_constants.dart';
import 'package:tugas_akhir/widget/info_snackbar.dart';

class PaketController extends GetxController {
  final isLoading = false.obs;
  final paketList = <Map<String, dynamic>>[].obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'Semua'.obs;

  List<Map<String, dynamic>> get filteredPaket {
    var result = paketList.toList();
    if (selectedFilter.value != 'Semua') {
      result = result.where((p) => p['status'] == selectedFilter.value).toList();
    }
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((p) {
        return (p['no_resi']?.toString() ?? '').toLowerCase().contains(q) ||
            (p['nama_penerima']?.toString() ?? '').toLowerCase().contains(q) ||
            (p['alamat_penerima']?.toString() ?? '').toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  Future<void> fetchPaket(int idKurir) async {
    isLoading.value = true;
    try {
      final url = Uri.parse('${ApiConstants.getPaketKurir}?id_kurir=$idKurir');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final List rawList = data['data'] ?? [];
        paketList.value = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
        _saveToCache();
      }
    } catch (e) {
      _loadFromCache();
      AppSnackbar.error('Gagal terhubung ke server. Menampilkan data cache.');
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFromCache() {
    try {
      var box = Hive.box('paketBox');
      if (box.isNotEmpty) {
        paketList.value = box.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {}
  }

  void _saveToCache() {
    try {
      var box = Hive.box('paketBox');
      box.clear();
      for (var item in paketList) {
        box.put(item['no_resi'], item);
      }
    } catch (_) {}
  }

  Future<void> updateStatus(String noResi, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.updateStatus),
        body: {'no_resi': noResi, 'status': newStatus},
      ).timeout(const Duration(seconds: 10));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final index = paketList.indexWhere((p) => p['no_resi'] == noResi);
        if (index != -1) {
          paketList[index] = {...paketList[index], 'status': newStatus};
          paketList.refresh();
          _saveToCache();
        }
        AppSnackbar.success('Status paket $noResi → "$newStatus"');
      } else {
        AppSnackbar.error(data['message'] ?? 'Gagal update status');
      }
    } catch (e) {
      AppSnackbar.error('Gagal terhubung ke server');
    }
  }
}
