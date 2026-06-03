import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tugas_akhir/constants/api_constants.dart';

class KurirTransitController extends GetxController {
  var paketList = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  Future<void> fetchPaketTransit(int idKurirTransit) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final url = Uri.parse('${ApiConstants.getPaketTransit}?id_kurir_transit=$idKurirTransit');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        paketList.value = List<Map<String, dynamic>>.from(data['data']);
      } else {
        errorMessage.value = data['message'] ?? 'Gagal memuat data';
      }
    } catch (e) {
      errorMessage.value = 'Gagal terhubung ke server';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateStatus(String noResi, String statusBaru) async {
    try {
      final url = Uri.parse(ApiConstants.updateStatus);
      final response = await http.post(url, body: {
        'no_resi': noResi,
        'status': statusBaru,
      }).timeout(const Duration(seconds: 10));
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      return false;
    }
  }
}
