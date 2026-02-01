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

  Future<Map<String, dynamic>?> parseTransaction(String userText) async {
    final model = await _getModel();
    if (model == null) throw Exception('API Key not found');

    final prompt = '''
      Extract transaction details from this text: "$userText".
      Return ONLY a JSON object with these keys:
      - title: (string) short description
      - amount: (number) positive value
      - type: (string) either "income" or "expense"
      - category: (string) one of [Food, Transport, Shopping, Bills, Entertainment, Health, Salary, Freelance, Business, Gift, Other] relative to the type.
      
      If the text is Bangla, translate/infer relevant English categories and title.
      If meaningful data is missing, return null.
      JSON:
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) return null;

      // Clean up markdown code blocks if present
      final cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      print('Gemini Error: $e');
      return null;
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
}
