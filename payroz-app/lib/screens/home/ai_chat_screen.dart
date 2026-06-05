import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final messages = provider.aiChatMessages;

    // Scroll down on load/update
    _scrollToBottom();

    void _sendMessage() async {
      final text = _msgController.text.trim();
      if (text.isEmpty) return;

      _msgController.clear();
      await provider.sendAiMessage(text);
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: PayRozTheme.primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.adb, color: PayRozTheme.accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PAYROZ AI Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('Online Chatbot', style: TextStyle(color: PayRozTheme.successColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Banner Notice
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFFFFF7ED),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.orange, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'AI bot can resolve refunds. Type "agent" to connect to a human.',
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                  ),
                )
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, idx) {
                final msg = messages[idx];
                final isAi = msg['sender'] == 'AI';
                final timeStr = DateFormat('hh:mm a').format(msg['time']);

                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isAi ? Colors.white : PayRozTheme.primaryColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isAi ? Radius.zero : const Radius.circular(12),
                              bottomRight: isAi ? const Radius.circular(12) : Radius.zero,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))
                            ]
                          ),
                          child: Text(
                            msg['message'],
                            style: GoogleFonts.outfit(
                              fontSize: 12, 
                              color: isAi ? PayRozTheme.textMain : Colors.white,
                              height: 1.4
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(timeStr, style: GoogleFonts.outfit(fontSize: 8, color: PayRozTheme.textMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Send Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: PayRozTheme.borderColor))
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type message to AI assistant...',
                      hintStyle: GoogleFonts.outfit(fontSize: 13, color: PayRozTheme.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: PayRozTheme.primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
