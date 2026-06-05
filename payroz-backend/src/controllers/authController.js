const jwt = require('jsonwebtoken');
const http = require('http');
const { User, LoginHistory } = require('../models');
const { JWT_SECRET } = require('../middleware/auth');
const { logSystem } = require('../services/automation');

// Simple local OTP storage (In production, use Redis or DB with expiry)
const otpStore = {};

exports.sendOtp = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ error: 'Phone number is required' });
    }

    // Generate random 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString(); 
    otpStore[phone] = {
      otp,
      expiresAt: Date.now() + 5 * 60 * 1000, // 5 mins
    };

    console.log(`[SMS-GATEWAY] Sending OTP ${otp} to phone ${phone} via MSG91...`);
    await logSystem('Info', `OTP SMS generated for phone ${phone}`);

    // Call real MSG91 HTTP API
    const dateStr = new Date().toLocaleDateString('en-GB'); // dd/mm/yyyy
    const msg = `Message, OTP is ${otp} on PayRoz login Rsponse is valid for 5 minutes by PayRoz via GS3 SOLUTION`;
    const url = `http://api.msg91.com/api/sendhttp.php?authkey=290953A5hyqLE9RlyU5d60e78a&mobiles=91${phone}&message=${encodeURIComponent(msg)}&sender=MEECSL&DLT_TE_ID=1207166115689631150&route=4`;

    http.get(url, (apiRes) => {
      let data = '';
      apiRes.on('data', (chunk) => { data += chunk; });
      apiRes.on('end', () => {
        console.log(`[MSG91-API] Response for ${phone}: ${data}`);
      });
    }).on('error', (err) => {
      console.error(`[MSG91-API] Error sending SMS to ${phone}:`, err);
    });

    res.status(200).json({
      message: 'OTP sent successfully',
      otp, // return for testing/debugging convenience
      phone
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { phone, otp, deviceId, name, email, referralCodeInput } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ error: 'Phone and OTP are required' });
    }

    const storedData = otpStore[phone];
    if (!storedData) {
      return res.status(400).json({ error: 'OTP request expired or not found' });
    }

    if (storedData.otp !== otp) {
      return res.status(400).json({ error: 'Invalid OTP entered' });
    }

    if (Date.now() > storedData.expiresAt) {
      delete otpStore[phone];
      return res.status(400).json({ error: 'OTP expired' });
    }

    // Verify Success -> Clear OTP
    delete otpStore[phone];

    // Find or Create User
    let user = await User.findOne({ where: { phone } });
    let isNewUser = false;

    if (!user) {
      isNewUser = true;

      // Handle Referral referralCodeInput
      let referrerId = null;
      if (referralCodeInput) {
        const referrer = await User.findOne({ where: { referralCode: referralCodeInput } });
        if (referrer) {
          if (deviceId && referrer.deviceId === deviceId) {
            return res.status(400).json({ error: 'Self-referral is not allowed on the same device.' });
          }
          const referralCount = await User.count({ where: { referredById: referrer.id } });
          if (referralCount >= 10) {
            return res.status(400).json({ error: 'This referral code has reached its usage limit.' });
          }
          referrerId = referrer.id;
        }
      }

      // Generate unique referral code for new user
      const uniqueCode = 'PAYROZ' + Math.floor(100 + Math.random() * 900) + phone.substring(phone.length - 3);

      user = await User.create({
        phone,
        name: name || 'User ' + phone.substring(phone.length - 4),
        email: email || '',
        referralCode: uniqueCode,
        referredById: referrerId,
        rewardsBalance: 0.0,
        kycStatus: 'None',
        deviceId,
        status: 'Active',
      });

      await logSystem('Info', `New user registered via OTP: ${phone} (Code: ${uniqueCode})`);
    } else {
      // Update device ID if changed
      if (deviceId && user.deviceId !== deviceId) {
        user.deviceId = deviceId;
        await user.save();
      }
    }

    // Record Login History
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '';
    await LoginHistory.create({
      userId: user.id,
      phone: user.phone,
      deviceId: deviceId || 'Unknown',
      ip,
      timestamp: new Date().toISOString()
    });

    // Generate JWT
    const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '30d' });

    res.status(200).json({
      message: isNewUser ? 'Registration successful' : 'Login successful',
      token,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        kycStatus: user.kycStatus,
        rewardsBalance: user.rewardsBalance,
        referralCode: user.referralCode,
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const user = req.user; // Set by authenticationToken middleware
    res.status(200).json({
      id: user.id,
      phone: user.phone,
      name: user.name,
      email: user.email,
      kycStatus: user.kycStatus,
      kycDetails: user.kycDetails ? JSON.parse(user.kycDetails) : null,
      rewardsBalance: user.rewardsBalance,
      referralCode: user.referralCode,
      referredById: user.referredById,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateKyc = async (req, res) => {
  try {
    const user = req.user;
    const { docType, docNumber } = req.body;

    if (!docType || !docNumber) {
      return res.status(400).json({ error: 'Document type and document number are required' });
    }

    user.kycStatus = 'Pending';
    user.kycDetails = JSON.stringify({
      docType,
      docNumber,
      submittedAt: new Date().toISOString(),
    });
    await user.save();

    await logSystem('Info', `User ${user.phone} submitted KYC docs for review`);

    res.status(200).json({
      message: 'KYC documents submitted. Status is now Pending.',
      kycStatus: user.kycStatus,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const user = req.user;
    const { name, email } = req.body;

    if (name !== undefined) user.name = name;
    if (email !== undefined) user.email = email;

    await user.save();
    
    await logSystem('Info', `User ${user.phone} updated profile: name=${name}, email=${email}`);

    res.status(200).json({
      message: 'Profile updated successfully',
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        kycStatus: user.kycStatus,
        rewardsBalance: user.rewardsBalance,
        referralCode: user.referralCode,
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getLoginHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const history = await LoginHistory.findAll({
      where: { userId },
      order: [['timestamp', 'DESC']],
      limit: 50
    });
    res.status(200).json(history);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
