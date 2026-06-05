const jwt = require('jsonwebtoken');
require('dotenv').config();
const { User, Staff } = require('../models');

const JWT_SECRET = process.env.JWT_SECRET || 'payroz_b2c_super_secure_secret_key_2026';

// General authenticator
async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    if (decoded.role) {
      // It's a staff member
      const staff = await Staff.findByPk(decoded.id);
      if (!staff || staff.status === 'Inactive') {
        return res.status(403).json({ error: 'Staff account suspended or invalid' });
      }
      req.staff = staff;
      req.userType = 'Staff';
    } else {
      // It's a customer
      const user = await User.findByPk(decoded.id);
      if (!user) {
        return res.status(403).json({ error: 'User not found' });
      }
      if (user.status === 'Blocked') {
        return res.status(403).json({ error: 'Your account is blocked. Contact support.' });
      }
      req.user = user;
      req.userType = 'Customer';
    }
    
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
}

// Require a specific staff role
function requireRole(roles) {
  return (req, res, next) => {
    if (req.userType !== 'Staff' || !req.staff) {
      return res.status(403).json({ error: 'Access denied: Staff login required' });
    }
    
    const hasRole = Array.isArray(roles) 
      ? roles.includes(req.staff.role) 
      : req.staff.role === roles || req.staff.role === 'Admin'; // Admin bypasses most restrictions

    if (!hasRole) {
      return res.status(403).json({ error: `Access denied: Requires role ${roles}` });
    }
    
    next();
  };
}

module.exports = {
  authenticateToken,
  requireRole,
  JWT_SECRET
};
