import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:tugas_akhir/screen/login_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tugas_akhir/constants/string_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tugas_akhir/services/notification_services.dart';
import 'package:tugas_akhir/theme/app_theme.dart';
import 'package:flutter/services.dart';

class HiveDatabaseHelper {
  static const secureStorage = FlutterSecureStorage();
  static const String _boxName = 'gudangPintarSecureBox';

  static Future<void> initHiveAndOpenBox() async {
    await Hive.initFlutter();

    String? encryptionKeyString = await secureStorage.read(
      key: 'hive_encryption_key',
    );

    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'hive_encryption_key',
        value: base64UrlEncode(key),
      );
      encryptionKeyString = base64UrlEncode(key);
    }

    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);

    await Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
    );

    debugPrint('Database Hive Terenkripsi Berhasil Dibuka!');
  }

  static Future<void> initNotifications() async {
    await NotificationService().init();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox(StringConstants.hiveBox);
  await HiveDatabaseHelper.initHiveAndOpenBox();
  await Hive.openBox('inventoryBox');
  await Hive.openBox('paketBox');
  await HiveDatabaseHelper.initNotifications();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
