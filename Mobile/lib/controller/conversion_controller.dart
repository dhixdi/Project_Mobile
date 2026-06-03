import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tugas_akhir/constants/api_constants.dart';

class ConversionController extends GetxController {
  final isLoadingRates = false.obs;
  final exchangeRates = <String, double>{
    'IDR': 1.0,
    'USD': 16200.0,
    'EUR': 17500.0,
    'GBP': 20500.0,
    'JPY': 105.0,
    'CNY': 2230.0,
    'SGD': 11900.0,
    'AUD': 10500.0,
    'CAD': 11800.0,
    'CHF': 17800.0,
  }.obs;

  final lastUpdated = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLiveRates();
  }

  Future<void> fetchLiveRates() async {
    isLoadingRates.value = true;
    try {
      final url = Uri.parse(ApiConstants.currencyApi);
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        exchangeRates['USD'] =
            rates['USD'] != null ? 1 / (rates['USD'] as num).toDouble() : 16200.0;
        exchangeRates['EUR'] =
            rates['EUR'] != null ? 1 / (rates['EUR'] as num).toDouble() : 17500.0;
        exchangeRates['GBP'] =
            rates['GBP'] != null ? 1 / (rates['GBP'] as num).toDouble() : 20500.0;
        exchangeRates['JPY'] =
            rates['JPY'] != null ? 1 / (rates['JPY'] as num).toDouble() : 105.0;
        exchangeRates['CNY'] =
            rates['CNY'] != null ? 1 / (rates['CNY'] as num).toDouble() : 2230.0;
        exchangeRates['SGD'] =
            rates['SGD'] != null ? 1 / (rates['SGD'] as num).toDouble() : 11900.0;
        exchangeRates['AUD'] =
            rates['AUD'] != null ? 1 / (rates['AUD'] as num).toDouble() : 10500.0;
        exchangeRates['CAD'] =
            rates['CAD'] != null ? 1 / (rates['CAD'] as num).toDouble() : 11800.0;
        exchangeRates['CHF'] =
            rates['CHF'] != null ? 1 / (rates['CHF'] as num).toDouble() : 17800.0;
        exchangeRates.refresh();
        lastUpdated.value = DateTime.now().toString().substring(0, 16);
      }
    } catch (e) {
      // Keep hardcoded rates as fallback
    } finally {
      isLoadingRates.value = false;
    }
  }
}
