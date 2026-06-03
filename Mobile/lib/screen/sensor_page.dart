import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  // Variabel untuk menyimpan nilai sensor
  List<double>? _accelerometerValues;
  List<double>? _gyroscopeValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  // Status peringatan paket
  bool _isUpsideDown = false;
  bool _isShocked = false;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  void _startSensors() {
    // 1. Mendengarkan event dari ACCELEROMETER
    _streamSubscriptions.add(
      accelerometerEventStream().listen((AccelerometerEvent event) {
        if (!mounted) return;
        setState(() {
          _accelerometerValues = [event.x, event.y, event.z];
          
          // A. Deteksi Terbalik
          _isUpsideDown = event.z < -6.0;

          // B. Deteksi Benturan/Jatuh
          double magnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
          if (magnitude > 25.0) {
            _isShocked = true;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _isShocked = false);
            });
          }
        });
      }),
    );

    // 2. Mendengarkan event dari GYROSCOPE
    _streamSubscriptions.add(
      gyroscopeEventStream().listen((GyroscopeEvent event) {
        if (!mounted) return;
        setState(() {
          _gyroscopeValues = [event.x, event.y, event.z];
          
          // C. Deteksi Putaran/Terguling
          double rotationMagnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
          if (rotationMagnitude > 5.0) {
            _isSpinning = true;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _isSpinning = false);
            });
          }
        });
      }),
    );
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  // --- FUNGSI TRIK DEVELOPER (MOCK DATA) ---
  // Fungsi ini dipanggil jika tombol bug ditekan di emulator
  void _simulateEmulatorData() {
    setState(() {
      // Mengisi nilai null agar loading hilang
      _accelerometerValues = [15.0, 20.0, -8.0]; // Guncangan keras & terbalik
      _gyroscopeValues = [6.0, 0.0, 0.0];        // Putaran cepat
      
      _isShocked = true;
      _isSpinning = true;
      _isUpsideDown = true;

      // Kembalikan ke normal setelah 3 detik
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isShocked = false;
            _isSpinning = false;
            _isUpsideDown = false;
            // Angka gravitasi normal saat HP diam di meja
            _accelerometerValues = [0.0, 0.0, 9.8]; 
            _gyroscopeValues = [0.0, 0.0, 0.0];
          });
        }
      });
    });
  }

  bool get _isPackageSafe => !_isUpsideDown && !_isShocked && !_isSpinning;

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Mengganti SafeArea murni dengan Scaffold agar bisa pakai FAB
      body: SafeArea(
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
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.precision_manufacturing, size: 32, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uji Kerapuhan Paket',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Simulasi Hardware Sensor',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- STATUS INDIKATOR UTAMA ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isPackageSafe ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isPackageSafe ? Colors.green.shade300 : Colors.red.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isPackageSafe ? Icons.check_circle : Icons.warning_rounded,
                      size: 64,
                      color: _isPackageSafe ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isPackageSafe ? 'PAKET AMAN' : 'PERINGATAN BAHAYA!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isPackageSafe ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- KARTU PERINGATAN ---
              if (_isUpsideDown) _buildWarningCard('Paket Terbalik (This Side Up!)', Icons.flip_camera_android),
              if (_isShocked) _buildWarningCard('Benturan/Guncangan Keras Terdeteksi!', Icons.vibration),
              if (_isSpinning) _buildWarningCard('Paket Terguling/Berputar Miring!', Icons.screen_rotation),

              const SizedBox(height: 16),

              // --- DATA SENSOR MENTAH ---
              const Text(
                'Detail Accelerometer (m/s²)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              _buildSensorDataCard(_accelerometerValues, Icons.speed, Colors.blue),
              
              const SizedBox(height: 24),

              const Text(
                'Detail Gyroscope (rad/s)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              _buildSensorDataCard(_gyroscopeValues, Icons.threesixty, Colors.purple),
            ],
          ),
        ),
      ),
      // --- TOMBOL DEBUG UNTUK EMULATOR ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateEmulatorData,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.bug_report, color: Colors.white),
        label: const Text('Simulasi (Emulator)', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Widget Pembantu: Kartu Data Sensor
  Widget _buildSensorDataCard(List<double>? values, IconData icon, Color color) {
    if (values == null) {
      return Center(
        child: Column(
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Menunggu hardware... (Tekan tombol Simulasi jika di Emulator)', style: TextStyle(fontSize: 12, color: Colors.grey))
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAxisData('X', values[0], color),
          _buildAxisData('Y', values[1], color),
          _buildAxisData('Z', values[2], color),
        ],
      ),
    );
  }

  Widget _buildAxisData(String axis, double value, Color color) {
    return Column(
      children: [
        Text(axis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWarningCard(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}