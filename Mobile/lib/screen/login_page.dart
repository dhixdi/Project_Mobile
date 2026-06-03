import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:tugas_akhir/constants/api_constants.dart';
import 'package:tugas_akhir/screen/menu_page.dart';
import 'package:tugas_akhir/screen/register_page.dart';
import 'package:tugas_akhir/services/biometric_auth_service.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _lastLoginUsernameKey = 'last_login_username';

  final BiometricAuthService _biometricService = BiometricAuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricSupported = false;
  bool _isAuthenticatingBiometric = false;
  String? _storedUsername;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    final bool biometricAvailable = await _biometricService.isBiometricAvailable();
    final String? storedUsername = await _secureStorage.read(key: _lastLoginUsernameKey);

    if (!mounted) return;
    setState(() {
      _isBiometricSupported = biometricAvailable || storedUsername != null;
      _storedUsername = storedUsername;
    });
  }

  // LOGIKA LOGIN BARU: Nembak ke API XAMPP[cite: 1, 2]
  Future<void> _loginWithPassword() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Username dan password wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(ApiConstants.login);
      
      final response = await http.post(url, body: {
        'username': username,
        'password': password, 
      }).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        // Simpan data ke Hive lokal agar fitur biometrik tetap jalan[cite: 5]
        var box = Hive.box('gudangPintarSecureBox');
        await box.put(username, {
          'id': data['data']['id'],
          'username': data['data']['username'],
          'role': data['data']['role'],
        });

        await _rememberLastLoginUsername(username);
        
        if (!mounted) return;
        _goToMenuPage(username);
      } else {
        _showErrorSnackBar(data['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Gagal terhubung ke server. Pastikan XAMPP nyala dan satu Wi-Fi.');
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // LOGIN BIOMETRIK (Fingerprint)
  Future<void> _loginWithBiometrics() async {
    if (_isAuthenticatingBiometric) return;
    if (_storedUsername == null) {
      _showErrorSnackBar('Login password dulu sekali untuk aktifkan biometrik');
      return;
    }

    setState(() => _isAuthenticatingBiometric = true);

    try {
      final bool authenticated = await _biometricService.authenticate(
        reason: 'Masuk ke Gudang Pintar dengan sidik jari',
      );

      if (authenticated && mounted) {
        _goToMenuPage(_storedUsername!);
      }
    } catch (e) {
      _showErrorSnackBar('Gagal verifikasi biometrik: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticatingBiometric = false);
    }
  }

  Future<void> _rememberLastLoginUsername(String username) async {
    await _secureStorage.write(key: _lastLoginUsernameKey, value: username);
  }

  void _goToMenuPage(String username) {
    var box = Hive.box('gudangPintarSecureBox');
    var userData = box.get(username);
    int idKurir = userData?['id'] ?? 0;
    Get.offAll(() => MenuPage(username: username, idKurir: idKurir));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Expanded(flex: 1, child: _buildHeader()),
                  Expanded(flex: 3, child: _buildLoginForm()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 60),
        const SizedBox(height: 10),
        const Text('Gudang Pintar', 
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        Text('Server: 192.168.18.106', 
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildLoginForm() {
    return ClipPath(
      clipper: WaveClipperOne(reverse: true),
      child: Container(
        color: AppColors.bg,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text('Masuk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Akses database MySQL via XAMPP', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            
            // Tombol Login dengan Loading State
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWithPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('MASUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            
            if (_isBiometricSupported) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _loginWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Masuk dengan Biometrik'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
            
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Belum punya akun? "),
                TextButton(
                  onPressed: () => Get.to(() => const RegisterPage()),
                  child: const Text("Daftar Sekarang", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}