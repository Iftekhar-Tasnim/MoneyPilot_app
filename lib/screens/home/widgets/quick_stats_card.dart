import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../utils/app_strings.dart';

class QuickStatsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String language;

  const QuickStatsCard({
    super.key,
    required this.transactions,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    double maxSpend = 0;
    double totalExpense = 0;
    
    // Simple logic: Look at last 30 days for stats
    final now = DateTime.now();
    final expenses = transactions.where((tx) {
        if (tx.type != 'expense') return false;
        final diff = now.difference(tx.date).inDays;
        return diff < 30;
    }).toList();

    if (expenses.isNotEmpty) {
       for (var tx in expenses) {
         if (tx.amount > maxSpend) maxSpend = tx.amount;
         totalExpense += tx.amount;
       }
    }

    // Average over 30 days (or days since first tx if less than 30? let's stick to 30 for simplicity of "Monthly context")
    // Or actually, let's do average of days that *had* spending? No, daily average usually means Total / TimePeriod.
    final dailyAvg = totalExpense / 30; // Last 30 days average

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            AppStrings.get(language, 'daily_avg'),
            '৳ ${NumberFormat('#,##0').format(dailyAvg)}',
            Icons.query_stats,
            const Color(0xFF0EA5E9),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            AppStrings.get(language, 'max_spend'),
            '৳ ${NumberFormat('#,##0').format(maxSpend)}',
            Icons.vertical_align_top,
            const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
