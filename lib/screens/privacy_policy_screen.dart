import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final String currentLanguage;

  const PrivacyPolicyScreen({super.key, required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    var lang = currentLanguage;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          AppStrings.get(lang, 'privacy_policy'),
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: GoogleFonts.outfit(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '''
Last updated: February 2026

1. Introduction
Welcome to Money Pilot. We respect your privacy and represent that we do not collect any personal data beyond what is necessary for the app to function.

2. Data Collection
We do not collect or store your financial data on any external servers. All transaction data is stored locally on your device using SQLite.

3. Voice Data
When you use voice input, your request is processed using Google's Speech-to-Text services and Gemini AI. 
- Speech data is transient and not stored by us.
- Text transcripts are sent to Gemini API for categorization and then discarded.
- In "Online Mode", audio is processed by Google's servers subject to their privacy policy.

4. API Keys
If you provide your own Gemini API Key, it is stored securely in your device's SharedPreferences and is only used to make requests to the Gemini API on your behalf.

5. Contact Us
If you have any questions about this Privacy Policy, please contact us at:
iftekhartasnim@gmail.com
                ''',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
