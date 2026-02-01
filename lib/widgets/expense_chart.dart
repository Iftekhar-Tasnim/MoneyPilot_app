import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../utils/app_strings.dart';

class ExpenseChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String language;

  const ExpenseChart({super.key, required this.transactions, required this.language});

  @override
  Widget build(BuildContext context) {
    
    // 1. Filter expenses
    final expenses = transactions.where((tx) => tx.type == 'expense').toList();
    
    if (expenses.isEmpty) return const SizedBox.shrink();

    // 2. Group by category
    final Map<String, double> categoryTotals = {};
    double totalExpense = 0;

    for (var tx in expenses) {
      final category = tx.category;
      final amount = tx.amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      totalExpense += amount;
    }

    // 3. Create Sections
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
    ];
    
    var index = 0;
    categoryTotals.forEach((category, amount) {
      final percentage = (amount / totalExpense) * 100;
      final isLarge = percentage > 15;
      
      sections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: isLarge ? 60 : 50,
          titleStyle: GoogleFonts.outfit(
            fontSize: isLarge ? 16 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _buildBadge(category, language),
          badgePositionPercentageOffset: .98,
        ),
      );
      index++;
    });

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.get(language, 'expenses_by_category'),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String category, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2),
        ]
      ),
      child: Text(
        AppStrings.getCategory(lang, category),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
