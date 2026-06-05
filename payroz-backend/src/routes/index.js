const express = require('express');
const router = express.Router();

const { authenticateToken, requireRole } = require('../middleware/auth');

// Controllers
const authController = require('../controllers/authController');
const serviceController = require('../controllers/serviceController');
const transactionController = require('../controllers/transactionController');
const supportController = require('../controllers/supportController');
const adminController = require('../controllers/adminController');
const aiSupportController = require('../controllers/aiSupportController');

// 1. Auth Routes
router.post('/auth/send-otp', authController.sendOtp);
router.post('/auth/verify-otp', authController.verifyOtp);
router.get('/auth/profile', authenticateToken, authController.getProfile);
router.put('/auth/profile', authenticateToken, authController.updateProfile);
router.get('/auth/login-history', authenticateToken, authController.getLoginHistory);
router.post('/auth/update-kyc', authenticateToken, authController.updateKyc);

// 2. Services & Banners Routes
router.get('/services/categories', serviceController.getCategories);
router.get('/banners', serviceController.getBanners);
router.get('/offers', serviceController.getOffers);
router.get('/notifications', authenticateToken, serviceController.getNotifications);
router.get('/reminders', authenticateToken, serviceController.getReminders);
router.get('/rewards/scratch-cards', authenticateToken, serviceController.getScratchCards);
router.post('/rewards/scratch/:id', authenticateToken, serviceController.scratchCard);

// 3. Transaction Routes
router.post('/transactions/create', authenticateToken, transactionController.createTransaction);
router.get('/transactions/history', authenticateToken, transactionController.getTransactionHistory);
router.get('/transactions/detail/:id', authenticateToken, transactionController.getTransactionDetail);
router.post('/coupons/validate', authenticateToken, serviceController.validateCoupon);

// 4. Complaint / Support Ticket Routes
router.post('/tickets/create', authenticateToken, supportController.createTicket);
router.get('/tickets', authenticateToken, supportController.getTickets);
router.get('/tickets/:ticketId/messages', authenticateToken, supportController.getTicketMessages);
router.post('/tickets/:ticketId/reply', authenticateToken, supportController.replyToTicket);
router.post('/tickets/:ticketId/transfer', authenticateToken, supportController.transferToHuman);

// 5. AI Support Chatbot Route
router.post('/ai/message', authenticateToken, aiSupportController.processAiChatMessage);

// Customer Feedback Route
router.post('/feedback/submit', authenticateToken, supportController.submitFeedback);

// 6. Admin & Staff Web Panel Routes
router.post('/admin/staff/login', adminController.staffLogin);

// Protected Admin/Staff Routes
router.get('/admin/stats', authenticateToken, requireRole(['Admin', 'Support', 'KYC', 'Refund', 'Marketing', 'Accounts']), adminController.getDashboardStats);
router.get('/admin/users', authenticateToken, requireRole(['Admin', 'KYC', 'Support']), adminController.getUsers);
router.get('/admin/users/:id', authenticateToken, requireRole(['Admin', 'KYC']), adminController.getUserDetail);
router.post('/admin/users/:id/kyc', authenticateToken, requireRole(['Admin', 'KYC']), adminController.approveKyc);

// Admin Category/Service Editing (Dynamic Services!)
router.get('/admin/categories', authenticateToken, requireRole(['Admin', 'Marketing']), serviceController.adminGetCategories);
router.post('/admin/categories', authenticateToken, requireRole(['Admin']), serviceController.adminCreateCategory);
router.put('/admin/categories/:id', authenticateToken, requireRole(['Admin']), serviceController.adminUpdateCategory);

router.get('/admin/services', authenticateToken, requireRole(['Admin', 'Marketing']), serviceController.adminGetServices);
router.post('/admin/services', authenticateToken, requireRole(['Admin']), serviceController.adminCreateService);
router.put('/admin/services/:id', authenticateToken, requireRole(['Admin']), serviceController.adminUpdateService);

// Admin User Administration & Logs
router.post('/admin/users/:id/block', authenticateToken, requireRole(['Admin']), adminController.blockUser);
router.post('/admin/users/:id/credit-bonus', authenticateToken, requireRole(['Admin', 'Marketing']), adminController.creditPromotionalBonus);
router.get('/admin/staff-logs', authenticateToken, requireRole(['Admin']), adminController.getStaffLogs);
router.get('/admin/feedbacks', authenticateToken, requireRole(['Admin', 'Support']), adminController.getFeedbacks);

// Admin Refund and Reports
router.post('/admin/refund', authenticateToken, requireRole(['Admin', 'Refund']), adminController.executeManualRefund);
router.get('/admin/reports', authenticateToken, requireRole(['Admin', 'Accounts']), adminController.getReports);
router.get('/admin/staff', authenticateToken, requireRole(['Admin']), adminController.getStaff);
router.post('/admin/staff', authenticateToken, requireRole(['Admin']), adminController.createStaff);
router.post('/admin/broadcast', authenticateToken, requireRole(['Admin', 'Marketing']), adminController.sendBroadcastNotification);

// Admin Ticket Actions
router.post('/admin/tickets/:ticketId/reply', authenticateToken, requireRole(['Admin', 'Support']), supportController.adminReplyToTicket);
router.put('/admin/tickets/:ticketId/status', authenticateToken, requireRole(['Admin', 'Support']), supportController.updateTicketStatus);

// Admin Coupon CRUD
router.post('/admin/coupons', authenticateToken, requireRole(['Admin', 'Marketing']), serviceController.createCoupon);
router.get('/admin/coupons', authenticateToken, requireRole(['Admin', 'Marketing']), serviceController.getCoupons);
router.put('/admin/coupons/:id', authenticateToken, requireRole(['Admin', 'Marketing']), serviceController.updateCoupon);

module.exports = router;
