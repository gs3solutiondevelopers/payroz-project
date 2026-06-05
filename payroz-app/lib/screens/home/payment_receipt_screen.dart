import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/payroz_models.dart';
import '../../theme.dart';
import 'ai_chat_screen.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final Transaction transaction;

  const PaymentReceiptScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isSuccess = transaction.status == 'Success';
    final isPending = transaction.status == 'Pending';
    final isFailed = transaction.status == 'Failed';

    Color bannerColor = PayRozTheme.successColor;
    IconData bannerIcon = Icons.check_circle;
    String statusTitle = 'Recharge Successful';

    if (isPending) {
      bannerColor = PayRozTheme.warningColor;
      bannerIcon = Icons.pending_actions;
      statusTitle = 'Verification Pending';
    } else if (isFailed) {
      bannerColor = PayRozTheme.errorColor;
      bannerIcon = Icons.error_outline;
      statusTitle = 'Transaction Failed';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: PayRozTheme.accentColor),
            tooltip: 'Download Invoice',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Invoice Download', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: PayRozTheme.textMain)),
                  content: Text('Generating Invoice PDF for Order ID: ${transaction.id.toUpperCase().substring(0, 12)}...', style: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.textMuted)),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invoice PDF downloaded successfully! Check your downloads folder.', style: GoogleFonts.outfit(fontSize: 13)),
                            backgroundColor: PayRozTheme.successColor,
                          ),
                        );
                      },
                      child: Text('OK', style: GoogleFonts.outfit(color: PayRozTheme.accentColor, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: PayRozTheme.accentColor),
            tooltip: 'Share Receipt',
            onPressed: () {
              final shareText = 'PAYROZ Receipt:\n'
                  'Service: ${transaction.serviceName}\n'
                  'Amount: ₹${transaction.amount}\n'
                  'Status: ${transaction.status}\n'
                  'Ref ID: ${transaction.operatorRefId ?? "Pending"}\n'
                  'Thank you for using PAYROZ!';
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Receipt details copied to clipboard! Ready to share.', style: GoogleFonts.outfit(fontSize: 13)),
                  backgroundColor: PayRozTheme.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: bannerColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bannerColor.withOpacity(0.12)),
                ),
                child: Column(
                  children: [
                    Icon(bannerIcon, size: 56, color: bannerColor),
                    const SizedBox(height: 12),
                    Text(statusTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: bannerColor)),
                    const SizedBox(height: 4),
                    Text(
                      isSuccess 
                        ? 'Your payment was processed instantly.' 
                        : isPending 
                          ? 'Checking provider status. Refreshes in 30 seconds.' 
                          : 'Amount will be refunded back to your wallet.',
                      style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Text('₹${transaction.amount.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: PayRozTheme.primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Automated Action alerts for Failed transaction
              if (isFailed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: PayRozTheme.errorColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Auto-Refund & Ticket Triggered', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: PayRozTheme.errorColor)),
                            Text('₹${transaction.amount} refunded back to your Rewards Wallet. Support ticket opened automatically.', style: GoogleFonts.outfit(fontSize: 10, color: Colors.red.shade900)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. Metadata Detail Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PayRozTheme.borderColor),
                ),
                child: Column(
                  children: [
                    ...transaction.inputsUsed.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, color: PayRozTheme.textMuted, fontWeight: FontWeight.bold)),
                            Text(entry.value.toString(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    _buildRow('Operator Ref ID', transaction.operatorRefId ?? 'WAITING-PG-VERIFY'),
                    _buildRow('Order ID', transaction.id.substring(0, 16).toUpperCase()),
                    _buildRow('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Payment breakdown box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PayRozTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: PayRozTheme.textMain)),
                    const Divider(height: 20),
                    _buildRow('Transaction Amount', '₹${transaction.amount.toStringAsFixed(2)}'),
                    _buildRow('Rewards Applied', '- ₹${transaction.rewardsAmountUsed.toStringAsFixed(2)}'),
                    _buildRow('Paid via Gateway', '₹${transaction.gatewayAmountPaid.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Help drawer buttons
              Text('Need Help?', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: PayRozTheme.primaryColor)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHelpBtn(
                    context, 
                    icon: Icons.note_add_outlined, 
                    label: 'Raise Ticket', 
                    action: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support ticket created automatically. Track under Help & Support.')),
                      );
                    }
                  ),
                  _buildHelpBtn(
                    context, 
                    icon: Icons.chat_bubble_outline, 
                    label: 'Chat Support', 
                    action: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                    }
                  ),
                  _buildHelpBtn(
                    context, 
                    icon: Icons.phone_forwarded, 
                    label: 'Call Support', 
                    action: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling helpline...')),
                      );
                    }
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Home button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.textMuted)),
          Expanded(child: Text(value, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildHelpBtn(BuildContext context, {required IconData icon, required String label, required VoidCallback action}) {
    return GestureDetector(
      onTap: action,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: PayRozTheme.borderColor),
            ),
            child: Icon(icon, color: PayRozTheme.primaryColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: PayRozTheme.textMain)),
        ],
      ),
    );
  }
}
