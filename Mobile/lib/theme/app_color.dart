import 'package:flutter/material.dart';

class AppColors {
  // Primary — Dark Navy Industrial
  static const Color primary      = Color(0xFF1E3A5F);
  static const Color primaryDark  = Color(0xFF152D4A);
  static const Color primaryLight = Color(0xFFE8F2FF);

  // Accent — Amber/Orange (Safety & Action)
  static const Color accent      = Color(0xFFF97316);
  static const Color accentLight = Color(0xFFFFF3E8);

  // Logistics Blue (Info & Secondary)
  static const Color logistics = Color(0xFF0EA5E9);

  // Status Paket (5 status)
  static const Color statusGudang       = Color(0xFF0EA5E9);
  static const Color statusTransit      = Color(0xFF8B5CF6);
  static const Color statusGudangTujuan = Color(0xFF6366F1);
  static const Color statusAntar        = Color(0xFFF97316);
  static const Color statusSelesai      = Color(0xFF10B981);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF97316);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF0EA5E9);

  // Neutral
  static const Color bg            = Color(0xFFF1F5F9);
  static const Color cardBg        = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border        = Color(0xFFE2E8F0);
  static const Color divider       = Color(0xFFF8FAFC);

  // Navigation
  static const Color navActive   = Color(0xFFF97316);
  static const Color navInactive = Color(0xFF94A3B8);

  // Hyperlink
  static const Color link = Color(0xFF0EA5E9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF0EA5E9)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  );
}
