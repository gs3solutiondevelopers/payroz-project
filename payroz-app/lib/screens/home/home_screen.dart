import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/payroz_models.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';
import 'service_form_screen.dart';
import 'ai_chat_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBalance = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PayRozProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Map backend icon string to Flutter IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'smartphone': return Icons.phone_android;
      case 'tv': return Icons.tv;
      case 'play': return Icons.play_arrow;
      case 'tag': return Icons.local_offer_outlined;
      case 'wifi': return Icons.wifi;
      case 'lightbulb': return Icons.lightbulb_outline;
      case 'flame': return Icons.local_fire_department;
      case 'droplet': return Icons.water_drop_outlined;
      case 'router': return Icons.router_outlined;
      case 'cylinder': return Icons.propane_tank_outlined;
      case 'building': return Icons.domain;
      case 'bike': return Icons.motorcycle;
      case 'car': return Icons.directions_car_filled;
      case 'activity': return Icons.favorite_border;
      case 'shield': return Icons.shield_outlined;
      case 'receipt': return Icons.receipt_long;
      default: return Icons.widgets_outlined;
    }
  }

  Color _getIconColor(String iconName) {
    switch (iconName) {
      case 'smartphone': return PayRozTheme.infoColor;
      case 'tv': return PayRozTheme.accentColor;
      case 'play': return Colors.green;
      case 'tag': return Colors.teal;
      case 'wifi': return Colors.indigo;
      case 'lightbulb': return PayRozTheme.warningColor;
      case 'flame': return Colors.deepOrange;
      case 'droplet': return Colors.blue;
      case 'router': return Colors.purple;
      case 'cylinder': return Colors.red;
      case 'building': return Colors.blueGrey;
      case 'bike': return PayRozTheme.primaryColor;
      case 'car': return PayRozTheme.infoColor;
      case 'activity': return PayRozTheme.errorColor;
      default: return PayRozTheme.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final user = provider.currentUser;
    final allCategories = provider.categories;
    final l10n = AppLocalizations.of(context)!;
    final List<Service> searchResults = [];
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      for (var cat in allCategories) {
        for (var srv in cat.services) {
          if (srv.name.toLowerCase().contains(query)) {
            searchResults.add(srv);
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC), // Slate 50 (Very light slate blue-grey)
              Color(0xFFEEF2F6), // Slate 100
              Color(0xFFE2E8F0), // Slate 200
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: provider.fetchDashboard,
          color: PayRozTheme.accentColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Premium Brand Sticky Header (Navy to Slate Blue with Orange Accent Glows)
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeHeaderDelegate(
                  topPadding: MediaQuery.of(context).padding.top,
                  minHeight: MediaQuery.of(context).padding.top + 145, // Header + Search + border radius buffer
                  maxHeight: _searchQuery.isNotEmpty 
                      ? MediaQuery.of(context).padding.top + 145 
                      : MediaQuery.of(context).padding.top + 350, // Header + Search + Wallet Card + padding
                  backgroundGlows: Stack(
                    children: [
                      Positioned(
                        right: -60,
                        top: -60,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: PayRozTheme.accentColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -50,
                        bottom: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  logoAndSearch: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. TOP HEADER ROW (App Bar)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo + White/Orange Branding
                          Image.asset(
                            'assets/images/file_00000000ee187208bda1e6e3562f6515.png',
                            height: 38,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/Screenshot_2026-06-03_203024-removebg-preview.png',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.8,
                                    ),
                                    children: const [
                                      TextSpan(text: 'PAY', style: TextStyle(color: Colors.white)),
                                      TextSpan(text: 'ROZ', style: TextStyle(color: PayRozTheme.accentColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Glassmorphic Actions (AI support & Notification bell)
                          Row(
                            children: [
                              // AI Support button
                              GestureDetector(
                                onTap: () { return; 
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: PayRozTheme.primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: PayRozTheme.primaryColor.withOpacity(0.15), width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, size: 13, color: PayRozTheme.accentColor),
                                      const SizedBox(width: 5),
                                      Text(
                                        l10n.aiSupport,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: PayRozTheme.primaryColor,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Notifications icon
                              GestureDetector(
                                onTap: () { return; 
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: PayRozTheme.primaryColor.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: PayRozTheme.primaryColor.withOpacity(0.15)),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(Icons.notifications_none_outlined, color: PayRozTheme.primaryColor, size: 20),
                                      if (provider.notifications.isNotEmpty)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: PayRozTheme.accentColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 18),
                      // 2. SEARCH BAR (Glassmorphic)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PayRozTheme.primaryColor.withOpacity(0.1), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.black54, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                                style: GoogleFonts.outfit(fontSize: 14, color: PayRozTheme.primaryColor, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: l10n.searchHint,
                                  hintStyle: GoogleFonts.outfit(color: Colors.black38, fontSize: 13.5, fontWeight: FontWeight.normal),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () { return; 
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: const Icon(Icons.clear, color: Colors.black54, size: 20),
                              )
                            else
                              const Icon(Icons.qr_code_scanner_outlined, color: PayRozTheme.accentColor, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  walletCard: _searchQuery.trim().isNotEmpty ? null : Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF090D16)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PayRozTheme.accentColor.withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: PayRozTheme.accentColor.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          // Glow decorative circles
                          Positioned(
                            right: -40,
                            top: -40,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: PayRozTheme.accentColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            left: -25,
                            bottom: -45,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Content Padding
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          l10n.rewardsWalletBalance.toUpperCase(),
                                          style: GoogleFonts.outfit(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => setState(() => _showBalance = !_showBalance),
                                          child: Icon(
                                            _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: Colors.white60,
                                            size: 14,
                                          ),
                                        )
                                      ],
                                    ),
                                    // Gold Card Chip
                                    Container(
                                      width: 28,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                                      ),
                                      child: CustomPaint(
                                        painter: ChipLinesPainter(),
                                      ),
                                    )
                                  ],
                                ),
                                // Balance & VIP Branding
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _showBalance ? '₹${(user?.rewardsBalance != null && user!.rewardsBalance > 0) ? user!.rewardsBalance.toStringAsFixed(2) : "250.00"}' : '••••••',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'REWARDS & CASHBACK',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white54,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1.0,
                                          ),
                                        )
                                      ],
                                    ),
                                    Text(
                                      'PAYROZ VIP',
                                      style: GoogleFonts.outfit(
                                        color: PayRozTheme.accentColor.withOpacity(0.85),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.5,
                                      ),
                                    )
                                  ],
                                ),
                                // Separator Line
                                Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                // Stats Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildWalletMiniStat(
                                      title: 'Cashback',
                                      value: '₹10,284',
                                      icon: Icons.stars,
                                      iconColor: PayRozTheme.accentColor,
                                    ),
                                    _buildWalletMiniStat(
                                      title: 'Referrals',
                                      value: '₹2,150',
                                      icon: Icons.people_alt,
                                      iconColor: Colors.lightBlueAccent,
                                    ),
                                    _buildWalletMiniStat(
                                      title: 'Refunds',
                                      value: '₹320',
                                      icon: Icons.history,
                                      iconColor: Colors.amberAccent,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const SizedBox(height: 20),
                if (_searchQuery.trim().isNotEmpty) ...[
                  // 2b. SEARCH RESULTS
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Results for "$_searchQuery"',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        if (searchResults.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off_outlined, size: 48, color: Colors.black26),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No services found matching "$_searchQuery"',
                                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: searchResults.length,
                            itemBuilder: (context, idx) {
                              final srv = searchResults[idx];
                              return Card(
                                color: Colors.white,
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.black.withOpacity(0.05)),
                                ),
                                child: ListTile(
                                  onTap: () { return; 
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormScreen(service: srv)));
                                  },
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0B192C),
                                          Color(0xFF1E293B),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: PayRozTheme.accentColor.withOpacity(0.4), width: 1.2),
                                    ),
                                    child: Icon(_getIconData(srv.icon), color: PayRozTheme.accentColor, size: 20),
                                  ),
                                  title: Text(
                                    srv.name,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13, color: const Color(0xFF0F172A)),
                                  ),
                                  trailing: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF64748B)),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ] else ...[

                    // 4. SMART REMINDERS (Top Actions For You)
                    if (false && provider.reminders.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Top Actions For You',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0B192C), // Brand Midnight Navy
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: PayRozTheme.errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${provider.reminders.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                                  ),
                                )
                              ],
                            ),
                            Text(
                              'View All',
                              style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.accentColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Horizontal scroll of Reminders
                      SizedBox(
                        height: 125,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          itemCount: provider.reminders.length,
                          itemBuilder: (context, index) {
                            final r = provider.reminders[index];
                            final serviceId = r['serviceId'];
                            
                            // Pick icon, color, status based on serviceName
                            IconData logo = Icons.widgets_outlined;
                            Color statusColor = PayRozTheme.infoColor;
                            final String sName = r['serviceName']?.toString() ?? '';
                            if (sName.contains('Recharge')) {
                              logo = Icons.phone_android;
                              statusColor = PayRozTheme.errorColor;
                            } else if (sName.contains('Bill') || sName.contains('Booking') || sName.contains('Tax')) {
                              logo = Icons.lightbulb_outline;
                              statusColor = PayRozTheme.warningColor;
                            } else if (sName.contains('Insurance')) {
                              logo = Icons.motorcycle;
                              statusColor = PayRozTheme.infoColor;
                            }

                            return GestureDetector(
                              onTap: () { return; 
                                if (serviceId != null) {
                                  Service? matchedService;
                                  for (var cat in provider.categories) {
                                    for (var srv in cat.services) {
                                      if (srv.id == serviceId) {
                                        matchedService = srv;
                                        break;
                                      }
                                    }
                                  }
                                  if (matchedService != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ServiceFormScreen(
                                          service: matchedService!,
                                          prefilledInputs: Map<String, dynamic>.from(r['inputsUsed'] ?? {}),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: _buildReminderCard(
                                status: r['title'] ?? 'Action Needed',
                                statusColor: statusColor,
                                title: sName,
                                subtitle: r['message'] ?? '',
                                amount: r['amount'] != null ? '₹${r['amount']}' : '',
                                buttonText: 'Pay Now',
                                logo: logo,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5. DYNAMIC CATEGORIES FEED (Recharge, BBPS, Insurance)
                    if (provider.categories.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: PayRozTheme.accentColor)))
                    else
                      ...provider.categories.map((category) {
                        if (category.name == 'Recharge Zone') {
                          return _buildRechargeZone(context, category);
                        } else if (category.name.contains('BBPS') || category.name.contains('Bill')) {
                          return _buildBbpsZone(context, category);
                        } else if (category.name.contains('Insurance')) {
                          return _buildInsuranceZone(context, category);
                        } else {
                          return _buildDefaultCategoryZone(context, category);
                        }
                      }),

                    // 6. MARKETING PROMO BANNERS
                    SizedBox(
                      height: 110,
                      child: provider.banners.isEmpty
                          ? ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                _buildFallbackBanner(
                                  gradientColors: [Colors.purple.shade700, Colors.deepPurpleAccent],
                                  title: 'Refer & Earn\nUnlimited Cash',
                                  subtitle: 'Invite friends, earn ₹50 each',
                                  actionText: 'Refer Now',
                                  icon: Icons.people,
                                ),
                                _buildFallbackBanner(
                                  gradientColors: [const Color(0xFFE65C00), const Color(0xFFF9D423)],
                                  title: 'Flat ₹25 Cashback\nOn Mobile Recharge',
                                  subtitle: 'First transaction offer',
                                  actionText: 'Recharge Now',
                                  icon: Icons.bolt,
                                ),
                              ],
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: provider.banners.length,
                              itemBuilder: (context, index) {
                                final banner = provider.banners[index];
                                return Container(
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      banner.imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey.shade100,
                                          alignment: Alignment.center,
                                          child: const CircularProgressIndicator(color: PayRozTheme.accentColor, strokeWidth: 2),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [PayRozTheme.primaryColor, Colors.blueGrey.shade800],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Special Promotion Active!',
                                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),

                    // 7. OFFERS SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 14,
                            decoration: BoxDecoration(
                              color: PayRozTheme.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Offers For You',
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0B192C), // Midnight Navy
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 105,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.offers.length,
                        itemBuilder: (context, idx) {
                          final offer = provider.offers[idx];
                          final isEven = idx % 2 == 0;
                          return Container(
                            width: 270,
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isEven 
                                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] // Premium Deep Navy
                                  : [const Color(0xFFFF7B00), const Color(0xFFFF5500)], // Vibrant Orange
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isEven ? const Color(0xFF0F172A) : const Color(0xFFFF5500)).withOpacity(0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Left Icon / Bubble
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'FLAT',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 8,
                                        ),
                                      ),
                                      Text(
                                        '₹${offer.cashbackAmount.toInt()}',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Offer Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        offer.title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        offer.description,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      // Promo Code Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.local_offer_rounded, color: Colors.white, size: 12),
                                            const SizedBox(width: 6),
                                            Text(
                                              offer.promoCode,
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  // Mini Stat Card inside Wallet
  Widget _buildWalletMiniStat({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 12),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w500)),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }

  // 1. Customized Recharge Zone Widget
  Widget _buildRechargeZone(BuildContext context, ServiceCategory category) {
    const Color brandBlue = Color(0xFF022268);
    const Color brandBlueMid = Color(0xFF0A3A8F);
    const Color brandBlueLight = Color(0xFF5B8DD9);
    const Color brandBluePale = Color(0xFFD6E4F7);
    const Color brandBlueFrost = Color(0xFFEBF1FA);
    
    // Calculate width to show exactly 3 cards (padding: 16*2 outer + 18*2 inner = 68. Gaps: 10*2 = 20)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth - 68 - 20) / 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFD9E5F8),
            Color(0xFFB8CCF0),
          ],
          stops: [0.0, 0.45, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brandBlue.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative floating geometric shapes
            Positioned(
              right: -25,
              top: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      brandBlue.withOpacity(0.06),
                      brandBlue.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: 15,
              child: Transform.rotate(
                angle: 0.5,
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: brandBlueLight.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 50,
              bottom: -12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: brandBlue.withOpacity(0.05), width: 1.5),
                ),
              ),
            ),
            // Subtle dot grid pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _DotPatternPainter(color: brandBlue.withOpacity(0.018)),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Header — Thunder icon (no bg) + Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Thunder icon with subtle glow — no rectangle bg, bigger size
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(Icons.bolt_rounded, color: brandBlue, size: 32),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w500,
                              color: brandBlue,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Instant recharge & top-ups',
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Horizontal scrolling service cards
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: category.services.length,
                      itemBuilder: (context, idx) {
                        final service = category.services[idx];

                        // Icon mapping
                        IconData serviceIcon = Icons.phone_android_rounded;
                        final name = service.name.toLowerCase();
                        if (name.contains('mobile')) {
                          serviceIcon = Icons.smartphone_rounded;
                        } else if (name.contains('dth')) {
                          serviceIcon = Icons.live_tv_rounded;
                        } else if (name.contains('play') || name.contains('google')) {
                          serviceIcon = Icons.sports_esports_rounded;
                        } else if (name.contains('tag') || name.contains('fastag')) {
                          serviceIcon = Icons.local_offer_rounded;
                        } else if (name.contains('data') || name.contains('wifi')) {
                          serviceIcon = Icons.wifi_rounded;
                        } else {
                          serviceIcon = _getIconData(service.icon);
                        }

                        return GestureDetector(
                          onTap: () { return; 
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormScreen(service: service)));
                          },
                          child: Container(
                            width: cardWidth, // Dynamically set to fit 3 options
                            margin: EdgeInsets.only(right: idx < category.services.length - 1 ? 10 : 0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFE6504).withOpacity(0.85), // Softer orange at top
                                  Colors.white, // Pure white at bottom
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.65], // Smooth spread down to 65%
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFFE6504).withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFE6504).withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Icon circle
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFE6504).withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(color: const Color(0xFFFE6504).withOpacity(0.1)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    serviceIcon,
                                    color: brandBlue,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Service name
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    service.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Customized BBPS Zone Widget (Premium Gradient Container + 3-Column Grid)
  Widget _buildBbpsZone(BuildContext context, ServiceCategory category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0F2FE), // Light sky blue
            Color(0xFFBAE6FD), // Sky blue
            Color(0xFF7DD3FC), // Deeper sky blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7DD3FC).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative shapes for premium look
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          category.name.replaceAll(RegExp(r'\s*\(BBPS\)', caseSensitive: false), '').trim(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0C4A6E),
                          ),
                        ),
                      ],
                    ),
                    // BBPS Logo
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/en/thumb/4/46/Bharat_BillPay_logo.svg/1200px-Bharat_BillPay_logo.svg.png',
                      height: 16,
                      errorBuilder: (c, e, s) => const SizedBox(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Services Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: category.services.length,
                  itemBuilder: (context, idx) {
                    final service = category.services[idx];
                    
                    // Specific styling per service type
                    IconData serviceIcon = Icons.receipt_long_rounded;
                    Color iconCol = const Color(0xFF334155);
                    
                    final name = service.name.toLowerCase();
                    if (name.contains('electricity')) {
                      serviceIcon = Icons.lightbulb_rounded;
                      iconCol = const Color(0xFFF59E0B);
                    } else if (name.contains('gas')) {
                      serviceIcon = Icons.local_fire_department_rounded;
                      iconCol = const Color(0xFFEF4444);
                    } else if (name.contains('water')) {
                      serviceIcon = Icons.water_drop_rounded;
                      iconCol = const Color(0xFF0EA5E9);
                    } else if (name.contains('broadband') || name.contains('internet')) {
                      serviceIcon = Icons.router_rounded;
                      iconCol = const Color(0xFF8B5CF6);
                    } else if (name.contains('lpg')) {
                      serviceIcon = Icons.propane_tank_rounded;
                      iconCol = const Color(0xFFF43F5E);
                    } else if (name.contains('municipal')) {
                      serviceIcon = Icons.apartment_rounded;
                      iconCol = const Color(0xFF64748B);
                    } else {
                      serviceIcon = _getIconData(service.icon);
                    }

                    return GestureDetector(
                      onTap: () { return; 
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormScreen(service: service)));
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0C4A6E).withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(serviceIcon, color: iconCol, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service.name,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0C4A6E),
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Customized Insurance Zone Widget (Premium Horizontal Quote Cards)
  Widget _buildInsuranceZone(BuildContext context, ServiceCategory category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF0FDF4), // very light mint
            Color(0xFFCCFBF1), // soft teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF99F6E4).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF0F766E), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF134E4A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Services Horizontal scrolling list
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: category.services.length,
                itemBuilder: (context, idx) {
                  final service = category.services[idx];
                  
                  // Specific styling per service type
                  IconData serviceIcon = Icons.shield_rounded;
                  Color startCol = const Color(0xFF8B5CF6);
                  Color endCol = const Color(0xFF7C3AED);
                  String badgeText = "Save 50%";
                  String subt = "Instant Policy";

                  final name = service.name.toLowerCase();
                  if (name.contains('bike') || name.contains('two')) {
                    serviceIcon = Icons.motorcycle_rounded;
                    startCol = const Color(0xFF14B8A6);
                    endCol = const Color(0xFF0D9488);
                    badgeText = "Up to 50% Off";
                    subt = "Quick Premium";
                  } else if (name.contains('car') || name.contains('four')) {
                    serviceIcon = Icons.directions_car_filled_rounded;
                    startCol = const Color(0xFF3B82F6);
                    endCol = const Color(0xFF2563EB);
                    badgeText = "Cashless Garage";
                    subt = "Best Coverage";
                  } else if (name.contains('health') || name.contains('medical')) {
                    serviceIcon = Icons.favorite_rounded;
                    startCol = const Color(0xFFF43F5E);
                    endCol = const Color(0xFFE11D48);
                    badgeText = "Paperless Claim";
                    subt = "Family Cover";
                  }

                  return GestureDetector(
                    onTap: () { return; 
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormScreen(service: service)));
                    },
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [startCol, endCol],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: endCol.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Stack(
                        children: [
                          // Decorative subtle shape
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(serviceIcon, size: 70, color: Colors.white.withOpacity(0.15)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(serviceIcon, color: endCol, size: 16),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        subt,
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right, size: 10, color: Colors.white.withOpacity(0.9)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Fallback Default Category Widget
  Widget _buildDefaultCategoryZone(BuildContext context, ServiceCategory category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14.0, 18.0, 14.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: PayRozTheme.accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0B192C),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: PayRozTheme.accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PayRozTheme.accentColor.withOpacity(0.15), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: PayRozTheme.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_ios, size: 8, color: PayRozTheme.accentColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.80,
                crossAxisSpacing: 8,
                mainAxisSpacing: 12,
              ),
              itemCount: category.services.length,
              itemBuilder: (context, idx) {
                final service = category.services[idx];
                return GestureDetector(
                  onTap: () { return; 
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormScreen(service: service)));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _getIconData(service.icon),
                          color: const Color(0xFF0B192C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service.name,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Modern fallback promo banner if banners fail to load or are empty
  Widget _buildFallbackBanner({
    required List<Color> gradientColors,
    required String title,
    required String subtitle,
    required String actionText,
    required IconData icon,
  }) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    actionText,
                    style: GoogleFonts.outfit(
                      color: gradientColors[0],
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white30, size: 48),
        ],
      ),
    );
  }

  // Modernized Glassmorphic Reminder card
  Widget _buildReminderCard({
    required String status,
    required Color statusColor,
    required String title,
    required String subtitle,
    required String amount,
    required String buttonText,
    required IconData logo,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFFBFDFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: PayRozTheme.accentColor.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(logo, color: statusColor, size: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: const Color(0xFF64748B),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (amount.isNotEmpty)
                Text(
                  amount,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                )
              else
                const SizedBox(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      buttonText,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: Colors.white, size: 9),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Gold Card Chip lines painter
class ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 1.0;
    
    // Draw chip design grid lines
    canvas.drawLine(Offset(size.width * 0.33, 0), Offset(size.width * 0.33, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.66, 0), Offset(size.width * 0.66, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.2), Offset(size.width * 0.15, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width * 0.85, size.height * 0.2), Offset(size.width * 0.85, size.height * 0.8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Dotted ticket separator line painter
class DashLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.2) // Brand Orange dashed divider
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    double maxExtent = size.height;
    double dashHeight = 3.0;
    double dashSpace = 2.5;
    double startY = 0.0;
    
    while (startY < maxExtent) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Subtle dot grid pattern painter for Recharge Zone background
class _DotPatternPainter extends CustomPainter {
  final Color color;
  _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double spacing = 22.0;
    const double radius = 1.2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final double minHeight;
  final double maxHeight;
  final Widget logoAndSearch;
  final Widget? walletCard;
  final Widget backgroundGlows;

  _HomeHeaderDelegate({
    required this.topPadding,
    required this.minHeight,
    required this.maxHeight,
    required this.logoAndSearch,
    this.walletCard,
    required this.backgroundGlows,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double scrollRange = maxExtent - minExtent;
    final double scrollFraction = scrollRange > 0 ? (shrinkOffset / scrollRange).clamp(0.0, 1.0) : 0.0;
    // Wallet fades out as we scroll (disappears at ~65% scroll)
    final double walletOpacity = (1.0 - scrollFraction * 1.5).clamp(0.0, 1.0);
    // Wallet positioned below logo+search. Logo(38) + Gap(18) + Search(~58) = ~114. Plus 20px gap = 134.
    final double walletBaseTop = topPadding + 16 + 134;
    // Wallet scrolls up 1:1 with content
    final double walletTop = walletBaseTop - shrinkOffset;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Orange gradient background — fills entire header, clipped with rounded corners
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, PayRozTheme.accentColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: backgroundGlows,
            ),
          ),
        ),
        // Wallet card — slides up & fades as you scroll
        if (walletCard != null && walletOpacity > 0)
          Positioned(
            top: walletTop,
            left: 16,
            right: 16,
            child: Opacity(
              opacity: walletOpacity,
              child: walletCard!,
            ),
          ),
        // Logo + Search — always stays pinned at top
        Positioned(
          top: topPadding + 16,
          left: 16,
          right: 16,
          child: logoAndSearch,
        ),
      ],
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
