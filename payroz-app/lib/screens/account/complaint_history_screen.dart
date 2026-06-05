import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';
import '../../models/payroz_models.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  const ComplaintHistoryScreen({super.key});

  @override
  State<ComplaintHistoryScreen> createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      Provider.of<PayRozProvider>(context, listen: false).fetchTickets();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRaiseTicketForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RaiseTicketScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final allTickets = provider.tickets;

    List<Ticket> getFilteredTickets(String status) {
      if (status == 'All') return allTickets;
      return allTickets.where((t) => t.status.toLowerCase() == status.toLowerCase()).toList();
    }

    Widget buildTicketList(String status) {
      final tickets = getFilteredTickets(status);

      if (provider.isLoading && allTickets.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: PayRozTheme.accentColor));
      }

      if (tickets.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: PayRozTheme.textMuted.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'No tickets in this section',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: PayRozTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, idx) {
          final tkt = tickets[idx];
          final date = tkt.updatedAt;
          final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

          Color statusColor = PayRozTheme.textMuted;
          if (tkt.status == 'Open') {
            statusColor = PayRozTheme.infoColor;
          } else if (tkt.status == 'Processing') {
            statusColor = PayRozTheme.warningColor;
          } else if (tkt.status == 'Resolved') {
            statusColor = PayRozTheme.successColor;
          } else if (tkt.status == 'Closed') {
            statusColor = PayRozTheme.textMuted;
          }

          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: PayRozTheme.borderColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TicketChatScreen(ticket: tkt)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tkt.ticketNumber,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: PayRozTheme.accentColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tkt.status,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tkt.subject,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: PayRozTheme.textMain),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tkt.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 12, color: PayRozTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last Updated: $formattedDate',
                          style: GoogleFonts.outfit(fontSize: 10, color: PayRozTheme.textMuted),
                        ),
                        Text(
                          'View Discussion →',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: PayRozTheme.primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: PayRozTheme.backgroundColor,
      appBar: AppBar(
        title: Text('My Support Tickets', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          labelColor: PayRozTheme.accentColor,
          unselectedLabelColor: PayRozTheme.textMuted,
          indicatorColor: PayRozTheme.accentColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Open'),
            Tab(text: 'Processing'),
            Tab(text: 'Resolved'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PayRozTheme.primaryColor,
        onPressed: _openRaiseTicketForm,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('RAISE TICKET', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTicketList('All'),
          buildTicketList('Open'),
          buildTicketList('Processing'),
          buildTicketList('Resolved'),
          buildTicketList('Closed'),
        ],
      ),
    );
  }
}

class RaiseTicketScreen extends StatefulWidget {
  const RaiseTicketScreen({super.key});

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedTransactionId;

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PayRozProvider>(context, listen: false);
    final success = await provider.createTicket(
      _subjectController.text.trim(),
      _descController.text.trim(),
      _selectedTransactionId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Support ticket raised successfully!' : 'Failed to raise ticket. Please try again.',
            style: GoogleFonts.outfit(fontSize: 13),
          ),
          backgroundColor: success ? PayRozTheme.successColor : PayRozTheme.errorColor,
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);
    final transactions = provider.transactions;

    return Scaffold(
      backgroundColor: PayRozTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Raise Support Ticket', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ticket Subject',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: PayRozTheme.textMain),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g., Double deduction, Payment failed but money debited',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Related Transaction (Optional)',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: PayRozTheme.textMain),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTransactionId,
                style: GoogleFonts.outfit(fontSize: 14, color: PayRozTheme.textMain),
                decoration: const InputDecoration(
                  hintText: 'Select Transaction',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None / General Inquiry')),
                  ...transactions.map((tx) => DropdownMenuItem(
                        value: tx.id,
                        child: Text('${tx.serviceName} - ₹${tx.amount} (${tx.status})'),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedTransactionId = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Detailed Description',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: PayRozTheme.textMain),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe your issue in detail. Please mention date, time, and operator reference if available.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PayRozTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: provider.isLoading ? null : _submitTicket,
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('SUBMIT TICKET', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketChatScreen extends StatefulWidget {
  final Ticket ticket;
  const TicketChatScreen({super.key, required this.ticket});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      Provider.of<PayRozProvider>(context, listen: false).fetchMessages(widget.ticket.id);
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final provider = Provider.of<PayRozProvider>(context, listen: false);
    await provider.sendTicketReply(widget.ticket.id, text);

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final messages = provider.activeTicketMessages;

    Color statusColor = PayRozTheme.textMuted;
    if (widget.ticket.status == 'Open') {
      statusColor = PayRozTheme.infoColor;
    } else if (widget.ticket.status == 'Processing') {
      statusColor = PayRozTheme.warningColor;
    } else if (widget.ticket.status == 'Resolved') {
      statusColor = PayRozTheme.successColor;
    } else if (widget.ticket.status == 'Closed') {
      statusColor = PayRozTheme.textMuted;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light slate color for chat background
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ticket.ticketNumber, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(widget.ticket.subject, style: GoogleFonts.outfit(fontSize: 10, color: PayRozTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.ticket.status,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 10, color: statusColor),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: PayRozTheme.accentColor))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, idx) {
                      final msg = messages[idx];
                      final isStaff = msg.senderType.toLowerCase() == 'staff';
                      final date = msg.createdAt;
                      final timeStr = DateFormat('hh:mm a').format(date);

                      return Align(
                        alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isStaff ? Colors.white : PayRozTheme.primaryColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isStaff ? 0 : 12),
                              bottomRight: Radius.circular(isStaff ? 12 : 0),
                            ),
                            border: isStaff ? Border.all(color: PayRozTheme.borderColor) : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg.message,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isStaff ? PayRozTheme.textMain : Colors.white,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  timeStr,
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: isStaff ? PayRozTheme.textMuted : Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Message input bar
          if (widget.ticket.status != 'Closed')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: PayRozTheme.borderColor)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        style: GoogleFonts.outfit(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.outfit(fontSize: 13, color: PayRozTheme.textMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: PayRozTheme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: PayRozTheme.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: PayRozTheme.accentColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                        onSubmitted: (_) => _sendReply(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: PayRozTheme.accentColor,
                      elevation: 0,
                      onPressed: _sendReply,
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
