import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/draft_transaction.dart';
import '../../utils/app_strings.dart';
import '../sheets/add_transaction_sheet.dart';

class TransactionReviewDialog extends StatefulWidget {
  final List<DraftTransaction> drafts;
  final String language;
  final Function() onTransactionSaved;

  const TransactionReviewDialog({
    super.key,
    required this.drafts,
    required this.language,
    required this.onTransactionSaved,
  });

  @override
  State<TransactionReviewDialog> createState() => _TransactionReviewDialogState();
}

class _TransactionReviewDialogState extends State<TransactionReviewDialog> {
  late List<DraftTransaction> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = List.from(widget.drafts);
  }

  void _processTransaction(int index) {
    final draft = _drafts[index];
    final tx = draft.model;
    
    // Determine if income based on type
    final isIncome = tx.type == 'income' || tx.type == 'loan_taken'; // simplified check

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => AddTransactionSheet(
        isIncome: isIncome,
        currentLanguage: widget.language,
        transaction: tx,
        originalPhrase: draft.originalPhrase, // Pass to Sheet for learning
        onTransactionAdded: () {
          // Called when user successfully saves
          widget.onTransactionSaved();
          setState(() {
            _drafts.removeAt(index);
          });
          if (_drafts.isEmpty) {
            Navigator.of(context).pop(); // Close dialog if all done
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppStrings.get(widget.language, 'review_transactions'),
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _drafts.isEmpty
            ? const SizedBox.shrink()
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _drafts.length,
                itemBuilder: (context, index) {
                  final draft = _drafts[index];
                  final tx = draft.model;
                  final isExpense = tx.type == 'expense';
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
                        child: Icon(
                          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isExpense ? Colors.red : Colors.green,
                          size: 16,
                        ),
                      ),
                      title: Text(tx.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${tx.category} • ৳${NumberFormat("#,##0").format(tx.amount)}',
                         style: GoogleFonts.outfit(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
                        onPressed: () => _processTransaction(index),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.get(widget.language, 'close'), style: GoogleFonts.outfit(color: Colors.grey)),
        ),
      ],
    );
  }
}
