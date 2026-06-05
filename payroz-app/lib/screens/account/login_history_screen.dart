import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      Provider.of<PayRozProvider>(context, listen: false).fetchLoginHistory();
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final history = provider.loginHistory;

    return Scaffold(
      backgroundColor: PayRozTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Login History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => provider.fetchLoginHistory(),
          )
        ],
      ),
      body: provider.isLoading && history.isEmpty
          ? const Center(child: CircularProgressIndicator(color: PayRozTheme.accentColor))
          : history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 64, color: PayRozTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No login history available',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: PayRozTheme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, idx) {
                    final item = history[idx];
                    final date = DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now();
                    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: PayRozTheme.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: PayRozTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.phone_android,
                                color: PayRozTheme.accentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['deviceId'] == 'Unknown' || item['deviceId'] == null
                                        ? 'Mobile App Login'
                                        : 'Device ID: ${item['deviceId']}',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: PayRozTheme.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'IP Address: ${item['ip'] ?? "Unknown"}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: PayRozTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: PayRozTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.verified_user,
                              color: PayRozTheme.successColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
