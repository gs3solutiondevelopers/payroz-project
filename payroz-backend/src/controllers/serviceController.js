const {
  ServiceCategory,
  Service,
  Banner,
  Offer,
  Notification,
  ScratchCard,
  User,
  Cashback,
  Coupon,
} = require('../models');
const { logSystem } = require('../services/automation');

// Get categories and nested services (Customer App dashboard feed)
exports.getCategories = async (req, res) => {
  try {
    const categories = await ServiceCategory.findAll({
      where: { status: 'Enabled' },
      order: [['sortOrder', 'ASC']],
      include: [
        {
          model: Service,
          as: 'services',
          where: { status: ['Enabled', 'Maintenance'] },
          required: false,
        },
      ],
    });

    // Parse JSON configurations so they are objects in response
    const formattedCategories = categories.map((cat) => {
      const services = cat.services.map((srv) => {
        return {
          id: srv.id,
          name: srv.name,
          icon: srv.icon,
          formFields: JSON.parse(srv.formFields || '[]'),
          apiProvider: srv.apiProvider,
          status: srv.status,
          sortOrder: srv.sortOrder,
          cashbackSetup: JSON.parse(srv.cashbackSetup || '{}'),
        };
      });
      
      // Sort services internally
      services.sort((a, b) => a.sortOrder - b.sortOrder);

      return {
        id: cat.id,
        name: cat.name,
        icon: cat.icon,
        sortOrder: cat.sortOrder,
        services,
      };
    });

    res.status(200).json(formattedCategories);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get Banners
exports.getBanners = async (req, res) => {
  try {
    const banners = await Banner.findAll({
      where: { status: 'Active' },
      order: [['sortOrder', 'ASC']],
    });
    res.status(200).json(banners);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get Offers
exports.getOffers = async (req, res) => {
  try {
    const offers = await Offer.findAll({
      where: { status: 'Active' },
    });
    res.status(200).json(offers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get User Notifications (Personalized & Global Broadcasts)
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;
    const { Op } = require('sequelize');

    const notifications = await Notification.findAll({
      where: {
        [Op.or]: [
          { userId: userId }, // specific to this user
          { userId: null }, // broadcasted to all users
        ],
      },
      order: [['createdAt', 'DESC']],
    });
    res.status(200).json(notifications);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ADMIN: Category CRUD
exports.adminGetCategories = async (req, res) => {
  try {
    const categories = await ServiceCategory.findAll({ order: [['sortOrder', 'ASC']] });
    res.status(200).json(categories);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.adminCreateCategory = async (req, res) => {
  try {
    const { name, icon, sortOrder } = req.body;
    const category = await ServiceCategory.create({ name, icon, sortOrder });
    await logSystem('Info', `Admin created category: ${name}`);
    res.status(201).json(category);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.adminUpdateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, icon, sortOrder, status } = req.body;
    const category = await ServiceCategory.findByPk(id);
    if (!category) return res.status(404).json({ error: 'Category not found' });

    await category.update({ name, icon, sortOrder, status });
    await logSystem('Info', `Admin updated category: ${name}`);
    res.status(200).json(category);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ADMIN: Service CRUD (Crucial for adding B2C services dynamically without app updates!)
exports.adminGetServices = async (req, res) => {
  try {
    const services = await Service.findAll({ order: [['sortOrder', 'ASC']] });
    const formatted = services.map((s) => ({
      ...s.toJSON(),
      formFields: JSON.parse(s.formFields),
      commissionSetup: JSON.parse(s.commissionSetup),
      cashbackSetup: JSON.parse(s.cashbackSetup),
    }));
    res.status(200).json(formatted);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.adminCreateService = async (req, res) => {
  try {
    const {
      categoryId,
      name,
      icon,
      formFields, // Expect array of field schema objects
      apiProvider,
      backupApiProvider,
      commissionSetup,
      cashbackSetup,
      sortOrder,
    } = req.body;

    const service = await Service.create({
      categoryId,
      name,
      icon,
      formFields: JSON.stringify(formFields || []),
      apiProvider: apiProvider || 'PrimaryProvider',
      backupApiProvider: backupApiProvider || 'BackupProvider',
      commissionSetup: JSON.stringify(commissionSetup || { type: 'flat', value: 0 }),
      cashbackSetup: JSON.stringify(cashbackSetup || { type: 'flat', value: 0 }),
      sortOrder: sortOrder || 0,
      status: 'Enabled',
    });

    await logSystem('Info', `Admin created new B2C Service dynamically: ${name}`);

    res.status(201).json({
      ...service.toJSON(),
      formFields: JSON.parse(service.formFields),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.adminUpdateService = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      categoryId,
      name,
      icon,
      formFields,
      apiProvider,
      backupApiProvider,
      commissionSetup,
      cashbackSetup,
      sortOrder,
      status,
    } = req.body;

    const service = await Service.findByPk(id);
    if (!service) return res.status(404).json({ error: 'Service not found' });

    await service.update({
      categoryId,
      name,
      icon,
      formFields: formFields ? JSON.stringify(formFields) : service.formFields,
      apiProvider: apiProvider || service.apiProvider,
      backupApiProvider: backupApiProvider || service.backupApiProvider,
      commissionSetup: commissionSetup ? JSON.stringify(commissionSetup) : service.commissionSetup,
      cashbackSetup: cashbackSetup ? JSON.stringify(cashbackSetup) : service.cashbackSetup,
      sortOrder: sortOrder !== undefined ? sortOrder : service.sortOrder,
      status: status || service.status,
    });

    await logSystem('Info', `Admin updated service config: ${name}`);

    res.status(200).json({
      ...service.toJSON(),
      formFields: JSON.parse(service.formFields),
      commissionSetup: JSON.parse(service.commissionSetup),
      cashbackSetup: JSON.parse(service.cashbackSetup),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get User Scratch Cards
exports.getScratchCards = async (req, res) => {
  try {
    const userId = req.user.id;
    const cards = await ScratchCard.findAll({
      where: { userId },
      order: [['createdAt', 'DESC']],
    });
    res.status(200).json(cards);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Scratch Card Action
exports.scratchCard = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const card = await ScratchCard.findByPk(id);
    if (!card) {
      return res.status(404).json({ error: 'Scratch card not found' });
    }

    if (card.userId !== userId) {
      return res.status(403).json({ error: 'Unauthorized access to card' });
    }

    if (card.status === 'Scratched') {
      return res.status(400).json({ error: 'This card has already been scratched' });
    }

    // Mark as scratched
    card.status = 'Scratched';
    card.scratchedAt = new Date().toISOString();
    await card.save();

    // Credit to user rewardsBalance
    const user = req.user; // loaded by auth token middleware
    const originalBalance = user.rewardsBalance;
    user.rewardsBalance += card.amount;
    await user.save();

    // Create Cashback Record
    await Cashback.create({
      userId: user.id,
      transactionId: card.id,
      amount: card.amount,
      status: 'Credited',
    });

    // Create a Notification alert
    await Notification.create({
      userId,
      title: 'Scratch Card Redeemed!',
      message: `Congratulations! You scratched and won ₹${card.amount.toFixed(2)} cashback added to your Rewards Wallet.`,
      type: 'Cashback',
    });

    await logSystem('Info', `User ${user.phone} scratched card ${id} and won ₹${card.amount}`, {
      prevBalance: originalBalance,
      newBalance: user.rewardsBalance,
    });

    res.status(200).json({
      message: 'Card scratched successfully',
      amount: card.amount,
      rewardsBalance: user.rewardsBalance,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get User Reminders
exports.getReminders = async (req, res) => {
  try {
    const userId = req.user.id;
    const { generateSmartReminders } = require('../services/automation');
    const reminders = await generateSmartReminders(userId);
    res.status(200).json(reminders);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.createCoupon = async (req, res) => {
  try {
    const { code, discountType, value, minAmount, maxUses, expiresAt, serviceFilter, status } = req.body;
    
    if (!code || !discountType || value === undefined) {
      return res.status(400).json({ error: 'Code, discountType, and value are required' });
    }

    const existing = await Coupon.findOne({ where: { code } });
    if (existing) {
      return res.status(400).json({ error: 'Coupon code already exists' });
    }

    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      discountType,
      value: parseFloat(value),
      minAmount: minAmount !== undefined ? parseFloat(minAmount) : 0,
      maxUses: maxUses !== undefined ? parseInt(maxUses, 10) : null,
      usedCount: 0,
      expiresAt: expiresAt || null,
      serviceFilter: serviceFilter || null,
      status: status || 'Enabled',
    });

    await logSystem('Info', `Coupon created: ${code}`);

    res.status(201).json(coupon);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getCoupons = async (req, res) => {
  try {
    const coupons = await Coupon.findAll({ order: [['createdAt', 'DESC']] });
    res.status(200).json(coupons);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateCoupon = async (req, res) => {
  try {
    const { id } = req.params;
    const { code, discountType, value, minAmount, maxUses, usedCount, expiresAt, serviceFilter, status } = req.body;

    const coupon = await Coupon.findByPk(id);
    if (!coupon) return res.status(404).json({ error: 'Coupon not found' });

    await coupon.update({
      code: code ? code.toUpperCase() : coupon.code,
      discountType: discountType || coupon.discountType,
      value: value !== undefined ? parseFloat(value) : coupon.value,
      minAmount: minAmount !== undefined ? parseFloat(minAmount) : coupon.minAmount,
      maxUses: maxUses !== undefined ? parseInt(maxUses, 10) : coupon.maxUses,
      usedCount: usedCount !== undefined ? parseInt(usedCount, 10) : coupon.usedCount,
      expiresAt: expiresAt !== undefined ? expiresAt : coupon.expiresAt,
      serviceFilter: serviceFilter !== undefined ? serviceFilter : coupon.serviceFilter,
      status: status || coupon.status,
    });

    res.status(200).json(coupon);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.validateCoupon = async (req, res) => {
  try {
    const { code, amount, serviceName } = req.body;

    if (!code) {
      return res.status(400).json({ error: 'Coupon code is required' });
    }

    const coupon = await Coupon.findOne({ where: { code: code.toUpperCase() } });
    if (!coupon) {
      return res.status(400).json({ error: 'Invalid coupon code' });
    }

    if (coupon.status !== 'Enabled') {
      return res.status(400).json({ error: 'Coupon is not active' });
    }

    // Check expiry
    if (coupon.expiresAt && new Date() > new Date(coupon.expiresAt)) {
      return res.status(400).json({ error: 'Coupon has expired' });
    }

    // Check usage limits
    if (coupon.maxUses !== null && coupon.usedCount >= coupon.maxUses) {
      return res.status(400).json({ error: 'Coupon has reached its maximum usage limit' });
    }

    // Check min amount
    if (amount !== undefined && parseFloat(amount) < coupon.minAmount) {
      return res.status(400).json({ error: `Minimum amount of ₹${coupon.minAmount} required to use this coupon` });
    }

    // Check service filter
    if (serviceName && coupon.serviceFilter && coupon.serviceFilter !== serviceName) {
      return res.status(400).json({ error: `This coupon is not applicable for ${serviceName}` });
    }

    // Calculate discount
    let discount = 0;
    const baseAmount = amount !== undefined ? parseFloat(amount) : 0;
    if (coupon.discountType === 'percent') {
      discount = (baseAmount * coupon.value) / 100;
    } else {
      discount = coupon.value;
    }

    // Cap discount to amount paid
    if (discount > baseAmount) {
      discount = baseAmount;
    }

    res.status(200).json({
      valid: true,
      couponId: coupon.id,
      code: coupon.code,
      discountType: coupon.discountType,
      value: coupon.value,
      discountAmount: discount,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};


