import 'package:local_auth/local_auth.dart';

/// Service untuk menangani autentikasi biometrik (fingerprint, face ID, dll).
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  factory BiometricAuthService() {
    return _instance;
  }

  BiometricAuthService._internal();

  /// Cek apakah perangkat mendukung biometrik dan biometrik sudah terdaftar.
  Future<bool> isBiometricAvailable() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      // Mengembalikan true jika perangkat mendukung setidaknya salah satunya
      return isDeviceSupported || canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Jalankan proses autentikasi biometrik dengan UI native.
  Future<bool> authenticate({required String reason}) async {
    try {
      // Menghapus stickyAuth dan hanya menggunakan parameter dasar yang pasti didukung
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // false agar sistem memperbolehkan fallback PIN/Pola
      );
    } catch (e) {
      rethrow;
    }
  }
}