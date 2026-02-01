import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/app_strings.dart';

class SpendingTrendChart extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String language;

  const SpendingTrendChart({
    super.key,
    required this.transactions,
    required this.language,
  });

  @override
  State<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends State<SpendingTrendChart> {
  bool _isWeekView = true; // Toggle state

  @override
  Widget build(BuildContext context) {
    // 1. Process Data based on Filter
    final now = DateTime.now();
    final daysToLookBack = _isWeekView ? 7 : 30;
    
    // Map of Date -> Total Amount
    final Map<int, double> dailyTotals = {};
    
    // Initialize with 0 for all days in range to show smooth line even if no spend
    for (int i = 0; i < daysToLookBack; i++) {
       final day = now.subtract(Duration(days: i));
       // Use day's milliseconds since epoch (at midnight) as key for simplicity in sorting
       final dateKey = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
       dailyTotals[dateKey] = 0.0;
    }

    final expenses = widget.transactions.where((tx) {
      if (tx.type != 'expense') return false;
      final diff = now.difference(tx.date).inDays;
      return diff < daysToLookBack && diff >= 0;
    });

    for (var tx in expenses) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day).millisecondsSinceEpoch;
      if (dailyTotals.containsKey(dateKey)) {
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + tx.amount;
      }
    }

    // Convert to FlSpots (X = index 0..N, Y = Amount)
    final sortedKeys = dailyTotals.keys.toList()..sort(); // Oldest first
    final List<FlSpot> spots = [];
    double maxAmount = 0;

    for (int i = 0; i < sortedKeys.length; i++) {
      final amount = dailyTotals[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), amount));
      if (amount > maxAmount) maxAmount = amount;
    }
    
    // Add some headroom to Y axis
    maxAmount = maxAmount == 0 ? 100 : maxAmount * 1.2;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(widget.language, 'spending_trend'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              // Filter Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildFilterButton(AppStrings.get(widget.language, 'this_week'), true),
                    _buildFilterButton(AppStrings.get(widget.language, 'this_month'), false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _isWeekView ? 1 : 5, // Show every day for week, every 5 days for month
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= sortedKeys.length) return const SizedBox.shrink();
                        
                        final date = DateTime.fromMillisecondsSinceEpoch(sortedKeys[index]);
                        final text = _isWeekView 
                            ? DateFormat('E').format(date) // Mon, Tue
                            : DateFormat('d').format(date); // 1, 6, 11
                            
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: GoogleFonts.outfit(
                              color: Colors.grey, 
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedKeys.length - 1).toDouble(),
                minY: 0,
                maxY: maxAmount,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF4F46E5),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: _isWeekView), // Only show dots on week view
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                   touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black87,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '৳${spot.y.toStringAsFixed(0)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      }
                   ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isWeek) {
    final isSelected = _isWeekView == isWeek;
    return GestureDetector(
      onTap: () => setState(() => _isWeekView = isWeek),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF1A1C1E) : Colors.grey,
          ),
        ),
      ),
    );
  }
}
