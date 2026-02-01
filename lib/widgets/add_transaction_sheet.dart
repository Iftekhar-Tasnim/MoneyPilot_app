import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../utils/app_strings.dart';

class AddTransactionSheet extends StatefulWidget {
  final bool isIncome;
  final String currentLanguage;
  final Function() onTransactionAdded;

  const AddTransactionSheet({
    super.key,
    required this.isIncome,
    required this.currentLanguage,
    required this.onTransactionAdded,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  
  // Predefined Categories
  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Business', 'Gift', 'Other'];
  final List<String> _expenseCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.isIncome ? _incomeCategories.first : _expenseCategories.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      final tx = TransactionModel(
        title: _titleController.text,
        amount: amount,
        date: _selectedDate,
        type: widget.isIncome ? 'income' : 'expense',
        category: _selectedCategory ?? 'Other',
      );

      await DatabaseService.instance.create(tx);
      widget.onTransactionAdded();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.isIncome;
    final lang = widget.currentLanguage;
    final primaryColor = isIncome ? const Color(0xFF166534) : const Color(0xFFB91C1C);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, 
        right: 20, 
        top: 20
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.get(lang, isIncome ? 'manual_input_income' : 'manual_input_expense'),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '৳ ',
                hintText: '0.00',
                labelText: AppStrings.get(lang, 'enter_amount'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              validator: (val) => val == null || val.isEmpty ? AppStrings.get(lang, 'enter_amount') : null,
            ),
            const SizedBox(height: 16),

            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppStrings.get(lang, 'description'),
                hintText: AppStrings.get(lang, isIncome ? 'hint_salary' : 'hint_grocery'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) => val == null || val.isEmpty ? AppStrings.get(lang, 'enter_description') : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Category Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: AppStrings.get(lang, 'category'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: (isIncome ? _incomeCategories : _expenseCategories)
                        .map((c) => DropdownMenuItem(
                          value: c, 
                          child: Text(AppStrings.getCategory(lang, c))
                        ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Date Picker
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppStrings.get(lang, 'date'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        DateFormat('MMM d').format(_selectedDate),
                        style: GoogleFonts.outfit(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppStrings.get(lang, 'save_transaction'),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
