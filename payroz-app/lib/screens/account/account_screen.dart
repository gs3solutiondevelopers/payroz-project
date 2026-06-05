import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';
import 'kyc_upload_screen.dart';
import 'edit_profile_screen.dart';
import 'login_history_screen.dart';
import 'help_support_screen.dart';
import 'complaint_history_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  void _showLanguageDialog() {
    final provider = Provider.of<PayRozProvider>(context, listen: false);
    final selectedLangCode = provider.locale.languageCode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.appLanguage ?? 'App Language', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              {'name': 'English', 'code': 'en'},
              {'name': 'Hindi (हिंदी)', 'code': 'hi'},
              {'name': 'Bengali (বাংলা)', 'code': 'bn'},
            ].map((lang) {
              return ListTile(
                title: Text(lang['name']!, style: GoogleFonts.outfit(fontSize: 14)),
                trailing: selectedLangCode == lang['code']
                  ? const Icon(Icons.check, color: PayRozTheme.accentColor) 
                  : null,
                onTap: () {
                  provider.changeLocale(lang['code']!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showRatingDialog() {
    int selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Rate PAYROZ App',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: PayRozTheme.textMain),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How do you like the new features?',
                    style: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      final starVal = idx + 1;
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedStars = starVal;
                          });
                        },
                        child: Icon(
                          starVal <= selectedStars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Share your feedback (optional)...',
                      hintStyle: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: PayRozTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: PayRozTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: PayRozTheme.accentColor),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: PayRozTheme.textMuted, fontSize: 13),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PayRozTheme.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final provider = Provider.of<PayRozProvider>(context, listen: false);
                    final success = await provider.submitFeedback(selectedStars, commentController.text);
                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Feedback submitted successfully! Thank you.' : 'Failed to submit feedback.',
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                          backgroundColor: success ? PayRozTheme.successColor : PayRozTheme.errorColor,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Submit Feedback',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final user = provider.currentUser;
    final l10n = AppLocalizations.of(context)!;

    Color kycColor = PayRozTheme.errorColor;
    if (user?.kycStatus == 'Approved') {
      kycColor = PayRozTheme.successColor;
    } else if (user?.kycStatus == 'Pending') {
      kycColor = PayRozTheme.warningColor;
    }

    String currentLang = 'English';
    if (provider.locale.languageCode == 'hi') {
      currentLang = 'Hindi (हिंदी)';
    } else if (provider.locale.languageCode == 'bn') {
      currentLang = 'Bengali (বাংলা)';
    }

    return Scaffold(
      backgroundColor: PayRozTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l10n.account, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. User details avatar header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PayRozTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(color: PayRozTheme.primaryColor, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Rajesh Sharma', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: PayRozTheme.textMain)),
                        Text('+91 ${user?.phone ?? "9876543210"}', style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.textMuted)),
                        Text(user?.email ?? 'rajesh@example.com', style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.textMuted)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. KYC Card Review Trigger
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PayRozTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KYC Verification Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: kycColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(user?.kycStatus ?? 'None', style: GoogleFonts.outfit(fontSize: 11, color: kycColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  if (user?.kycStatus == 'None' || user?.kycStatus == 'Rejected')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const KycUploadScreen()));
                      },
                      child: const Text('Complete KYC'),
                    )
                  else
                    const Icon(Icons.verified, color: PayRozTheme.successColor, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Settings Items List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PayRozTheme.borderColor),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: l10n.editProfile,
                    trailing: '',
                    action: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.language,
                    title: l10n.appLanguage,
                    trailing: currentLang,
                    action: _showLanguageDialog,
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.star_border,
                    title: l10n.rateFeedback,
                    trailing: '5 Stars',
                    action: _showRatingDialog,
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.history_toggle_off,
                    title: l10n.loginHistory,
                    trailing: '',
                    action: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginHistoryScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.confirmation_number_outlined,
                    title: l10n.myComplaintsTickets,
                    trailing: '',
                    action: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintHistoryScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: l10n.helpSupport,
                    trailing: 'Support',
                    action: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 4. Log Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: PayRozTheme.errorColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => provider.logout(),
                child: Text(l10n.logout, style: GoogleFonts.outfit(color: PayRozTheme.errorColor, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String trailing,
    required VoidCallback action,
  }) {
    return ListTile(
      onTap: action,
      leading: Icon(icon, color: PayRozTheme.primaryColor),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: PayRozTheme.textMain)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailing, style: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.textMuted)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: PayRozTheme.textMuted),
        ],
      ),
    );
  }
}
