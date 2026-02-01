import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction_model.dart';
import '../utils/app_strings.dart';
import '../screens/home_screen.dart'; // For TransactionList widget re-use

import '../services/database_service.dart'; // Add import

class AllTransactionsScreen extends StatefulWidget {
  final String language;

  const AllTransactionsScreen({
    super.key,
    required this.language,
  });

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllHistory();
  }

  Future<void> _loadAllHistory() async {
    final data = await DatabaseService.instance.readAllTransactions();
    if (mounted) {
      setState(() {
        _allTransactions = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          AppStrings.get(widget.language, 'all_transactions'),
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: TransactionList(transactions: _allTransactions, language: widget.language),
          ),
    );
  }
}
