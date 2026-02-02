import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../utils/app_strings.dart';

class LoansScreen extends StatefulWidget {
  final String currentLanguage;

  const LoansScreen({super.key, required this.currentLanguage});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TransactionModel> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    final allTx = await DatabaseService.instance.readAllTransactions();
    
    // Logic: 
    // - Given loans are reduced by loan_recovery
    // - Taken loans are reduced by loan_repayment
    // We'll group by title to associate settlements with original loans.
    // Note: This assumes title is consistent (which we enforced in _settleLoan)
    
    final Map<String, double> netBalances = {};
    final Map<String, TransactionModel> originalLoans = {};

    for (var tx in allTx) {
      if (tx.category != 'loan') continue;

      // Strip " (Settled)" suffix for matching if it exists
      final baseTitle = tx.title.replaceFirst(' (Settled)', '');
      
      double amount = tx.amount;
      if (tx.type == 'loan_recovery' || tx.type == 'loan_repayment') {
        amount = -amount; // Settlements reduce the balance
      }

      netBalances[baseTitle] = (netBalances[baseTitle] ?? 0) + amount;
      
      // Keep track of one original transaction to use as a model for the list item
      if (tx.type == 'loan_given' || tx.type == 'loan_taken') {
        originalLoans[baseTitle] = tx;
      }
    }

    final List<TransactionModel> activeLoans = [];
    netBalances.forEach((title, balance) {
      if (balance.abs() > 0.01) { // Not fully settled
        final original = originalLoans[title];
        if (original != null) {
          activeLoans.add(TransactionModel(
            id: original.id,
            title: title,
            amount: balance,
            date: original.date,
            type: original.type,
            category: original.category,
          ));
        }
      }
    });

    setState(() {
      _loans = activeLoans;
      _isLoading = false;
    });
  }

  Future<void> _addLoan(bool isGiven) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final lang = widget.currentLanguage;
    final primaryColor = isGiven ? const Color(0xFF166534) : const Color(0xFFB91C1C);
    final backgroundColor = isGiven ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24, 
          right: 24, 
          top: 12
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isGiven ? AppStrings.get(lang, 'add_income') : AppStrings.get(lang, 'add_expense'), // Fallback labels
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1C1E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isGiven ? Icons.arrow_outward : Icons.arrow_downward,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Amount Input
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.outfit(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    prefixText: '৳ ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Colors.grey[300]),
                    filled: true,
                    fillColor: backgroundColor.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? AppStrings.get(lang, 'enter_amount') : null,
                ),
                const SizedBox(height: 24),

                // Name Input
                Text(
                  AppStrings.get(lang, 'category'), // Using category as a close match or I should add 'person_name'
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    hintText: 'Who are you dealing with?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (val) => val == null || val.isEmpty ? AppStrings.get(lang, 'enter_description') : null,
                ),
                const SizedBox(height: 20),

                // Note Input
                Text(
                  AppStrings.get(lang, 'description'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: noteController,
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    hintText: 'Add some details',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final amountValue = double.tryParse(amountController.text) ?? 0;
                        
                        final tx = TransactionModel(
                          title: '${nameController.text} ${noteController.text.isNotEmpty ? '(${noteController.text})' : ''}',
                          amount: amountValue,
                          date: DateTime.now(),
                          type: isGiven ? 'loan_given' : 'loan_taken',
                          category: 'loan',
                        );
                        
                        await DatabaseService.instance.create(tx);
                        _loadLoans();
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppStrings.get(lang, 'save_transaction'),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _settleLoan(TransactionModel loan) async {
    final isGiven = loan.type == 'loan_given';
    
    final settlement = TransactionModel(
      title: '${loan.title} (Settled)',
      amount: loan.amount, // Settle full amount for now
      date: DateTime.now(),
      type: isGiven ? 'loan_recovery' : 'loan_repayment',
      category: 'loan',
    );

    await DatabaseService.instance.create(settlement);
    _loadLoans();
    
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(AppStrings.get(widget.currentLanguage, 'loan_settled_msg')),
           backgroundColor: Colors.green,
         ),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.currentLanguage;
    final givenLoans = _loans.where((tx) => tx.type == 'loan_given').toList();
    final takenLoans = _loans.where((tx) => tx.type == 'loan_taken').toList();

    double totalGiven = givenLoans.fold(0, (sum, item) => sum + item.amount);
    double totalTaken = takenLoans.fold(0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          AppStrings.get(lang, 'loans'),
          style: GoogleFonts.outfit(color: const Color(0xFF1A1C1E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4F46E5),
          tabs: [
            Tab(text: AppStrings.get(lang, 'given')),
            Tab(text: AppStrings.get(lang, 'taken')),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildLoanList(givenLoans, totalGiven, true, lang),
              _buildLoanList(takenLoans, totalTaken, false, lang),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _addLoan(_tabController.index == 0);
        },
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.get(lang, 'add_loan')),
      ),
    );
  }

  Widget _buildLoanList(List<TransactionModel> loans, double total, bool isGiven, String lang) {
    if (loans.isEmpty) {
      return Center(child: Text(AppStrings.get(lang, 'loan_no_active'), style: GoogleFonts.outfit(color: Colors.grey)));
    }

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isGiven ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isGiven ? AppStrings.get(lang, 'total_given') : AppStrings.get(lang, 'total_taken'),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isGiven ? const Color(0xFF166534) : const Color(0xFF991B1B),
                ),
              ),
              Text(
                '৳ ${NumberFormat('#,##0').format(total)}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isGiven ? const Color(0xFF166534) : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isGiven ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isGiven ? Icons.arrow_outward : Icons.arrow_downward,
                        color: isGiven ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.title,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            DateFormat('MMM d, y').format(loan.date),
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳ ${NumberFormat('#,##0').format(loan.amount)}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _settleLoan(loan),
                          child: Text(
                            AppStrings.get(lang, 'settle'),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
