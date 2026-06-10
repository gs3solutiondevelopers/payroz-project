import React, { useState, useEffect } from 'react';
import { 
  LayoutDashboard, 
  Settings, 
  UserCheck, 
  CreditCard, 
  HelpCircle, 
  Tag, 
  Users, 
  FileText, 
  LogOut, 
  Plus, 
  Edit, 
  Check, 
  X, 
  Send, 
  ArrowRight, 
  Bell, 
  RefreshCw, 
  User, 
  Search,
  AlertTriangle,
  Lock
} from 'lucide-react';

// Use localhost for local development, and Cloud Run URL for production build
const API_BASE = import.meta.env.DEV ? 'http://localhost:5000/api' : 'https://payroz-project-427839361332.asia-south1.run.app/api';

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('admin_token') || '');
  const [staff, setStaff] = useState(JSON.parse(localStorage.getItem('admin_staff') || 'null'));
  const [currentTab, setCurrentTab] = useState('dashboard');
  
  // Login State
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [twoFactorStep, setTwoFactorStep] = useState(false);
  const [twoFactorCode, setTwoFactorCode] = useState('');
  const [authError, setAuthError] = useState('');

  // Dashboard Stats State
  const [stats, setStats] = useState(null);
  const [recentLogs, setRecentLogs] = useState([]);
  
  // Lists
  const [users, setUsers] = useState([]);
  const [categories, setCategories] = useState([]);
  const [services, setServices] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [tickets, setTickets] = useState([]);
  const [staffList, setStaffList] = useState([]);
  const [reports, setReports] = useState([]);
  const [reportType, setReportType] = useState('revenue');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [userFilterId, setUserFilterId] = useState('');

  // Coupon States
  const [coupons, setCoupons] = useState([]);
  const [showAddCouponModal, setShowAddCouponModal] = useState(false);
  const [editingCoupon, setEditingCoupon] = useState(null);
  const [couponCode, setCouponCode] = useState('');
  const [couponDiscountType, setCouponDiscountType] = useState('flat');
  const [couponValue, setCouponValue] = useState(0);
  const [couponMinAmount, setCouponMinAmount] = useState(0);
  const [couponMaxUses, setCouponMaxUses] = useState('');
  const [couponExpiresAt, setCouponExpiresAt] = useState('');
  const [couponServiceFilter, setCouponServiceFilter] = useState('');
  const [couponStatus, setCouponStatus] = useState('Enabled');

  // Staff Logs & Feedbacks
  const [staffLogs, setStaffLogs] = useState([]);
  const [feedbacks, setFeedbacks] = useState([]);
  const [showBonusModal, setShowBonusModal] = useState(false);
  const [selectedUserForBonus, setSelectedUserForBonus] = useState(null);
  const [bonusAmount, setBonusAmount] = useState('');
  const [bonusRemark, setBonusRemark] = useState('');
  const [customerSearchQuery, setCustomerSearchQuery] = useState('');

  // Active Chats / Selections
  const [activeTicket, setActiveTicket] = useState(null);
  const [ticketMessages, setTicketMessages] = useState([]);
  const [replyText, setReplyText] = useState('');

  // Modals / Creators
  const [showAddServiceModal, setShowAddServiceModal] = useState(false);
  const [editingService, setEditingService] = useState(null);
  const [showAddCategoryModal, setShowAddCategoryModal] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [showAddStaffModal, setShowAddStaffModal] = useState(false);

  // Service form creator state (Dynamic services support)
  const [serviceName, setServiceName] = useState('');
  const [serviceCategoryId, setServiceCategoryId] = useState('');
  const [serviceIcon, setServiceIcon] = useState('smartphone');
  const [serviceProvider, setServiceProvider] = useState('PrimaryProvider');
  const [serviceBackupProvider, setServiceBackupProvider] = useState('BackupProvider');
  const [serviceSortOrder, setServiceSortOrder] = useState(0);
  const [serviceFields, setServiceFields] = useState([]); // [{ name, type, label, required }]
  const [cashbackType, setCashbackType] = useState('flat');
  const [cashbackVal, setCashbackVal] = useState(0);
  const [cashbackMax, setCashbackMax] = useState(0);
  
  // Notifications Creator state
  const [notifyTitle, setNotifyTitle] = useState('');
  const [notifyMessage, setNotifyMessage] = useState('');
  const [notifyType, setNotifyType] = useState('System');

  // Staff creation state
  const [newStaffName, setNewStaffName] = useState('');
  const [newStaffEmail, setNewStaffEmail] = useState('');
  const [newStaffPass, setNewStaffPass] = useState('');
  const [newStaffRole, setNewStaffRole] = useState('Support');

  useEffect(() => {
    if (token) {
      fetchDashboardStats();
      fetchCategories();
      fetchServices();
      fetchUsers();
      fetchTransactions();
      fetchTickets();
      fetchStaff();
      fetchReports();
      fetchStaffLogs();
      fetchFeedbacks();
      fetchCoupons();
    }
  }, [token]);

  // Auth Operations
  const handleLoginSubmit = async (e) => {
    e.preventDefault();
    setAuthError('');
    if (!email || !password) {
      setAuthError('Email and Password are required');
      return;
    }
    
    // Check credentials first
    try {
      const res = await fetch(`${API_BASE}/admin/staff/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) {
        setAuthError(data.error || 'Invalid credentials');
        return;
      }
      
      // If credentials correct, proceed to 2FA verification step
      setTwoFactorStep(true);
    } catch (err) {
      setAuthError('Server connection failed');
    }
  };

  const handleTwoFactorVerify = async (e) => {
    e.preventDefault();
    setAuthError('');
    if (twoFactorCode.length !== 6) {
      setAuthError('Please enter a valid 6-digit code');
      return;
    }

    // Authenticate and save token
    try {
      const res = await fetch(`${API_BASE}/admin/staff/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (res.ok) {
        localStorage.setItem('admin_token', data.token);
        localStorage.setItem('admin_staff', JSON.stringify(data.staff));
        setToken(data.token);
        setStaff(data.staff);
        setTwoFactorStep(false);
      } else {
        setAuthError(data.error || '2FA Authentication Failed');
      }
    } catch (err) {
      setAuthError('Error during login completion');
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_staff');
    setToken('');
    setStaff(null);
  };

  // API Fetches
  const fetchDashboardStats = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/stats`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.status === 401 || res.status === 403) {
        handleLogout();
        return;
      }
      const data = await res.json();
      if (res.ok) {
        setStats(data.stats);
        setRecentLogs(data.recentLogs);
      }
    } catch (e) { console.error(e); }
  };

  const fetchCategories = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/categories`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setCategories(data);
    } catch (e) { console.error(e); }
  };

  const fetchServices = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/services`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setServices(data);
    } catch (e) { console.error(e); }
  };

  const fetchUsers = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/users`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setUsers(data);
    } catch (e) { console.error(e); }
  };

  const fetchTransactions = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/reports?reportType=revenue`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setTransactions(data);
    } catch (e) { console.error(e); }
  };

  const fetchTickets = async () => {
    try {
      const res = await fetch(`${API_BASE}/tickets`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setTickets(data);
    } catch (e) { console.error(e); }
  };

  const fetchStaff = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/staff`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setStaffList(data);
    } catch (e) { console.error(e); }
  };

  const fetchReports = async () => {
    try {
      let url = `${API_BASE}/admin/reports?reportType=${reportType}`;
      if (startDate) url += `&startDate=${startDate}`;
      if (endDate) url += `&endDate=${endDate}`;
      if (userFilterId) url += `&userId=${userFilterId}`;

      const res = await fetch(url, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setReports(data);
    } catch (e) { console.error(e); }
  };

  const fetchCoupons = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/coupons`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setCoupons(data);
    } catch (e) { console.error(e); }
  };

  useEffect(() => {
    if (token) fetchReports();
  }, [reportType]);

  const fetchStaffLogs = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/staff-logs`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setStaffLogs(data);
    } catch (e) { console.error(e); }
  };

  const fetchFeedbacks = async () => {
    try {
      const res = await fetch(`${API_BASE}/admin/feedbacks`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setFeedbacks(data);
    } catch (e) { console.error(e); }
  };

  const handleToggleBlockUser = async (userId) => {
    try {
      const res = await fetch(`${API_BASE}/admin/users/${userId}/block`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        }
      });
      const data = await res.json();
      if (res.ok) {
        alert(data.message);
        fetchUsers();
        fetchDashboardStats();
        fetchStaffLogs();
      } else {
        alert(data.error || 'Failed to toggle block status');
      }
    } catch (e) { console.error(e); }
  };

  const handleCreditBonusSubmit = async (e) => {
    e.preventDefault();
    if (!selectedUserForBonus || !bonusAmount || isNaN(parseFloat(bonusAmount))) return;
    try {
      const res = await fetch(`${API_BASE}/admin/users/${selectedUserForBonus.id}/credit-bonus`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ amount: parseFloat(bonusAmount), remark: bonusRemark })
      });
      const data = await res.json();
      if (res.ok) {
        alert(`Successfully credited ₹${bonusAmount} to ${selectedUserForBonus.name || selectedUserForBonus.phone}`);
        setShowBonusModal(false);
        setSelectedUserForBonus(null);
        setBonusAmount('');
        setBonusRemark('');
        fetchUsers();
        fetchDashboardStats();
        fetchStaffLogs();
      } else {
        alert(data.error || 'Failed to credit bonus');
      }
    } catch (e) { console.error(e); }
  };

  // Load chat messages
  const selectTicket = async (ticket) => {
    setActiveTicket(ticket);
    try {
      const res = await fetch(`${API_BASE}/tickets/${ticket.id}/messages`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) setTicketMessages(data);
    } catch (e) { console.error(e); }
  };

  const handleTicketReply = async (e) => {
    e.preventDefault();
    if (!replyText.trim()) return;

    try {
      const res = await fetch(`${API_BASE}/admin/tickets/${activeTicket.id}/reply`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ message: replyText }),
      });
      const data = await res.json();
      if (res.ok) {
        setTicketMessages([...ticketMessages, data]);
        setReplyText('');
        fetchTickets(); // refresh status/updated times
      }
    } catch (e) { console.error(e); }
  };

  // KYC Approval
  const handleKycStatusUpdate = async (userId, status) => {
    try {
      const res = await fetch(`${API_BASE}/admin/users/${userId}/kyc`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ status }),
      });
      if (res.ok) {
        fetchUsers();
        fetchDashboardStats();
      }
    } catch (e) { console.error(e); }
  };

  // Manual Refund
  const handleManualRefund = async (txId) => {
    try {
      const res = await fetch(`${API_BASE}/admin/refund`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ transactionId: txId }),
      });
      if (res.ok) {
        alert('Manual refund credited to customer Rewards Wallet!');
        fetchTransactions();
        fetchDashboardStats();
      }
    } catch (e) { console.error(e); }
  };

  // Service Management Actions
  const addInputField = () => {
    setServiceFields([...serviceFields, { name: '', type: 'text', label: '', required: true, options: '' }]);
  };

  const removeInputField = (index) => {
    const fields = [...serviceFields];
    fields.splice(index, 1);
    setServiceFields(fields);
  };

  const updateInputField = (index, key, value) => {
    const fields = [...serviceFields];
    fields[index][key] = value;
    setServiceFields(fields);
  };

  const handleCreateService = async (e) => {
    e.preventDefault();
    const formattedFields = serviceFields.map(f => ({
      ...f,
      options: f.options ? f.options.split(',').map(s => s.trim()) : undefined
    }));

    const payload = {
      categoryId: serviceCategoryId,
      name: serviceName,
      icon: serviceIcon,
      formFields: formattedFields,
      apiProvider: serviceProvider,
      backupApiProvider: serviceBackupProvider,
      sortOrder: parseInt(serviceSortOrder),
      cashbackSetup: { type: cashbackType, value: parseFloat(cashbackVal), maxAmount: parseFloat(cashbackMax) },
    };

    try {
      const url = editingService 
        ? `${API_BASE}/admin/services/${editingService.id}` 
        : `${API_BASE}/admin/services`;
      const method = editingService ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        setShowAddServiceModal(false);
        setEditingService(null);
        // Clear
        setServiceName('');
        setServiceCategoryId('');
        setServiceFields([]);
        setCashbackVal(0);
        fetchServices();
      }
    } catch (e) { console.error(e); }
  };

  const handleEditServiceClick = (srv) => {
    setEditingService(srv);
    setServiceName(srv.name);
    setServiceCategoryId(srv.categoryId);
    setServiceIcon(srv.icon);
    setServiceProvider(srv.apiProvider);
    setServiceBackupProvider(srv.backupApiProvider);
    setServiceSortOrder(srv.sortOrder);
    setCashbackType(srv.cashbackSetup.type || 'flat');
    setCashbackVal(srv.cashbackSetup.value || 0);
    setCashbackMax(srv.cashbackSetup.maxAmount || 0);
    
    // Map form fields
    const fields = srv.formFields.map(f => ({
      ...f,
      options: f.options ? f.options.join(', ') : ''
    }));
    setServiceFields(fields);
    setShowAddServiceModal(true);
  };

  const toggleServiceStatus = async (srv, status) => {
    try {
      const res = await fetch(`${API_BASE}/admin/services/${srv.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ status }),
      });
      if (res.ok) fetchServices();
    } catch (e) { console.error(e); }
  };

  const handleCreateCoupon = async (e) => {
    e.preventDefault();
    const payload = {
      code: couponCode,
      discountType: couponDiscountType,
      value: parseFloat(couponValue),
      minAmount: parseFloat(couponMinAmount) || 0,
      maxUses: couponMaxUses ? parseInt(couponMaxUses, 10) : null,
      expiresAt: couponExpiresAt || null,
      serviceFilter: couponServiceFilter || null,
      status: couponStatus,
    };

    try {
      const url = editingCoupon 
        ? `${API_BASE}/admin/coupons/${editingCoupon.id}` 
        : `${API_BASE}/admin/coupons`;
      const method = editingCoupon ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        setShowAddCouponModal(false);
        setEditingCoupon(null);
        setCouponCode('');
        setCouponValue(0);
        setCouponMinAmount(0);
        setCouponMaxUses('');
        setCouponExpiresAt('');
        setCouponServiceFilter('');
        fetchCoupons();
      } else {
        const d = await res.json();
        alert(d.error || 'Failed to save coupon');
      }
    } catch (e) { console.error(e); }
  };

  const handleEditCouponClick = (cpn) => {
    setEditingCoupon(cpn);
    setCouponCode(cpn.code);
    setCouponDiscountType(cpn.discountType);
    setCouponValue(cpn.value);
    setCouponMinAmount(cpn.minAmount);
    setCouponMaxUses(cpn.maxUses || '');
    setCouponExpiresAt(cpn.expiresAt ? new Date(cpn.expiresAt).toISOString().split('T')[0] : '');
    setCouponServiceFilter(cpn.serviceFilter || '');
    setCouponStatus(cpn.status);
    setShowAddCouponModal(true);
  };

  const toggleCouponStatus = async (cpn) => {
    const newStatus = cpn.status === 'Enabled' ? 'Disabled' : 'Enabled';
    try {
      const res = await fetch(`${API_BASE}/admin/coupons/${cpn.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ status: newStatus }),
      });
      if (res.ok) fetchCoupons();
    } catch (e) { console.error(e); }
  };

  // Staff creation
  const handleCreateStaff = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch(`${API_BASE}/admin/staff`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          name: newStaffName,
          email: newStaffEmail,
          password: newStaffPass,
          role: newStaffRole
        })
      });
      if (res.ok) {
        setShowAddStaffModal(false);
        setNewStaffName('');
        setNewStaffEmail('');
        setNewStaffPass('');
        fetchStaff();
      } else {
        const d = await res.json();
        alert(d.error);
      }
    } catch (e) { console.error(e); }
  };

  // Broadcast Alert
  const handleBroadcastAlert = async (e) => {
    e.preventDefault();
    if (!notifyTitle || !notifyMessage) return;

    try {
      const res = await fetch(`${API_BASE}/admin/broadcast`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ title: notifyTitle, message: notifyMessage, type: notifyType })
      });
      if (res.ok) {
        alert('Broadcast push notification sent successfully!');
        setNotifyTitle('');
        setNotifyMessage('');
      }
    } catch (e) { console.error(e); }
  };

  // RENDER LOGIN SCREEN
  if (!token) {
    return (
      <div style={{
        display: 'flex', minHeight: '100vh', width: '100%', 
        alignItems: 'center', justifyContent: 'center', 
        backgroundColor: '#0B192C',
        background: 'radial-gradient(circle, rgba(11,25,44,1) 0%, rgba(15,23,42,1) 100%)',
        padding: '1.5rem'
      }}>
        <div style={{
          backgroundColor: '#FFFFFF', padding: '2.5rem', borderRadius: '16px',
          boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.3)', width: '100%', maxWidth: '420px'
        }} className="fade-in">
          
          <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
            <div style={{
              width: '80px', height: '80px', borderRadius: '16px',
              backgroundColor: '#FFFFFF', padding: '8px',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              marginBottom: '1rem', boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
            }}>
              <img 
                src="/logo.png" 
                alt="Payroz Logo" 
                style={{ width: '100%', height: '100%', objectFit: 'contain' }} 
              />
            </div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: '800', color: '#0B192C' }}>PAYROZ</h1>
            <p style={{ fontSize: '0.875rem', color: '#64748B', marginTop: '0.25rem' }}>Administration Web Portal</p>
          </div>

          {authError && (
            <div style={{
              backgroundColor: '#FCE8E6', color: '#EF4444', padding: '0.75rem 1rem',
              borderRadius: '8px', marginBottom: '1rem', fontSize: '0.875rem', fontWeight: '500',
              display: 'flex', gap: '0.5rem', alignItems: 'center'
            }}>
              <AlertTriangle size={16} /> {authError}
            </div>
          )}

          {!twoFactorStep ? (
            <form onSubmit={handleLoginSubmit}>
              <div className="form-group">
                <label className="form-label">Email Address</label>
                <input 
                  type="email" 
                  className="form-input" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@payroz.com"
                  required
                />
              </div>

              <div className="form-group" style={{ marginBottom: '2rem' }}>
                <label className="form-label">Secret Password</label>
                <input 
                  type="password" 
                  className="form-input" 
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                />
              </div>

              <button type="submit" className="btn btn-primary" style={{ width: '100%' }}>
                Verify Credentials <ArrowRight size={16} />
              </button>
            </form>
          ) : (
            <form onSubmit={handleTwoFactorVerify}>
              <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
                <Lock size={36} color="#FF6B00" style={{ margin: '0 auto 0.75rem' }} />
                <h3 style={{ fontWeight: '700', color: '#0B192C' }}>Two-Factor Authentication</h3>
                <p style={{ fontSize: '0.875rem', color: '#64748B', marginTop: '0.25rem' }}>
                  Enter the 6-digit code from Google Authenticator.
                </p>
              </div>

              <div className="form-group" style={{ marginBottom: '2rem' }}>
                <input 
                  type="text" 
                  className="form-input" 
                  style={{ textAlign: 'center', fontSize: '1.5rem', letterSpacing: '0.5em', fontWeight: '700' }}
                  maxLength={6}
                  value={twoFactorCode}
                  onChange={(e) => setTwoFactorCode(e.target.value.replace(/\D/g,''))}
                  placeholder="000000"
                  required
                />
              </div>

              <div style={{ display: 'flex', gap: '0.75rem' }}>
                <button type="button" className="btn btn-outline" style={{ flex: 1 }} onClick={() => setTwoFactorStep(false)}>
                  Back
                </button>
                <button type="submit" className="btn btn-secondary" style={{ flex: 2 }}>
                  Verify & Log In
                </button>
              </div>
            </form>
          )}

          <div style={{ marginTop: '1.5rem', textAlign: 'center', fontSize: '0.75rem', color: '#64748B' }}>
            PAYROZ B2C Secure Administration Terminal. Authorized Personnel Only.
          </div>
        </div>
      </div>
    );
  }

  // MAIN DASHBOARD LAYOUT
  return (
    <div className="app-container">
      
      {/* SIDEBAR NAVIGATION */}
      <aside style={{
        width: 'var(--sidebar-width)',
        backgroundColor: 'var(--primary-color)',
        color: '#FFFFFF',
        position: 'fixed',
        top: 0, bottom: 0, left: 0,
        display: 'flex',
        flexDirection: 'column',
        zIndex: 100
      }}>
        <div style={{
          padding: '2rem 1.5rem',
          display: 'flex',
          alignItems: 'center',
          gap: '0.75rem',
          borderBottom: '1px solid #1E293B'
        }}>
          <div style={{
            width: '40px', height: '40px', borderRadius: '8px',
            backgroundColor: '#FFFFFF', padding: '4px',
            display: 'flex', alignItems: 'center', justifyContent: 'center'
          }}>
            <img 
              src="/logo.png" 
              alt="Payroz Logo" 
              style={{ width: '100%', height: '100%', objectFit: 'contain' }} 
            />
          </div>
          <div>
            <h2 style={{ fontSize: '1.15rem', fontWeight: '800', letterSpacing: '0.05em' }}>PAYROZ</h2>
            <span style={{ fontSize: '0.75rem', color: 'var(--accent-color)', fontWeight: '600' }}>
              {staff.role} Portal
            </span>
          </div>
        </div>

        <nav style={{ flex: 1, padding: '1.5rem 1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem', overflowY: 'auto' }}>
          
          {/* Dashboard is visible to all roles */}
          <button 
            className={`btn ${currentTab === 'dashboard' ? 'btn-primary' : 'btn-outline'}`}
            style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'dashboard' ? 'white' : '#94A3B8', border: 'none' }}
            onClick={() => setCurrentTab('dashboard')}
          >
            <LayoutDashboard size={18} /> Dashboard
          </button>

          {/* Dynamic Service Builder - Admin / Marketing */}
          {['Admin', 'Marketing'].includes(staff.role) && (
            <button 
              className={`btn ${currentTab === 'services' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'services' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('services')}
            >
              <Settings size={18} /> Service Builder
            </button>
          )}

          {/* KYC Audits - Admin / KYC Officer */}
          {['Admin', 'KYC'].includes(staff.role) && (
            <button 
              className={`btn ${currentTab === 'kyc' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'kyc' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('kyc')}
            >
              <UserCheck size={18} /> KYC Approvals
            </button>
          )}

          {/* Transactions & Refunds - Admin / Refund Specialist */}
          {['Admin', 'Refund', 'Accounts'].includes(staff.role) && (
            <button 
              className={`btn ${currentTab === 'transactions' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'transactions' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('transactions')}
            >
              <CreditCard size={18} /> Transactions & Refunds
            </button>
          )}

          {/* Customer Tickets - Admin / Support Staff */}
          {['Admin', 'Support'].includes(staff.role) && (
            <button 
              className={`btn ${currentTab === 'tickets' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'tickets' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('tickets')}
            >
              <HelpCircle size={18} /> Complaint Center
            </button>
          )}

          {/* Marketing Panel - Admin / Marketing Staff */}
          {['Admin', 'Marketing'].includes(staff.role) && (
            <button 
              className={`btn ${currentTab === 'marketing' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'marketing' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('marketing')}
            >
              <Bell size={18} /> Push & Campaigns
            </button>
          )}

          {/* Coupons Management - Admin / Marketing Staff */}
          {['Admin', 'Marketing'].includes(staff.role) && (
            <button 
              className={`btn ${currentTab === 'coupons' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'coupons' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('coupons')}
            >
              <Tag size={18} /> Coupons Management
            </button>
          )}

          {/* Staff Panel - Admin Only */}
          {staff.role === 'Admin' && (
            <button 
              className={`btn ${currentTab === 'staff' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'staff' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('staff')}
            >
              <Users size={18} /> Staff Roles
            </button>
          )}

          {/* Customers - Admin / Support / KYC */}
          {['Admin', 'Support', 'KYC'].includes(staff.role) && (
            <button 
              className={`btn ${currentTab === 'customers' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'customers' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('customers')}
            >
              <User size={18} /> Customers
            </button>
          )}

          {/* Accounts & Ledger Reports - Admin / Accounts Staff */}
          {['Admin', 'Accounts'].includes(staff.role) && (
            <button 
              className={`btn ${currentTab === 'reports' ? 'btn-primary' : 'btn-outline'}`}
              style={{ width: '100%', justifyContent: 'flex-start', color: currentTab === 'reports' ? 'white' : '#94A3B8', border: 'none' }}
              onClick={() => setCurrentTab('reports')}
            >
              <FileText size={18} /> Reports Ledger
            </button>
          )}

        </nav>

        {/* User Info footer */}
        <div style={{
          padding: '1.5rem',
          borderTop: '1px solid #1E293B',
          display: 'flex',
          flexDirection: 'column',
          gap: '0.75rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div style={{
              width: '32px', height: '32px', borderRadius: '50%',
              backgroundColor: '#334155', display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <User size={14} color="#94A3B8" />
            </div>
            <div style={{ overflow: 'hidden' }}>
              <p style={{ fontSize: '0.85rem', fontWeight: '600', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>
                {staff.name}
              </p>
              <p style={{ fontSize: '0.75rem', color: '#94A3B8' }}>{staff.email}</p>
            </div>
          </div>
          <button className="btn btn-outline" style={{ width: '100%', color: '#EF4444', borderColor: '#334155' }} onClick={handleLogout}>
            <LogOut size={14} /> Log Out
          </button>
        </div>
      </aside>

      {/* MAIN PANEL CONTENT */}
      <main className="main-content">
        
        {/* HEADER SECTION */}
        <header style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '2.5rem',
          paddingBottom: '1rem',
          borderBottom: '1px solid var(--border-color)'
        }}>
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: '700', textTransform: 'capitalize' }}>
              {currentTab === 'kyc' ? 'KYC Review Center' : currentTab === 'tickets' ? 'Support & Complaints' : currentTab === 'marketing' ? 'Marketing Alerts & Banners' : currentTab === 'coupons' ? 'Promo Coupons Management' : currentTab === 'reports' ? 'Fintech Ledger Reports' : currentTab === 'customers' ? 'Customer Accounts Management' : currentTab === 'staff' ? 'Support Staff & Audit Logs' : currentTab}
            </h1>
            <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
              PAYROZ B2C Fintech Customer App Control Dashboard.
            </p>
          </div>
          
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
            <button className="btn btn-outline" onClick={() => {
              fetchDashboardStats();
              fetchCategories();
              fetchServices();
              fetchUsers();
              fetchTransactions();
              fetchTickets();
              fetchStaffLogs();
              fetchFeedbacks();
              fetchCoupons();
            }}>
              <RefreshCw size={14} /> Sync Live Data
            </button>
            <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)', fontWeight: '500' }}>
              System Time: <strong>{new Date().toLocaleDateString()}</strong>
            </div>
          </div>
        </header>

        {/* -------------------- TAB 1: DASHBOARD STATS -------------------- */}
        {currentTab === 'dashboard' && stats && (
          <div className="fade-in">
            {/* STAT CARDS ROW */}
            <div className="card-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', display: 'grid', gap: '1rem', marginBottom: '2rem' }}>
              <div className="stat-card">
                <div className="stat-icon" style={{ backgroundColor: '#EFF6FF', color: '#2563EB' }}>
                  <Users size={24} />
                </div>
                <div className="stat-info">
                  <h3>Total Customers</h3>
                  <p>{stats.totalUsers}</p>
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-icon" style={{ backgroundColor: '#ECFDF5', color: '#10B981' }}>
                  <CreditCard size={24} />
                </div>
                <div className="stat-info">
                  <h3>Gateway Volume</h3>
                  <p>₹{stats.totalRevenue.toFixed(2)}</p>
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-icon" style={{ backgroundColor: '#EEF2F6', color: '#6366F1' }}>
                  <CreditCard size={24} />
                </div>
                <div className="stat-info">
                  <h3>Operator Commission</h3>
                  <p>₹{(stats.totalCommission || 0).toFixed(2)}</p>
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-icon" style={{ backgroundColor: '#FEF3C7', color: '#D97706' }}>
                  <Tag size={24} />
                </div>
                <div className="stat-info">
                  <h3>Cashbacks Claimed</h3>
                  <p>₹{stats.totalCashback.toFixed(2)}</p>
                </div>
              </div>

              <div className="stat-card">
                <div className="stat-icon" style={{ backgroundColor: '#FDF2F8', color: '#EC4899' }}>
                  <Users size={24} />
                </div>
                <div className="stat-info">
                  <h3>Referrals Paid</h3>
                  <p>₹{(stats.totalReferrals || 0).toFixed(2)}</p>
                </div>
              </div>

              <div className="stat-card" style={{ border: '2px solid #10B981', boxShadow: '0 4px 6px -1px rgba(16, 185, 129, 0.1)' }}>
                <div className="stat-icon" style={{ backgroundColor: '#D1FAE5', color: '#059669' }}>
                  <Check size={24} />
                </div>
                <div className="stat-info">
                  <h3>Net Profit (Earnings)</h3>
                  <p style={{ color: '#059669', fontWeight: 'bold' }}>₹{(stats.netProfit || 0).toFixed(2)}</p>
                </div>
              </div>
            </div>

            {/* TRANSACTIONS BAR SUMMARY AND LOGS */}
            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '2rem' }}>
              
              {/* Transaction Metrics Card */}
              <div style={{ backgroundColor: 'white', padding: '2rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
                <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '1.5rem' }}>Transaction Completion Status</h3>
                
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', marginBottom: '0.5rem' }}>
                      <span style={{ color: 'var(--success)', fontWeight: '600' }}>Success Transactions</span>
                      <strong>{stats.successTransactions} ({stats.totalTransactions ? Math.round(stats.successTransactions / stats.totalTransactions * 100) : 0}%)</strong>
                    </div>
                    <div style={{ height: '8px', backgroundColor: '#F1F5F9', borderRadius: '9999px', overflow: 'hidden' }}>
                      <div style={{ height: '100%', backgroundColor: 'var(--success)', width: `${stats.totalTransactions ? (stats.successTransactions / stats.totalTransactions * 100) : 0}%` }}></div>
                    </div>
                  </div>

                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', marginBottom: '0.5rem' }}>
                      <span style={{ color: 'var(--error)', fontWeight: '600' }}>Failed Payments</span>
                      <strong>{stats.failedTransactions} ({stats.totalTransactions ? Math.round(stats.failedTransactions / stats.totalTransactions * 100) : 0}%)</strong>
                    </div>
                    <div style={{ height: '8px', backgroundColor: '#F1F5F9', borderRadius: '9999px', overflow: 'hidden' }}>
                      <div style={{ height: '100%', backgroundColor: 'var(--error)', width: `${stats.totalTransactions ? (stats.failedTransactions / stats.totalTransactions * 100) : 0}%` }}></div>
                    </div>
                  </div>

                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', marginBottom: '0.5rem' }}>
                      <span style={{ color: 'var(--warning)', fontWeight: '600' }}>Pending PG Verification</span>
                      <strong>{stats.pendingTransactions} ({stats.totalTransactions ? Math.round(stats.pendingTransactions / stats.totalTransactions * 100) : 0}%)</strong>
                    </div>
                    <div style={{ height: '8px', backgroundColor: '#F1F5F9', borderRadius: '9999px', overflow: 'hidden' }}>
                      <div style={{ height: '100%', backgroundColor: 'var(--warning)', width: `${stats.totalTransactions ? (stats.pendingTransactions / stats.totalTransactions * 100) : 0}%` }}></div>
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '1px solid var(--border-color)', marginTop: '2rem', paddingTop: '1.5rem', fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                  <span>Cumulative Referral Payouts: <strong>₹{stats.totalReferrals.toFixed(2)}</strong></span>
                  <span>Total Database Queries: <strong>Healthy SQLite Session</strong></span>
                </div>
              </div>

              {/* System Logs List */}
              <div style={{ backgroundColor: 'white', padding: '2rem', borderRadius: '12px', border: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column' }}>
                <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '1.5rem' }}>Activity Logs</h3>
                
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.75rem', overflowY: 'auto' }}>
                  {recentLogs.map((log) => (
                    <div key={log.id} style={{
                      padding: '0.75rem', borderRadius: '8px', borderLeft: `4px solid ${log.level === 'Error' ? 'var(--error)' : log.level === 'Warning' ? 'var(--warning)' : 'var(--info)'}`,
                      backgroundColor: '#F8FAFC', fontSize: '0.75rem'
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                        <strong>{log.level}</strong>
                        <span>{new Date(log.createdAt).toLocaleTimeString()}</span>
                      </div>
                      <p style={{ color: 'var(--text-main)', fontWeight: '500' }}>{log.message}</p>
                    </div>
                  ))}
                  {recentLogs.length === 0 && <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>No recent activity logged</div>}
                </div>
              </div>

            </div>

            {/* FEEDBACKS SECTION */}
            <div style={{ marginTop: '2rem', backgroundColor: 'white', padding: '2rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '1.5rem' }}>Recent Customer Reviews & Feedbacks</h3>
              
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.25rem' }}>
                {feedbacks.map((f) => (
                  <div key={f.id} style={{
                    padding: '1.25rem', borderRadius: '8px', border: '1px solid var(--border-color)',
                    backgroundColor: '#F8FAFC', display: 'flex', flexDirection: 'column', gap: '0.5rem'
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <strong>{f.userName || 'Anonymous'} ({f.userPhone})</strong>
                      <span style={{ color: '#FFD700', fontSize: '1rem', fontWeight: 'bold' }}>
                        {'★'.repeat(f.rating)}{'☆'.repeat(5 - f.rating)}
                      </span>
                    </div>
                    <p style={{ fontSize: '0.875rem', color: 'var(--text-main)', fontStyle: f.review ? 'normal' : 'italic' }}>
                      {f.review || '"No written review comment"'}
                    </p>
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', alignSelf: 'flex-end' }}>
                      {new Date(f.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                ))}
                {feedbacks.length === 0 && (
                  <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                    No customer feedback received yet.
                  </div>
                )}
              </div>
            </div>

          </div>
        )}

        {/* -------------------- TAB 2: SERVICE BUILDER (DYNAMIC SERVICES) -------------------- */}
        {currentTab === 'services' && (
          <div className="fade-in">
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700' }}>Dynamic Category & Services Config</h3>
              
              <div style={{ display: 'flex', gap: '0.75rem' }}>
                <button className="btn btn-secondary" onClick={() => {
                  setEditingService(null);
                  setServiceName('');
                  setServiceFields([]);
                  setCashbackVal(0);
                  setShowAddServiceModal(true);
                }}>
                  <Plus size={16} /> Add Dynamic Service
                </button>
              </div>
            </div>

            {/* List Services Grid */}
            <div className="table-container">
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Service Name</th>
                      <th>Category</th>
                      <th>API Provider</th>
                      <th>Cashback Setup</th>
                      <th>Fields Required</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {services.map((srv) => {
                      const category = categories.find(c => c.id === srv.categoryId);
                      return (
                        <tr key={srv.id}>
                          <td style={{ fontWeight: '600' }}>{srv.name}</td>
                          <td><span className="badge badge-info">{category ? category.name : 'Unknown'}</span></td>
                          <td>
                            <div style={{ fontSize: '0.8rem' }}><strong>Primary:</strong> {srv.apiProvider}</div>
                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}><strong>Backup:</strong> {srv.backupApiProvider}</div>
                          </td>
                          <td>
                            <span className="badge badge-success">
                              {srv.cashbackSetup.value > 0 
                                ? `${srv.cashbackSetup.type === 'percent' ? `${srv.cashbackSetup.value}%` : `₹${srv.cashbackSetup.value}`} (Max ₹${srv.cashbackSetup.maxAmount})`
                                : 'No Cashback'}
                            </span>
                          </td>
                          <td>
                            <span style={{ fontSize: '0.8rem' }}>
                              {srv.formFields.map(f => f.label).join(', ') || 'No inputs'}
                            </span>
                          </td>
                          <td>
                            <span className={`badge ${srv.status === 'Enabled' ? 'badge-success' : srv.status === 'Maintenance' ? 'badge-warning' : 'badge-danger'}`}>
                              {srv.status}
                            </span>
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: '0.5rem' }}>
                              <button className="btn btn-outline" style={{ padding: '0.4rem 0.6rem' }} onClick={() => handleEditServiceClick(srv)}>
                                <Edit size={14} /> Edit
                              </button>
                              {srv.status === 'Enabled' ? (
                                <button className="btn btn-outline" style={{ padding: '0.4rem 0.6rem', color: 'var(--warning)' }} onClick={() => toggleServiceStatus(srv, 'Maintenance')}>
                                  Maintenance
                                </button>
                              ) : (
                                <button className="btn btn-outline" style={{ padding: '0.4rem 0.6rem', color: 'var(--success)' }} onClick={() => toggleServiceStatus(srv, 'Enabled')}>
                                  Enable
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* -------------------- TAB 3: KYC APPROVALS -------------------- */}
        {currentTab === 'kyc' && (
          <div className="fade-in">
            <h3 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '1.5rem' }}>B2C Customers KYC Review Panel</h3>
            
            <div className="table-container">
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Customer Phone</th>
                      <th>Display Name</th>
                      <th>Registered On</th>
                      <th>KYC Status</th>
                      <th>Document details</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map((usr) => {
                      const kycDetailsObj = usr.kycDetails ? JSON.parse(usr.kycDetails) : null;
                      return (
                        <tr key={usr.id}>
                          <td style={{ fontWeight: '700' }}>{usr.phone}</td>
                          <td>{usr.name}</td>
                          <td>{new Date(usr.createdAt).toLocaleDateString()}</td>
                          <td>
                            <span className={`badge ${
                              usr.kycStatus === 'Approved' ? 'badge-success' : usr.kycStatus === 'Pending' ? 'badge-warning' : 'badge-danger'
                            }`}>
                              {usr.kycStatus}
                            </span>
                          </td>
                          <td>
                            {kycDetailsObj ? (
                              <div style={{ fontSize: '0.8rem' }}>
                                <strong>Type:</strong> {kycDetailsObj.docType} <br/>
                                <strong>No:</strong> {kycDetailsObj.docNumber}
                              </div>
                            ) : (
                              <span style={{ color: 'var(--text-muted)', fontSize: '0.8rem' }}>No documents uploaded</span>
                            )}
                          </td>
                          <td>
                            {usr.kycStatus === 'Pending' && (
                              <div style={{ display: 'flex', gap: '0.5rem' }}>
                                <button className="btn btn-secondary" style={{ padding: '0.4rem 0.8rem', backgroundColor: 'var(--success)' }} onClick={() => handleKycStatusUpdate(usr.id, 'Approved')}>
                                  <Check size={14} /> Approve
                                </button>
                                <button className="btn btn-danger" style={{ padding: '0.4rem 0.8rem' }} onClick={() => handleKycStatusUpdate(usr.id, 'Rejected')}>
                                  <X size={14} /> Reject
                                </button>
                              </div>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* -------------------- TAB 4: TRANSACTIONS & REFUNDS -------------------- */}
        {currentTab === 'transactions' && (
          <div className="fade-in">
            <h3 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '1.5rem' }}>Live B2C Transaction Ledger</h3>
            
            <div className="table-container">
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Ref ID</th>
                      <th>Customer Phone</th>
                      <th>Service Name</th>
                      <th>Amount</th>
                      <th>Payment Mode</th>
                      <th>Date</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {transactions.map((tx) => (
                      <tr key={tx.id}>
                        <td style={{ fontSize: '0.8rem', fontWeight: '600' }}>{tx.operatorRefId || 'WAITING-PG'}</td>
                        <td style={{ fontWeight: '700' }}>{tx.user?.phone || '9876543210'}</td>
                        <td>{tx.serviceName}</td>
                        <td style={{ fontWeight: '700' }}>₹{tx.amount.toFixed(2)}</td>
                        <td>
                          <span className="badge badge-info">{tx.paymentMode}</span>
                          {tx.rewardsAmountUsed > 0 && <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Wallet applied: ₹{tx.rewardsAmountUsed}</div>}
                        </td>
                        <td>{new Date(tx.createdAt).toLocaleString()}</td>
                        <td>
                          <span className={`badge ${
                            tx.status === 'Success' ? 'badge-success' : tx.status === 'Failed' ? 'badge-danger' : 'badge-warning'
                          }`}>
                            {tx.status}
                          </span>
                        </td>
                        <td>
                          {['Failed', 'Pending'].includes(tx.status) && (
                            <button className="btn btn-primary" style={{ padding: '0.4rem 0.8rem', fontSize: '0.75rem' }} onClick={() => handleManualRefund(tx.id)}>
                              Refund to Wallet
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* -------------------- TAB 5: COMPLAINT CENTER -------------------- */}
        {currentTab === 'tickets' && (
          <div className="fade-in" style={{ display: 'grid', gridTemplateColumns: '1fr 1.5fr', gap: '2rem', height: 'calc(100vh - 200px)' }}>
            
            {/* Tickets Inbox list */}
            <div style={{ backgroundColor: 'white', border: '1px solid var(--border-color)', borderRadius: '12px', overflowY: 'auto', display: 'flex', flexDirection: 'column' }}>
              <div style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-color)', backgroundColor: '#F8FAFC' }}>
                <h4 style={{ fontWeight: '700' }}>Complaints Inbox ({tickets.length})</h4>
              </div>
              
              <div style={{ flex: 1, overflowY: 'auto' }}>
                {tickets.map((tkt) => (
                  <div 
                    key={tkt.id} 
                    onClick={() => selectTicket(tkt)}
                    style={{
                      padding: '1.25rem', borderBottom: '1px solid var(--border-color)', cursor: 'pointer',
                      backgroundColor: activeTicket?.id === tkt.id ? '#EFF6FF' : 'transparent',
                      transition: 'background 0.2s'
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                      <strong style={{ fontSize: '0.85rem' }}>{tkt.ticketNumber}</strong>
                      <span className={`badge ${
                        tkt.status === 'Open' ? 'badge-danger' : tkt.status === 'Processing' ? 'badge-warning' : 'badge-success'
                      }`}>{tkt.status}</span>
                    </div>
                    <p style={{ fontWeight: '600', fontSize: '0.875rem', marginBottom: '0.25rem' }}>{tkt.subject}</p>
                    <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {tkt.description}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            {/* Ticket Chat Window */}
            {activeTicket ? (
              <div style={{ backgroundColor: 'white', border: '1px solid var(--border-color)', borderRadius: '12px', display: 'flex', flexDirection: 'column' }}>
                
                {/* Chat Header */}
                <div style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#F8FAFC' }}>
                  <div>
                    <h4 style={{ fontWeight: '700' }}>{activeTicket.ticketNumber}</h4>
                    <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{activeTicket.subject}</p>
                  </div>
                  
                  {/* Status Dropdown */}
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                    <span style={{ fontSize: '0.8rem', fontWeight: '600' }}>Status:</span>
                    <select 
                      value={activeTicket.status} 
                      onChange={async (e) => {
                        const newStatus = e.target.value;
                        try {
                          const res = await fetch(`${API_BASE}/admin/tickets/${activeTicket.id}/status`, {
                            method: 'PUT',
                            headers: { 
                              'Content-Type': 'application/json',
                              'Authorization': `Bearer ${token}` 
                            },
                            body: JSON.stringify({ status: newStatus }),
                          });
                          if (res.ok) {
                            alert(`Status updated to ${newStatus}`);
                            setActiveTicket({ ...activeTicket, status: newStatus });
                            fetchTickets();
                          }
                        } catch(err) { console.error(err); }
                      }}
                      className="form-input"
                      style={{ width: '130px', padding: '0.25rem 0.5rem', height: '35px' }}
                    >
                      <option value="Open">Open</option>
                      <option value="Processing">Processing</option>
                      <option value="Resolved">Resolved</option>
                      <option value="Closed">Closed</option>
                    </select>
                  </div>
                </div>

                {/* Messages Body */}
                <div style={{ flex: 1, padding: '1.5rem', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '1rem', backgroundColor: '#F1F5F9' }}>
                  {ticketMessages.map((msg) => {
                    const isStaff = msg.senderType === 'Staff';
                    return (
                      <div key={msg.id} style={{
                        alignSelf: isStaff ? 'flex-end' : 'flex-start',
                        maxWidth: '75%', display: 'flex', flexDirection: 'column'
                      }}>
                        <div style={{
                          backgroundColor: isStaff ? 'var(--primary-color)' : '#FFFFFF',
                          color: isStaff ? '#FFFFFF' : 'var(--text-main)',
                          padding: '0.85rem 1.15rem', borderRadius: '12px',
                          borderTopRightRadius: isStaff ? '0' : '12px',
                          borderTopLeftRadius: isStaff ? '12px' : '0',
                          boxShadow: '0 1px 2px rgba(0,0,0,0.05)'
                        }}>
                          <p style={{ fontSize: '0.875rem' }}>{msg.message}</p>
                        </div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: '0.25rem', alignSelf: isStaff ? 'flex-end' : 'flex-start' }}>
                          {new Date(msg.createdAt).toLocaleTimeString()}
                        </span>
                      </div>
                    );
                  })}
                </div>

                {/* Chat Reply Form */}
                <form onSubmit={handleTicketReply} style={{ padding: '1.25rem', borderTop: '1px solid var(--border-color)', display: 'flex', gap: '0.75rem' }}>
                  <input 
                    type="text" 
                    className="form-input" 
                    placeholder="Type response to customer..."
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    required
                  />
                  <button type="submit" className="btn btn-secondary" style={{ padding: '0.75rem' }}>
                    <Send size={18} />
                  </button>
                </form>

              </div>
            ) : (
              <div style={{ backgroundColor: 'white', border: '1px solid var(--border-color)', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)' }}>
                Select a ticket from the inbox to open chat support
              </div>
            )}

          </div>
        )}

        {/* -------------------- TAB 6: PUSH & CAMPAIGNS -------------------- */}
        {currentTab === 'marketing' && (
          <div className="fade-in" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
            
            {/* Push Notification Broadcast Card */}
            <div style={{ backgroundColor: 'white', padding: '2rem', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '1.5rem' }}>Broadcast Push Notification</h3>
              
              <form onSubmit={handleBroadcastAlert}>
                <div className="form-group">
                  <label className="form-label">Alert Header / Title</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    placeholder="e.g. System Maintenance / Flat 50% Cashback Alert"
                    value={notifyTitle}
                    onChange={(e) => setNotifyTitle(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Notification Body Content</label>
                  <textarea 
                    className="form-input" 
                    style={{ minHeight: '120px', resize: 'vertical' }}
                    placeholder="Write detailed notification body description..."
                    value={notifyMessage}
                    onChange={(e) => setNotifyMessage(e.target.value)}
                    required
                  ></textarea>
                </div>

                <div className="form-group" style={{ marginBottom: '2rem' }}>
                  <label className="form-label">Notification Tag Category</label>
                  <select className="form-input" value={notifyType} onChange={(e) => setNotifyType(e.target.value)}>
                    <option value="System">System Alert</option>
                    <option value="Cashback">Cashback Promo</option>
                    <option value="Offer">Exclusive Offer</option>
                    <option value="Reminder">Utility Bill Reminder</option>
                  </select>
                </div>

                <button type="submit" className="btn btn-primary" style={{ width: '100%' }}>
                  <Bell size={16} /> Broadcast Push Notification to All Users
                </button>
              </form>
            </div>

            {/* App Banners Display list */}
            <div style={{ backgroundColor: 'white', padding: '2rem', borderRadius: '12px', border: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column' }}>
              <h3 style={{ fontSize: '1.15rem', fontWeight: '700', marginBottom: '1.5rem' }}>Active Promo Banners</h3>
              
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '1rem', overflowY: 'auto' }}>
                <div style={{ padding: '1rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                  <img src="https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&q=80&w=800" style={{ width: '100%', height: '100px', objectFit: 'cover', borderRadius: '6px', marginBottom: '0.5rem' }} alt="" />
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem' }}>
                    <strong>Refer & Earn Unlimited Banner</strong>
                    <span className="badge badge-success">Active</span>
                  </div>
                </div>

                <div style={{ padding: '1rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                  <img src="https://images.unsplash.com/photo-1621416894569-0f39ed31d247?auto=format&fit=crop&q=80&w=800" style={{ width: '100%', height: '100px', objectFit: 'cover', borderRadius: '6px', marginBottom: '0.5rem' }} alt="" />
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem' }}>
                    <strong>Flat ₹25 Recharge Cashback Promo</strong>
                    <span className="badge badge-success">Active</span>
                  </div>
                </div>
              </div>
            </div>

          </div>
        )}

        {/* -------------------- TAB 7: STAFF ROLES -------------------- */}
        {currentTab === 'staff' && (
          <div className="fade-in">
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700' }}>Support Staff Credentials & Permissions</h3>
              
              <button className="btn btn-secondary" onClick={() => setShowAddStaffModal(true)}>
                <Plus size={16} /> Add Staff Account
              </button>
            </div>

            <div className="table-container">
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Staff Name</th>
                      <th>Email ID</th>
                      <th>Security Role</th>
                      <th>Account Status</th>
                      <th>Created On</th>
                    </tr>
                  </thead>
                  <tbody>
                    {staffList.map((st) => (
                      <tr key={st.id}>
                        <td style={{ fontWeight: '600' }}>{st.name}</td>
                        <td>{st.email}</td>
                        <td>
                          <span className={`badge ${st.role === 'Admin' ? 'badge-danger' : 'badge-info'}`}>
                            {st.role} Role
                          </span>
                        </td>
                        <td>
                          <span className={`badge ${st.status === 'Active' ? 'badge-success' : 'badge-warning'}`}>
                            {st.status}
                          </span>
                        </td>
                        <td>{new Date(st.createdAt).toLocaleDateString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Staff Activity Logs */}
            <div style={{ marginTop: '3rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '1.5rem' }}>Staff Activity & Security Audits</h3>
              
              <div className="table-container">
                <div className="table-wrapper">
                  <table>
                    <thead>
                      <tr>
                        <th>Timestamp</th>
                        <th>Staff Name</th>
                        <th>Action Performed</th>
                        <th>Log Details</th>
                      </tr>
                    </thead>
                    <tbody>
                      {staffLogs.map((log) => (
                        <tr key={log.id}>
                          <td style={{ fontSize: '0.8rem' }}>{new Date(log.createdAt).toLocaleString()}</td>
                          <td style={{ fontWeight: '600' }}>{log.staffName}</td>
                          <td>
                            <span className="badge badge-info">{log.action}</span>
                          </td>
                          <td style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontFamily: 'monospace' }}>
                            {log.details}
                          </td>
                        </tr>
                      ))}
                      {staffLogs.length === 0 && (
                        <tr>
                          <td colSpan="4" style={{ textAlign: 'center', padding: '2rem' }}>No staff activity logged yet</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

          </div>
        )}

        {/* -------------------- TAB 8: REPORTS LEDGER -------------------- */}
        {currentTab === 'reports' && (
          <div className="fade-in">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              
              {/* Filters Panel */}
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem', alignItems: 'center' }}>
                <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                  <span style={{ fontWeight: '600', fontSize: '0.875rem' }}>Report Type:</span>
                  <select className="form-input" style={{ width: '220px' }} value={reportType} onChange={(e) => setReportType(e.target.value)}>
                    <option value="revenue">Direct PG Successful Payments</option>
                    <option value="cashback">Cashback Distributions</option>
                    <option value="referral">Referral Level 1 Rewards</option>
                    <option value="refund">Failed Transaction Refunds</option>
                    <option value="service">Service-wise Volume & Commission</option>
                    <option value="complaint">Support Tickets & Complaints</option>
                    <option value="user">User-wise Transaction Ledger</option>
                    <option value="date">Date-wise Transaction Volume</option>
                  </select>
                </div>

                <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                  <span style={{ fontWeight: '600', fontSize: '0.875rem' }}>From:</span>
                  <input type="date" className="form-input" style={{ width: '135px', padding: '0.25rem' }} value={startDate} onChange={(e) => setStartDate(e.target.value)} />
                </div>

                <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                  <span style={{ fontWeight: '600', fontSize: '0.875rem' }}>To:</span>
                  <input type="date" className="form-input" style={{ width: '135px', padding: '0.25rem' }} value={endDate} onChange={(e) => setEndDate(e.target.value)} />
                </div>

                {reportType === 'user' && (
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                    <span style={{ fontWeight: '600', fontSize: '0.875rem' }}>User ID:</span>
                    <input type="text" className="form-input" style={{ width: '200px' }} placeholder="Customer User UUID" value={userFilterId} onChange={(e) => setUserFilterId(e.target.value)} />
                  </div>
                )}

                <button className="btn btn-secondary" onClick={fetchReports}>
                  Apply Filters
                </button>
              </div>

              <button className="btn btn-outline" onClick={() => {
                alert('Downloading raw data file in CSV format...');
              }}>
                Export CSV Audit File
              </button>
            </div>

            {reportType === 'complaint' && reports.counts && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
                <div style={{ padding: '1rem', borderRadius: '12px', backgroundColor: '#EFF6FF', color: '#1E40AF', textAlign: 'center' }}>
                  <div style={{ fontSize: '1.5rem', fontWeight: '800' }}>{reports.counts.Open}</div>
                  <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', fontWeight: '600', opacity: 0.8 }}>Open</div>
                </div>
                <div style={{ padding: '1rem', borderRadius: '12px', backgroundColor: '#FEF3C7', color: '#92400E', textAlign: 'center' }}>
                  <div style={{ fontSize: '1.5rem', fontWeight: '800' }}>{reports.counts.Processing}</div>
                  <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', fontWeight: '600', opacity: 0.8 }}>Processing</div>
                </div>
                <div style={{ padding: '1rem', borderRadius: '12px', backgroundColor: '#ECFDF5', color: '#065F46', textAlign: 'center' }}>
                  <div style={{ fontSize: '1.5rem', fontWeight: '800' }}>{reports.counts.Resolved}</div>
                  <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', fontWeight: '600', opacity: 0.8 }}>Resolved</div>
                </div>
                <div style={{ padding: '1rem', borderRadius: '12px', backgroundColor: '#F3F4F6', color: '#374151', textAlign: 'center' }}>
                  <div style={{ fontSize: '1.5rem', fontWeight: '800' }}>{reports.counts.Closed}</div>
                  <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', fontWeight: '600', opacity: 0.8 }}>Closed</div>
                </div>
              </div>
            )}

            <div className="table-container">
              <div className="table-wrapper">
                <table>
                  {reportType === 'service' ? (
                    <>
                      <thead>
                        <tr>
                          <th>Service Name</th>
                          <th>Transaction Count</th>
                          <th>Total Volume</th>
                          <th>Total Commission</th>
                        </tr>
                      </thead>
                      <tbody>
                        {Array.isArray(reports) && reports.map((rep, idx) => (
                          <tr key={idx}>
                            <td style={{ fontWeight: '600' }}>{rep.serviceName}</td>
                            <td>{rep.count}</td>
                            <td style={{ fontWeight: '700' }}>₹{parseFloat(rep.totalAmount || 0).toFixed(2)}</td>
                            <td style={{ color: '#10B981', fontWeight: '700' }}>₹{parseFloat(rep.totalCommission || 0).toFixed(2)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </>
                  ) : reportType === 'complaint' ? (
                    <>
                      <thead>
                        <tr>
                          <th>Ticket ID</th>
                          <th>User ID</th>
                          <th>Subject</th>
                          <th>Status</th>
                          <th>Last Updated</th>
                        </tr>
                      </thead>
                      <tbody>
                        {reports.tickets && reports.tickets.map((t) => (
                          <tr key={t.id}>
                            <td style={{ fontSize: '0.8rem' }}>{t.ticketNumber}</td>
                            <td style={{ fontSize: '0.8rem' }}>{t.userId}</td>
                            <td>{t.subject}</td>
                            <td>
                              <span style={{
                                padding: '0.25rem 0.5rem', borderRadius: '6px', fontSize: '0.75rem', fontWeight: '600',
                                backgroundColor: t.status === 'Open' ? '#EFF6FF' : t.status === 'Processing' ? '#FEF3C7' : t.status === 'Resolved' ? '#ECFDF5' : '#F3F4F6',
                                color: t.status === 'Open' ? '#1E40AF' : t.status === 'Processing' ? '#92400E' : t.status === 'Resolved' ? '#065F46' : '#374151'
                              }}>{t.status}</span>
                            </td>
                            <td>{new Date(t.updatedAt).toLocaleString()}</td>
                          </tr>
                        ))}
                      </tbody>
                    </>
                  ) : ['revenue', 'user', 'date'].includes(reportType) ? (
                    <>
                      <thead>
                        <tr>
                          <th>Transaction ID</th>
                          <th>User ID</th>
                          <th>Service Name</th>
                          <th>Amount Paid</th>
                          <th>Gateway Paid</th>
                          <th>Wallet Used</th>
                          <th>Status</th>
                          <th>Timestamp</th>
                        </tr>
                      </thead>
                      <tbody>
                        {Array.isArray(reports) && reports.map((rep) => (
                          <tr key={rep.id}>
                            <td style={{ fontSize: '0.8rem' }}>{rep.id}</td>
                            <td style={{ fontSize: '0.8rem' }}>{rep.userId}</td>
                            <td>{rep.serviceName || 'Promo / Manual'}</td>
                            <td style={{ fontWeight: '700' }}>₹{parseFloat(rep.amount || 0).toFixed(2)}</td>
                            <td style={{ fontWeight: '500' }}>₹{parseFloat(rep.gatewayAmountPaid || 0).toFixed(2)}</td>
                            <td style={{ fontWeight: '500', color: '#6B7280' }}>₹{parseFloat(rep.rewardsAmountUsed || 0).toFixed(2)}</td>
                            <td>
                              <span style={{
                                padding: '0.25rem 0.5rem', borderRadius: '6px', fontSize: '0.75rem', fontWeight: '600',
                                backgroundColor: rep.status === 'Success' ? '#ECFDF5' : rep.status === 'Pending' ? '#FEF3C7' : '#FCE8E6',
                                color: rep.status === 'Success' ? '#065F46' : rep.status === 'Pending' ? '#92400E' : '#EF4444'
                              }}>{rep.status}</span>
                            </td>
                            <td>{new Date(rep.createdAt).toLocaleString()}</td>
                          </tr>
                        ))}
                      </tbody>
                    </>
                  ) : (
                    <>
                      <thead>
                        <tr>
                          <th>Record ID</th>
                          <th>Ref/Trans ID</th>
                          <th>User/Referrer ID</th>
                          <th>Amount</th>
                          <th>Status</th>
                          <th>Timestamp</th>
                        </tr>
                      </thead>
                      <tbody>
                        {Array.isArray(reports) && reports.map((rep) => (
                          <tr key={rep.id}>
                            <td style={{ fontSize: '0.8rem' }}>{rep.id}</td>
                            <td style={{ fontSize: '0.8rem' }}>{rep.transactionId || rep.refereeId || 'System'}</td>
                            <td style={{ fontSize: '0.8rem' }}>{rep.userId || rep.referrerId}</td>
                            <td style={{ fontWeight: '700' }}>₹{parseFloat(rep.amount || 0).toFixed(2)}</td>
                            <td>
                              <span style={{
                                padding: '0.25rem 0.5rem', borderRadius: '6px', fontSize: '0.75rem', fontWeight: '600',
                                backgroundColor: '#ECFDF5', color: '#065F46'
                              }}>{rep.status}</span>
                            </td>
                            <td>{new Date(rep.createdAt).toLocaleString()}</td>
                          </tr>
                        ))}
                      </tbody>
                    </>
                  )}
                </table>
              </div>
            </div>
          </div>
        )}

        {/* -------------------- TAB: COUPONS MANAGEMENT -------------------- */}
        {currentTab === 'coupons' && (
          <div className="fade-in">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700' }}>Promo Coupons Management</h3>
              <button className="btn btn-primary" onClick={() => {
                setEditingCoupon(null);
                setCouponCode('');
                setCouponDiscountType('flat');
                setCouponValue(0);
                setCouponMinAmount(0);
                setCouponMaxUses('');
                setCouponExpiresAt('');
                setCouponServiceFilter('');
                setCouponStatus('Enabled');
                setShowAddCouponModal(true);
              }}>
                <Plus size={16} style={{ marginRight: '0.5rem' }} /> Add Promo Coupon
              </button>
            </div>

            <div className="table-container">
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Coupon Code</th>
                      <th>Discount Type</th>
                      <th>Value</th>
                      <th>Min Order Amount</th>
                      <th>Service Filter</th>
                      <th>Usage Limit</th>
                      <th>Used Count</th>
                      <th>Expiry Date</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {coupons.map((cpn) => (
                      <tr key={cpn.id}>
                        <td style={{ fontWeight: '700', color: 'var(--primary-color)' }}>{cpn.code}</td>
                        <td>{cpn.discountType === 'percent' ? 'Percentage (%)' : 'Flat (₹)'}</td>
                        <td>{cpn.discountType === 'percent' ? `${cpn.value}%` : `₹${cpn.value}`}</td>
                        <td>₹{cpn.minAmount || 0}</td>
                        <td>{cpn.serviceFilter || 'All Services'}</td>
                        <td>{cpn.maxUses !== null ? cpn.maxUses : 'Unlimited'}</td>
                        <td>{cpn.usedCount || 0}</td>
                        <td>{cpn.expiresAt ? new Date(cpn.expiresAt).toLocaleDateString() : 'No Expiry'}</td>
                        <td>
                          <span style={{
                            padding: '0.25rem 0.5rem', borderRadius: '6px', fontSize: '0.75rem', fontWeight: '600',
                            backgroundColor: cpn.status === 'Enabled' ? '#ECFDF5' : '#FCE8E6',
                            color: cpn.status === 'Enabled' ? '#065F46' : '#EF4444'
                          }}>
                            {cpn.status}
                          </span>
                        </td>
                        <td>
                          <div style={{ display: 'flex', gap: '0.5rem' }}>
                            <button className="btn btn-outline" style={{ padding: '0.25rem 0.5rem', fontSize: '0.75rem' }} onClick={() => handleEditCouponClick(cpn)}>
                              Edit
                            </button>
                            <button 
                              className="btn" 
                              style={{ 
                                padding: '0.25rem 0.5rem', fontSize: '0.75rem',
                                backgroundColor: cpn.status === 'Enabled' ? '#F3F4F6' : '#ECFDF5',
                                color: cpn.status === 'Enabled' ? '#EF4444' : '#065F46',
                                border: '1px solid currentColor'
                              }} 
                              onClick={() => toggleCouponStatus(cpn)}
                            >
                              {cpn.status === 'Enabled' ? 'Disable' : 'Enable'}
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* -------------------- TAB: CUSTOMERS -------------------- */}
        {currentTab === 'customers' && (
          <div className="fade-in">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700' }}>Customer Accounts Management</h3>
              <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                <div style={{ position: 'relative' }}>
                  <input
                    type="text"
                    className="form-input"
                    style={{ paddingLeft: '2.5rem', width: '300px' }}
                    placeholder="Search by phone or name..."
                    value={customerSearchQuery}
                    onChange={(e) => setCustomerSearchQuery(e.target.value)}
                  />
                  <Search size={16} style={{ position: 'absolute', left: '10px', top: '14px', color: '#94A3B8' }} />
                </div>
              </div>
            </div>

            <div className="table-container">
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Customer Phone</th>
                      <th>Name / Email</th>
                      <th>Rewards Wallet Balance</th>
                      <th>KYC Status</th>
                      <th>Account Status</th>
                      <th>Registered On</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users
                      .filter(u => 
                        u.phone.toLowerCase().includes(customerSearchQuery.toLowerCase()) || 
                        (u.name && u.name.toLowerCase().includes(customerSearchQuery.toLowerCase()))
                      )
                      .map((usr) => (
                        <tr key={usr.id}>
                          <td style={{ fontWeight: '700' }}>{usr.phone}</td>
                          <td>
                            <div style={{ fontWeight: '600' }}>{usr.name || 'Anonymous'}</div>
                            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{usr.email || 'No email'}</div>
                          </td>
                          <td style={{ fontWeight: '700', color: 'var(--accent-color)' }}>
                            ₹{(parseFloat(usr.rewardsBalance) || 0).toFixed(2)}
                          </td>
                          <td>
                            <span className={`badge ${
                              usr.kycStatus === 'Approved' ? 'badge-success' : usr.kycStatus === 'Pending' ? 'badge-warning' : 'badge-danger'
                            }`}>
                              {usr.kycStatus || 'Not Started'}
                            </span>
                          </td>
                          <td>
                            <span className={`badge ${usr.status === 'Blocked' ? 'badge-danger' : 'badge-success'}`}>
                              {usr.status || 'Active'}
                            </span>
                          </td>
                          <td>{new Date(usr.createdAt).toLocaleDateString()}</td>
                          <td>
                            <div style={{ display: 'flex', gap: '0.5rem' }}>
                              <button 
                                className="btn btn-outline" 
                                style={{ padding: '0.4rem 0.6rem', color: usr.status === 'Blocked' ? 'var(--success)' : 'var(--error)' }}
                                onClick={() => handleToggleBlockUser(usr.id)}
                              >
                                {usr.status === 'Blocked' ? 'Unblock' : 'Block'}
                              </button>
                              {['Admin', 'Marketing'].includes(staff.role) && (
                                <button 
                                  className="btn btn-secondary" 
                                  style={{ padding: '0.4rem 0.6rem' }}
                                  onClick={() => {
                                    setSelectedUserForBonus(usr);
                                    setShowBonusModal(true);
                                  }}
                                >
                                  Credit Bonus
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))}
                    {users.length === 0 && (
                      <tr>
                        <td colSpan="7" style={{ textAlign: 'center', padding: '2rem' }}>No customers found</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

      </main>

      {/* -------------------- MODAL: ADD/EDIT SERVICE -------------------- */}
      {showAddServiceModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '650px' }}>
            <div className="modal-header">
              <h2>{editingService ? 'Edit B2C Service Config' : 'Add New Dynamic B2C Service'}</h2>
              <button style={{ background: 'none', border: 'none', cursor: 'pointer' }} onClick={() => setShowAddServiceModal(false)}>
                <X size={20} />
              </button>
            </div>
            
            <form onSubmit={handleCreateService}>
              <div className="modal-body">
                
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label">Service Title Name</label>
                    <input type="text" className="form-input" value={serviceName} onChange={(e) => setServiceName(e.target.value)} placeholder="e.g. Water Bill, Mobile Recharge" required />
                  </div>
                  
                  <div className="form-group">
                    <label className="form-label">Category Group</label>
                    <select className="form-input" value={serviceCategoryId} onChange={(e) => setServiceCategoryId(e.target.value)} required>
                      <option value="">-- Choose Category --</option>
                      {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                    </select>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label">Primary API Provider</label>
                    <input type="text" className="form-input" value={serviceProvider} onChange={(e) => setServiceProvider(e.target.value)} />
                  </div>
                  
                  <div className="form-group">
                    <label className="form-label">Backup Provider</label>
                    <input type="text" className="form-input" value={serviceBackupProvider} onChange={(e) => setServiceBackupProvider(e.target.value)} />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Sort Order Index</label>
                    <input type="number" className="form-input" value={serviceSortOrder} onChange={(e) => setServiceSortOrder(e.target.value)} />
                  </div>
                </div>

                {/* Cashback Setup */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem', backgroundColor: '#F8FAFC', padding: '1rem', borderRadius: '8px', marginBottom: '1.25rem' }}>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Cashback Calculation</label>
                    <select className="form-input" value={cashbackType} onChange={(e) => setCashbackType(e.target.value)}>
                      <option value="flat">Flat Amount (₹)</option>
                      <option value="percent">Percentage (%)</option>
                    </select>
                  </div>

                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Value</label>
                    <input type="number" step="0.01" className="form-input" value={cashbackVal} onChange={(e) => setCashbackVal(e.target.value)} />
                  </div>

                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Max Limit (₹)</label>
                    <input type="number" className="form-input" value={cashbackMax} onChange={(e) => setCashbackMax(e.target.value)} />
                  </div>
                </div>

                {/* Form Inputs specifications (Builder) */}
                <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '1.25rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                    <h4 style={{ fontWeight: '700', fontSize: '0.9rem' }}>Inputs Schema Required from User (App Form Builder)</h4>
                    <button type="button" className="btn btn-outline" style={{ padding: '0.4rem 0.8rem', fontSize: '0.75rem' }} onClick={addInputField}>
                      <Plus size={12} /> Add Input Variable
                    </button>
                  </div>

                  {serviceFields.map((field, idx) => (
                    <div key={idx} style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr 1.5fr 0.5fr', gap: '0.5rem', marginBottom: '0.5rem', alignItems: 'center' }}>
                      <input 
                        type="text" className="form-input" style={{ padding: '0.4rem' }} placeholder="Field Name (key)" 
                        value={field.name} onChange={(e) => updateInputField(idx, 'name', e.target.value)} required 
                      />
                      <select 
                        className="form-input" style={{ padding: '0.4rem' }} 
                        value={field.type} onChange={(e) => updateInputField(idx, 'type', e.target.value)}
                      >
                        <option value="text">Text box</option>
                        <option value="number">Number</option>
                        <option value="tel">Telephone / Mobile</option>
                        <option value="select">Dropdown Options</option>
                      </select>
                      <input 
                        type="text" className="form-input" style={{ padding: '0.4rem' }} placeholder="Dropdown Options (csv) / Input Label" 
                        value={field.type === 'select' ? field.options : field.label} 
                        onChange={(e) => updateInputField(idx, field.type === 'select' ? 'options' : 'label', e.target.value)} required 
                      />
                      <button type="button" className="btn btn-danger" style={{ padding: '0.4rem' }} onClick={() => removeInputField(idx)}>
                        <X size={14} />
                      </button>
                    </div>
                  ))}
                  {serviceFields.length === 0 && <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', textAlign: 'center', padding: '1rem', border: '1px dashed var(--border-color)', borderRadius: '6px' }}>No input fields configured. (Free payment form)</div>}
                </div>

              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-outline" onClick={() => setShowAddServiceModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  {editingService ? 'Save Service Updates' : 'Publish New B2C Service'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* -------------------- MODAL: ADD/EDIT COUPON -------------------- */}
      {showAddCouponModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '500px' }}>
            <div className="modal-header">
              <h2>{editingCoupon ? 'Edit Coupon Code' : 'Add New Promo Coupon'}</h2>
              <button style={{ background: 'none', border: 'none', cursor: 'pointer' }} onClick={() => setShowAddCouponModal(false)}>
                <X size={20} />
              </button>
            </div>
            
            <form onSubmit={handleCreateCoupon}>
              <div className="modal-body">
                
                <div className="form-group">
                  <label className="form-label">Coupon Code</label>
                  <input type="text" className="form-input" value={couponCode} onChange={(e) => setCouponCode(e.target.value)} placeholder="e.g. PAYROZ50" required />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label">Discount Type</label>
                    <select className="form-input" value={couponDiscountType} onChange={(e) => setCouponDiscountType(e.target.value)}>
                      <option value="flat">Flat Amount (₹)</option>
                      <option value="percent">Percentage (%)</option>
                    </select>
                  </div>
                  
                  <div className="form-group">
                    <label className="form-label">Discount Value</label>
                    <input type="number" step="0.01" className="form-input" value={couponValue} onChange={(e) => setCouponValue(e.target.value)} required />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label">Min Transaction Amount (₹)</label>
                    <input type="number" className="form-input" value={couponMinAmount} onChange={(e) => setCouponMinAmount(e.target.value)} />
                  </div>
                  
                  <div className="form-group">
                    <label className="form-label">Max Uses Limit (Total)</label>
                    <input type="number" className="form-input" value={couponMaxUses} onChange={(e) => setCouponMaxUses(e.target.value)} placeholder="Unlimited if empty" />
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Expiry Date</label>
                  <input type="date" className="form-input" value={couponExpiresAt} onChange={(e) => setCouponExpiresAt(e.target.value)} />
                </div>

                <div className="form-group">
                  <label className="form-label">Service Applicability Filter</label>
                  <select className="form-input" value={couponServiceFilter} onChange={(e) => setCouponServiceFilter(e.target.value)}>
                    <option value="">Apply to All Services</option>
                    {services.map(s => <option key={s.id} value={s.name}>{s.name}</option>)}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Coupon Status</label>
                  <select className="form-input" value={couponStatus} onChange={(e) => setCouponStatus(e.target.value)}>
                    <option value="Enabled">Enabled (Active)</option>
                    <option value="Disabled">Disabled</option>
                  </select>
                </div>

              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-outline" onClick={() => setShowAddCouponModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  {editingCoupon ? 'Save Coupon' : 'Create Coupon'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* -------------------- MODAL: ADD STAFF -------------------- */}
      {showAddStaffModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '450px' }}>
            <div className="modal-header">
              <h2>Add Staff Account</h2>
              <button style={{ background: 'none', border: 'none', cursor: 'pointer' }} onClick={() => setShowAddStaffModal(false)}>
                <X size={20} />
              </button>
            </div>
            
            <form onSubmit={handleCreateStaff}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Full Name</label>
                  <input type="text" className="form-input" value={newStaffName} onChange={(e) => setNewStaffName(e.target.value)} placeholder="Amit Roy" required />
                </div>

                <div className="form-group">
                  <label className="form-label">Email ID</label>
                  <input type="email" className="form-input" value={newStaffEmail} onChange={(e) => setNewStaffEmail(e.target.value)} placeholder="email@payroz.com" required />
                </div>

                <div className="form-group">
                  <label className="form-label">Password</label>
                  <input type="password" className="form-input" value={newStaffPass} onChange={(e) => setNewStaffPass(e.target.value)} placeholder="••••••••" required />
                </div>

                <div className="form-group">
                  <label className="form-label">Designated Role Permission</label>
                  <select className="form-input" value={newStaffRole} onChange={(e) => setNewStaffRole(e.target.value)}>
                    <option value="Support">Support Desk Executive</option>
                    <option value="KYC">KYC Audits Special</option>
                    <option value="Refund">Refunds Manager</option>
                    <option value="Marketing">Marketing Specialist</option>
                    <option value="Accounts">Accounts Auditor</option>
                    <option value="Admin">Administrator</option>
                  </select>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-outline" onClick={() => setShowAddStaffModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Activate Staff Credentials
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* -------------------- MODAL: CREDIT PROMOTIONAL BONUS -------------------- */}
      {showBonusModal && selectedUserForBonus && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '450px' }}>
            <div className="modal-header">
              <h2>Credit Promotional Bonus</h2>
              <button style={{ background: 'none', border: 'none', cursor: 'pointer' }} onClick={() => {
                setShowBonusModal(false);
                setSelectedUserForBonus(null);
              }}>
                <X size={20} />
              </button>
            </div>
            
            <form onSubmit={handleCreditBonusSubmit}>
              <div className="modal-body">
                <div style={{ marginBottom: '1.25rem', backgroundColor: '#F8FAFC', padding: '0.75rem 1rem', borderRadius: '8px', fontSize: '0.875rem' }}>
                  <strong>Target Customer:</strong> {selectedUserForBonus.name || 'Anonymous'} ({selectedUserForBonus.phone})<br/>
                  <strong>Current Rewards:</strong> ₹{(parseFloat(selectedUserForBonus.rewardsBalance) || 0).toFixed(2)}
                </div>

                <div className="form-group">
                  <label className="form-label">Bonus Amount (₹)</label>
                  <input 
                    type="number" 
                    step="0.01"
                    min="1"
                    className="form-input" 
                    value={bonusAmount} 
                    onChange={(e) => setBonusAmount(e.target.value)} 
                    placeholder="e.g. 50" 
                    required 
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Remark / Description</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    value={bonusRemark} 
                    onChange={(e) => setBonusRemark(e.target.value)} 
                    placeholder="e.g. Promotional campaign sign-up bonus" 
                    required 
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-outline" onClick={() => {
                  setShowBonusModal(false);
                  setSelectedUserForBonus(null);
                }}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" style={{ backgroundColor: 'var(--success)' }}>
                  Credit Wallet Balance
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
