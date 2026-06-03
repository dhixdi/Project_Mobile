import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tugas_akhir/constants/api_constants.dart';

class AiController extends GetxController {
  final messages = <Map<String, String>>[].obs;
  final isTyping = false.obs;
  final scrollController = ScrollController();

  final List<Map<String, dynamic>> _apiHistory = [];

  @override
  void onInit() {
    super.onInit();
    _addWelcomeMessage();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _addWelcomeMessage() {
    messages.add({
      'role': 'model',
      'text':
          'Halo! 👋 Saya Pintar, asisten kurir digital Anda.\n\nSaya bisa membantu dengan:\n• Info cuaca di area pengiriman\n• Estimasi waktu tempuh\n• Tips pengiriman aman\n• Dan pertanyaan lainnya!\n\nAda yang bisa saya bantu?',
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isTyping.value) return;

    messages.add({'role': 'user', 'text': text});
    _apiHistory.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ]
    });
    _scrollToBottom();

    isTyping.value = true;

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.geminiProxy),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'contents': _apiHistory}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      String reply;

      if (data['candidates'] != null &&
          (data['candidates'] as List).isNotEmpty) {
        reply = data['candidates'][0]['content']['parts'][0]['text'] ??
            'Maaf, saya tidak bisa memproses permintaan ini.';
      } else if (data['error'] != null) {
        reply = 'Error: ${data['error']['message'] ?? 'Terjadi kesalahan'}';
      } else {
        reply = 'Maaf, saya tidak bisa memproses permintaan ini.';
      }

      messages.add({'role': 'model', 'text': reply});
      _apiHistory.add({
        'role': 'model',
        'parts': [
          {'text': reply}
        ]
      });
    } catch (e) {
      messages.add({
        'role': 'model',
        'text':
            'Maaf, saya tidak bisa terhubung ke server saat ini. Pastikan XAMPP menyala dan perangkat terhubung ke jaringan yang sama. 🔌',
      });
    } finally {
      isTyping.value = false;
      _scrollToBottom();
    }
  }

  void clearChat() {
    messages.clear();
    _apiHistory.clear();
    _addWelcomeMessage();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
