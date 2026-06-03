import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:tugas_akhir/theme/app_color.dart';

class ShippingPage extends StatefulWidget {
  const ShippingPage({super.key});

  @override
  State<ShippingPage> createState() => _ShippingPageState();
}

class _ShippingPageState extends State<ShippingPage> {
  bool _isLoading = false;
  String _locationMessage = "Tekan tombol di bawah untuk melacak lokasi armada.";
  
  // Data dari GPS
  double? _latitude;
  double? _longitude;

  // Data dari API Cuaca
  String _weatherStatus = "-";
  double _temperature = 0.0;
  double _windSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  // --- 1. LOGIKA LBS (Mendapatkan Koordinat GPS) ---
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // PERBAIKAN UX: Pesan ramah jika pengguna menolak izin pertama kali
        setState(() => _locationMessage = "Izin lokasi ditolak. Aplikasi Gudang Pintar butuh akses GPS untuk melacak posisi armada Anda.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // PERBAIKAN UX: Pesan ramah dan solusi jika izin diblokir permanen
      setState(() => _locationMessage = "Akses GPS diblokir permanen. Silakan buka Pengaturan HP Anda > Aplikasi > Izinkan akses Lokasi.");
      return;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationMessage = "Mendapatkan sinyal satelit GPS...";
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationMessage = "Lokasi berhasil dikunci!";
      });

      await _fetchWeatherData(position.latitude, position.longitude);

    } catch (e) {
      // PERBAIKAN UX: Menangani error saat GPS mati atau tidak ada sinyal
      setState(() {
        _locationMessage = "Sinyal GPS tidak ditemukan. Pastikan fitur Lokasi/GPS di HP Anda sudah menyala.\n\n(Kode Error: $e)";
        _isLoading = false;
      });
    }
  }

  // --- 2. LOGIKA API WEB SERVICE (Mendapatkan Data Cuaca) ---
  Future<void> _fetchWeatherData(double lat, double lon) async {
    setState(() {
      _locationMessage = "Menghubungi satelit cuaca internasional...";
    });

    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentWeather = data['current_weather'];

        setState(() {
          _temperature = currentWeather['temperature'];
          _windSpeed = currentWeather['windspeed'];
          
          int weatherCode = currentWeather['weathercode'];
          _weatherStatus = _translateWeatherCode(weatherCode);
          
          _locationMessage = "Data lokasi dan cuaca berhasil diperbarui secara real-time!";
          _isLoading = false;
        });
      } else {
        // Melempar error spesifik jika server API menolak (misal error 404/500)
        throw Exception('Server merespons dengan kode HTTP ${response.statusCode}');
      }
    } catch (e) {
      // PERBAIKAN UX: Menangani error saat HP tidak ada internet atau server API down
      setState(() {
        _locationMessage = "Sistem gagal mengambil data cuaca. Silakan periksa koneksi internet Anda atau coba beberapa saat lagi.\n\n(Detail Error: $e)";
        _isLoading = false;
      });
    }
  }

  String _translateWeatherCode(int code) {
    if (code == 0) return "Cerah (Clear sky)";
    if (code == 1 || code == 2 || code == 3) return "Berawan (Cloudy)";
    if (code >= 45 && code <= 48) return "Berkabut (Foggy)";
    if (code >= 51 && code <= 67) return "Hujan Ringan/Gerimis (Rain)";
    if (code >= 71 && code <= 77) return "Hujan Salju (Snow)";
    if (code >= 80 && code <= 82) return "Hujan Deras (Rain showers)";
    if (code >= 95 && code <= 99) return "Badai Petir (Thunderstorm)";
    return "Tidak Diketahui";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.local_shipping, size: 32, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pelacakan Armada',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Integrasi LBS & API Cuaca',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- TOMBOL AKSI UTAMA ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.my_location),
                label: Text(
                  _isLoading ? 'Memproses Data...' : 'Lacak Lokasi Sekarang',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                _locationMessage,
                style: TextStyle(
                  fontSize: 13, 
                  color: _locationMessage.contains('Error') || _locationMessage.contains('ditolak') || _locationMessage.contains('diblokir') 
                      ? Colors.red.shade700 
                      : Colors.grey.shade600,
                  fontStyle: FontStyle.italic
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // --- KARTU LBS (KOORDINAT GPS) ---
            if (_latitude != null && _longitude != null) ...[
              _buildModernCard(
                title: 'Data Lokasi (LBS)',
                icon: Icons.gps_fixed,
                iconColor: Colors.redAccent,
                children: [
                  _buildDataRow('Latitude', _latitude.toString()),
                  const Divider(height: 24),
                  _buildDataRow('Longitude', _longitude.toString()),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Text('💡 Koordinat ini dikirim ke server API cuaca secara real-time.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  )
                ],
              ),
              const SizedBox(height: 24),
            ],

            // --- KARTU API CUACA ---
            if (_latitude != null) ...[
              _buildModernCard(
                title: 'Data Cuaca (Web Service API)',
                icon: Icons.cloud_outlined,
                iconColor: Colors.lightBlue,
                children: [
                  _buildDataRow('Suhu Lingkungan', '$_temperature °C'),
                  const Divider(height: 24),
                  _buildDataRow('Kondisi Cuaca', _weatherStatus),
                  const Divider(height: 24),
                  _buildDataRow('Kecepatan Angin', '$_windSpeed km/h'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- WIDGET PEMBANTU UI ---
  Widget _buildModernCard({required String title, required IconData icon, required Color iconColor, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
      ],
    );
  }
}