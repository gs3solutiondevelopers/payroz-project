import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payroz_models.dart';

class PayRozProvider with ChangeNotifier {
  final String apiBase = 'http://localhost:5000/api'; // Use 10.0.2.2 for Android Emulator, localhost for iOS/web/testing
  
  String? _token;
  User? _currentUser;
  bool _isLoading = false;
  Locale _locale = const Locale('en');
  
  List<ServiceCategory> _categories = [];
  List<BannerModel> _banners = [];
  List<OfferModel> _offers = [];
  List<NotificationModel> _notifications = [];
  List<Transaction> _transactions = [];
  List<Ticket> _tickets = [];
  List<TicketMessage> _activeTicketMessages = [];
  List<ScratchCardModel> _scratchCards = [];
  List<dynamic> _reminders = [];
  List<dynamic> _loginHistory = [];
  
  // Custom message representation for AI Support chat Screen
  final List<Map<String, dynamic>> _aiChatMessages = [
    {
      'sender': 'AI',
      'message': 'Hello! I am your PAYROZ AI Assistant. How can I help you today? You can ask about: \n- Refund check\n- Wallet Rules\n- Handoff to human agent\n- Raise a complaint ticket',
      'time': DateTime.now(),
    }
  ];

  // Getters
  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  Locale get locale => _locale;
  
  List<ServiceCategory> get categories => _categories;
  List<BannerModel> get banners => _banners;
  List<OfferModel> get offers => _offers;
  List<NotificationModel> get notifications => _notifications;
  List<Transaction> get transactions => _transactions;
  List<Ticket> get tickets => _tickets;
  List<TicketMessage> get activeTicketMessages => _activeTicketMessages;
  List<Map<String, dynamic>> get aiChatMessages => _aiChatMessages;
  List<ScratchCardModel> get scratchCards => _scratchCards;
  List<dynamic> get reminders => _reminders;
  List<dynamic> get loginHistory => _loginHistory;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  PayRozProvider() {
    _tryAutoLogin();
  }

  // Auto login from stored preferences
  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('locale')) {
      _locale = Locale(prefs.getString('locale')!);
    }
    if (!prefs.containsKey('token')) {
      notifyListeners();
      return;
    }
    
    _token = prefs.getString('token');
    notifyListeners();
    await fetchProfile();
    await fetchDashboard();
  }

  Future<void> changeLocale(String langCode) async {
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', langCode);
    notifyListeners();
  }

  // Set Loading state
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // Auth Operations
  Future<bool> sendOtp(String phone) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('$apiBase/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      _setLoading(false);
      return res.statusCode == 200;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String phone,
    required String otp,
    required String deviceId,
    String? name,
    String? email,
    String? referralCodeInput,
  }) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('$apiBase/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
          'deviceId': deviceId,
          'name': name,
          'email': email,
          'referralCodeInput': referralCodeInput,
        }),
      );

      _setLoading(false);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        
        notifyListeners();
        await fetchDashboard();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  // Profile
  Future<void> fetchProfile() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/auth/profile'), headers: _headers);
      if (res.statusCode == 200) {
        _currentUser = User.fromJson(jsonDecode(res.body));
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  Future<bool> submitKyc(String docType, String docNumber) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('$apiBase/auth/update-kyc'),
        headers: _headers,
        body: jsonEncode({'docType': docType, 'docNumber': docNumber}),
      );
      _setLoading(false);
      if (res.statusCode == 200) {
        await fetchProfile();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Dashboard Data loading
  Future<void> fetchDashboard() async {
    try {
      // Load Categories and Services
      final catRes = await http.get(Uri.parse('$apiBase/services/categories'), headers: _headers);
      if (catRes.statusCode == 200) {
        var list = jsonDecode(catRes.body) as List;
        _categories = list.map((i) => ServiceCategory.fromJson(i)).toList();
      }

      // Load Banners
      final bannerRes = await http.get(Uri.parse('$apiBase/banners'), headers: _headers);
      if (bannerRes.statusCode == 200) {
        var list = jsonDecode(bannerRes.body) as List;
        _banners = list.map((i) => BannerModel.fromJson(i)).toList();
      }

      // Load Offers
      final offerRes = await http.get(Uri.parse('$apiBase/offers'), headers: _headers);
      if (offerRes.statusCode == 200) {
        var list = jsonDecode(offerRes.body) as List;
        _offers = list.map((i) => OfferModel.fromJson(i)).toList();
      }

      // Load Notifications
      if (isAuthenticated) {
        final notifRes = await http.get(Uri.parse('$apiBase/notifications'), headers: _headers);
        if (notifRes.statusCode == 200) {
          var list = jsonDecode(notifRes.body) as List;
          _notifications = list.map((i) => NotificationModel.fromJson(i)).toList();
        }
        
        // Load Scratch Cards
        final scratchRes = await http.get(Uri.parse('$apiBase/rewards/scratch-cards'), headers: _headers);
        if (scratchRes.statusCode == 200) {
          var list = jsonDecode(scratchRes.body) as List;
          _scratchCards = list.map((i) => ScratchCardModel.fromJson(i)).toList();
        }

        // Load Reminders
        final reminderRes = await http.get(Uri.parse('$apiBase/reminders'), headers: _headers);
        if (reminderRes.statusCode == 200) {
          _reminders = jsonDecode(reminderRes.body) as List;
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  // Transactions list
  Future<void> fetchTransactions(String type) async {
    _setLoading(true);
    try {
      final res = await http.get(
        Uri.parse('$apiBase/transactions/history?type=$type'),
        headers: _headers,
      );
      _setLoading(false);
      if (res.statusCode == 200) {
        var list = jsonDecode(res.body) as List;
        _transactions = list.map((i) => Transaction.fromJson(i)).toList();
        notifyListeners();
      }
    } catch (e) {
      _setLoading(false);
    }
  }

  // Create payment Transaction
  Future<Transaction?> payService({
    required String serviceId,
    required double amount,
    required Map<String, dynamic> inputsUsed,
    required bool useRewardsWallet,
  }) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('$apiBase/transactions/create'),
        headers: _headers,
        body: jsonEncode({
          'serviceId': serviceId,
          'amount': amount,
          'inputsUsed': inputsUsed,
          'useRewardsWallet': useRewardsWallet,
        }),
      );
      _setLoading(false);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final tx = Transaction.fromJson(data['transaction']);
        
        // Refresh User profile balance
        await fetchProfile();
        return tx;
      }
      return null;
    } catch (e) {
      _setLoading(false);
      return null;
    }
  }

  // Ticket Management
  Future<void> fetchTickets() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/tickets'), headers: _headers);
      if (res.statusCode == 200) {
        var list = jsonDecode(res.body) as List;
        _tickets = list.map((i) => Ticket.fromJson(i)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  Future<bool> createTicket(String subject, String description, String? txId) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('$apiBase/tickets/create'),
        headers: _headers,
        body: jsonEncode({
          'subject': subject,
          'description': description,
          'transactionId': txId,
        }),
      );
      _setLoading(false);
      if (res.statusCode == 201) {
        await fetchTickets();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchMessages(String ticketId) async {
    try {
      final res = await http.get(Uri.parse('$apiBase/tickets/$ticketId/messages'), headers: _headers);
      if (res.statusCode == 200) {
        var list = jsonDecode(res.body) as List;
        _activeTicketMessages = list.map((i) => TicketMessage.fromJson(i)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  Future<bool> sendTicketReply(String ticketId, String message) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/tickets/$ticketId/reply'),
        headers: _headers,
        body: jsonEncode({'message': message}),
      );
      if (res.statusCode == 201) {
        final newMsg = TicketMessage.fromJson(jsonDecode(res.body));
        _activeTicketMessages.add(newMsg);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // AI Chat Client
  Future<void> sendAiMessage(String msgText) async {
    // 1. Add User message locally
    _aiChatMessages.add({
      'sender': 'User',
      'message': msgText,
      'time': DateTime.now(),
    });
    notifyListeners();

    try {
      // 2. Call AI Message API
      final res = await http.post(
        Uri.parse('$apiBase/ai/message'),
        headers: _headers,
        body: jsonEncode({'message': msgText}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _aiChatMessages.add({
          'sender': 'AI',
          'message': data['reply'],
          'time': DateTime.now(),
        });
        
        // Refresh profile / tickets if AI did some actions
        if (data['actionTriggered'] != 'None') {
          await fetchProfile();
          await fetchTickets();
        }
      } else {
        _aiChatMessages.add({
          'sender': 'AI',
          'message': 'Sorry, I am facing connectivity issues. Please try again or type "agent" to connect with a staff member.',
          'time': DateTime.now(),
        });
      }
    } catch (e) {
      _aiChatMessages.add({
        'sender': 'AI',
        'message': 'Connection error occurred.',
        'time': DateTime.now(),
      });
    }
    notifyListeners();
  }

  // Scratch Cards
  Future<void> fetchScratchCards() async {
    try {
      final res = await http.get(Uri.parse('$apiBase/rewards/scratch-cards'), headers: _headers);
      if (res.statusCode == 200) {
        var list = jsonDecode(res.body) as List;
        _scratchCards = list.map((i) => ScratchCardModel.fromJson(i)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  Future<double?> scratchCard(String id) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('$apiBase/rewards/scratch/$id'),
        headers: _headers,
      );
      _setLoading(false);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final double amount = (data['amount'] as num).toDouble();
        
        // Refresh local listings
        await fetchProfile();
        await fetchScratchCards();
        return amount;
      }
      return null;
    } catch (e) {
      _setLoading(false);
      return null;
    }
  }

  // Reminders
  Future<void> fetchReminders() async {
    if (!isAuthenticated) return;
    try {
      final res = await http.get(Uri.parse('$apiBase/reminders'), headers: _headers);
      if (res.statusCode == 200) {
        _reminders = jsonDecode(res.body) as List;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  Future<bool> submitFeedback(int rating, String review) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('$apiBase/feedback/submit'),
        headers: _headers,
        body: jsonEncode({
          'rating': rating,
          'review': review,
        }),
      );
      _setLoading(false);
      return res.statusCode == 201;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile(String name, String email) async {
    _setLoading(true);
    try {
      final res = await http.put(
        Uri.parse('$apiBase/auth/profile'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
        }),
      );
      _setLoading(false);
      if (res.statusCode == 200) {
        await fetchProfile();
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchLoginHistory() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/auth/login-history'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        _loginHistory = jsonDecode(res.body) as List;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  Future<Map<String, dynamic>?> validateCoupon(String code, double amount, String serviceName) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse('$apiBase/coupons/validate'),
        headers: _headers,
        body: jsonEncode({
          'code': code,
          'amount': amount,
          'serviceName': serviceName,
        }),
      );
      _setLoading(false);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        final Map<String, dynamic> data = jsonDecode(res.body);
        return {'valid': false, 'error': data['error'] ?? 'Invalid coupon'};
      }
    } catch (e) {
      _setLoading(false);
      return null;
    }
  }
}
