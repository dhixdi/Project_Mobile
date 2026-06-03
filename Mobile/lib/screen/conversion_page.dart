import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tugas_akhir/theme/app_color.dart';

class ConversionPage extends StatefulWidget {
  const ConversionPage({super.key});

  @override
  State<ConversionPage> createState() => _ConversionPageState();
}

class _ConversionPageState extends State<ConversionPage> {
  // === VARIABEL WAKTU ===
  late Timer _timer;
  DateTime _nowUtc = DateTime.now().toUtc();

  // Daftar lengkap zona waktu yang bisa dipilih
  final List<Map<String, dynamic>> _availableTimeZones = [
    {'name': 'London (GMT)', 'offset': 0},
    {'name': 'Jakarta (WIB)', 'offset': 7},
    {'name': 'Makassar (WITA)', 'offset': 8},
    {'name': 'Jayapura (WIT)', 'offset': 9},
    {'name': 'New York (EST)', 'offset': -5},
    {'name': 'Tokyo (JST)', 'offset': 9},
    {'name': 'Sydney (AEST)', 'offset': 10},
    {'name': 'Dubai (GST)', 'offset': 4},
  ];

  late List<Map<String, dynamic>> _selectedTimeZones;

  // === VARIABEL MATA UANG ===
  final TextEditingController _currencyController = TextEditingController();
  double _inputAmount = 0.0;
  String _baseCurrency = 'IDR';

  List<String> _targetCurrencies = ['USD', 'EUR', 'GBP'];

  final Map<String, double> _exchangeRates = {
    'IDR': 1.0,
    'USD': 16200.0,
    'EUR': 17500.0,
    'GBP': 20500.0,
    'JPY': 105.0,
    'CNY': 2230.0,
    'SGD': 11900.0,
    'AUD': 10500.0,
    'CAD': 11800.0,
    'CHF': 17800.0,
  };

  final Map<String, String> _currencySymbols = {
    'IDR': 'Rp', 'USD': '\$', 'EUR': '€', 'GBP': '£',
    'JPY': '¥', 'CNY': '¥', 'SGD': 'S\$', 'AUD': 'A\$',
    'CAD': 'C\$', 'CHF': 'Fr',
  };

  // Live rate state
  bool _isLoadingRates = false;
  String _ratesStatus = 'offline';

  @override
  void initState() {
    super.initState();
    _selectedTimeZones = [
      _availableTimeZones[0],
      _availableTimeZones[1],
      _availableTimeZones[2],
      _availableTimeZones[3],
    ];

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _nowUtc = DateTime.now().toUtc();
        });
      }
    });

    _fetchLiveRates();
  }

  Future<void> _fetchLiveRates() async {
    setState(() => _isLoadingRates = true);
    try {
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/IDR');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        setState(() {
          _exchangeRates['USD'] = 1 / (rates['USD'] as num).toDouble();
          _exchangeRates['EUR'] = 1 / (rates['EUR'] as num).toDouble();
          _exchangeRates['GBP'] = 1 / (rates['GBP'] as num).toDouble();
          _exchangeRates['JPY'] = 1 / (rates['JPY'] as num).toDouble();
          _exchangeRates['CNY'] = 1 / (rates['CNY'] as num).toDouble();
          _exchangeRates['SGD'] = 1 / (rates['SGD'] as num).toDouble();
          _exchangeRates['AUD'] = 1 / (rates['AUD'] as num).toDouble();
          _exchangeRates['CAD'] = 1 / (rates['CAD'] as num).toDouble();
          _exchangeRates['CHF'] = 1 / (rates['CHF'] as num).toDouble();
          _ratesStatus = 'live';
        });
      }
    } catch (e) {
      setState(() => _ratesStatus = 'offline');
    } finally {
      setState(() => _isLoadingRates = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _currencyController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    String s = time.second.toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  double _convertCurrency(String targetCurrency) {
    if (_inputAmount == 0.0) return 0.0;
    double valueInIdr = _inputAmount * _exchangeRates[_baseCurrency]!;
    return valueInIdr / _exchangeRates[targetCurrency]!;
  }

  // --- FUNGSI BARU: Pemisah Ribuan (Thousand Separator) ---
  // Berfungsi untuk mengubah angka panjang menjadi mudah dibaca (contoh: 1,000,000.00)
  String _formatCurrency(double value) {
    if (value == 0) return '0.00';
    String stringValue = value.toStringAsFixed(2);
    List<String> parts = stringValue.split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String mathFunc(Match match) => '${match[1]},';
    parts[0] = parts[0].replaceAllMapped(reg, mathFunc);
    return parts.join('.');
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.public, size: 32, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemasok Internasional',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Pantau jam & estimasi biaya impor',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- BAGIAN 1: KONVERSI WAKTU ---
            Row(
              children: [
                const Icon(Icons.access_time_filled, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Jam Operasional Global',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 105, 
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                DateTime localTime = _nowUtc.add(Duration(hours: _selectedTimeZones[index]['offset']));
                return _buildModernTimeCard(index, _formatTime(localTime));
              },
            ),

            const SizedBox(height: 40),

            // --- BAGIAN 2: KONVERSI MATA UANG ---
            Row(
              children: [
                const Icon(Icons.currency_exchange, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Kalkulator Biaya Impor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade800),
                ),
                const Spacer(),
                // Refresh button
                IconButton(
                  icon: _isLoadingRates
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 20, color: AppColors.primary),
                  onPressed: _isLoadingRates ? null : _fetchLiveRates,
                ),
              ],
            ),
            // Live status indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ratesStatus == 'live' ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _ratesStatus == 'live' ? 'Kurs live ✓' : 'Kurs offline (default)',
                  style: TextStyle(fontSize: 11, color: _ratesStatus == 'live' ? Colors.green : Colors.grey),
                ),
              ]),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // AREA INPUT (Base Currency)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _baseCurrency,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                              items: _exchangeRates.keys.map((String cur) {
                                return DropdownMenuItem<String>(
                                  value: cur,
                                  child: Text(cur),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _baseCurrency = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _currencyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              prefixText: '${_currencySymbols[_baseCurrency]} ',
                              prefixStyle: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            onChanged: (value) {
                              setState(() {
                                // Menghilangkan koma jika pengguna mengetik format manual
                                String cleanValue = value.replaceAll(',', '');
                                _inputAmount = double.tryParse(cleanValue) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.swap_vert_circle, color: Colors.grey, size: 28),
                  ),
                  
                  // AREA HASIL (3 Target Currencies)
                  ...List.generate(3, (index) {
                    return _buildModernResultRow(index);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PEMBANTU: KARTU WAKTU MODERN ---
  Widget _buildModernTimeCard(int index, String timeStr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 16),
                value: _selectedTimeZones[index],
                items: _availableTimeZones.map((tz) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: tz,
                    child: Text(
                      tz['name'],
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newTz) {
                  if (newTz != null) {
                    setState(() => _selectedTimeZones[index] = newTz);
                  }
                },
              ),
            ),
          ),
          
          Align(
            alignment: Alignment.centerRight,
            child: FittedBox( // PENCEGAH OVERFLOW PADA JAM (Jaga-jaga)
              fit: BoxFit.scaleDown,
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 1.0,
                  color: Colors.black87
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET PEMBANTU: BARIS HASIL MATA UANG MODERN ---
  Widget _buildModernResultRow(int index) {
    String targetCur = _targetCurrencies[index];
    double result = _convertCurrency(targetCur);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
                value: targetCur,
                items: _exchangeRates.keys.map((String cur) {
                  return DropdownMenuItem<String>(
                    value: cur,
                    child: Text(cur),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _targetCurrencies[index] = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // PERBAIKAN: Menggunakan FittedBox untuk mengecilkan angka panjang secara otomatis
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${_currencySymbols[targetCur]} ${_formatCurrency(result)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w800, 
                  color: AppColors.primary
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}