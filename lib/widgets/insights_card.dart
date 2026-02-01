import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../services/gemini_service.dart';
import '../utils/app_strings.dart';

class InsightsCard extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String currentLanguage;

  const InsightsCard({
    super.key,
    required this.transactions,
    required this.currentLanguage,
  });

  @override
  State<InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<InsightsCard> {
  bool _isLoading = false;
  Map<String, String>? _advice;

  Future<void> _analyze() async {
    if (widget.transactions.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    final result = await GeminiService.instance.getFinancialAdvice(widget.transactions);
    
    if (mounted) {
      setState(() {
         _advice = result;
         _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var lang = widget.currentLanguage;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF), // Light Purple
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology, color: Color(0xFF9333EA)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.get(lang, 'ai_insights'),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              if (_advice == null && !_isLoading)
                ElevatedButton(
                  onPressed: _analyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    AppStrings.get(lang, 'analyze'),
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.get(lang, 'analyzing'),
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          if (_advice != null) ...[
            const SizedBox(height: 20),
            
            // Good Job Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7), // Light Green
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   const Icon(Icons.thumb_up, color: Color(0xFF166534), size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(AppStrings.get(lang, 'good_job'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF166534))),
                         Text(_advice!['good'] ?? '', style: GoogleFonts.outfit(color: const Color(0xFF14532D))),
                       ],
                     ),
                   )
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // Tip Section
            Container(
               padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // Light Amber
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   const Icon(Icons.lightbulb, color: Color(0xFFB45309), size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(AppStrings.get(lang, 'tips'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFFB45309))),
                         Text(_advice!['tip'] ?? '', style: GoogleFonts.outfit(color: const Color(0xFF78350F))),
                       ],
                     ),
                   )
                ],
              ),
            ),
            
            // Refresh Button (Small)
            Center(
              child: TextButton(
                onPressed: _analyze, 
                child: const Icon(Icons.refresh, color: Colors.grey, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
