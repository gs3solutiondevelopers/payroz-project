import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../home/ai_chat_screen.dart';
import 'complaint_history_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How does the PAYROZ wallet work?',
      'answer': 'PAYROZ is a pure B2C customer app with NO "Add Money" or top-up wallet. Payments for all recharges and bills are made directly through your bank or payment gateway. Your wallet is a Rewards Wallet containing only Cashback, Referrals, promotional bonus, and failed transaction refunds.'
    },
    {
      'question': 'When is cashback credited?',
      'answer': 'Cashback is instantly credited to your Rewards Wallet after any successful eligible transaction. You can use this balance to pay for future services.'
    },
    {
      'question': 'What happens if a transaction fails?',
      'answer': 'If a transaction fails but money is deducted from your bank account, PAYROZ automatically processes an instant refund to your Rewards Wallet so you do not have to wait for banking cycles.'
    },
    {
      'question': 'Is KYC mandatory?',
      'answer': 'Basic services do not require KYC. However, high-value utility bill payments and special promotions require KYC documents to be uploaded and approved.'
    },
    {
      'question': 'How do I earn referral income?',
      'answer': 'Share your unique referral code with friends. When they register using your code and complete their first transaction, ₹50.00 referral reward is added to your Rewards Wallet.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayRozTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Chat banner card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [PayRozTheme.primaryColor, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: PayRozTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Instant Help?',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Chat with our AI Support Assistant for instant solutions regarding refunds, cashbacks, and transactions.',
                          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PayRozTheme.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                          },
                          child: Text('CHAT WITH AI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.rocket_launch, size: 56, color: PayRozTheme.accentColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tickets Section link
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintHistoryScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PayRozTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PayRozTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.confirmation_number_outlined, color: PayRozTheme.accentColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Support Tickets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: PayRozTheme.textMain)),
                          const SizedBox(height: 2),
                          Text('Raise a complaint, upload screenshots, or check status', style: GoogleFonts.outfit(fontSize: 10, color: PayRozTheme.textMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: PayRozTheme.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // FAQ Title
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: PayRozTheme.textMain),
            ),
            const SizedBox(height: 16),

            // FAQ Accordion
            ..._faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PayRozTheme.borderColor),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: PayRozTheme.textMain),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(
                        faq['answer']!,
                        style: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.textMuted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),

            // Help Center Contact Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PayRozTheme.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alternate_email, color: PayRozTheme.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text('support@payroz.com', style: GoogleFonts.outfit(fontSize: 13, color: PayRozTheme.textMain)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone_in_talk, color: PayRozTheme.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text('+91 1800-123-4567 (Toll-Free)', style: GoogleFonts.outfit(fontSize: 13, color: PayRozTheme.textMain)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
