import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_strings.dart';

class BalanceCard extends StatelessWidget {
  final Map<String, double> summary;
  final String language;

  const BalanceCard({super.key, required this.summary, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E), // Dark card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.get(language, 'total_balance'),
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '৳ ${NumberFormat('#,##0').format(summary['balance'])}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                label: AppStrings.get(language, 'income'),
                amount: '৳ ${NumberFormat('#,##0').format(summary['income'])}',
                color: const Color(0xFF22C55E), // Green
                icon: Icons.arrow_downward,
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              _buildSummaryItem(
                label: AppStrings.get(language, 'expense'),
                amount: '৳ ${NumberFormat('#,##0').format(summary['expense'])}',
                color: const Color(0xFFEF4444), // Red
                icon: Icons.arrow_upward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
