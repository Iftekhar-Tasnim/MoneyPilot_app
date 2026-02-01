import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../utils/app_strings.dart';

class IncomeScreen extends StatefulWidget {
  final String currentLanguage;
  final VoidCallback onIncomeAdded;

  const IncomeScreen({
    super.key,
    required this.currentLanguage,
    required this.onIncomeAdded,
  });

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'salary'; // Default
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    var lang = widget.currentLanguage;
    final categories = ['salary', 'bonus', 'other'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          AppStrings.get(lang, 'add_income'),
          style: GoogleFonts.outfit(color: const Color(0xFF1A1C1E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input
            Text(
              'Amount',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '৳ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Category Selection
             Text(
              'Source',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(AppStrings.get(lang, cat) == cat ? cat.toUpperCase() : AppStrings.get(lang, cat)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF22C55E).withOpacity(0.2),
                  labelStyle: GoogleFonts.outfit(
                    color: isSelected ? const Color(0xFF166534) : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
             const SizedBox(height: 20),

            // Date Selection
            Text(
              'Date',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
             const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM d, y').format(_selectedDate),
                      style: GoogleFonts.outfit(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

             const SizedBox(height: 20),
            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Save Income',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveIncome() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final tx = TransactionModel(
      title: _noteController.text.isEmpty ? AppStrings.get(widget.currentLanguage, _selectedCategory) : _noteController.text,
      amount: amount,
      date: _selectedDate,
      type: 'income',
      category: _selectedCategory,
    );

    await DatabaseService.instance.create(tx);
    widget.onIncomeAdded();
    if (mounted) Navigator.pop(context);
  }
}
