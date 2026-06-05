const { ComplaintTicket, TicketMessage, Staff, Feedback } = require('../models');
const { logSystem } = require('../services/automation');

exports.createTicket = async (req, res) => {
  try {
    const user = req.user;
    const { subject, description, transactionId } = req.body;

    if (!subject || !description) {
      return res.status(400).json({ error: 'Subject and description are required' });
    }

    const ticketNo = 'PRZ-TKT-' + Math.floor(100000 + Math.random() * 900000);
    
    // Assign support staff member (Least-loaded support staff)
    const staffList = await Staff.findAll({ where: { role: 'Support', status: 'Active' } });
    let assignedId = null;
    if (staffList.length > 0) {
      const staffCounts = [];
      for (const s of staffList) {
        const count = await ComplaintTicket.count({ where: { assignedStaffId: s.id } });
        staffCounts.push({ id: s.id, count });
      }
      staffCounts.sort((a, b) => a.count - b.count);
      assignedId = staffCounts[0].id;
    }

    const ticket = await ComplaintTicket.create({
      ticketNumber: ticketNo,
      userId: user.id,
      transactionId: transactionId || null,
      subject,
      description,
      status: 'Open',
      assignedStaffId: assignedId,
    });

    // Create Initial Message
    await TicketMessage.create({
      ticketId: ticket.id,
      senderId: user.id,
      senderType: 'User',
      message: description,
    });

    await logSystem('Info', `User ${user.phone} created support ticket ${ticketNo}`);

    res.status(201).json({
      message: 'Complaint ticket created successfully',
      ticket,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getTickets = async (req, res) => {
  try {
    let whereClause = {};
    if (req.userType === 'Customer') {
      whereClause.userId = req.user.id;
    } else if (req.userType === 'Staff') {
      // Support staff see assigned tickets or open tickets
      if (req.staff.role !== 'Admin') {
        whereClause.assignedStaffId = req.staff.id;
      }
    }

    const tickets = await ComplaintTicket.findAll({
      where: whereClause,
      order: [['updatedAt', 'DESC']],
    });

    res.status(200).json(tickets);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getTicketMessages = async (req, res) => {
  try {
    const { ticketId } = req.params;

    // Verify ownership
    const ticket = await ComplaintTicket.findByPk(ticketId);
    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    if (req.userType === 'Customer' && ticket.userId !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized access to ticket' });
    }

    const messages = await TicketMessage.findAll({
      where: { ticketId },
      order: [['createdAt', 'ASC']],
    });

    res.status(200).json(messages);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.replyToTicket = async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message content cannot be empty' });
    }

    const ticket = await ComplaintTicket.findByPk(ticketId);
    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    let senderId;
    let senderType;

    if (req.userType === 'Customer') {
      if (ticket.userId !== req.user.id) {
        return res.status(403).json({ error: 'Unauthorized' });
      }
      senderId = req.user.id;
      senderType = 'User';
      // Reopen ticket if closed and user responds
      if (ticket.status === 'Closed' || ticket.status === 'Resolved') {
        ticket.status = 'Processing';
      }
    } else {
      senderId = req.staff.id;
      senderType = 'Staff';
      // Mark as processing when agent responds
      if (ticket.status === 'Open') {
        ticket.status = 'Processing';
      }
    }

    const newMessage = await TicketMessage.create({
      ticketId: ticket.id,
      senderId,
      senderType,
      message,
    });

    // Update ticket time
    ticket.changed('updatedAt', true);
    await ticket.save();

    res.status(201).json(newMessage);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.transferToHuman = async (req, res) => {
  try {
    const { ticketId } = req.params;
    const ticket = await ComplaintTicket.findByPk(ticketId);
    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

    ticket.status = 'Processing';
    
    // Auto re-assign to active support staff if none is assigned
    if (!ticket.assignedStaffId) {
      const staffList = await Staff.findAll({ where: { role: 'Support', status: 'Active' } });
      if (staffList.length > 0) {
        const staffCounts = [];
        for (const s of staffList) {
          const count = await ComplaintTicket.count({ where: { assignedStaffId: s.id } });
          staffCounts.push({ id: s.id, count });
        }
        staffCounts.sort((a, b) => a.count - b.count);
        ticket.assignedStaffId = staffCounts[0].id;
      }
    }
    await ticket.save();

    await TicketMessage.create({
      ticketId: ticket.id,
      senderId: '00000000-0000-0000-0000-000000000000',
      senderType: 'Staff',
      message: `System Alert: AI Chat Support has successfully transferred this request to support staff. A support executive will respond shortly.`,
    });

    res.status(200).json({ message: 'Transferred to human support successfully', ticket });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.submitFeedback = async (req, res) => {
  try {
    const user = req.user;
    const { rating, review } = req.body;

    if (!rating || isNaN(parseInt(rating, 10))) {
      return res.status(400).json({ error: 'Valid rating (1-5) is required' });
    }

    const ratingVal = parseInt(rating, 10);
    if (ratingVal < 1 || ratingVal > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    const feedback = await Feedback.create({
      userId: user.id,
      userName: user.name || 'Anonymous',
      userPhone: user.phone,
      rating: ratingVal,
      review: review || '',
    });

    res.status(201).json({
      message: 'Feedback submitted successfully',
      feedback,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.adminReplyToTicket = async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { message } = req.body;
    const staff = req.staff;

    if (!message) {
      return res.status(400).json({ error: 'Message content cannot be empty' });
    }

    const ticket = await ComplaintTicket.findByPk(ticketId);
    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    const newMessage = await TicketMessage.create({
      ticketId: ticket.id,
      senderId: staff.id,
      senderType: 'Staff',
      message,
    });

    if (ticket.status === 'Open') {
      ticket.status = 'Processing';
    }
    ticket.changed('updatedAt', true);
    await ticket.save();

    res.status(201).json(newMessage);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateTicketStatus = async (req, res) => {
  try {
    const { ticketId } = req.params;
    const { status } = req.body;

    if (!['Open', 'Processing', 'Resolved', 'Closed'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }

    const ticket = await ComplaintTicket.findByPk(ticketId);
    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    ticket.status = status;
    ticket.changed('updatedAt', true);
    await ticket.save();

    await logSystem('Info', `Ticket ${ticket.ticketNumber} status updated to ${status}`);

    res.status(200).json({ message: 'Ticket status updated successfully', ticket });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
