import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/payroz_models.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';
import 'payment_receipt_screen.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  final Service service;
  final double amount;
  final Map<String, dynamic> inputsUsed;

  const PaymentCheckoutScreen({
    super.key,
    required this.service,
    required this.amount,
    required this.inputsUsed,
  });

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  bool _useRewardsWallet = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final user = provider.currentUser;

    double rewardsBalance = user?.rewardsBalance ?? 0.0;
    double walletDeduction = 0.0;
    double netPayable = widget.amount;

    if (_useRewardsWallet && rewardsBalance > 0) {
      if (rewardsBalance >= widget.amount) {
        walletDeduction = widget.amount;
        netPayable = 0.0;
      } else {
        walletDeduction = rewardsBalance;
        netPayable = widget.amount - rewardsBalance;
      }
    }

    void _executePayment() async {
      final tx = await provider.payService(
        serviceId: widget.service.id,
        amount: widget.amount,
        inputsUsed: widget.inputsUsed,
        useRewardsWallet: _useRewardsWallet,
      );

      if (!mounted) return;

      if (tx != null) {
        // Redirect to status receipt page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentReceiptScreen(transaction: tx)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Gateway connection failed. Please try again.')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout Summary', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Transaction Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PayRozTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.service.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: PayRozTheme.primaryColor)),
                        const Divider(height: 24),
                        ...widget.inputsUsed.entries.map((entry) {
                          if (entry.key == 'amount') return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, color: PayRozTheme.textMuted, fontWeight: FontWeight.bold)),
                                Text(entry.value.toString(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: PayRozTheme.textMain)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Wallet Deduct Toggle Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PayRozTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: PayRozTheme.accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stars, color: PayRozTheme.accentColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply Rewards Balance',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Available balance: ₹${rewardsBalance.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _useRewardsWallet,
                          onChanged: rewardsBalance > 0 
                            ? (val) => setState(() => _useRewardsWallet = val)
                            : null,
                          activeColor: PayRozTheme.accentColor,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Price Breakdown Card
                  Container(
                    width: double.infinity,
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recharge Amount', style: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.textMuted)),
                            Text('₹${widget.amount.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (walletDeduction > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Rewards Deducted', style: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.successColor)),
                              Text('- ₹${walletDeduction.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: PayRozTheme.successColor)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Processing Fees', style: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.textMuted)),
                            Text('₹0.00', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Net Payable', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: PayRozTheme.primaryColor)),
                            Text('₹${netPayable.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: PayRozTheme.accentColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar containing "Pay Now" Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ]
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _executePayment,
                child: provider.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Pay ₹${netPayable.toStringAsFixed(2)} Now'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
