import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/community_post_service.dart';
import '../../theme/app_colors.dart';

class CreateVacancyPostScreen extends StatefulWidget {
  const CreateVacancyPostScreen({super.key});

  @override
  State<CreateVacancyPostScreen> createState() =>
      _CreateVacancyPostScreenState();
}

class _CreateVacancyPostScreenState extends State<CreateVacancyPostScreen> {
  final _seatsController = TextEditingController(text: '1');
  final _rentController = TextEditingController();
  final _bodyController = TextEditingController();
  final _service = CommunityPostService();
  bool _includeCode = false;
  bool _loading = false;

  @override
  void dispose() {
    _seatsController.dispose();
    _rentController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final seats = int.tryParse(_seatsController.text.trim()) ?? 0;
      await _service.createVacancyPost(
        seatsAvailable: seats,
        body: _bodyController.text,
        rentHint: _rentController.text,
        includeMessCode: _includeCode,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'পোস্ট আপলোড হয়েছে',
            style: GoogleFonts.notoSansBengali(),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e', style: GoogleFonts.notoSansBengali()),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          'ভ্যাকান্সি পোস্ট',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'খালি সিটের সংখ্যা',
            style: GoogleFonts.notoSansBengali(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _seatsController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.notoSansBengali(),
            decoration: _dec('যেমন: ২'),
          ),
          const SizedBox(height: 14),
          Text(
            'ভাড়া / খরচ (ঐচ্ছিক)',
            style: GoogleFonts.notoSansBengali(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _rentController,
            style: GoogleFonts.notoSansBengali(),
            decoration: _dec('যেমন: মাসিক ~৩৫০০ টাকা'),
          ),
          const SizedBox(height: 14),
          Text(
            'বিবরণ',
            style: GoogleFonts.notoSansBengali(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            style: GoogleFonts.notoSansBengali(),
            decoration: _dec('মেসের পরিবেশ, নিয়ম, লোকেশন ইত্যাদি…'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'মেস জয়েন কোড পোস্টে দেখাও',
              style: GoogleFonts.notoSansBengali(fontSize: 13),
            ),
            value: _includeCode,
            activeThumbColor: AppColors.primaryGreen,
            onChanged: (v) => setState(() => _includeCode = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'পোস্ট করুন',
                    style: GoogleFonts.notoSansBengali(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansBengali(color: AppColors.textGrey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
      );
}
