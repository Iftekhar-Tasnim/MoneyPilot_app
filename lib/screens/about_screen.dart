import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_strings.dart';

class AboutScreen extends StatelessWidget {
  final String currentLanguage;

  const AboutScreen({super.key, required this.currentLanguage});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch \$url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: 'iftekhartasnim@gmail.com',
    );
     if (!await launchUrl(uri)) {
      throw Exception('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    var lang = currentLanguage;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          AppStrings.get(lang, 'about'),
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1), width: 8),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.get(lang, 'app_title'),
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                '${AppStrings.get(lang, 'version')} 1.0.0',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              
              // Developer Info
              _buildInfoRow(
                icon: Icons.person_outline,
                label: AppStrings.get(lang, 'developer'),
                value: 'Iftekhar Tasnim',
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _launchEmail,
                child: _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'iftekhartasnim@gmail.com',
                  isLink: true,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _launchUrl('https://github.com/Iftekhar-Tasnim'),
                child: _buildInfoRow(
                  icon: Icons.code,
                  label: 'Github',
                  value: 'Iftekhar-Tasnim',
                  isLink: true,
                ),
              ),
              
              const Spacer(),
              Text(
                '© 2026 Money Pilot',
                style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4F46E5), size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isLink ? const Color(0xFF4F46E5) : const Color(0xFF1A1C1E),
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
