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
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();

  final Map<String, IconData> _incomeCategories = {
    'Salary': Icons.payments_outlined,
    'Freelance': Icons.laptop_mac_outlined,
    'Business': Icons.storefront_outlined,
    'Investment': Icons.trending_up_outlined,
    'Gift': Icons.card_giftcard_outlined,
    'Other': Icons.more_horiz_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final lang = widget.currentLanguage;
    const primaryColor = Color(0xFF166534);
    const backgroundColor = Color(0xFFF0FDF4);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppStrings.get(lang, 'add_income'),
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1C1E), 
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      AppStrings.get(lang, 'enter_amount'),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      decoration: InputDecoration(
                        prefixText: '৳ ',
                        prefixStyle: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey[300]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (val) => val == null || val.isEmpty ? AppStrings.get(lang, 'enter_amount') : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Description
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
                controller: _noteController,
                style: GoogleFonts.outfit(),
                decoration: InputDecoration(
                  hintText: AppStrings.get(lang, 'hint_salary'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text(
                AppStrings.get(lang, 'category'),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _incomeCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final catKey = _incomeCategories.keys.elementAt(index);
                    final icon = _incomeCategories.values.elementAt(index);
                    final isSelected = _selectedCategory == catKey;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = catKey),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? primaryColor : Colors.grey[200]!,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon, 
                              size: 20, 
                              color: isSelected ? Colors.white : Colors.grey[600]
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.getCategory(lang, catKey),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Date Selection
              Text(
                AppStrings.get(lang, 'date'),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.expand_more, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF166534),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final tx = TransactionModel(
        title: _noteController.text.isEmpty ? AppStrings.get(widget.currentLanguage, _selectedCategory.toLowerCase()) : _noteController.text,
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
}
