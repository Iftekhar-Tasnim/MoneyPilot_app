import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../screens/settings_screen.dart';
import '../widgets/add_transaction_sheet.dart';
import '../utils/app_strings.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> _transactions = [];
  Map<String, double> _summary = {'balance': 0, 'income': 0, 'expense': 0};
  bool _isLoading = true;
  String _currentLanguage = 'en'; // Default language
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _initVoice();
  }

  void _initVoice() async {
    await _voiceService.init();
    _voiceService.onStatusChanged = (status) {
      if (status == 'notListening' || status == 'done') {
         // Auto-close if we are supposedly listening but the service stopped
         if (mounted && _isListening && !_isProcessing) {
            setState(() => _isListening = false);
            if (Navigator.canPop(context)) { 
               Navigator.of(context).pop(); 
            }
         }
      }
    };
    _voiceService.onErrorChanged = (error) {
      if (mounted) {
         setState(() => _isListening = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
         );
         if (Navigator.canPop(context)) { 
             Navigator.of(context).pop(); 
         }
      }
    };
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final transactions = await DatabaseService.instance.readAllTransactions();
    final summary = await DatabaseService.instance.getSummary();
    setState(() {
      _transactions = transactions;
      _summary = summary;
      _isLoading = false;
    });
  }
  
  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'en' ? 'bn' : 'en';
    });
  }

  Future<void> _handleVoiceInput() async {
    if (_isListening || _isProcessing) {
      await _voiceService.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    
    // Show listening dialog
    showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(AppStrings.get(_currentLanguage, 'speak') + '...')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _voiceService.stop(); 
              // State update handled by listener or explicitly:
              if (mounted) setState(() => _isListening = false);
              Navigator.pop(ctx);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    ).then((_) {
       // Cleanup if dismissed by tap-out
       if (_isListening) {
         _voiceService.stop();
         setState(() => _isListening = false);
       }
    });

    final locale = _currentLanguage == 'bn' ? 'bn_BD' : 'en_US';

    await _voiceService.startListening(
      localeId: locale,
      onResult: (text) async {
        if (_isProcessing) return; 
        _isProcessing = true;
        
        await _voiceService.stop();

        if (mounted && _isListening) {
           Navigator.of(context).pop(); // Close listening dialog
        }
        
        if (mounted) setState(() => _isListening = false);
        
        if (text.isEmpty) {
          _isProcessing = false;
          return;
        }

        // Show processing dialog
        if (mounted) {
           showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const AlertDialog(
              content: Row(
                children: [
                   CircularProgressIndicator(),
                   SizedBox(width: 20),
                   Text('Processing...'),
                ],
              ),
            ),
          );
        }

        final data = await GeminiService.instance.parseTransaction(text);
        
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close processing dialog
        }

        if (data != null && mounted) {
          final tx = TransactionModel(
             title: data['title'] ?? 'Voice Entry',
             amount: (data['amount'] as num).toDouble(),
             date: DateTime.now(),
             type: (data['type'] ?? 'expense').toLowerCase(),
             category: data['category'] ?? 'Other',
          );

          await DatabaseService.instance.create(tx);
          _refreshData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction Added!'), backgroundColor: Colors.green),
          );
        } else if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not understand. Try again.'), backgroundColor: Colors.red),
            );
        }
        
        _isProcessing = false;
      },
    );
  }

  void _showAddTransactionSheet({required bool isIncome}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => AddTransactionSheet(
        isIncome: isIncome,
        currentLanguage: _currentLanguage,
        onTransactionAdded: _refreshData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Soft Web-like background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppStrings.get(_currentLanguage, 'app_title'),
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // Language Switcher
          GestureDetector(
            onTap: _toggleLanguage,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C1E).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(
                    _currentLanguage.toUpperCase(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.language, size: 16),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A1C1E)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(currentLanguage: _currentLanguage),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Content
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BalanceCard(summary: _summary, language: _currentLanguage),
                      const SizedBox(height: 24),
                      Text(
                        AppStrings.get(_currentLanguage, 'recent_transactions'),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TransactionList(transactions: _transactions, language: _currentLanguage),
                    ],
                  ),
                ),

                // Bottom Actions
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Income Button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7), // Light Green
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _showAddTransactionSheet(isIncome: true),
                          icon: const Icon(Icons.arrow_downward, color: Color(0xFF166534)), // Green arrow
                          tooltip: AppStrings.get(_currentLanguage, 'add_income'),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Expense Button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2), // Light Red
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _showAddTransactionSheet(isIncome: false),
                          icon: const Icon(Icons.arrow_upward, color: Color(0xFFB91C1C)), // Red arrow
                          tooltip: AppStrings.get(_currentLanguage, 'add_expense'),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Voice Input Button (Main)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: FloatingActionButton.extended(
                          onPressed: _handleVoiceInput,
                          backgroundColor: const Color(0xFF4F46E5), // Indigo
                          icon: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
                          label: Text(
                            AppStrings.get(_currentLanguage, 'speak'),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

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

class TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String language;

  const TransactionList({super.key, required this.transactions, required this.language});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            AppStrings.get(language, 'no_transactions'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isExpense = tx.type == 'expense';
        final amount = tx.amount;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isExpense ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExpense ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined,
                  color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.getCategory(language, tx.category),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? "-" : "+"} ৳${NumberFormat('#,##0').format(amount)}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(tx.date),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
