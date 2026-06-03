import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppController {
  static const secureStorage = FlutterSecureStorage();

  // Fungsi untuk mengosongkan SEMUA data aplikasi (Debug/Reset Complete)
  static Future<void> clearAllUserData() async {
    try {
      // 1. Hapus Hive box untuk login & user data
      if (Hive.isBoxOpen('gudangPintarSecureBox')) {
        var secureBox = Hive.box('gudangPintarSecureBox');
        await secureBox.clear();
      }

      // 2. Hapus Hive box untuk item data
      if (Hive.isBoxOpen('items')) {
        var itemsBox = Hive.box('items');
        await itemsBox.clear();
      }

      // 3. Hapus encryption key dari secure storage
      await secureStorage.delete(key: 'hive_encryption_key');

      debugPrint('✓ Semua data berhasil dihapus (Hive + Secure Storage)');
    } catch (e) {
      debugPrint('✗ Terjadi kesalahan saat menghapus data: $e');
    }
  }
}