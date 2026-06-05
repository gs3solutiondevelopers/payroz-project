const { sequelize, db } = require('./db');
const {
  Staff,
  ServiceCategory,
  Service,
  Banner,
  Offer,
  User,
  Coupon,
} = require('../models');

async function seedDatabase() {
  try {
    // Clear Firestore collections to simulate force-sync
    console.log('[SEED] Clearing Firestore collections for a clean test run...');
    const collections = [
      'staff',
      'categories',
      'services',
      'banners',
      'offers',
      'users',
      'transactions',
      'refunds',
      'cashbacks',
      'referrals',
      'tickets',
      'ticket_messages',
      'notifications',
      'logs',
      'scratch_cards',
      'staff_logs',
      'feedbacks',
      'login_history',
      'coupons'
    ];
    
    for (const collName of collections) {
      const ref = db.collection(collName);
      const snapshot = await ref.get();
      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
      }
    }
    
    await sequelize.sync({ force: true });
    console.log('Database collections cleared successfully!');

    // 1. Create Staff
    const admin = await Staff.create({
      name: 'Super Admin',
      email: 'admin@payroz.com',
      passwordHash: 'admin123', // In production, bcrypt is used
      role: 'Admin',
      status: 'Active',
    });

    const support = await Staff.create({
      name: 'Rahul Kumar (Support)',
      email: 'support@payroz.com',
      passwordHash: 'support123',
      role: 'Support',
      status: 'Active',
    });

    const refundOfficer = await Staff.create({
      name: 'Amit Sen (Refunds)',
      email: 'refund@payroz.com',
      passwordHash: 'refund123',
      role: 'Refund',
      status: 'Active',
    });

    const kycOfficer = await Staff.create({
      name: 'Pooja Roy (KYC)',
      email: 'kyc@payroz.com',
      passwordHash: 'kyc123',
      role: 'KYC',
      status: 'Active',
    });

    console.log('Staff seeded.');

    // 2. Create Categories
    const catRecharge = await ServiceCategory.create({
      name: 'Recharge Zone',
      icon: 'smartphone',
      sortOrder: 10,
      status: 'Enabled',
    });

    const catBbps = await ServiceCategory.create({
      name: 'Bill Payments (BBPS)',
      icon: 'receipt',
      sortOrder: 20,
      status: 'Enabled',
    });

    const catInsurance = await ServiceCategory.create({
      name: 'Insurance Zone',
      icon: 'shield',
      sortOrder: 30,
      status: 'Enabled',
    });

    console.log('Categories seeded.');

    // 3. Create Services

    // Recharge Services
    await Service.create({
      categoryId: catRecharge.id,
      name: 'Mobile Recharge',
      icon: 'smartphone',
      formFields: JSON.stringify([
        { name: 'mobile_number', type: 'tel', label: '10-Digit Mobile Number', required: true, pattern: '^[6-9]\\d{9}$' },
        { name: 'operator', type: 'select', label: 'Operator', required: true, options: ['Jio', 'Airtel', 'Vi', 'BSNL'] },
        { name: 'circle', type: 'select', label: 'Circle/Region', required: true, options: ['West Bengal', 'Delhi', 'Mumbai', 'Karnataka', 'Maharashtra'] },
        { name: 'amount', type: 'number', label: 'Recharge Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_RECHARGE_API_V1',
      backupApiProvider: 'MOCK_RECHARGE_API_V2',
      status: 'Enabled',
      commissionSetup: JSON.stringify({ type: 'percent', value: 2.5 }),
      cashbackSetup: JSON.stringify({ type: 'flat', value: 10, maxAmount: 10 }),
      sortOrder: 1,
    });

    await Service.create({
      categoryId: catRecharge.id,
      name: 'DTH Recharge',
      icon: 'tv',
      formFields: JSON.stringify([
        { name: 'customer_id', type: 'text', label: 'Customer ID / Smart Card Number', required: true },
        { name: 'operator', type: 'select', label: 'Operator', required: true, options: ['Tata Play', 'Dish TV', 'Airtel Digital TV', 'Sun Direct'] },
        { name: 'amount', type: 'number', label: 'Recharge Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_DTH_API',
      status: 'Enabled',
      commissionSetup: JSON.stringify({ type: 'percent', value: 3.0 }),
      cashbackSetup: JSON.stringify({ type: 'flat', value: 15, maxAmount: 15 }),
      sortOrder: 2,
    });

    await Service.create({
      categoryId: catRecharge.id,
      name: 'Google Play Recharge',
      icon: 'play',
      formFields: JSON.stringify([
        { name: 'mobile_number', type: 'tel', label: 'Mobile Number for Delivery', required: true },
        { name: 'amount', type: 'number', label: 'Voucher Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_GOOGLE_PLAY_API',
      status: 'Enabled',
      commissionSetup: JSON.stringify({ type: 'flat', value: 1 }),
      cashbackSetup: JSON.stringify({ type: 'percent', value: 2.0, maxAmount: 50 }),
      sortOrder: 3,
    });

    await Service.create({
      categoryId: catRecharge.id,
      name: 'FASTag Recharge',
      icon: 'tag',
      formFields: JSON.stringify([
        { name: 'vehicle_number', type: 'text', label: 'Vehicle Number (e.g. MH12AB1234)', required: true },
        { name: 'bank', type: 'select', label: 'Issuing Bank', required: true, options: ['SBI FASTag', 'HDFC Bank', 'ICICI Bank', 'Paytm Payments Bank'] },
        { name: 'amount', type: 'number', label: 'Recharge Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_FASTAG_API',
      status: 'Enabled',
      sortOrder: 4,
    });

    await Service.create({
      categoryId: catRecharge.id,
      name: 'Data Card Recharge',
      icon: 'wifi',
      formFields: JSON.stringify([
        { name: 'data_card_number', type: 'text', label: 'Data Card Number', required: true },
        { name: 'operator', type: 'select', label: 'Operator', required: true, options: ['JioFi', 'Airtel Dongle', 'Vi Dongle'] },
        { name: 'amount', type: 'number', label: 'Recharge Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_DATACARD_API',
      status: 'Enabled',
      sortOrder: 5,
    });

    // BBPS Services
    await Service.create({
      categoryId: catBbps.id,
      name: 'Electricity Bill',
      icon: 'lightbulb',
      formFields: JSON.stringify([
        { name: 'consumer_id', type: 'text', label: 'Consumer Number / Connection ID', required: true },
        { name: 'board', type: 'select', label: 'Electricity Board', required: true, options: ['WBSEDCL (West Bengal)', 'TPDDL (Delhi)', 'BEST (Mumbai)', 'BESCOM (Bengaluru)'] },
        { name: 'amount', type: 'number', label: 'Bill Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_BBPS_ELECTRICITY',
      status: 'Enabled',
      cashbackSetup: JSON.stringify({ type: 'flat', value: 50, maxAmount: 50 }),
      sortOrder: 1,
    });

    await Service.create({
      categoryId: catBbps.id,
      name: 'Gas Bill',
      icon: 'flame',
      formFields: JSON.stringify([
        { name: 'consumer_id', type: 'text', label: 'Customer Reference ID', required: true },
        { name: 'operator', type: 'select', label: 'Gas Operator', required: true, options: ['Indraprastha Gas', 'Mahanagar Gas', 'Adani Gas'] },
        { name: 'amount', type: 'number', label: 'Bill Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_BBPS_GAS',
      status: 'Enabled',
      sortOrder: 2,
    });

    await Service.create({
      categoryId: catBbps.id,
      name: 'Water Bill',
      icon: 'droplet',
      formFields: JSON.stringify([
        { name: 'consumer_id', type: 'text', label: 'Consumer Number', required: true },
        { name: 'board', type: 'select', label: 'Water Board', required: true, options: ['Delhi Jal Board', 'MCGM Mumbai', 'KWA Kerala'] },
        { name: 'amount', type: 'number', label: 'Bill Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_BBPS_WATER',
      status: 'Enabled',
      sortOrder: 3,
    });

    await Service.create({
      categoryId: catBbps.id,
      name: 'Broadband Bill',
      icon: 'router',
      formFields: JSON.stringify([
        { name: 'account_no', type: 'text', label: 'Broadband Account Number', required: true },
        { name: 'operator', type: 'select', label: 'Service Provider', required: true, options: ['Airtel Xstream', 'JioFiber', 'BSNL Broadband', 'ACT Fibernet'] },
        { name: 'amount', type: 'number', label: 'Bill Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_BBPS_BROADBAND',
      status: 'Enabled',
      sortOrder: 4,
    });

    await Service.create({
      categoryId: catBbps.id,
      name: 'LPG Booking',
      icon: 'cylinder',
      formFields: JSON.stringify([
        { name: 'mobile_number', type: 'tel', label: 'Registered Mobile Number', required: true },
        { name: 'distributor', type: 'select', label: 'LPG Provider', required: true, options: ['Indane Gas', 'HP Gas', 'Bharat Gas'] },
        { name: 'amount', type: 'number', label: 'Booking Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_BBPS_LPG',
      status: 'Enabled',
      sortOrder: 5,
    });

    await Service.create({
      categoryId: catBbps.id,
      name: 'Municipal Tax',
      icon: 'building',
      formFields: JSON.stringify([
        { name: 'property_id', type: 'text', label: 'Property Assessment ID', required: true },
        { name: 'corporation', type: 'select', label: 'Municipal Corporation', required: true, options: ['Kolkata Municipal Corp', 'Municipal Corp of Delhi', 'BMC Mumbai'] },
        { name: 'amount', type: 'number', label: 'Tax Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_BBPS_MUNICIPAL',
      status: 'Enabled',
      sortOrder: 6,
    });

    // Insurance Services
    await Service.create({
      categoryId: catInsurance.id,
      name: 'Bike Insurance',
      icon: 'bike',
      formFields: JSON.stringify([
        { name: 'vehicle_number', type: 'text', label: 'Vehicle Registration Number', required: true },
        { name: 'owner_name', type: 'text', label: 'Owner Full Name', required: true },
        { name: 'provider', type: 'select', label: 'Insurance Partner', required: true, options: ['Digit Insurance', 'Bajaj Allianz', 'HDFC ERGO', 'ICICI Lombard'] },
        { name: 'amount', type: 'number', label: 'Premium Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_INSURANCE_BIKE',
      status: 'Enabled',
      sortOrder: 1,
    });

    await Service.create({
      categoryId: catInsurance.id,
      name: 'Car Insurance',
      icon: 'car',
      formFields: JSON.stringify([
        { name: 'vehicle_number', type: 'text', label: 'Vehicle Registration Number', required: true },
        { name: 'provider', type: 'select', label: 'Insurance Partner', required: true, options: ['Digit Insurance', 'Bajaj Allianz', 'HDFC ERGO'] },
        { name: 'amount', type: 'number', label: 'Premium Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_INSURANCE_CAR',
      status: 'Enabled',
      sortOrder: 2,
    });

    await Service.create({
      categoryId: catInsurance.id,
      name: 'Health Insurance',
      icon: 'activity',
      formFields: JSON.stringify([
        { name: 'proposer_name', type: 'text', label: 'Proposer Full Name', required: true },
        { name: 'age', type: 'number', label: 'Age of Eldest Member', required: true },
        { name: 'provider', type: 'select', label: 'Insurance Partner', required: true, options: ['Star Health', 'Niva Bupa', 'Care Health'] },
        { name: 'amount', type: 'number', label: 'Premium Amount (₹)', required: true },
      ]),
      apiProvider: 'MOCK_INSURANCE_HEALTH',
      status: 'Enabled',
      sortOrder: 3,
    });

    console.log('Services seeded.');

    // 4. Create Banners
    await Banner.create({
      imageUrl: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&q=80&w=800',
      linkUrl: '/refer',
      sortOrder: 1,
      status: 'Active',
    });

    await Banner.create({
      imageUrl: 'https://images.unsplash.com/photo-1621416894569-0f39ed31d247?auto=format&fit=crop&q=80&w=800',
      linkUrl: '/offers',
      sortOrder: 2,
      status: 'Active',
    });

    console.log('Banners seeded.');

    // 5. Create Offers
    await Offer.create({
      title: 'Flat ₹25 Mobile Cashback',
      description: 'On Mobile Recharge of ₹199 or more.',
      promoCode: 'PAYROZ25',
      cashbackAmount: 25.0,
      status: 'Active',
    });

    await Offer.create({
      title: 'Flat ₹50 Utility Bill Cashback',
      description: 'On Bill Payment of ₹500 or more.',
      promoCode: 'BILL50',
      cashbackAmount: 50.0,
      status: 'Active',
    });

    await Offer.create({
      title: 'Flat ₹15 DTH Cashback',
      description: 'On DTH Recharge of ₹200 or more.',
      promoCode: 'DTH15',
      cashbackAmount: 15.0,
      status: 'Active',
    });

    console.log('Offers seeded.');

    // 6. Seed a Default Customer
    const customer = await User.create({
      phone: '9876543210',
      name: 'Rajesh Sharma',
      email: 'rajesh@example.com',
      referralCode: 'PAYROZ987',
      rewardsBalance: 125.50,
      kycStatus: 'Approved',
      kycDetails: JSON.stringify({ docType: 'Aadhaar', docNumber: '123456789012' }),
      status: 'Active',
    });

    console.log('Default user seeded: Phone=9876543210 (Code=PAYROZ987)');

    // 7. Seed Coupons
    await Coupon.create({
      code: 'PAYROZ50',
      discountType: 'flat',
      value: 50.0,
      minAmount: 200.0,
      maxUses: 100,
      usedCount: 0,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      serviceFilter: null,
      status: 'Enabled',
    });

    await Coupon.create({
      code: 'FIRST100',
      discountType: 'percent',
      value: 10.0,
      minAmount: 100.0,
      maxUses: 500,
      usedCount: 0,
      expiresAt: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
      serviceFilter: null,
      status: 'Enabled',
    });

    await Coupon.create({
      code: 'RECHARGE25',
      discountType: 'flat',
      value: 25.0,
      minAmount: 199.0,
      maxUses: 1000,
      usedCount: 0,
      expiresAt: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000).toISOString(),
      serviceFilter: 'Mobile Recharge',
      status: 'Enabled',
    });

    console.log('Sample coupons seeded.');

  } catch (error) {
    console.error('Error seeding database:', error);
  }
}

module.exports = { seedDatabase };
