const { Transaction, ComplaintTicket, TicketMessage, Staff } = require('../models');
const { logSystem } = require('../services/automation');

// Simple NLP Rules Engine simulating a top-tier fintech AI Assistant
exports.processAiChatMessage = async (req, res) => {
  try {
    const user = req.user;
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message content required' });
    }

    const text = message.toLowerCase();
    let reply = '';
    let actionTriggered = 'None'; // 'TicketCreated', 'HumanTransfer', 'TxCheck'
    let metadata = {};

    // 1. FAQ: Wallet Rules
    if (text.includes('wallet') || text.includes('add money') || text.includes('topup') || text.includes('top up') || text.includes('load balance')) {
      reply = `In PAYROZ, there is NO option to manually add money or top up your wallet. Payments for all services are processed directly via your bank/Payment Gateway. Your Rewards Wallet only stores Cashback, Referrals, and Refunds, which can be applied to reduce the cost of future payments.`;
    }
    // 2. FAQ: Refunds
    else if (text.includes('refund') || text.includes('money deducted') || text.includes('failed payment')) {
      // Find the user's latest transaction
      const latestTx = await Transaction.findOne({
        where: { userId: user.id },
        order: [['createdAt', 'DESC']],
      });

      if (latestTx) {
        actionTriggered = 'TxCheck';
        metadata = {
          txId: latestTx.id,
          serviceName: latestTx.serviceName,
          amount: latestTx.amount,
          status: latestTx.status,
          date: latestTx.createdAt,
        };

        if (latestTx.status === 'Failed') {
          reply = `I see your latest transaction for ${latestTx.serviceName} of ₹${latestTx.amount} on ${new Date(latestTx.createdAt).toLocaleDateString()} failed. Don't worry! A full refund has been credited back to your Rewards Wallet. If you need further help, type "raise ticket" or "connect to agent".`;
        } else if (latestTx.status === 'Pending') {
          reply = `I see your latest transaction for ${latestTx.serviceName} of ₹${latestTx.amount} is currently PENDING. Our systems check pending transactions every 30 seconds. If it fails, you'll receive an automatic refund and a ticket will be opened. If you want to connect to a human agent, type "connect to agent".`;
        } else {
          reply = `Your latest transaction for ${latestTx.serviceName} of ₹${latestTx.amount} was SUCCESSFUL. Ref ID: ${latestTx.operatorRefId}. If you are referring to a different transaction, please type "raise ticket" so a staff member can look into it.`;
        }
      } else {
        reply = `I couldn't find any recent transactions in your history. Standard refund policy: Any failed payment is refunded back to your Rewards Wallet instantly.`;
      }
    }
    // 3. Connect to Human Staff
    else if (text.includes('agent') || text.includes('human') || text.includes('staff') || text.includes('chat with support') || text.includes('help')) {
      actionTriggered = 'HumanTransfer';
      
      const ticketNo = 'PRZ-TKT-' + Math.floor(100000 + Math.random() * 900000);
      const supportAgent = await Staff.findOne({ where: { role: 'Support', status: 'Active' } });
      const assignedId = supportAgent ? supportAgent.id : null;

      // Automatically create a ticket for human handoff
      const ticket = await ComplaintTicket.create({
        ticketNumber: ticketNo,
        userId: user.id,
        subject: 'Chat Handoff to Human Support',
        description: 'User requested transfer from AI bot during support session.',
        status: 'Open',
        assignedStaffId: assignedId,
      });

      // Insert message history
      await TicketMessage.create({
        ticketId: ticket.id,
        senderId: user.id,
        senderType: 'User',
        message: `Chat Handoff Request: ${message}`,
      });

      await TicketMessage.create({
        ticketId: ticket.id,
        senderId: assignedId || '00000000-0000-0000-0000-000000000000',
        senderType: 'Staff',
        message: `System: Transferring you to support officer. Ticket No: ${ticketNo}. Please wait...`,
      });

      reply = `I have created a support ticket (${ticketNo}) and transferred this conversation to a human support agent. They will join this chat shortly. You can track this in the Help & Support section.`;
      metadata = { ticketId: ticket.id, ticketNumber: ticketNo };

      await logSystem('Info', `AI transferred user ${user.phone} to human staff. Ticket: ${ticketNo}`);
    }
    // 4. Manual Ticket Creation from AI
    else if (text.includes('ticket') || text.includes('complaint') || text.includes('complain') || text.includes('raise ticket')) {
      actionTriggered = 'TicketCreated';
      const ticketNo = 'PRZ-TKT-' + Math.floor(100000 + Math.random() * 900000);
      const supportAgent = await Staff.findOne({ where: { role: 'Support', status: 'Active' } });
      const assignedId = supportAgent ? supportAgent.id : null;

      const ticket = await ComplaintTicket.create({
        ticketNumber: ticketNo,
        userId: user.id,
        subject: 'Complaint via AI Chatbot',
        description: `Self-reported issue during AI chat: "${message}"`,
        status: 'Open',
        assignedStaffId: assignedId,
      });

      await TicketMessage.create({
        ticketId: ticket.id,
        senderId: user.id,
        senderType: 'User',
        message: `AI chat query: "${message}"`,
      });

      reply = `I have successfully raised a complaint ticket for you! Ticket number: **${ticketNo}**. You will receive an update once our team reviews it.`;
      metadata = { ticketId: ticket.id, ticketNumber: ticketNo };
      
      await logSystem('Info', `Complaint ticket ${ticketNo} created for user ${user.phone} via AI chatbot`);
    }
    // 5. Default Fallback FAQ replies
    else {
      reply = `Hello! I am your PAYROZ AI Assistant. I can help you with:
1. Checking failed payment & refund status
2. Explaining wallet & reward rules (cashback, referrals)
3. Directing you to a human agent (type "agent" or "help")
4. Raising a complaint ticket (type "raise ticket")
      
How can I assist you today?`;
    }

    res.status(200).json({
      reply,
      actionTriggered,
      metadata,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
