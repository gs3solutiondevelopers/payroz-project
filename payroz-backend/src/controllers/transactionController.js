const { Transaction, User, Service, Notification, Coupon } = require('../models');
const { autoProcessCashback, logSystem, autoProcessRefund } = require('../services/automation');

exports.createTransaction = async (req, res) => {
  try {
    const user = req.user;
    const { serviceId, amount, inputsUsed, useRewardsWallet, couponCode } = req.body;

    if (!serviceId || !amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid Service ID and amount are required' });
    }

    // Get service details
    const service = await Service.findByPk(serviceId);
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    if (service.status === 'Disabled') {
      return res.status(400).json({ error: 'This service is currently disabled.' });
    }

    if (service.status === 'Maintenance') {
      return res.status(400).json({ error: 'This service is under maintenance. Please try again later.' });
    }

    // Validate Coupon if provided
    let discountAmount = 0.0;
    let couponId = null;

    if (couponCode) {
      const coupon = await Coupon.findOne({ where: { code: couponCode.toUpperCase() } });
      if (!coupon) {
        return res.status(400).json({ error: 'Invalid coupon code' });
      }
      if (coupon.status !== 'Enabled') {
        return res.status(400).json({ error: 'Coupon is not active' });
      }
      if (coupon.expiresAt && new Date() > new Date(coupon.expiresAt)) {
        return res.status(400).json({ error: 'Coupon has expired' });
      }
      if (coupon.maxUses !== null && coupon.usedCount >= coupon.maxUses) {
        return res.status(400).json({ error: 'Coupon has reached its maximum usage limit' });
      }
      if (amount < coupon.minAmount) {
        return res.status(400).json({ error: `Minimum amount of ₹${coupon.minAmount} required to use this coupon` });
      }
      if (coupon.serviceFilter && coupon.serviceFilter !== service.name) {
        return res.status(400).json({ error: `This coupon is not applicable for ${service.name}` });
      }

      // Calculate discount
      if (coupon.discountType === 'percent') {
        discountAmount = (amount * coupon.value) / 100;
      } else {
        discountAmount = coupon.value;
      }

      if (discountAmount > amount) {
        discountAmount = amount;
      }
      couponId = coupon.id;
    }

    const netAmount = amount - discountAmount;
    let rewardsAmountUsed = 0.0;
    let gatewayAmountPaid = netAmount;

    // Apply Rewards Wallet Balance if requested
    if (useRewardsWallet && user.rewardsBalance > 0) {
      if (user.rewardsBalance >= netAmount) {
        rewardsAmountUsed = netAmount;
        gatewayAmountPaid = 0.0;
      } else {
        rewardsAmountUsed = user.rewardsBalance;
        gatewayAmountPaid = netAmount - user.rewardsBalance;
      }
    }

    // Deduct rewards balance immediately if used
    if (rewardsAmountUsed > 0) {
      user.rewardsBalance -= rewardsAmountUsed;
      await user.save();
    }

    // Determine status (Simulate Fintech PG: 90% instant success, 10% pending)
    let finalStatus = 'Success';
    let operatorRefId = null;
    let errorMessage = null;

    if (gatewayAmountPaid > 0) {
      // Simulate Payment Gateway API Call
      const randomValue = Math.random();
      if (randomValue < 0.10) {
        // 10% is marked as Pending to trigger our background automation!
        finalStatus = 'Pending';
      } else if (randomValue < 0.12) {
        // 2% fail immediately
        finalStatus = 'Failed';
        errorMessage = 'Payment Gateway Declined - Insufficient Funds in Card';
      } else {
        // 88% Success
        finalStatus = 'Success';
        operatorRefId = 'ONR' + Math.floor(1000000000000000 + Math.random() * 9000000000000000);
      }
    } else {
      // 100% paid by Rewards Wallet, instant success
      operatorRefId = 'ONR-WAL-' + Math.floor(100000 + Math.random() * 900000);
    }

    // Calculate earned commission if successful
    let commissionEarned = 0.0;
    if (finalStatus === 'Success') {
      try {
        const commConfig = JSON.parse(service.commissionSetup || '{}');
        if (commConfig && commConfig.value > 0) {
          if (commConfig.type === 'flat') {
            commissionEarned = commConfig.value;
          } else if (commConfig.type === 'percent') {
            commissionEarned = (amount * commConfig.value) / 100;
          }
        }
      } catch (e) {
        commissionEarned = 0.0;
      }
    }

    // Create Transaction Record
    const tx = await Transaction.create({
      userId: user.id,
      serviceId: service.id,
      serviceName: service.name,
      amount,
      status: finalStatus,
      paymentMode: rewardsAmountUsed > 0 ? (gatewayAmountPaid > 0 ? 'Hybrid' : 'Rewards') : 'Direct',
      rewardsAmountUsed,
      gatewayAmountPaid,
      operatorRefId,
      errorMessage,
      receiptUrl: `/receipts/receipt_${Date.now()}.pdf`,
      inputsUsed: JSON.stringify(inputsUsed || {}),
      commissionEarned,
      couponCode: couponCode || null,
      discountAmount,
    });

    await logSystem('Info', `Created TX ${tx.id} for User ${user.phone}: status=${finalStatus}, gatewayPaid=${gatewayAmountPaid}, walletUsed=${rewardsAmountUsed}`);

    // If transaction failed, we process refund (to give back the wallet amount if debited)
    if (finalStatus === 'Failed') {
      if (rewardsAmountUsed > 0) {
        user.rewardsBalance += rewardsAmountUsed;
        await user.save();
      }
      
      // Auto notification
      await Notification.create({
        userId: user.id,
        title: 'Payment Failed',
        message: `Your payment of ₹${amount} for ${service.name} failed. Reason: ${errorMessage}.`,
        type: 'System',
      });
    }

    // If successful, trigger cashback automation and increment coupon usage
    if (finalStatus === 'Success') {
      if (couponId) {
        const coupon = await Coupon.findByPk(couponId);
        if (coupon) {
          coupon.usedCount = (coupon.usedCount || 0) + 1;
          await coupon.save();
        }
      }
      await autoProcessCashback(tx);
    }

    res.status(201).json({
      message: 'Transaction processed',
      transaction: {
        id: tx.id,
        serviceName: tx.serviceName,
        amount: tx.amount,
        status: tx.status,
        paymentMode: tx.paymentMode,
        rewardsAmountUsed: tx.rewardsAmountUsed,
        gatewayAmountPaid: tx.gatewayAmountPaid,
        operatorRefId: tx.operatorRefId,
        errorMessage: tx.errorMessage,
        createdAt: tx.createdAt,
        receiptUrl: tx.receiptUrl,
        inputsUsed: JSON.parse(tx.inputsUsed),
        couponCode: tx.couponCode,
        discountAmount: tx.discountAmount,
      },
      rewardsBalance: user.rewardsBalance,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getTransactionHistory = async (req, res) => {
  try {
    const user = req.user;
    const { type } = req.query; // 'All', 'Refunds', 'Cashback'
    const { Op } = require('sequelize');

    let whereClause = { userId: user.id };

    const transactions = await Transaction.findAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
    });

    let formatted = transactions.map((t) => ({
      id: t.id,
      serviceName: t.serviceName,
      amount: t.amount,
      status: t.status,
      paymentMode: t.paymentMode,
      rewardsAmountUsed: t.rewardsAmountUsed,
      gatewayAmountPaid: t.gatewayAmountPaid,
      operatorRefId: t.operatorRefId,
      errorMessage: t.errorMessage,
      createdAt: t.createdAt,
      inputsUsed: t.inputsUsed ? JSON.parse(t.inputsUsed) : {},
    }));

    // If filter is specific
    if (type === 'Refunds') {
      // Find all transaction records with refunds
      const refunds = await Transaction.findAll({
        where: {
          userId: user.id,
          status: 'Failed',
        },
        order: [['createdAt', 'DESC']],
      });
      formatted = refunds.map((t) => ({
        id: t.id,
        serviceName: t.serviceName + ' (Refunded)',
        amount: t.amount,
        status: 'Success', // Mock refund status as Success for display list
        paymentMode: 'Rewards',
        rewardsAmountUsed: 0.0,
        gatewayAmountPaid: 0.0,
        operatorRefId: t.operatorRefId,
        createdAt: t.createdAt,
        isRefund: true,
      }));
    } else if (type === 'Cashback') {
      // Mock cashback item rows for list representation
      const { Cashback } = require('../models');
      const cashbacks = await Cashback.findAll({
        where: { userId: user.id },
        order: [['createdAt', 'DESC']],
      });
      formatted = cashbacks.map((c) => ({
        id: c.id,
        serviceName: 'Cashback Credit',
        amount: c.amount,
        status: 'Success',
        paymentMode: 'Rewards',
        rewardsAmountUsed: 0.0,
        gatewayAmountPaid: 0.0,
        createdAt: c.createdAt,
        isCashback: true,
      }));
    }

    res.status(200).json(formatted);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getTransactionDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const tx = await Transaction.findOne({
      where: { id, userId: req.user.id },
    });

    if (!tx) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    res.status(200).json({
      id: tx.id,
      serviceName: tx.serviceName,
      amount: tx.amount,
      status: tx.status,
      paymentMode: tx.paymentMode,
      rewardsAmountUsed: tx.rewardsAmountUsed,
      gatewayAmountPaid: tx.gatewayAmountPaid,
      operatorRefId: tx.operatorRefId,
      errorMessage: tx.errorMessage,
      createdAt: tx.createdAt,
      receiptUrl: tx.receiptUrl,
      inputsUsed: JSON.parse(tx.inputsUsed || '{}'),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
