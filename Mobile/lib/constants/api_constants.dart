class ApiConstants {
  static const String baseUrl = 'http://192.168.18.106/gudang_pintar/api';
  static const String login         = '$baseUrl/login.php';
  static const String register      = '$baseUrl/register.php';
  static const String getPaketKurir = '$baseUrl/get_paket_kurir.php';
  static const String getPaket      = '$baseUrl/get_paket.php';
  static const String updateStatus  = '$baseUrl/update_status.php';
  static const String geminiProxy   = '$baseUrl/gemini_proxy.php';
  static const String getPaketTransit = '$baseUrl/get_paket_transit.php';
  static const String currencyApi   = 'https://api.exchangerate-api.com/v4/latest/IDR';
}
