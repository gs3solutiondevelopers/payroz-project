import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';
import '../home/payment_receipt_screen.dart';
import '../home/ai_chat_screen.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  State<TransactionsHistoryScreen> createState() => _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _activeFilter = 'All'; // 'All', 'Refunds', 'Cashback'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      final filters = ['All', 'Refunds', 'Cashback'];
      setState(() {
        _activeFilter = filters[_tabController.index];
      });
      Provider.of<PayRozProvider>(context, listen: false).fetchTransactions(_activeFilter);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PayRozProvider>(context, listen: false).fetchTransactions(_activeFilter);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final list = provider.transactions;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC), // Light blue-gray background
      appBar: AppBar(
        title: Text('All Transactions', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B192C),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 16, color: Color(0xFF0B192C)),
                  const SizedBox(width: 4),
                  Text('Filter', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0B192C))),
                ],
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Elegant Search box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, number or ID',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Premium Tab Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF7A00),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFFFF7A00),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Refunds'),
                Tab(text: 'Cashback'),
              ],
            ),
          ),

          // List body
          Expanded(
            child: provider.isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
              : list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 60, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 16),
                        Text('No transactions found', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: list.length + 1,
                    itemBuilder: (context, idx) {
                      if (idx == list.length) {
                        return _buildHelpBanner(context);
                      }

                      final tx = list[idx];
                      return _buildTransactionCard(tx);
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildHelpBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 30),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need Help?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Raise a complaint or contact 24/7 support', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFFFF7A00), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    final isDb = tx.paymentMode != 'Rewards' && !tx.isRefund && !tx.isCashback; // Debit
    final isFailed = tx.status == 'Failed';
    final isPending = tx.status == 'Pending';

    Color amountColor = const Color(0xFF10B981); // Green
    String prefix = '+ ';
    String subText = 'Cashback';
    Color iconBg = const Color(0xFFECFDF5);
    Color iconColor = const Color(0xFF10B981);
    IconData icon = Icons.south_west; // Income arrow

    if (isDb) {
      amountColor = const Color(0xFF0F172A); // Dark navy for debits
      prefix = '- ';
      subText = 'Paid';
      iconBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF64748B);
      icon = Icons.north_east;
      
      if (isFailed) {
        amountColor = const Color(0xFFEF4444);
        iconBg = const Color(0xFFFEF2F2);
        iconColor = const Color(0xFFEF4444);
        icon = Icons.error_outline;
      }
    } else if (tx.isRefund) {
      amountColor = const Color(0xFF10B981);
      prefix = '+ ';
      subText = 'Refund';
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      icon = Icons.refresh;
    } else if (tx.isCashback) {
      amountColor = const Color(0xFFFF7A00); // Orange for cashback
      prefix = '+ ';
      subText = 'Cashback';
      iconBg = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFFF7A00);
      icon = Icons.stars;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!tx.isCashback && !tx.isRefund) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentReceiptScreen(transaction: tx)));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.serviceName, 
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy • hh:mm a').format(tx.createdAt), 
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$prefix₹${tx.amount.toInt()}',
                      style: GoogleFonts.outfit(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(subText, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                        if (isFailed || isPending) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFailed ? const Color(0xFFFEF2F2) : const Color(0xFFFEFCE8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isFailed ? const Color(0xFFFECACA) : const Color(0xFFFEF08A)),
                            ),
                            child: Text(
                              tx.status,
                              style: GoogleFonts.outfit(
                                color: isFailed ? const Color(0xFFEF4444) : const Color(0xFFEAB308), 
                                fontSize: 9, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          )
                        ]
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
