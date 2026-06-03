import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tugas_akhir/controller/paket_controller.dart';
import 'package:tugas_akhir/controller/navigasi_controller.dart';
import 'package:tugas_akhir/controller/ai_controller.dart';
import 'package:tugas_akhir/controller/conversion_controller.dart';
import 'package:tugas_akhir/controller/kurir_transit_controller.dart';
import 'package:tugas_akhir/screen/paket_saya_page.dart';
import 'package:tugas_akhir/screen/kurir_transit_page.dart';
import 'package:tugas_akhir/screen/navigasi_page.dart';
import 'package:tugas_akhir/screen/conversion_page.dart';
import 'package:tugas_akhir/screen/ai_helper_page.dart';
import 'package:tugas_akhir/screen/profile_page.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.username, required this.idKurir, required this.role});
  final String username;
  final int idKurir;
  final String role;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.put(PaketController());
    Get.put(NavigasiController());
    Get.put(AiController());
    Get.put(ConversionController());
    if (widget.role == 'kurir_transit') {
      Get.put(KurirTransitController());
      Get.find<KurirTransitController>().fetchPaketTransit(widget.idKurir);
    } else {
      Get.find<PaketController>().fetchPaket(widget.idKurir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTransit = widget.role == 'kurir_transit';
    
    final pages = [
      isTransit
          ? KurirTransitPage(idKurir: widget.idKurir)
          : PaketSayaPage(idKurir: widget.idKurir),
      const NavigasiPage(),
      const ConversionPage(),
      const AiHelperPage(),
      ProfilePage(username: widget.username),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.cardBg,
        height: 68,
        indicatorColor: AppColors.accent.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: isTransit ? 'Transit' : 'Paket',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Navigasi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: 'Konversi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Pintar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}