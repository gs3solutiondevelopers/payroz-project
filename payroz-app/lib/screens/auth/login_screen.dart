import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralController = TextEditingController();
  
  // OTP digits
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isRegistering = false;
  bool _isOtpSent = false;
  bool _kycSuccessStep = false;
  String _tempOtp = '';

  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResendOtp = false;

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 30;
      _canResendOtp = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        setState(() {
          _canResendOtp = true;
          _resendTimer?.cancel();
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _sendOtpCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    final provider = Provider.of<PayRozProvider>(context, listen: false);
    final success = await provider.sendOtp(phone);

    if (success) {
      setState(() {
        _isOtpSent = true;
        _tempOtp = '123456';
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent successfully (Use $_tempOtp for testing)')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP. Server offline?')),
      );
    }
  }

  void _verifyOtpCode() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit OTP code')),
      );
      return;
    }

    final provider = Provider.of<PayRozProvider>(context, listen: false);
    final success = await provider.verifyOtp(
      phone: _phoneController.text.trim(),
      otp: otp,
      deviceId: 'DEVICE-ID-MOCK-12345',
      name: _isRegistering ? _nameController.text.trim() : null,
      email: _isRegistering ? _emailController.text.trim() : null,
      referralCodeInput: _isRegistering ? _referralController.text.trim() : null,
    );

    if (success) {
      if (_isRegistering) {
        setState(() {
          _kycSuccessStep = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please enter 123456')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);

    if (_kycSuccessStep) {
      return _buildSuccessScreen(provider);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC), // Very light gray/blue background
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF0B192C)),
                      onPressed: () {
                        if (_isOtpSent) {
                          setState(() {
                            _isOtpSent = false;
                            for (var c in _otpControllers) {
                              c.clear();
                            }
                          });
                        } else if (_isRegistering) {
                          setState(() => _isRegistering = false);
                        } else {
                          // Exit or do nothing
                        }
                      },
                    ),
                  ),
                  
                  // Logo
                  Image.asset(
                    'assets/images/Screenshot_2026-06-03_203024-removebg-preview.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, size: 120, color: PayRozTheme.primaryColor),
                  ),
                  const SizedBox(height: 10),

                  if (_isOtpSent) 
                    _buildOtpScreen(provider)
                  else if (_isRegistering)
                    _buildRegisterContent(provider)
                  else
                    _buildLoginContent(provider),
                    
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginContent(PayRozProvider provider) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mobile_friendly, color: Color(0xFFFF7A00), size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Login with Mobile',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0B192C)),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your mobile number and we\'ll send\nyou a 6-digit OTP to login securely.',
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: 'Enter Mobile Number',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0B192C)),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _sendOtpCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B192C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Send OTP', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0B192C)),
                  const SizedBox(width: 6),
                  Text('100% Secure & Encrypted', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        // Footer toggles
        Text(
          'New to PayRoz?',
          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0B192C), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _isRegistering = true;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Create an Account',
                style: GoogleFonts.outfit(fontSize: 15, color: const Color(0xFFFF7A00), fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16, color: Color(0xFFFF7A00)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              'By continuing, you agree to our ',
              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
            ),
            Text(
              'Terms & Conditions',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRegisterContent(PayRozProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Create Your Account',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0B192C)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Join PayRoz and get exciting cashback\non every payment.',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        _buildInputField(
          controller: _nameController,
          hint: 'Full Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _phoneController,
          hint: 'Mobile Number',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          maxLength: 10,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _emailController,
          hint: 'Gmail ID',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: provider.isLoading ? null : _sendOtpCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B192C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: provider.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Continue', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('OR', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              // Google SignIn placeholder
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B192C),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simple G icon since we don't have asset
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Text('G', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Text('Continue with Google', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Features Grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureItem(Icons.percent, 'Exciting\nCashback'),
            _buildFeatureItem(Icons.verified_user_outlined, '100% Secure\nPayments'),
            _buildFeatureItem(Icons.bolt, 'Instant\nPayment'),
            _buildFeatureItem(Icons.headset_mic_outlined, '24/7\nSupport'),
          ],
        ),
        const SizedBox(height: 32),
        
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isRegistering = false;
              });
            },
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
                children: [
                  TextSpan(
                    text: 'Login',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFFF7A00)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOtpScreen(PayRozProvider provider) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Column(
            children: [
              // OTP graphic representation
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0B192C), width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '123456',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFFF7A00), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              Text(
                'Verify Your Mobile Number',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0B192C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit OTP sent to\n+91 ${_phoneController.text}',
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // OTP Boxes Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0B192C)),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0B192C), width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _otpFocusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              
              _canResendOtp
                  ? TextButton(
                      onPressed: _sendOtpCode,
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFFF7A00), fontWeight: FontWeight.bold),
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        text: 'Resend OTP in ',
                        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                        children: [
                          TextSpan(
                            text: '00:${_resendCountdown.toString().padLeft(2, '0')}',
                            style: GoogleFonts.outfit(color: const Color(0xFFFF7A00), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _verifyOtpCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B192C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Verify & Continue', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF0B192C)),
                  const SizedBox(width: 6),
                  Text('100% Secure & Encrypted', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen(PayRozProvider provider) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Confetti / Check graphic placeholder
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Account Created!',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B192C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account has been created\nsuccessfully.',
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Biometric Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fingerprint, size: 40, color: Color(0xFF22C55E)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Biometric Login',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0B192C)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Login faster and more securely\nusing your fingerprint or face.',
                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    provider.fetchProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B192C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Enable Now', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  provider.fetchProfile();
                },
                child: Text('Maybe Later', style: GoogleFonts.outfit(color: const Color(0xFF0B192C), fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B192C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text('ENABLE BIOMETRIC', style: GoogleFonts.outfit(letterSpacing: 1, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0B192C)),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF7A00), size: 28),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF0B192C), fontWeight: FontWeight.w600, height: 1.3),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

}
