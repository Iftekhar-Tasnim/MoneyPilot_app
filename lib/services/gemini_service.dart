import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static final GeminiService instance = GeminiService._init();
  GeminiService._init();

  Future<GenerativeModel?> _getModel() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');
    // Default to 'gemini-1.5-flash' but respect what was found working
    final modelName = prefs.getString('gemini_model_name') ?? 'gemini-1.5-flash';
    
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );
  }

  Future<List<Map<String, dynamic>>> parseTransaction(String userText) async {
    final model = await _getModel();
    if (model == null) throw Exception('API Key not found');

    final prompt = '''
      Extract transaction details from this text: "$userText".
      Return ONLY a JSON object with this exact schema:
      {
        "transactions": [
          {
            "title": "string (short description)",
            "amount": number (positive),
            "type": "income" or "expense",
            "category": "string (Best fitting category or INVENT one)",
            "note": "string (optional)"
          }
        ]
      }

      Standard Categories: 
      [Food, Dining, Groceries, Transport, Fuel, Shopping, Clothing, Bills, Rent, Utilities, Entertainment, Health, Education, Salary, Freelance, Business, Investment, Gift, Travel]

      Rules:
      1. If the text is Bangla, translate and infer.
      2. If meaningful data is missing, return empty transactions list.
      3. Valid JSON only. No markdown.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) return [];

      // Clean up markdown code blocks if present
      print('DEBUG: Gemini Raw Response: $responseText');
      final cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      print('DEBUG: Cleaned JSON: $cleanJson');
      
      try {
        final decoded = jsonDecode(cleanJson);
        if (decoded is Map<String, dynamic> && decoded.containsKey('transactions')) {
             return List<Map<String, dynamic>>.from(decoded['transactions']);
        } else if (decoded is Map<String, dynamic>) {
             // Fallback for single object if AI messes up list structure
             return [decoded];
        }
        return [];
      } catch (e) {
        print('DEBUG: JSON Parse Error: $e');
        // Do not throw, just return empty to fail gracefully? 
        // Plan says: "If JSON parsing fails, retry once, then abort." 
        // For now, I'll throw to let UI handle "Could not understand" or return empty.
        // Existing UI handles exceptions.
        throw Exception('Failed to parse AI response'); 
      }
    } catch (e) {
      print('Gemini Error: $e');
      rethrow; 
    }
  }

  Future<String?> testApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    try {
      // 1. Dynamic Discovery via HTTP
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey');
      final httpResponse = await http.get(uri);

      if (httpResponse.statusCode == 200) {
        final data = jsonDecode(httpResponse.body);
        if (data['models'] != null && data['models'] is List) {
           final models = (data['models'] as List).cast<Map<String, dynamic>>();
           
           // Find candidates that support generateContent
           final validModels = models.where((m) => 
              (m['supportedGenerationMethods'] as List).contains('generateContent')
           ).toList();

           if (validModels.isEmpty) {
             return 'No models support generateContent. Found: ${models.length} raw models.';
           }

           // Prioritize specific models (flash > pro > others)
           validModels.sort((a, b) {
             final nameA = a['name'].toString();
             final nameB = b['name'].toString();
             // Prefer flash
             if (nameA.contains('flash') && !nameB.contains('flash')) return -1;
             if (!nameA.contains('flash') && nameB.contains('flash')) return 1;
             // Prefer 1.5
             if (nameA.contains('1.5') && !nameB.contains('1.5')) return -1;
             if (!nameA.contains('1.5') && nameB.contains('1.5')) return 1;
             return 0;
           });

           // Try the top 3 discovered models
           final topCandidates = validModels.take(3).map((m) => m['name'].toString().replaceFirst('models/', '')).toList();
           
           for (final name in topCandidates) {
             try {
               print('Testing discovered model: $name');
               final model = GenerativeModel(model: name, apiKey: cleanKey);
               final content = [Content.text('Hello')];
               final response = await model.generateContent(content);
               if (response.text != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('gemini_model_name', name);
                  return null; // Success!
               }
             } catch (e) {
               print('Discovered model $name failed: $e');
             }
           }
        }
      } else {
        return 'ListModels failed: ${httpResponse.statusCode} ${httpResponse.body}';
      }

      // Fallback to manual list if discovery fails or yields no working models
      final fallbackCandidates = [
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-pro',
      ];

      for (final modelName in fallbackCandidates) {
         try {
           final model = GenerativeModel(model: modelName, apiKey: cleanKey);
           final response = await model.generateContent([Content.text('Hello')]);
           if (response.text != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('gemini_model_name', modelName);
              return null;
           }
         } catch (_) {}
      }

      return 'No working model found. Checked dynamic list + fallbacks.';

    } catch (e) {
      return 'Discovery Error: $e';
    }
  }
  // Financial Advice (Money Coach)
  Future<Map<String, dynamic>?> getFinancialAdvice(List<dynamic> transactions) async {
    final model = await _getModel();
    if (model == null) throw Exception('API Key not found');

    // Summarize data to save tokens
    if (transactions.isEmpty) return null;
    
    // Take last 30 transactions for better analysis
    final recentTx = transactions.take(30).map((tx) {
      return "${tx.amount} (${tx.category})";
    }).join(", ");

    final prompt = '''
      Analyze these recent expenses: [$recentTx].
      Act as a friendly but professional Financial Advisor.
      
      Provide a comprehensive assessment of the user's spending habits.
      Return ONLY a JSON object with this EXACT structure (no markdown):
      {
        "en": {
          "good": "A specific positive observation about their spending (e.g. 'You kept dining costs low').",
          "tip": "A comprehensive, actionable advice on how to manage money better based on this data (e.g. 'Your transport costs are high; try monthly passes...')."
        },
        "bn": {
          "good": "Bangla translation of the good observation.",
          "tip": "Bangla translation of the comprehensive advice."
        }
      }
      
      Maximize value in minimum words (max 25 words per field).
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) return null;

      final cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      print('Gemini Advice Error: $e');
      return null;
    }
  }
}
