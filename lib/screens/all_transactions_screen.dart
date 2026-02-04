import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/sheets/add_transaction_sheet.dart';
import '../models/transaction_model.dart';
import '../utils/app_strings.dart';
import '../screens/home_screen.dart';
import '../services/database_service.dart';

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
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  
  // Filter States
  String _searchQuery = '';
  String _selectedType = 'all'; // all, income, expense, loan
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHistory() async {
    final data = await DatabaseService.instance.readAllTransactions();
    if (mounted) {
      setState(() {
        _allTransactions = data;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        // Search Filter
        final matchesSearch = tx.title.toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Type Filter
        bool matchesType = true;
        if (_selectedType == 'income') {
          matchesType = tx.type == 'income' || tx.type == 'loan_taken';
        } else if (_selectedType == 'expense') {
          matchesType = tx.type == 'expense' || tx.type == 'loan_given';
        } else if (_selectedType == 'loan') {
          matchesType = tx.type == 'loan_given' || tx.type == 'loan_taken';
        }

        // Category Filter
        final matchesCategory = _selectedCategory == null || tx.category == _selectedCategory;

        // Date Filter
        bool matchesDate = true;
        if (_selectedDateRange != null) {
          final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
          final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
          
          matchesDate = (txDate.isAtSameMomentAs(start) || txDate.isAfter(start)) && 
                        (txDate.isAtSameMomentAs(end) || txDate.isBefore(end));
        }

        return matchesSearch && matchesType && matchesCategory && matchesDate;
      }).toList();
    });
  }

  double get _filteredIncome {
    return _filteredTransactions
        .where((tx) => tx.type == 'income' || tx.type == 'loan_taken')
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  double get _filteredExpense {
    return _filteredTransactions
        .where((tx) => tx.type == 'expense' || tx.type == 'loan_given')
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  void _showAddTransactionSheet({bool isIncome = false, TransactionModel? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        isIncome: isIncome,
        currentLanguage: widget.language,
        onTransactionAdded: _loadAllHistory,
        transaction: transaction,
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        language: widget.language,
        selectedType: _selectedType,
        selectedCategory: _selectedCategory,
        selectedDateRange: _selectedDateRange,
        categories: _allTransactions.map((tx) => tx.category).toSet().toList(),
        onApply: (type, category, range) {
          setState(() {
            _selectedType = type;
            _selectedCategory = category;
            _selectedDateRange = range;
            _applyFilters();
          });
        },
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedType = 'all';
      _selectedCategory = null;
      _selectedDateRange = null;
      _applyFilters();
    });
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
        actions: [
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: AppStrings.get(widget.language, 'search_hint'),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Active Filter Pills
          if (_selectedType != 'all' || _selectedCategory != null || _selectedDateRange != null)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (_selectedType != 'all')
                    _buildActiveFilterPill(AppStrings.get(widget.language, _selectedType), () {
                      setState(() {
                        _selectedType = 'all';
                        _applyFilters();
                      });
                    }),
                  if (_selectedCategory != null)
                    _buildActiveFilterPill(AppStrings.getCategory(widget.language, _selectedCategory!), () {
                      setState(() {
                        _selectedCategory = null;
                        _applyFilters();
                      });
                    }),
                  if (_selectedDateRange != null)
                    _buildActiveFilterPill(
                      '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
                      () {
                        setState(() {
                          _selectedDateRange = null;
                          _applyFilters();
                        });
                      }
                    ),
                ],
              ),
            ),

          // Summary Card
          if (!_isLoading && _filteredTransactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      AppStrings.get(widget.language, 'filtered_results'),
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '৳${NumberFormat('#,##0').format(_filteredIncome - _filteredExpense)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(AppStrings.get(widget.language, 'income'), _filteredIncome, Colors.greenAccent),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _buildSummaryItem(AppStrings.get(widget.language, 'expense'), _filteredExpense, Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Transaction List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredTransactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      return _buildDetailedTransactionItem(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterPill(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF4F46E5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF4F46E5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '৳${NumberFormat('#,##0').format(amount)}',
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            AppStrings.get(widget.language, 'no_matching_results'),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _resetFilters,
            child: Text(AppStrings.get(widget.language, 'clear_filters')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTransactionItem(TransactionModel tx) {
    final isExpense = tx.type == 'expense' || tx.type == 'loan_given' || tx.type == 'loan_repayment';
    final amount = tx.amount;
    final primaryColor = isExpense ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final bgColor = isExpense ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddTransactionSheet(
            isIncome: tx.type == 'income' || tx.type == 'loan_taken' || tx.type == 'loan_recovery',
            transaction: tx,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                    color: primaryColor,
                    size: 20,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppStrings.getCategory(widget.language, tx.category),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(tx.date),
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
                Text(
                  '${isExpense ? "-" : "+"} ৳${NumberFormat('#,##0').format(amount)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String language;
  final String selectedType;
  final String? selectedCategory;
  final DateTimeRange? selectedDateRange;
  final List<String> categories;
  final Function(String, String?, DateTimeRange?) onApply;

  const _FilterBottomSheet({
    required this.language,
    required this.selectedType,
    this.selectedCategory,
    this.selectedDateRange,
    required this.categories,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _type;
  String? _category;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    _category = widget.selectedCategory;
    _range = widget.selectedDateRange;
  }

  void _setPresetRange(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (preset) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'last3months':
        start = DateTime(now.year, now.month - 3, 1);
        break;
      default:
        return;
    }
    setState(() => _range = DateTimeRange(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(widget.language, 'filters'),
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _type = 'all';
                    _category = null;
                    _range = null;
                  });
                },
                child: Text(
                  AppStrings.get(widget.language, 'reset_all'),
                  style: GoogleFonts.outfit(color: const Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Date Range Presets
          Text(
            AppStrings.get(widget.language, 'date_range'),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip(AppStrings.get(widget.language, 'today'), 'today'),
                _buildPresetChip(AppStrings.get(widget.language, 'this_week'), 'week'),
                _buildPresetChip(AppStrings.get(widget.language, 'this_month'), 'month'),
                _buildPresetChip(AppStrings.get(widget.language, 'last_3_months'), 'last3months'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _range,
              );
              if (picked != null) setState(() => _range = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 12),
                  Text(
                    _range == null 
                      ? AppStrings.get(widget.language, 'select_custom_range') 
                      : '${DateFormat('MMM d, yyyy').format(_range!.start)} - ${DateFormat('MMM d, yyyy').format(_range!.end)}',
                    style: GoogleFonts.outfit(color: _range == null ? Colors.grey : const Color(0xFF1A1C1E)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            AppStrings.get(widget.language, 'transaction_type'),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeIconCard(AppStrings.get(widget.language, 'all'), 'all', Icons.all_inclusive_rounded),
              const SizedBox(width: 12),
              _buildTypeIconCard(AppStrings.get(widget.language, 'income'), 'income', Icons.arrow_downward_rounded),
              const SizedBox(width: 12),
              _buildTypeIconCard(AppStrings.get(widget.language, 'expense'), 'expense', Icons.arrow_upward_rounded),
              const SizedBox(width: 12),
              _buildTypeIconCard(AppStrings.get(widget.language, 'loans'), 'loan', Icons.handshake_rounded),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            AppStrings.get(widget.language, 'category'),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((cat) => _buildFilterChip(AppStrings.getCategory(widget.language, cat), cat)).toList(),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_type, _category, _range);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(AppStrings.get(widget.language, 'apply_filters'), style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String preset) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _setPresetRange(preset),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[200]!),
        labelStyle: GoogleFonts.outfit(fontSize: 12),
      ),
    );
  }

  Widget _buildTypeIconCard(String label, String value, IconData icon) {
    bool isSelected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _category == value;
    return GestureDetector(
      onTap: () => setState(() => _category = isSelected ? null : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey[200]!),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
