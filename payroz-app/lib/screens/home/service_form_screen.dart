import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/payroz_models.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';
import 'payment_checkout_screen.dart';

class ServiceFormScreen extends StatefulWidget {
  final Service service;
  final Map<String, dynamic>? prefilledInputs;

  const ServiceFormScreen({super.key, required this.service, this.prefilledInputs});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    // Prefill form data
    if (widget.prefilledInputs != null) {
      _formData.addAll(widget.prefilledInputs!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.service.formFields;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display service banner or icon info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PayRozTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                        child: Icon(Icons.info_outline, color: PayRozTheme.accentColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant & Secure Payment',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'This service is powered by ${widget.service.apiProvider}. 100% secure.',
                              style: GoogleFonts.outfit(fontSize: 10, color: PayRozTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // RECOMMENDED OFFER CODE RECOMMENDATION BANNER
                () {
                  final provider = Provider.of<PayRozProvider>(context);
                  final offers = provider.offers;
                  
                  OfferModel? recommendedOffer;
                  for (final offer in offers) {
                    final title = offer.title.toLowerCase();
                    final desc = offer.description.toLowerCase();
                    final name = widget.service.name.toLowerCase();
                    
                    if (name.contains('recharge') && (title.contains('recharge') || title.contains('mobile') || desc.contains('recharge'))) {
                      recommendedOffer = offer;
                      break;
                    } else if (name.contains('bill') && (title.contains('bill') || title.contains('utility') || desc.contains('bill') || desc.contains('utility'))) {
                      recommendedOffer = offer;
                      break;
                    } else if (name.contains('dth') && (title.contains('dth') || desc.contains('dth'))) {
                      recommendedOffer = offer;
                      break;
                    }
                  }

                  if (recommendedOffer == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD8A8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, color: PayRozTheme.accentColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendedOffer.title,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: PayRozTheme.textMain),
                                ),
                                Text(
                                  recommendedOffer.description,
                                  style: GoogleFonts.outfit(fontSize: 10, color: PayRozTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: recommendedOffer!.promoCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Promo Code ${recommendedOffer!.promoCode} copied to clipboard!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: PayRozTheme.accentColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    recommendedOffer.promoCode,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: PayRozTheme.accentColor),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy, color: PayRozTheme.accentColor, size: 10),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }(),

                // Dynamically build fields
                ...fields.map((field) {
                  final String name = field['name'] ?? '';
                  final String type = field['type'] ?? 'text';
                  final String label = field['label'] ?? '';
                  final bool required = field['required'] ?? false;
                  final List<dynamic> options = field['options'] ?? [];
                  
                  final prefilledVal = widget.prefilledInputs?[name]?.toString();

                  if (type == 'select') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: options.map((e) => e.toString()).contains(prefilledVal) ? prefilledVal : null,
                        decoration: InputDecoration(
                          labelText: required ? '$label *' : label,
                        ),
                        hint: Text('Select $label'),
                        validator: (value) {
                          if (required && (value == null || value.isEmpty)) {
                            return 'Please select $label';
                          }
                          return null;
                        },
                        items: options.map<DropdownMenuItem<String>>((opt) {
                          return DropdownMenuItem<String>(
                            value: opt.toString(),
                            child: Text(opt.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _formData[name] = value;
                        },
                      ),
                    );
                  } else {
                    TextInputType keyType = TextInputType.text;
                    if (type == 'number') {
                      keyType = TextInputType.number;
                    } else if (type == 'tel') {
                      keyType = TextInputType.phone;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        initialValue: prefilledVal,
                        keyboardType: keyType,
                        decoration: InputDecoration(
                          labelText: required ? '$label *' : label,
                          hintText: 'Enter $label',
                        ),
                        validator: (value) {
                          if (required && (value == null || value.trim().isEmpty)) {
                            return 'Please enter $label';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _formData[name] = value;
                        },
                      ),
                    );
                  }
                }),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        
                        // Extract billing amount (or set a default if amount input doesn't exist)
                        double billAmount = 199.0;
                        if (_formData.containsKey('amount')) {
                          billAmount = double.tryParse(_formData['amount'].toString()) ?? 199.0;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentCheckoutScreen(
                              service: widget.service,
                              amount: billAmount,
                              inputsUsed: _formData,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Proceed to Pay'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
