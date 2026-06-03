import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tugas_akhir/services/notification_services.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, required this.username});
  final String username;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<dynamic> _selectedKeys = {}; 
  bool _isLoading = false; // Untuk indikator loading API

  @override
  void initState() {
    super.initState();
    // Langsung tarik data dari MySQL saat halaman dibuka
    _fetchDataFromAPI();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FUNGSI BARU: Mengambil data dari API XAMPP
  Future<void> _fetchDataFromAPI() async {
    setState(() => _isLoading = true);
    try {
      // Menggunakan IP Wi-Fi laptopmu
      final url = Uri.parse('http://192.168.18.106/gudang_pintar/api/get_paket.php');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == 'success') {
          var box = Hive.box('inventoryBox');
          await box.clear(); // Bersihkan data lama agar sinkron dengan database

          List dataPaket = jsonResponse['data'];
          for (var item in dataPaket) {
            // Memasukkan data dari MySQL ke Hive
            await box.put(item['no_resi'], {
              'name': item['deskripsi_barang'] ?? 'Tanpa Nama',
              'stock': 1, // Default stok 1 per resi
              'no_resi': item['no_resi'],
              'penerima': item['nama_penerima'],
              'status_paket': item['status'], // Mengambil status dari Enum MySQL
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error Sinkronisasi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logika Menambah Stok
  void _increaseStock(dynamic key, Map data) {
    var box = Hive.box('inventoryBox');
    box.put(key, {
      ...data, // Simpan data lainnya (resi, penerima, dll)
      'stock': data['stock'] + 1
    });
  }

  // Logika Mengurangi Stok & Notifikasi[cite: 3]
  void _decreaseStock(dynamic key, Map data) {
    if (data['stock'] > 0) {
      var box = Hive.box('inventoryBox');
      int newStock = data['stock'] - 1;
      
      box.put(key, {
        ...data,
        'stock': newStock
      });

      if (newStock < 5) {
        NotificationService().showInstantNotification(
          title: '⚠️ Peringatan Stok Tipis!',
          body: 'Stok "${data['name']}" sisa $newStock.',
        );
      }
    }
  }

  void _deleteSelectedItems() {
    var box = Hive.box('inventoryBox');
    box.deleteAll(_selectedKeys);
    setState(() => _selectedKeys.clear());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header dengan Username[cite: 3]
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.warehouse, size: 40, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventaris Gudang',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('Admin: ${widget.username}', 
                        style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Tombol Refresh API
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: _fetchDataFromAPI,
                ),
                if (_selectedKeys.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSelectedItems,
                  ),
              ],
            ),
          ),

          // Search Bar[cite: 3]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari resi atau nama barang...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          if (_isLoading) const LinearProgressIndicator(),

          // Daftar Barang dari Hive ValueListenableBuilder[cite: 3]
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box('inventoryBox').listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty && !_isLoading) {
                  return const Center(child: Text('Gudang kosong (Database MySQL kosong).'));
                }

                // Filter Pencarian
                var filteredEntries = box.toMap().entries.where((entry) {
                  var itemData = entry.value as Map;
                  var searchBase = "${itemData['name']} ${itemData['no_resi']}".toLowerCase();
                  return searchBase.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    var key = filteredEntries[index].key;
                    var data = filteredEntries[index].value as Map;
                    bool isSelected = _selectedKeys.contains(key);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              value == true ? _selectedKeys.add(key) : _selectedKeys.remove(key);
                            });
                          },
                        ),
                        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resi: ${data['no_resi'] ?? '-'}'),
                            Text('Status: ${data['status_paket']}', 
                                 style: TextStyle(color: _getStatusColor(data['status_paket']), fontWeight: FontWeight.bold)),
                            Text('Stok: ${data['stock']}', 
                                 style: TextStyle(color: data['stock'] < 5 ? Colors.red : Colors.green)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                              onPressed: () => _decreaseStock(key, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: () => _increaseStock(key, data),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'Selesai') return Colors.green;
    if (status == 'Sedang Diantar') return Colors.orange;
    return Colors.blue;
  }
}