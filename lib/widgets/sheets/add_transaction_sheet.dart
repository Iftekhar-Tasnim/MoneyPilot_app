import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_strings.dart';

class AddTransactionSheet extends StatefulWidget {
  final bool isIncome;
  final String currentLanguage;
  final Function() onTransactionAdded;
  final TransactionModel? transaction; // Optional transaction for editing
  final String? originalPhrase; // Phase 6: For learning corrections

  const AddTransactionSheet({
    super.key,
    required this.isIncome,
    required this.currentLanguage,
    required this.onTransactionAdded,
    this.transaction,
    this.originalPhrase,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  String? _selectedCategory;
  
  // To track if user changed the category
  String? _initialCategory;
  
  // Predefined Categories with Icons
  final Map<String, IconData> _incomeCategories = {
    'Salary': Icons.payments_outlined,
    'Freelance': Icons.laptop_mac_outlined,
    'Business': Icons.storefront_outlined,
    'Investment': Icons.trending_up_outlined,
    'Gift': Icons.card_giftcard_outlined,
    'Other': Icons.more_horiz_outlined,
  };

  final Map<String, IconData> _expenseCategories = {
    'Food': Icons.restaurant_outlined,
    'Dining': Icons.local_dining_outlined,
    'Groceries': Icons.shopping_cart_outlined,
    'Transport': Icons.directions_bus_outlined,
    'Fuel': Icons.local_gas_station_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Clothing': Icons.checkroom_outlined,
    'Electronics': Icons.devices_outlined,
    'Bills': Icons.receipt_long_outlined,
    'Rent': Icons.home_outlined,
    'Utilities': Icons.plumbing_outlined,
    'Entertainment': Icons.movie_outlined,
    'Movies': Icons.theaters_outlined,
    'Health': Icons.medical_services_outlined,
    'Medicine': Icons.medication_outlined,
    'Education': Icons.school_outlined,
    'Tuition': Icons.auto_stories_outlined,
    'Travel': Icons.flight_takeoff_outlined,
    'Other': Icons.more_horiz_outlined,
  };

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(text: tx?.amount != null ? tx!.amount.toStringAsFixed(2) : '');
    _selectedDate = tx?.date ?? DateTime.now();
    
    final validCategories = widget.isIncome ? _incomeCategories.keys : _expenseCategories.keys;
    
    // Phase 4: Validate Category
    String initialCategory = tx?.category ?? (widget.isIncome ? _incomeCategories.keys.first : _expenseCategories.keys.first);
    if (!validCategories.contains(initialCategory)) {
      initialCategory = 'Other';
    }
    _selectedCategory = initialCategory;
    _initialCategory = initialCategory; // Track initial
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
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
            colorScheme: ColorScheme.light(
              primary: widget.isIncome ? const Color(0xFF166534) : const Color(0xFFB91C1C),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1A1C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      // Phase 4: Hard Guardrails
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get(widget.currentLanguage, 'amount_must_be_positive') ?? 'Amount must be positive'), backgroundColor: Colors.red),
        );
        return;
      }
      
      if (amount > 1000000) { // 10 Lakh limit
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount exceeds limit (1,000,000)'), backgroundColor: Colors.red),
        );
        return;
      }
      
      // Phase 6: Learning Loop (Save Correction)
      if (widget.originalPhrase != null && 
          _selectedCategory != null && 
          _selectedCategory != _initialCategory) {
        // User changed the category manually!
        await DatabaseService.instance.saveCorrection(widget.originalPhrase!, _selectedCategory!);
      }
      
      final tx = TransactionModel(
        id: widget.transaction?.id,
        title: _titleController.text,
        amount: amount,
        date: _selectedDate,
        type: widget.isIncome ? 'income' : 'expense',
        category: _selectedCategory ?? 'Other',
      );



      // Fix: Check if ID exists. Voice drafts have a model but NO ID.
      if (widget.transaction != null && widget.transaction!.id != null) {
        await DatabaseService.instance.update(tx);
      } else {
        await DatabaseService.instance.create(tx);
      }
      
      widget.onTransactionAdded();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.isIncome;
    // Fix: Only consider it "Editing" if it's an existing DB record
    final isEditing = widget.transaction != null && widget.transaction!.id != null;
    final lang = widget.currentLanguage;
    final primaryColor = isIncome ? const Color(0xFF166534) : const Color(0xFFB91C1C);
    final backgroundColor = isIncome ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final categories = isIncome ? _incomeCategories : _expenseCategories;

    return Container(
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
        key: _formKey,
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
                    isEditing 
                      ? AppStrings.get(lang, isIncome ? 'edit_income' : 'edit_expense')
                      : AppStrings.get(lang, isIncome ? 'manual_input_income' : 'manual_input_expense'),
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
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Amount Input
              TextFormField(
                controller: _amountController,
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

              // Description Input
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
                controller: _titleController,
                style: GoogleFonts.outfit(),
                decoration: InputDecoration(
                  hintText: AppStrings.get(lang, isIncome ? 'hint_salary' : 'hint_grocery'),
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

              // Category Selection
              Text(
                AppStrings.get(lang, 'category'),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: GoogleFonts.outfit(color: const Color(0xFF1A1C1E)),
                decoration: InputDecoration(
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: categories.entries.map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(entry.value, size: 20, color: primaryColor),
                      const SizedBox(width: 12),
                      Text(AppStrings.getCategory(lang, entry.key)),
                    ],
                  ),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 24),

              // Date Selection
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 20, color: primaryColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get(lang, 'date'),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1C1E),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
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
                  onPressed: _submit,
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
    );
  }
}
