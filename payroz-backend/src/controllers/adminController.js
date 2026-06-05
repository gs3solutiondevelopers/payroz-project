const jwt = require('jsonwebtoken');
const {
  User,
  Transaction,
  Refund,
  Cashback,
  Referral,
  ComplaintTicket,
  Staff,
  Notification,
  SystemLog,
  StaffLog,
  Feedback
} = require('../models');
const crypto = require('crypto');

async function logStaffAction(staffId, staffName, action, details) {
  try {
    await StaffLog.create({
      staffId,
      staffName,
      action,
      details: typeof details === 'object' ? JSON.stringify(details) : String(details),
    });
  } catch (err) {
    console.error('Error logging staff action:', err);
  }
}
const { autoProcessRefund, logSystem } = require('../services/automation');

// Get Dashboard Stats (Total users, active, success/fail/pending txs, revenue, logs)
exports.getDashboardStats = async (req, res) => {
  try {
    const totalUsers = await User.count();
    const activeUsers = await User.count({ where: { status: 'Active' } });
    
    const totalTransactions = await Transaction.count();
    const successTransactions = await Transaction.count({ where: { status: 'Success' } });
    const failedTransactions = await Transaction.count({ where: { status: 'Failed' } });
    const pendingTransactions = await Transaction.count({ where: { status: 'Pending' } });

    // Revenue calculations: Sum of transaction amounts where status = 'Success'
    // Total cashback paid: Sum of cashback credited
    // Total referral paid: Sum of referral credited
    const revenueSum = await Transaction.sum('gatewayAmountPaid', { where: { status: 'Success' } }) || 0.0;
    const commissionSum = await Transaction.sum('commissionEarned', { where: { status: 'Success' } }) || 0.0;
    const cashbackSum = await Cashback.sum('amount') || 0.0;
    const referralSum = await Referral.sum('amount') || 0.0;
    const refundsSum = await Refund.sum('amount') || 0.0;
    const netProfit = commissionSum - cashbackSum - referralSum;

    // Recent 5 system logs
    const recentLogs = await SystemLog.findAll({
      limit: 5,
      order: [['createdAt', 'DESC']],
    });

    res.status(200).json({
      stats: {
        totalUsers,
        activeUsers,
        totalTransactions,
        successTransactions,
        failedTransactions,
        pendingTransactions,
        totalRevenue: revenueSum,
        totalCashback: cashbackSum,
        totalReferrals: referralSum,
        totalRefunds: refundsSum,
        totalCommission: commissionSum,
        netProfit: netProfit,
      },
      recentLogs,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Users management
exports.getUsers = async (req, res) => {
  try {
    const users = await User.findAll({
      order: [['createdAt', 'DESC']],
    });
    res.status(200).json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getUserDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByPk(id, {
      include: [
        { model: Transaction, as: 'transactions', limit: 10, order: [['createdAt', 'DESC']] },
        { model: ComplaintTicket, as: 'tickets', limit: 10 },
      ]
    });
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.status(200).json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.approveKyc = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body; // 'Approved' or 'Rejected'

    if (!['Approved', 'Rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid KYC status' });
    }

    const user = await User.findByPk(id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.kycStatus = status;
    await user.save();

    await Notification.create({
      userId: user.id,
      title: `KYC Submission ${status}`,
      message: status === 'Approved' 
        ? 'Congratulations! Your KYC submission has been approved.' 
        : 'Unfortunately, your KYC documents were rejected. Please upload correct documents.',
      type: 'System',
    });

    await logSystem('Info', `Admin updated User ${user.phone} KYC status to ${status}`);

    // Log staff action
    if (req.staff) {
      await logStaffAction(req.staff.id, req.staff.name, 'KYC Audit', {
        userId: user.id,
        userPhone: user.phone,
        status: status
      });
    }

    res.status(200).json({ message: `KYC updated to ${status}`, user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Manual Refund trigger (e.g. from refund panel or transaction history)
exports.executeManualRefund = async (req, res) => {
  try {
    const { transactionId } = req.body;
    const tx = await Transaction.findByPk(transactionId);
    
    if (!tx) return res.status(404).json({ error: 'Transaction not found' });
    if (tx.status !== 'Failed' && tx.status !== 'Pending') {
      return res.status(400).json({ error: 'Only pending or failed transactions can be refunded' });
    }

    // Call refund process
    await autoProcessRefund(tx.id, 'Refund approved manually by Administrator');

    // Log staff action
    if (req.staff) {
      await logStaffAction(req.staff.id, req.staff.name, 'Manual Refund', {
        transactionId: tx.id,
        amount: tx.amount
      });
    }

    res.status(200).json({ message: 'Refund processed successfully.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get System Reports
exports.getReports = async (req, res) => {
  try {
    const { reportType, userId, startDate, endDate } = req.query;

    let data = [];
    
    // Date filter helper
    const filterByDate = (list) => {
      if (!startDate && !endDate) return list;
      const start = startDate ? new Date(startDate) : new Date(0);
      const end = endDate ? new Date(endDate) : new Date();
      if (endDate) {
        end.setHours(23, 59, 59, 999);
      }
      return list.filter(item => {
        const itemDate = new Date(item.createdAt);
        return itemDate >= start && itemDate <= end;
      });
    };

    if (reportType === 'cashback') {
      const list = await Cashback.findAll({ order: [['createdAt', 'DESC']] });
      data = filterByDate(list);
    } else if (reportType === 'referral') {
      const list = await Referral.findAll({ order: [['createdAt', 'DESC']] });
      data = filterByDate(list);
    } else if (reportType === 'refund') {
      const list = await Refund.findAll({ order: [['createdAt', 'DESC']] });
      data = filterByDate(list);
    } else if (reportType === 'service') {
      let txs = await Transaction.findAll({ where: { status: 'Success' } });
      txs = filterByDate(txs);
      
      const serviceSummary = {};
      for (const tx of txs) {
        const name = tx.serviceName || 'Unknown';
        if (!serviceSummary[name]) {
          serviceSummary[name] = { serviceName: name, count: 0, totalAmount: 0.0, totalCommission: 0.0 };
        }
        serviceSummary[name].count += 1;
        serviceSummary[name].totalAmount += parseFloat(tx.amount || 0);
        serviceSummary[name].totalCommission += parseFloat(tx.commissionEarned || 0);
      }
      data = Object.values(serviceSummary);
    } else if (reportType === 'complaint') {
      const tickets = await ComplaintTicket.findAll({ order: [['createdAt', 'DESC']] });
      const filteredTickets = filterByDate(tickets);
      
      const counts = { Open: 0, Processing: 0, Resolved: 0, Closed: 0 };
      for (const t of filteredTickets) {
        if (counts[t.status] !== undefined) {
          counts[t.status]++;
        }
      }
      // Return counts and list directly
      return res.status(200).json({ counts, tickets: filteredTickets });
    } else if (reportType === 'user') {
      if (!userId) {
        return res.status(400).json({ error: 'userId query parameter is required for user-wise report' });
      }
      const txs = await Transaction.findAll({
        where: { userId },
        order: [['createdAt', 'DESC']],
      });
      data = filterByDate(txs);
    } else if (reportType === 'date') {
      if (!startDate || !endDate) {
        return res.status(400).json({ error: 'startDate and endDate query parameters are required for date-wise report' });
      }
      const txs = await Transaction.findAll({ order: [['createdAt', 'DESC']] });
      data = filterByDate(txs);
    } else {
      // Default to Revenue Report (Successful Transactions list)
      const txs = await Transaction.findAll({
        where: { status: 'Success' },
        order: [['createdAt', 'DESC']],
      });
      data = filterByDate(txs);
    }

    res.status(200).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Staff management
exports.getStaff = async (req, res) => {
  try {
    const staff = await Staff.findAll();
    res.status(200).json(staff);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.createStaff = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    
    const existing = await Staff.findOne({ where: { email } });
    if (existing) return res.status(400).json({ error: 'Email already registered for staff' });

    const newStaff = await Staff.create({
      name,
      email,
      passwordHash: password, // In production use bcrypt
      role,
      status: 'Active',
    });

    await logSystem('Info', `Created staff account: ${email} with role ${role}`);

    // Log staff action
    if (req.staff) {
      await logStaffAction(req.staff.id, req.staff.name, 'Create Staff', {
        createdStaffId: newStaff.id,
        createdStaffEmail: email,
        createdStaffRole: role
      });
    }

    res.status(201).json(newStaff);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Send broadcast notifications to all users
exports.sendBroadcastNotification = async (req, res) => {
  try {
    const { title, message, type } = req.body;

    if (!title || !message) {
      return res.status(400).json({ error: 'Title and message are required' });
    }

    const notification = await Notification.create({
      userId: null, // null is global broadcast
      title,
      message,
      type: type || 'System',
    });

    await logSystem('Info', `Admin broadcast notification: ${title}`);

    res.status(201).json(notification);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Staff Login
exports.staffLogin = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const staff = await Staff.findOne({ where: { email } });
    if (!staff || staff.passwordHash !== password) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }

    if (staff.status === 'Inactive') {
      return res.status(403).json({ error: 'Staff account is deactivated.' });
    }

    const token = jwt.sign({ id: staff.id, role: staff.role }, process.env.JWT_SECRET || 'payroz_b2c_super_secure_secret_key_2026', { expiresIn: '24h' });

    // Log staff action
    await logStaffAction(staff.id, staff.name, 'Login', `Staff logged in from IP ${req.ip || 'unknown'}`);

    res.status(200).json({
      message: 'Staff login successful',
      token,
      staff: {
        id: staff.id,
        name: staff.name,
        email: staff.email,
        role: staff.role,
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Block / Unblock User
exports.blockUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByPk(id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.status = user.status === 'Blocked' ? 'Active' : 'Blocked';
    await user.save();

    // Log staff action
    if (req.staff) {
      await logStaffAction(req.staff.id, req.staff.name, user.status === 'Blocked' ? 'Block User' : 'Unblock User', {
        userId: user.id,
        userPhone: user.phone
      });
    }

    // Create system notification
    await Notification.create({
      userId: user.id,
      title: 'Account Status Update',
      message: `Your account has been ${user.status === 'Blocked' ? 'blocked' : 'unblocked'}. Please contact support for assistance.`,
      type: 'System',
    });

    res.status(200).json({ message: `User status changed to ${user.status}`, user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Credit Promotional Bonus to Rewards Wallet
exports.creditPromotionalBonus = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, remark } = req.body;

    if (!amount || isNaN(parseFloat(amount)) || parseFloat(amount) <= 0) {
      return res.status(400).json({ error: 'Valid promotional bonus amount is required' });
    }

    const bonusAmount = parseFloat(amount);
    const user = await User.findByPk(id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.rewardsBalance = (parseFloat(user.rewardsBalance) || 0) + bonusAmount;
    await user.save();

    // Create a Promo Credit Transaction
    const txId = 'TX-' + Math.floor(100000 + Math.random() * 900000);
    await Transaction.create({
      id: txId,
      userId: user.id,
      serviceName: 'Promo Bonus Credit',
      amount: bonusAmount,
      gatewayAmountPaid: 0,
      paymentMode: 'Rewards',
      status: 'Success',
      commissionEarned: 0,
      description: remark || 'Admin Promotional Bonus',
    });

    // Create notification
    await Notification.create({
      userId: user.id,
      title: 'Rewards Credited 🎁',
      message: `An amount of ₹${bonusAmount} promotional bonus has been credited to your rewards wallet. Reason: ${remark || 'Promotional Credit'}`,
      type: 'System',
    });

    // Log staff action
    if (req.staff) {
      await logStaffAction(req.staff.id, req.staff.name, 'Credit Promo Bonus', {
        userId: user.id,
        userPhone: user.phone,
        amount: bonusAmount,
        remark: remark || ''
      });
    }

    res.status(200).json({ message: `Successfully credited ₹${bonusAmount} to rewards wallet`, user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get Staff Activity Logs
exports.getStaffLogs = async (req, res) => {
  try {
    const logs = await StaffLog.findAll({
      order: [['createdAt', 'DESC']],
    });
    res.status(200).json(logs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get Customer Feedbacks
exports.getFeedbacks = async (req, res) => {
  try {
    const feedbacks = await Feedback.findAll({
      order: [['createdAt', 'DESC']],
    });
    res.status(200).json(feedbacks);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
