import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({super.key});

  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage> {
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _lives = 3;
  int _timeLeft = 45;

  // Courier position (0.0 to 1.0)
  double _courierX = 0.5;
  final double _courierWidth = 0.15;

  // Falling packages
  final List<Map<String, double>> _fallingPackets = [];
  final Random _random = Random();

  // Timers & subscriptions
  Timer? _gameLoop;
  Timer? _countdown;
  Timer? _spawnTimer;
  StreamSubscription? _gyroSub;
  StreamSubscription? _accelSub;

  // Sensitivity
  final double _gyroSensitivity = 0.025;

  @override
  void dispose() {
    _stopGame();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _lives = 3;
      _timeLeft = 45;
      _courierX = 0.5;
      _fallingPackets.clear();
    });

    // Start sensors
    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!_isPlaying) return;
      setState(() {
        _courierX -= event.y * _gyroSensitivity;
        _courierX = _courierX.clamp(0.0, 1.0 - _courierWidth);
      });
    });

    _accelSub = accelerometerEventStream().listen((event) {
      if (!_isPlaying) return;
      double magnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 25) {
        _gameOver('HP terguncang terlalu keras! 📱💥');
      }
    });

    // Game loop ~60fps
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_isPlaying) return;
      _updateGame();
    });

    // Spawn packages
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_isPlaying) return;
      _spawnPacket();
    });

    // Countdown
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _gameOver('Waktu habis! ⏰');
      }
    });
  }

  void _spawnPacket() {
    final x = _random.nextDouble() * 0.85;
    final speed = 0.003 + _random.nextDouble() * 0.003;
    setState(() {
      _fallingPackets.add({'x': x, 'y': 0.0, 'speed': speed});
    });
  }

  void _updateGame() {
    setState(() {
      for (int i = _fallingPackets.length - 1; i >= 0; i--) {
        _fallingPackets[i]['y'] = _fallingPackets[i]['y']! + _fallingPackets[i]['speed']!;

        // Check catch (bottom area)
        if (_fallingPackets[i]['y']! > 0.82 && _fallingPackets[i]['y']! < 0.95) {
          double packetCenter = _fallingPackets[i]['x']! + 0.05;
          double courierCenter = _courierX + _courierWidth / 2;
          if ((packetCenter - courierCenter).abs() < _courierWidth * 0.7) {
            _score += 10;
            _fallingPackets.removeAt(i);
            continue;
          }
        }

        // Missed
        if (_fallingPackets[i]['y']! > 1.0) {
          _fallingPackets.removeAt(i);
          _lives--;
          if (_lives <= 0) {
            _gameOver('Nyawa habis! 💔');
          }
        }
      }
    });
  }

  void _gameOver(String reason) {
    _isPlaying = false;
    _isGameOver = true;
    _stopSensorsAndTimers();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Game Over!', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📦', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(reason, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text('SKOR AKHIR', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              Text('$_score', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('Keluar'),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _startGame(); },
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 42)),
            child: const Text('Main Lagi'),
          ),
        ],
      ),
    );
  }

  void _stopSensorsAndTimers() {
    _gyroSub?.cancel();
    _accelSub?.cancel();
    _gameLoop?.cancel();
    _countdown?.cancel();
    _spawnTimer?.cancel();
  }

  void _stopGame() {
    _isPlaying = false;
    _stopSensorsAndTimers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paket Jatuh', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          if (_isPlaying) ...[
            // Timer
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _timeLeft <= 10
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.timer, size: 16,
                    color: _timeLeft <= 10 ? AppColors.error : AppColors.accent),
                const SizedBox(width: 4),
                Text('${_timeLeft}s',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _timeLeft <= 10 ? AppColors.error : AppColors.accent)),
              ]),
            ),
            // Score
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('🏆 $_score',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            // Lives
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: List.generate(3, (i) => Text(
                    i < _lives ? '❤️' : '🖤',
                    style: const TextStyle(fontSize: 16))),
              ),
            ),
          ],
        ],
      ),
      body: _isPlaying ? _buildGameArea() : _buildStartScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📦', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('Paket Jatuh',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tangkap paket yang jatuh!',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _instructionRow('🎮', 'Miringkan HP ke kiri/kanan (Gyroscope)'),
              const SizedBox(height: 10),
              _instructionRow('📦', 'Tangkap paket = +10 poin'),
              const SizedBox(height: 10),
              _instructionRow('💔', 'Paket jatuh = -1 nyawa (3 total)'),
              const SizedBox(height: 10),
              _instructionRow('📱', 'Jangan guncang HP! (Accelerometer)'),
              const SizedBox(height: 10),
              _instructionRow('⏰', 'Waktu: 45 detik'),
            ]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Mulai Main',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
                backgroundColor: AppColors.accent,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _instructionRow(String emoji, String text) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Text(text,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary))),
    ]);
  }

  Widget _buildGameArea() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accent.withValues(alpha: 0.05),
                AppColors.bg,
              ],
            ),
          ),
        ),

        // Ground line
        Positioned(
          bottom: h * 0.08,
          left: 0,
          right: 0,
          child: Container(height: 2, color: AppColors.border),
        ),

        // Falling packages
        ..._fallingPackets.map((pkt) => Positioned(
              left: pkt['x']! * w,
              top: pkt['y']! * h,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning, width: 2),
                ),
                child: const Center(child: Text('📦', style: TextStyle(fontSize: 22))),
              ),
            )),

        // Courier
        Positioned(
          left: _courierX * w,
          bottom: h * 0.05,
          child: Container(
            width: _courierWidth * w,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(child: Text('🏃', style: TextStyle(fontSize: 24))),
          ),
        ),
      ]);
    });
  }
}