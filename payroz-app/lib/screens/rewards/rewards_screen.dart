import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/payroz_provider.dart';
import '../../models/payroz_models.dart';
import '../../theme.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch scratch cards on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PayRozProvider>(context, listen: false).fetchScratchCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final user = provider.currentUser;
    final scratchCards = provider.scratchCards;

    return Scaffold(
      backgroundColor: PayRozTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Rewards & Scratch Cards', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchScratchCards();
          await provider.fetchProfile();
        },
        color: PayRozTheme.accentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cashback Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFFFF6B00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.yellow, size: 16),
                        const SizedBox(width: 6),
                        Text('REWARDS WALLET BALANCE', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('₹${user?.rewardsBalance.toStringAsFixed(2) ?? "0.00"}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Used automatically to discount recharge and BBPS utility payments.', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 9)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Scratch Cards Section
              Text('My Scratch Cards', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: PayRozTheme.primaryColor)),
              const SizedBox(height: 12),
              
              if (scratchCards.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PayRozTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.redeem_outlined, color: Colors.grey, size: 40),
                      const SizedBox(height: 12),
                      Text('No rewards yet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: PayRozTheme.primaryColor)),
                      const SizedBox(height: 4),
                      Text('Complete a recharge or utility bill payment to win scratch cards!', style: GoogleFonts.outfit(fontSize: 9, color: PayRozTheme.textMuted), textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: scratchCards.length,
                  itemBuilder: (context, index) {
                    final card = scratchCards[index];
                    return _buildScratchCardItem(context, card);
                  },
                ),
                
              const SizedBox(height: 30),

              // List of available coupons
              Text('Active Promo Codes', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: PayRozTheme.primaryColor)),
              const SizedBox(height: 12),
              ...provider.offers.map((offer) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PayRozTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: PayRozTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(offer.promoCode, style: GoogleFonts.outfit(color: PayRozTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(offer.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(offer.description, style: GoogleFonts.outfit(fontSize: 9, color: PayRozTheme.textMuted)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScratchCardItem(BuildContext context, ScratchCardModel card) {
    final isScratched = card.status == 'Scratched';
    
    return InkWell(
      onTap: () {
        if (!isScratched) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => InteractiveScratchDialog(card: card),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You won ₹${card.amount.toStringAsFixed(2)} from this scratch card!', style: GoogleFonts.outfit()),
              backgroundColor: PayRozTheme.primaryColor,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isScratched ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isScratched ? Colors.orange.shade200 : PayRozTheme.borderColor,
            width: isScratched ? 1.5 : 1,
          ),
          boxShadow: [
            if (!isScratched)
              const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isScratched ? Icons.check_circle_outline : Icons.redeem,
              color: isScratched ? Colors.orange : PayRozTheme.accentColor,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              isScratched ? '₹${card.amount.toStringAsFixed(0)}' : 'REWARD',
              style: GoogleFonts.outfit(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: isScratched ? Colors.orange.shade800 : PayRozTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isScratched ? 'Scratched' : 'Tap to reveal',
              style: GoogleFonts.outfit(fontSize: 7, color: PayRozTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class InteractiveScratchDialog extends StatefulWidget {
  final ScratchCardModel card;
  const InteractiveScratchDialog({super.key, required this.card});

  @override
  State<InteractiveScratchDialog> createState() => _InteractiveScratchDialogState();
}

class _InteractiveScratchDialogState extends State<InteractiveScratchDialog> with SingleTickerProviderStateMixin {
  double _scratchProgress = 0.0;
  bool _isRedeemed = false;
  double? _wonAmount;
  bool _isLoading = false;

  void _onScratch() async {
    if (_isRedeemed || _isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<PayRozProvider>(context, listen: false);
    final amount = await provider.scratchCard(widget.card.id);

    setState(() {
      _isLoading = false;
      if (amount != null) {
        _wonAmount = amount;
        _isRedeemed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 300,
        height: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRedeemed ? 'Congratulations! 🎉' : 'Scratch & Win!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: PayRozTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              _isRedeemed 
                ? 'Added to your Rewards Wallet' 
                : 'Drag your finger across the card below to reveal your prize.',
              style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Scratchable Card Container
            GestureDetector(
              onPanUpdate: (details) {
                if (_scratchProgress < 1.0) {
                  setState(() {
                    _scratchProgress += 0.02; // Increment progress as they swipe
                  });
                  if (_scratchProgress >= 1.0) {
                    _onScratch();
                  }
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Revealed Reward (Behind Layer)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _wonAmount != null 
                            ? '₹${_wonAmount!.toStringAsFixed(2)}' 
                            : '₹${widget.card.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: PayRozTheme.accentColor),
                        ),
                        const SizedBox(height: 4),
                        Text('CASHBACK', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: PayRozTheme.textMuted)),
                      ],
                    ),
                  ),

                  // Silver Scratch Layer (Fades out when scratched)
                  if (!_isRedeemed)
                    Opacity(
                      opacity: (1.0 - _scratchProgress).clamp(0.0, 1.0),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade300, Colors.grey.shade400, Colors.grey.shade300],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.redeem, color: Colors.white, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'PAYROZ REWARDS',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator(color: PayRozTheme.accentColor)
            else if (_isRedeemed)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PayRozTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Awesome!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              )
            else
              Text(
                'Scratching: ${(_scratchProgress * 100).clamp(0, 100).toInt()}%',
                style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.accentColor, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
