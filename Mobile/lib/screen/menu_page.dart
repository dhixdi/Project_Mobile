import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tugas_akhir/controller/paket_controller.dart';
import 'package:tugas_akhir/controller/navigasi_controller.dart';
import 'package:tugas_akhir/controller/ai_controller.dart';
import 'package:tugas_akhir/controller/conversion_controller.dart';
import 'package:tugas_akhir/screen/paket_saya_page.dart';
import 'package:tugas_akhir/screen/navigasi_page.dart';
import 'package:tugas_akhir/screen/conversion_page.dart';
import 'package:tugas_akhir/screen/ai_helper_page.dart';
import 'package:tugas_akhir/screen/profile_page.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.username, required this.idKurir});
  final String username;
  final int idKurir;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize GetX controllers
    Get.put(PaketController());
    Get.put(NavigasiController());
    Get.put(AiController());
    Get.put(ConversionController());
    // Fetch paket for this courier
    Get.find<PaketController>().fetchPaket(widget.idKurir);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PaketSayaPage(idKurir: widget.idKurir),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Paket',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Navigasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: 'Konversi',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Pintar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}