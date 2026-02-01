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
    setState(() {
      _loans = allTx.where((tx) => tx.type == 'loan_given' || tx.type == 'loan_taken').toList();
      _isLoading = false;
    });
  }

  Future<void> _addLoan(bool isGiven) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isGiven ? 'Lend Money (Given)' : 'Borrow Money (Taken)'), // Simplified for now, should use AppStrings
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '৳ '),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Person Name'),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty || nameController.text.isEmpty) return;
              final amount = double.tryParse(amountController.text) ?? 0;
              
              final tx = TransactionModel(
                title: '${nameController.text} ${noteController.text.isNotEmpty ? '(${noteController.text})' : ''}',
                amount: amount,
                date: DateTime.now(),
                type: isGiven ? 'loan_given' : 'loan_taken',
                category: 'loan',
              );
              
              await DatabaseService.instance.create(tx);
              _loadLoans();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _settleLoan(TransactionModel loan) async {
    // For now, just delete the loan. In future, we might mark as 'settled'.
    await DatabaseService.instance.delete(loan.id!);
    _loadLoans();
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Loan settled')),
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
      return Center(child: Text('No active loans', style: GoogleFonts.outfit(color: Colors.grey)));
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
