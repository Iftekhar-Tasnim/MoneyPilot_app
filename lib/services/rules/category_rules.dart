class CategoryRules {
  // Ordered map of keywords to categories.
  // Keys should be lower case.
  static final Map<String, String> _keywords = {
    'bus': 'Transport',
    'বাস': 'Transport',
    'rickshaw': 'Transport',
    'রিকশা': 'Transport',
    'auto': 'Transport',
    'cng': 'Transport',
    'uber': 'Transport',
    'pathao': 'Transport',
    'trin': 'Transport',
    'train': 'Transport',
    'flight': 'Transport',
    'ভাড়া': 'Transport',
    
    'bazaar': 'Groceries',
    'বাজার': 'Groceries',
    'sobjo': 'Groceries',
    'sobji': 'Groceries',
    'fish': 'Groceries',
    'মাছ': 'Groceries',
    'chal': 'Groceries',
    'dal': 'Groceries',
    'oil': 'Groceries',
    
    'cha': 'Food',
    'চা': 'Food',
    'coffee': 'Food',
    'nasta': 'Food',
    'নাস্তা': 'Food',
    'lunch': 'Food',
    'dinner': 'Food',
    'burger': 'Food',
    'pizza': 'Food',
    
    'mobile': 'Bills',
    'recharge': 'Bills',
    'internet': 'Bills',
    'wifi': 'Bills',
    'electricity': 'Bills',
    'gas': 'Bills',
    'water': 'Bills',
    'karrent': 'Bills',
    'current': 'Bills',
    
    'salary': 'Salary',
    'beton': 'Salary',
    'বেতন': 'Salary',
    'bonus': 'Salary',
    
    'freelance': 'Freelance',
    'fiverr': 'Freelance',
    'upwork': 'Freelance',
    
    'shop': 'Shopping',
    'dress': 'Shopping',
    'shirt': 'Shopping',
    'pant': 'Shopping',
    'shoes': 'Shopping',
    
    'medicine': 'Health',
    'doctor': 'Health',
    'hospital': 'Health',
    'ঔষধ': 'Health',
  };

  /// Apply rules to override category based on input text
  static void apply(Map<String, dynamic> transaction, String originalText) {
    if (originalText.isEmpty) return;
    
    final lowerText = originalText.toLowerCase();
    
    for (var entry in _keywords.entries) {
      // Simple contains check. 
      // Could be improved with regex/word boundaries for English, 
      // but Bangla often concatenates or has different boundaries.
      if (lowerText.contains(entry.key.toLowerCase())) {
        print('DEBUG: Rule applied: Found "${entry.key}" -> Override Category to "${entry.value}"');
        transaction['category'] = entry.value;
        return; // Stop after first match (Priority determined by Map order)
      }
    }
  }
}
