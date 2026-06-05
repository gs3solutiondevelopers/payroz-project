import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/payroz_provider.dart';
import '../../theme.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docNoController = TextEditingController();
  String _selectedDoc = 'Aadhaar';

  @override
  void dispose() {
    _docNoController.dispose();
    super.dispose();
  }

  void _submitKyc() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<PayRozProvider>(context, listen: false);
      final success = await provider.submitKyc(_selectedDoc, _docNoController.text.trim());
      
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC documents uploaded successfully. Under review.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Check network link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PayRozProvider>(context);

    return Scaffold(
      backgroundColor: PayRozTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Submit KYC Docs', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: PayRozTheme.primaryColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identity Verification',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: PayRozTheme.primaryColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Please submit document details to verify your account identity. Verified users are eligible for premium utility promotions.',
                style: GoogleFonts.outfit(fontSize: 11, color: PayRozTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDoc,
                decoration: const InputDecoration(labelText: 'Document Type'),
                items: ['Aadhaar', 'PAN Card', 'Voter ID'].map((doc) {
                  return DropdownMenuItem<String>(
                    value: doc,
                    child: Text(doc),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDoc = val ?? 'Aadhaar';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Doc Number Input
              TextFormField(
                controller: _docNoController,
                decoration: InputDecoration(
                  labelText: 'Document Number',
                  hintText: _selectedDoc == 'Aadhaar' ? '12-digit UID' : '10-digit alpha-numeric',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter document number';
                  }
                  if (_selectedDoc == 'Aadhaar' && val.length != 12) {
                    return 'Aadhaar must be exactly 12 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submitKyc,
                  child: provider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit KYC Verification'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
