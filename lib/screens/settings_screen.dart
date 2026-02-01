import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import '../utils/app_strings.dart';
import '../services/gemini_service.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String currentLanguage;

  const SettingsScreen({super.key, required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    var lang = currentLanguage;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          AppStrings.get(lang, 'settings_title'),
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.vpn_key_outlined,
            title: AppStrings.get(lang, 'configure_api'),
            color: const Color(0xFF4F46E5),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApiKeyScreen(currentLanguage: currentLanguage),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            icon: Icons.mic_none_outlined,
            title: AppStrings.get(lang, 'voice_settings'),
            color: const Color(0xFF10B981), // Greenish
            onTap: () => AppSettings.openAppSettings(type: AppSettingsType.settings), // Generic settings
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            icon: Icons.backup_outlined,
            title: AppStrings.get(lang, 'backup_restore'),
            color: const Color(0xFF0EA5E9),
            onTap: () => _showComingSoon(context, lang),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: AppStrings.get(lang, 'change_password'),
            color: const Color(0xFFF59E0B),
            onTap: () => _showComingSoon(context, lang),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: AppStrings.get(lang, 'privacy_policy'),
            color: const Color(0xFF8B5CF6), // Violet
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicyScreen(currentLanguage: lang),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: AppStrings.get(lang, 'about'),
            color: const Color(0xFFEC4899), // Pink
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutScreen(currentLanguage: lang),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: const Color(0xFF1A1C1E),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.get(lang, 'coming_soon')),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class ApiKeyScreen extends StatefulWidget {
  final String currentLanguage;

  const ApiKeyScreen({super.key, required this.currentLanguage});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _testApiKey() async {
    if (_apiKeyController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final errorMsg = await GeminiService.instance.testApiKey(_apiKeyController.text);
    setState(() => _isLoading = false);

    if (mounted) {
      final success = errorMsg == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? AppStrings.get(widget.currentLanguage, 'test_success')
              : 'Error: $errorMsg' // Show actual error
          ),
          backgroundColor: success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          duration: const Duration(seconds: 5), // Longer duration to read error
        ),
      );
    }
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get(widget.currentLanguage, 'key_saved')),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var lang = widget.currentLanguage;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          AppStrings.get(lang, 'configure_api'),
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(lang, 'api_key_label'),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      hintText: AppStrings.get(lang, 'api_key_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.key, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Get API Key Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
                        if (!await launchUrl(url)) {
                          if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not launch URL')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(
                        AppStrings.get(lang, 'get_api_key'),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Test API Key Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _testApiKey,
                      icon: const Icon(Icons.bug_report, color: Color(0xFF4F46E5)),
                      label: Text(
                        AppStrings.get(lang, 'test_api'),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveApiKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.get(lang, 'save_key'),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
