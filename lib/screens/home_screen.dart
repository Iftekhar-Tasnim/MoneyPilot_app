import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_settings/app_settings.dart';

import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../screens/settings_screen.dart';
import '../screens/all_transactions_screen.dart';
import '../widgets/sheets/add_transaction_sheet.dart';
import '../utils/app_strings.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import '../services/preprocessing/text_preprocessor.dart';
import '../services/rules/category_rules.dart';
import '../models/draft_transaction.dart';
import 'home/widgets/spending_trend_chart.dart';
import '../widgets/dialogs/transaction_review_dialog.dart';
import 'home/widgets/quick_stats_card.dart';
import 'income_screen.dart';
import 'loans_screen.dart';
import 'home/widgets/insights_card.dart';
import 'home/widgets/balance_card.dart';
import 'home/widgets/transaction_list.dart';
import 'notifications_screen.dart';

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
  final ValueNotifier<String?> _voiceWarningNotifier = ValueNotifier(null);
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initVoice();
  }

  @override
  void dispose() {
    _voiceWarningNotifier.dispose();
    super.dispose();
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

  Future<void> _loadData({bool showLoading = true}) async { 
    if (showLoading) setState(() => _isLoading = true);
    
    // Monthly Filter Logic
    final now = DateTime.now();
    final transactions = await DatabaseService.instance.getTransactionsForMonth(now.year, now.month);
    final summary = await DatabaseService.instance.getMonthlySummary(now.year, now.month);
    final unreadCount = await DatabaseService.instance.getUnreadNotificationCount();

    if (mounted) {
      setState(() {
        _transactions = transactions;
        _summary = summary;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    }
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
    _voiceWarningNotifier.value = null; // Reset warning
    
    // Show listening dialog
    showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.get(_currentLanguage, 'speak') + '...'),
                  ValueListenableBuilder<String?>(
                    valueListenable: _voiceWarningNotifier,
                    builder: (context, warning, _) {
                      if (warning == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          warning == 'online_mode_pack_missing' 
                              ? 'Online Mode: Offline pack missing' 
                              : warning,
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<String?>(
            valueListenable: _voiceWarningNotifier,
            builder: (context, warning, _) {
              if (warning == 'online_mode_pack_missing') {
                return TextButton(
                  onPressed: () {
                     // Open settings to help user install pack
                     // We use AppSettings.openAppSettings() as a generic fallback or openInputMethodSettings
                     AppSettings.openAppSettings(); 
                  },
                  child: const Text('Open Settings'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          TextButton(
            onPressed: () async {
              await _voiceService.stop(); 
              if (mounted) setState(() => _isListening = false);
              Navigator.pop(ctx);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    ).then((_) {
       if (_isListening) {
         _voiceService.stop();
         setState(() {
            _isListening = false;
         });
       }
    });

    // Pass simple code 'bn' or 'en' - service handles locale logic
    final warning = await _voiceService.startListening(
      languageCode: _currentLanguage,
      onResult: (text) async {
        if (_isProcessing) return; 
        _isProcessing = true;
        _voiceWarningNotifier.value = null; 
        
        await _voiceService.stop();

        if (mounted && _isListening) {
           Navigator.of(context).pop(); // Close listening dialog
        }
        
        if (mounted) setState(() => _isListening = false);
        
        if (text.isEmpty) {
          _isProcessing = false;
          return;
        }

        print('DEBUG: Recognized Voice Text: "$text"');

        // Show processing dialog
        if (mounted) {
           showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              content: Row(
                children: [
                   CircularProgressIndicator(),
                   SizedBox(width: 20),
                   Expanded(child: Text(AppStrings.get(_currentLanguage, 'processing'))),
                ],
              ),
            ),
          );
        }

        try {
          // Phase 2: Pre-processing
          final clauses = TextPreprocessor.instance.process(text);
          print('DEBUG: Clauses: $clauses');

          List<DraftTransaction> allDrafts = [];

          // Process each clause separately as per plan
          for (var clause in clauses) {
             try {
                // Phase 6: Check Correction Memory first
                final knownCategory = await DatabaseService.instance.getCorrection(clause);
                
                if (knownCategory != null) {
                  print('DEBUG: Found correction for "$clause" -> "$knownCategory"');
                  // We can skip AI entirely?
                  // Wait, we need the AMOUNT. 
                  // So we still need AI to parse amount/desc, but we force the category.
                  // OR we try to regex parse?
                  // Plan says "Apply correction memory mapping before AI next time".
                  // Simplest: Let AI parse, then override with known category.
                }

                final result = await GeminiService.instance.parseTransaction(clause);
                
                for (var txData in result) {
                  // Phase 6: Apply Correction Override
                  if (knownCategory != null) {
                    txData['category'] = knownCategory; // Override AI
                  } else {
                    // Phase 3: Rule-based Overrides (Only if unknown)
                    CategoryRules.apply(txData, clause);
                  }
                  
                  final tx = TransactionModel(
                     title: txData['title'] ?? 'Voice Entry',
                     amount: (txData['amount'] as num).toDouble(),
                     date: DateTime.now(),
                     type: (txData['type'] ?? 'expense').toLowerCase(),
                     category: txData['category'] ?? 'Other',
                  );
                  
                  allDrafts.add(DraftTransaction(model: tx, originalPhrase: clause));
                }
                
             } catch (e) {
                print('DEBUG: Error parsing clause "$clause": $e');
             }
          }
          
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context); // Close processing dialog
          }

          if (allDrafts.isNotEmpty && mounted) {
            
            if (allDrafts.length == 1) {
              final draft = allDrafts.first;
              // Phase 1: Disable Auto-Save. Show Edit Sheet instead.
              _showAddTransactionSheet(
                isIncome: draft.model.type == 'income',
                transaction: draft.model,
                originalPhrase: draft.originalPhrase, // Phase 6 support
              );
            } else {
               // Phase 5: Multiple Transactions Review
               showDialog(
                 context: context,
                 builder: (context) => TransactionReviewDialog(
                   drafts: allDrafts, 
                   language: _currentLanguage,
                   onTransactionSaved: () => _loadData(showLoading: false),
                 ),
               );
            }
            
          } else if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.get(_currentLanguage, 'could_not_understand')),
                  backgroundColor: Colors.red
                ),
              );
          }
        } catch (e) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context); // Close processing dialog
          }
          
          String errorMsg = AppStrings.get(_currentLanguage, 'voice_error'); // Default fallback if not specific
          if (e.toString().contains('Quota exceeded')) {
            errorMsg = AppStrings.get(_currentLanguage, 'api_limit_reached');
          } else if (e.toString().contains('API Key not found')) {
            errorMsg = AppStrings.get(_currentLanguage, 'api_key_missing');
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
          }
        }
        
        _isProcessing = false;
      },
    );

    // Update notifier if warning returned
    if (warning != null && mounted && _isListening) {
       _voiceWarningNotifier.value = warning;
    }
  }

  void _showAddTransactionSheet({bool isIncome = false, TransactionModel? transaction, String? originalPhrase}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => AddTransactionSheet(
        isIncome: isIncome,
        currentLanguage: _currentLanguage,
        onTransactionAdded: () => _loadData(showLoading: false),
        transaction: transaction,
        originalPhrase: originalPhrase,
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
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1C1E)),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(language: _currentLanguage),
                    ),
                  );
                  _loadData();
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB91C1C),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
                      
                      // Quick Stats
                      const SizedBox(height: 16),
                      QuickStatsCard(transactions: _transactions, language: _currentLanguage),

                      // AI Insights
                      const SizedBox(height: 16),
                      InsightsCard(transactions: _transactions, currentLanguage: _currentLanguage),

                      // Chart
                      SpendingTrendChart(transactions: _transactions, language: _currentLanguage),
                      
                      const SizedBox(height: 16),
                      
                      // Recent Transactions Header with See All
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.get(_currentLanguage, 'recent_transactions'),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                          if (_transactions.length > 5)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AllTransactionsScreen(
                                      language: _currentLanguage,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                AppStrings.get(_currentLanguage, 'see_all'),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Limited List
                      TransactionList(
                        transactions: _transactions.take(5).toList(), 
                        language: _currentLanguage,
                        onTransactionTap: (tx) => _showAddTransactionSheet(
                          isIncome: tx.type == 'income' || tx.type == 'loan_taken',
                          transaction: tx,
                        ),
                      ),
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

                      const SizedBox(width: 16),

                      // Loans Button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE), // Light Blue
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
                          onPressed: () async {
                             await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoansScreen(currentLanguage: _currentLanguage),
                              ),
                            );
                            _loadData();
                          },
                          icon: const Icon(Icons.handshake_outlined, color: Color(0xFF1E40AF)), // Blue Handshake
                          tooltip: AppStrings.get(_currentLanguage, 'loans'),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),

                      const SizedBox(width: 16),

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




