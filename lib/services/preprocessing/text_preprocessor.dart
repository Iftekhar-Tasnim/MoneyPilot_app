class TextPreprocessor {
  static final TextPreprocessor instance = TextPreprocessor._init();
  TextPreprocessor._init();

  // Basic Bangla Data
  static final Map<String, String> _banglaNumbers = {
    'শূন্য': '0', 'এক': '1', 'দুই': '2', 'তিন': '3', 'চার': '4',
    'পাঁচ': '5', 'ছয়': '6', 'পাচ': '5', 'সাত': '7', 'আট': '8', 'নয়': '9', 'দশ': '10',
    'বিশ': '20', 'ত্রিশ': '30', 'চল্লিশ': '40', 'পঞ্চাশ': '50',
    'ষাট': '60', 'সত্তর': '70', 'আশি': '80', 'নব্বই': '90',
    'একশ': '100', 'একশো': '100', 'দুশ': '200', 'দুশো': '200',
    'পাঁচশ': '500', 'পাচশ': '500', 'পাঁচশো': '500', 
    'হাজার': '1000',
    '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
    '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9'
  };

  static final List<String> _fillers = [
    'আজকে', 'মানে', 'তো', 'আসলে', 'আরকি', 'হ্যালো', 'শুনছেন'
  ];

  static final List<String> _splitters = [
    ' এবং ', ' আর ', ' কিন্তু ', ' পরে ', ' then ', ' and ', ' also ',
    ',', '।'
  ];

  /// Main processing entry point
  List<String> process(String rawText) {
    if (rawText.isEmpty) return [];

    String text = rawText;
    
    // 1. Remove fillers
    text = _removeFillers(text);

    // 2. Normalize numbers
    text = _normalizeNumbers(text);

    // 3. Split clauses
    List<String> clauses = _splitClauses(text);

    // 4. Cleanup clauses
    clauses = clauses.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

    return clauses;
  }

  String _removeFillers(String text) {
    String processed = text;
    for (var filler in _fillers) {
      processed = processed.replaceAll(filler, '');
    }
    return processed; // Simple removal. Ideally regex with word boundary.
  }

  String _normalizeNumbers(String text) {
    String processed = text;
    // Sort keys by length descending to match "পাঁচশ" before "পাঁচ"
    var keys = _banglaNumbers.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (var key in keys) {
      processed = processed.replaceAll(key, _banglaNumbers[key]!);
    }
    return processed;
  }
  
  List<String> _splitClauses(String text) {
    // Regex split
    // constructing regex pattern from splitters
    // escape regex special chars if any (like .)
    // splitters include ' এবং ', ' আর '.
    
    String temp = text;
    // Replace all splitters with a common unique delimiter
    const delimiter = "|||";
    
    for (var splitter in _splitters) {
      temp = temp.replaceAll(splitter, delimiter);
    }
    
    return temp.split(delimiter);
  }
}
