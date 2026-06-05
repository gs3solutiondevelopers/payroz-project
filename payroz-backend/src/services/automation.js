const {
  User,
  Transaction,
  Refund,
  Cashback,
  Referral,
  ComplaintTicket,
  TicketMessage,
  Staff,
  Notification,
  SystemLog,
  ScratchCard,
} = require('../models');

// Helper to log system events
async function logSystem(level, message, details = '') {
  try {
    await SystemLog.create({
      level,
      message,
      details: typeof details === 'object' ? JSON.stringify(details) : details,
    });
    console.log(`[SYS-LOG][${level}] ${message}`);
  } catch (err) {
    console.error('SysLog error:', err);
  }
}

// 1. Process Refund to Rewards Wallet
async function autoProcessRefund(transactionId, reason = 'Operator Timeout') {
  try {
    const tx = await Transaction.findByPk(transactionId);
    if (!tx || tx.status !== 'Pending') return;

    tx.status = 'Failed';
    tx.errorMessage = reason;
    await tx.save();

    // Refund full amount to rewards balance
    const user = await User.findByPk(tx.userId);
    if (user) {
      const originalBalance = user.rewardsBalance;
      user.rewardsBalance += tx.amount;
      await user.save();

      // Create Refund Row
      await Refund.create({
        transactionId: tx.id,
        userId: user.id,
        amount: tx.amount,
        status: 'Refunded',
        reason,
      });

      // Notify User
      await Notification.create({
        userId: user.id,
        title: 'Refund Credited to Rewards Wallet',
        message: `Your payment of ₹${tx.amount} for ${tx.serviceName} failed. The amount has been refunded to your Rewards Wallet.`,
        type: 'Refund',
      });

      await logSystem('Info', `Auto-refunded ₹${tx.amount} to User ${user.phone} for failed TX ${tx.id}`, {
        txId: tx.id,
        prevBalance: originalBalance,
        newBalance: user.rewardsBalance,
      });

      // 2. Auto Complaint Ticket Creation
      await autoCreateComplaintTicket(tx, reason);
    }
  } catch (err) {
    await logSystem('Error', `Failed auto-refund process for TX ${transactionId}`, err.message);
  }
}

// 2. Auto Complaint Ticket Creation on Failure
async function autoCreateComplaintTicket(transaction, reason) {
  try {
    const ticketNo = 'PRZ-TKT-' + Math.floor(100000 + Math.random() * 900000);
    
    // Assign support staff round-robin (or just pick one)
    const staffMember = await Staff.findOne({ where: { role: 'Support', status: 'Active' } });
    const assignedId = staffMember ? staffMember.id : null;

    const ticket = await ComplaintTicket.create({
      ticketNumber: ticketNo,
      userId: transaction.userId,
      transactionId: transaction.id,
      subject: `Failed Payment: ${transaction.serviceName}`,
      description: `System auto-generated complaint. The transaction of ₹${transaction.amount} failed with reason: ${reason}. Refund has been initiated to the Rewards Wallet.`,
      status: 'Open',
      assignedStaffId: assignedId,
    });

    // Create First Message in Chat
    await TicketMessage.create({
      ticketId: ticket.id,
      senderId: assignedId || '00000000-0000-0000-0000-000000000000', // System ID
      senderType: 'Staff',
      message: `Hello! Our system detected that your transaction for ${transaction.serviceName} failed due to ${reason}. We have automatically filed this ticket and credited a full refund of ₹${transaction.amount} to your Rewards Wallet. How else can we help you?`,
    });

    await logSystem('Info', `Auto-created Complaint Ticket ${ticketNo} for User ${transaction.userId}`);
  } catch (err) {
    await logSystem('Error', `Failed auto ticket creation for TX ${transaction.id}`, err.message);
  }
}

// 3. Process Cashback Credit
async function autoProcessCashback(transaction) {
  try {
    if (transaction.status !== 'Success' || transaction.cashbackCredited) return;

    // Get service config for cashback
    const { Service } = require('../models');
    const service = await Service.findByPk(transaction.serviceId);
    if (!service || !service.cashbackSetup) return;

    const cbConfig = JSON.parse(service.cashbackSetup);
    if (!cbConfig || cbConfig.value <= 0) return;

    let cbAmount = 0;
    if (cbConfig.type === 'flat') {
      cbAmount = cbConfig.value;
    } else if (cbConfig.type === 'percent') {
      cbAmount = (transaction.amount * cbConfig.value) / 100;
      if (cbConfig.maxAmount > 0 && cbAmount > cbConfig.maxAmount) {
        cbAmount = cbConfig.maxAmount;
      }
    }

    if (cbAmount > 0) {
      const user = await User.findByPk(transaction.userId);
      if (user) {
        // Mark Transaction as cashback processed
        transaction.cashbackCredited = true;
        await transaction.save();

        // Create an Unscratched Scratch Card
        await ScratchCard.create({
          userId: user.id,
          amount: cbAmount,
          status: 'Unscratched',
          title: `Cashback: ${transaction.serviceName}`,
          description: `Claim your cashback on transaction of ₹${transaction.amount}`,
        });

        // Notify User
        await Notification.create({
          userId: user.id,
          title: 'You Won a Scratch Card! 🎁',
          message: `Congratulations! You received a scratch card on your ${transaction.serviceName} payment. Go to Rewards to claim your cashback.`,
          type: 'Cashback',
        });

        await logSystem('Info', `Issued Scratch Card of ₹${cbAmount} to User ${user.phone} for TX ${transaction.id}`);
        
        // Try referral credit if referee's first success transaction
        await autoProcessReferral(user);
      }
    }
  } catch (err) {
    await logSystem('Error', `Failed auto-cashback process for TX ${transaction.id}`, err.message);
  }
}

// 4. Auto Referral Credit
async function autoProcessReferral(refereeUser) {
  try {
    if (!refereeUser.referredById) return;

    // Check if referee already had a successful transaction before this
    const successfulTxCount = await Transaction.count({
      where: {
        userId: refereeUser.id,
        status: 'Success',
      }
    });

    // We only credit referral on the very FIRST successful transaction
    if (successfulTxCount !== 1) return;

    // Check if referral was already credited
    const existingRef = await Referral.findOne({
      where: { refereeId: refereeUser.id, status: 'Credited' }
    });
    if (existingRef) return;

    // Credit Referral amount (Admin can set referral amount; let's use a standard ₹50)
    const referralReward = 50.0; 

    const referrer = await User.findByPk(refereeUser.referredById);
    if (referrer) {
      referrer.rewardsBalance += referralReward;
      await referrer.save();

      // Create Referral Row
      await Referral.create({
        referrerId: referrer.id,
        refereeId: refereeUser.id,
        amount: referralReward,
        status: 'Credited',
      });

      // Notify Referrer
      await Notification.create({
        userId: referrer.id,
        title: 'Referral Reward Credited!',
        message: `Your friend ${refereeUser.name || refereeUser.phone} completed their first payment. ₹${referralReward} has been added to your Rewards Wallet.`,
        type: 'Referral',
      });

      // Notify Referee
      await Notification.create({
        userId: refereeUser.id,
        title: 'Referral Join Bonus!',
        message: `Thanks for joining via referral code! Your friend received a bonus.`,
        type: 'Referral',
      });

      await logSystem('Info', `Referral credited: ₹${referralReward} paid to Referrer ${referrer.phone} for Referee ${refereeUser.phone}`);
    }
  } catch (err) {
    await logSystem('Error', `Failed referral credit process for Referee ${refereeUser.id}`, err.message);
  }
}

// 5. Auto Failed Transaction Scanner
// Checks for transactions that have been "Pending" for more than 30 seconds and simulates failure.
async function autoCheckFailedTransactions() {
  try {
    const { Op } = require('sequelize');
    const cutoffTime = new Date(Date.now() - 30 * 1000); // 30 seconds ago
    const pendingTxs = await Transaction.findAll({
      where: {
        status: 'Pending',
        createdAt: {
          [Op.lt]: cutoffTime,
        }
      }
    });

    for (const tx of pendingTxs) {
      // Simulate that 50% fail and 50% succeed after check delay
      if (Math.random() > 0.5) {
        // Success
        tx.status = 'Success';
        tx.operatorRefId = 'ONR' + Math.floor(1000000000000000 + Math.random() * 9000000000000000);
        
        // Calculate commission earned
        try {
          const { Service } = require('../models');
          const service = await Service.findByPk(tx.serviceId);
          if (service) {
            const commConfig = JSON.parse(service.commissionSetup || '{}');
            if (commConfig && commConfig.value > 0) {
              if (commConfig.type === 'flat') {
                tx.commissionEarned = commConfig.value;
              } else if (commConfig.type === 'percent') {
                tx.commissionEarned = (tx.amount * commConfig.value) / 100;
              }
            }
          }
        } catch (e) {
          tx.commissionEarned = 0.0;
        }

        await tx.save();

        await Notification.create({
          userId: tx.userId,
          title: 'Payment Successful',
          message: `Your payment of ₹${tx.amount} for ${tx.serviceName} was completed successfully.`,
          type: 'System',
        });

        await logSystem('Info', `System marked pending TX ${tx.id} as Success`);
        await autoProcessCashback(tx);
      } else {
        // Fail -> triggers auto-refund and ticket creation
        await autoProcessRefund(tx.id, 'Operator Timeout - Billing Node Down');
      }
    }
  } catch (err) {
    console.error('Pending transaction checker error:', err);
  }
}

// 6. Generate Smart Reminders for Home Screen
// Fetches personalized bill reminders based on past successful transaction history.
async function generateSmartReminders(userId) {
  try {
    const { Transaction, Service } = require('../models');
    
    // Get user's successful transactions
    const txs = await Transaction.findAll({
      where: { userId, status: 'Success' },
      order: [['createdAt', 'DESC']],
    });

    const reminders = [];
    const processedKeys = new Set();

    for (const tx of txs) {
      if (!tx.inputsUsed || !tx.serviceId) continue;

      let inputsMap = {};
      try {
        inputsMap = JSON.parse(tx.inputsUsed);
      } catch (e) {
        continue;
      }

      // Unique key for grouping: mobile_number/consumer_id + serviceName
      const uniqueId = inputsMap.mobile_number || inputsMap.consumer_id || inputsMap.customer_id || inputsMap.vehicle_number;
      if (!uniqueId) continue;

      const groupKey = `${tx.serviceName}_${uniqueId}`;
      if (processedKeys.has(groupKey)) continue;
      processedKeys.add(groupKey);

      // Check date difference
      const txDate = new Date(tx.createdAt);
      const daysPassed = Math.floor((Date.now() - txDate.getTime()) / (1000 * 60 * 60 * 24));

      // Remind if more than 20 days passed (typical bill cycle is 28-30 days)
      if (daysPassed >= 20) {
        let title = `${tx.serviceName} Due`;
        let message = `Payment for ${uniqueId} (last paid ₹${tx.amount}) is due.`;
        
        // Custom message descriptions
        if (tx.serviceName.includes('Recharge')) {
          title = `${tx.serviceName} Due`;
          message = `Your plan for ${uniqueId} is expiring soon. Last recharged for ₹${tx.amount}.`;
        } else if (tx.serviceName.includes('Bill')) {
          title = `${tx.serviceName} Due`;
          message = `Your monthly bill for connection ${uniqueId} (last paid ₹${tx.amount}) is pending.`;
        } else if (tx.serviceName.includes('Insurance')) {
          title = `${tx.serviceName} Expiry`;
          message = `Your policy for vehicle ${uniqueId} is expiring soon. Click to renew.`;
        }

        reminders.push({
          title,
          message,
          type: 'Reminder',
          serviceId: tx.serviceId,
          serviceName: tx.serviceName,
          amount: tx.amount,
          inputsUsed: inputsMap,
        });
      }
    }

    // Fallback: If the user is new and has no transaction history, return standard default reminders!
    if (reminders.length === 0) {
      // Find dynamic services to link them correctly
      const mobileService = await Service.findOne({ where: { name: 'Mobile Recharge' } });
      const electricityService = await Service.findOne({ where: { name: 'Electricity Bill' } });
      const bikeService = await Service.findOne({ where: { name: 'Bike Insurance' } });

      return [
        {
          title: 'Electricity Bill Due',
          message: 'Your Electricity Bill (BEST) of ₹1,245 is due in 3 days.',
          type: 'Reminder',
          serviceId: electricityService ? electricityService.id : null,
          serviceName: 'Electricity Bill',
          amount: 1245,
          inputsUsed: { consumer_id: '100492812', board: 'BEST (Mumbai)', amount: 1245 },
        },
        {
          title: 'Bike Insurance Renewal',
          message: 'Your Bike Insurance policy (MH12AB1234) is expiring in 7 days.',
          type: 'Reminder',
          serviceId: bikeService ? bikeService.id : null,
          serviceName: 'Bike Insurance',
          amount: 1560,
          inputsUsed: { vehicle_number: 'MH12AB1234', owner_name: 'Rajesh Sharma', provider: 'Digit Insurance', amount: 1560 },
        },
        {
          title: 'Mobile Recharge Due',
          message: 'Prepaid plan for 9876543210 of ₹199 expires today.',
          type: 'Reminder',
          serviceId: mobileService ? mobileService.id : null,
          serviceName: 'Mobile Recharge',
          amount: 199,
          inputsUsed: { mobile_number: '9876543210', operator: 'Jio', circle: 'Mumbai', amount: 199 },
        }
      ];
    }

    return reminders;
  } catch (err) {
    console.error('Reminder generation error:', err);
    return [];
  }
}

module.exports = {
  autoProcessRefund,
  autoProcessCashback,
  autoProcessReferral,
  autoCheckFailedTransactions,
  generateSmartReminders,
  logSystem,
};
