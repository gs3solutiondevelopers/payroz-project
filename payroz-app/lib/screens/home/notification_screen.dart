import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final list = provider.notifications;

    return Scaffold(
      backgroundColor: PayRozTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: PayRozTheme.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: GoogleFonts.outfit(fontSize: 14, color: PayRozTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, idx) {
                final notif = list[idx];
                
                IconData leadingIcon = Icons.notifications;
                Color circleColor = PayRozTheme.infoColor;

                if (notif.type == 'Cashback') {
                  leadingIcon = Icons.stars;
                  circleColor = PayRozTheme.successColor;
                } else if (notif.type == 'Refund') {
                  leadingIcon = Icons.cached;
                  circleColor = PayRozTheme.errorColor;
                } else if (notif.type == 'Reminder') {
                  leadingIcon = Icons.schedule;
                  circleColor = PayRozTheme.warningColor;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PayRozTheme.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: circleColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(leadingIcon, color: circleColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(notif.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(
                                  DateFormat('hh:mm a').format(notif.createdAt),
                                  style: GoogleFonts.outfit(fontSize: 9, color: PayRozTheme.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.message,
                              style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.textMuted, height: 1.4),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
