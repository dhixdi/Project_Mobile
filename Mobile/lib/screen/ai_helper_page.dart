import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tugas_akhir/controller/ai_controller.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class AiHelperPage extends StatelessWidget {
  const AiHelperPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AiController>();
    final inputCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Pintar',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Obx(() => Text(
                  ctrl.isTyping.value ? 'Sedang mengetik...' : 'Gemini 2.0 Flash',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: ctrl.isTyping.value
                          ? AppColors.accent
                          : AppColors.textSecondary),
                )),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hapus Chat?'),
                content: const Text('Semua riwayat percakapan akan dihapus.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal')),
                  ElevatedButton(
                    onPressed: () {
                      ctrl.clearChat();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error, minimumSize: const Size(0, 40)),
                    child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // MESSAGES
        Expanded(
          child: Obx(() => ListView.builder(
                controller: ctrl.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: ctrl.messages.length + (ctrl.isTyping.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == ctrl.messages.length && ctrl.isTyping.value) {
                    return _TypingIndicator();
                  }
                  final msg = ctrl.messages[index];
                  final isUser = msg['role'] == 'user';
                  return _ChatBubble(
                    text: msg['text'] ?? '',
                    isUser: isUser,
                  );
                },
              )),
        ),

        // QUICK REPLIES
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              'Cuaca hari ini?',
              'Estimasi waktu?',
              'Tips pengiriman?',
              'Kondisi jalan?',
            ]
                .map((chip) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(chip,
                            style: GoogleFonts.poppins(fontSize: 12)),
                        backgroundColor: AppColors.cardBg,
                        side: const BorderSide(color: AppColors.border),
                        onPressed: () {
                          inputCtrl.text = chip;
                          ctrl.sendMessage(chip);
                          inputCtrl.clear();
                        },
                      ),
                    ))
                .toList(),
          ),
        ),

        // INPUT
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: inputCtrl,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  filled: true,
                  fillColor: AppColors.bg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (v) {
                  ctrl.sendMessage(v);
                  inputCtrl.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: () {
                ctrl.sendMessage(inputCtrl.text);
                inputCtrl.clear();
              },
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          Text('Sedang mengetik...',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
