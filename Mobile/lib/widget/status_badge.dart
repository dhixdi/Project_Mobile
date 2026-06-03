import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tugas_akhir/theme/app_color.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'Di Gudang':
        color = AppColors.statusGudang;
        icon = Icons.warehouse_outlined;
        label = 'Di Gudang';
        break;
      case 'Sedang Diantar':
        color = AppColors.statusAntar;
        icon = Icons.directions_bike;
        label = 'Diantar';
        break;
      case 'Selesai':
        color = AppColors.statusSelesai;
        icon = Icons.check_circle_outline;
        label = 'Selesai';
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.help_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
