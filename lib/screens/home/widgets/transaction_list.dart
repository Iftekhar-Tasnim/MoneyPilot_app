import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../utils/app_strings.dart';

class TransactionList extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String language;
  final Function(TransactionModel) onTransactionTap;

  const TransactionList({
    super.key, 
    required this.transactions, 
    required this.language,
    required this.onTransactionTap,
  });

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            AppStrings.get(widget.language, 'no_transactions'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.transactions.length,
      itemBuilder: (context, index) {
        return TransactionItem(
          transaction: widget.transactions[index],
          language: widget.language,
          isExpanded: _expandedIndex == index,
          onTap: () {
            setState(() {
              if (_expandedIndex == index) {
                 _expandedIndex = null; // Collapse if already open
              } else {
                 _expandedIndex = index; // Expand new
              }
            });
          },
          onEditTap: () => widget.onTransactionTap(widget.transactions[index]),
        );
      },
    );
  }
}

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final String language;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onEditTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.language,
    required this.isExpanded,
    required this.onTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isExpense = tx.type == 'expense';
    final amount = tx.amount;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? const Color(0xFF4F46E5) : Colors.grey.withOpacity(0.1),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded ? [
             BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
          ] : [],
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
            
            // Amount or Edit Button
            if (isExpanded)
              IconButton(
                onPressed: onEditTap,
                icon: const Icon(Icons.edit, color: Color(0xFF4F46E5)),
                tooltip: 'Edit',
              )
            else
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
                    DateFormat('MMM d').format(tx.date), // Simplified date
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
