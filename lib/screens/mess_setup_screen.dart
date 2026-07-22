import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../models/mess.dart';
import '../config/feature_flags.dart';
import '../services/mess_service.dart';
import '../theme/app_colors.dart';
import '../widgets/mess_setup_banner.dart';
import 'community/community_hub_screen.dart';

enum MessSetupMode { create, join }

class MessSetupScreen extends StatefulWidget {
  const MessSetupScreen({super.key});

  @override
  State<MessSetupScreen> createState() => _MessSetupScreenState();
}

class _MessSetupScreenState extends State<MessSetupScreen> {
  MessSetupMode _mode = MessSetupMode.create;
  final _messNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _messService = MessService();
  bool _loading = false;

  @override
  void dispose() {
    _messNameController.dispose();
    _addressController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _showCreatedCode(Mess mess) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'মেস তৈরি হয়েছে!',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'অন্য ইউজারকে এই কোড দিয়ে মেসে যোগ দিতে বলুন:',
              style: GoogleFonts.notoSansBengali(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.featureGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mess.code,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'কপি',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: mess.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'কোড কপি হয়েছে',
                            style: GoogleFonts.notoSansBengali(),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.copy_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  IconButton(
                    tooltip: 'শেয়ার',
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              'আমাদের মেস "${mess.name}"-এ যোগ দিন।\nমেস কোড: ${mess.code}\nMass Manager অ্যাপে কোড দিয়ে জয়েন করুন।',
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.share_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ঠিক আছে',
              style: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_mode == MessSetupMode.create) {
        // Create first without routing, show code, then go Home.
        final mess = await _messService.createMess(
          name: _messNameController.text,
          location: _addressController.text,
          linkUser: false,
        );
        if (!mounted) return;
        setState(() => _loading = false);
        await _showCreatedCode(mess);
        await _messService.linkCurrentUserToMess(mess.id);
      } else {
        // Join → messId set → AppEntry routes to Home.
        await _messService.joinMess(code: _joinCodeController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'মেসে সফলভাবে যোগ দিয়েছেন',
              style: GoogleFonts.notoSansBengali(),
            ),
          ),
        );
      }
    } on MessException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.notoSansBengali())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।',
            style: GoogleFonts.notoSansBengali(),
          ),
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
      body: SafeArea(
        child: Column(
          children: [
            const _MessSetupHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const MessSetupBanner(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'অ্যাডমিন মেস তৈরি করবে। অন্য ইউজার আলাদা অ্যাকাউন্ট দিয়ে লগইন করে মেস কোড দিয়ে মেম্বার হিসেবে জয়েন করবে।',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              selected: _mode == MessSetupMode.create,
                              icon: Icons.home_rounded,
                              title: 'মেস তৈরি (অ্যাডমিন)',
                              subtitle: 'আপনি অ্যাডমিন হবেন',
                              onTap: _loading
                                  ? () {}
                                  : () => setState(() => _mode = MessSetupMode.create),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              selected: _mode == MessSetupMode.join,
                              icon: Icons.vpn_key_rounded,
                              title: 'মেসে জয়েন',
                              subtitle: 'মেম্বার হিসেবে যোগ',
                              onTap: _loading
                                  ? () {}
                                  : () => setState(() => _mode = MessSetupMode.join),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FormCard(
                      mode: _mode,
                      messNameController: _messNameController,
                      addressController: _addressController,
                      joinCodeController: _joinCodeController,
                      loading: _loading,
                      onSubmit: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 16),
                    if (FeatureFlags.communityEnabled) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CommunityHubScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.groups_rounded,
                            color: AppColors.primaryGreen,
                          ),
                          label: Text(
                            'কমিউনিটি দেখুন — মেস খুঁজুন',
                            style: GoogleFonts.notoSansBengali(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primaryGreen,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const _InfoFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessSetupHeader extends StatelessWidget {
  const _MessSetupHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.headerIcon, size: 22),
          const SizedBox(width: 8),
          Text(
            'মেস সেটআপ',
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: AppColors.headerIcon),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedCardBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.borderGrey,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryGreen : const Color(0xFFECECEC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansBengali(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.darkGreen : AppColors.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansBengali(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: selected ? AppColors.primaryGreen : AppColors.textGrey,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.mode,
    required this.messNameController,
    required this.addressController,
    required this.joinCodeController,
    required this.loading,
    this.onSubmit,
  });

  final MessSetupMode mode;
  final TextEditingController messNameController;
  final TextEditingController addressController;
  final TextEditingController joinCodeController;
  final bool loading;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mode == MessSetupMode.create) ...[
            _FormField(
              label: 'মেসের নাম',
              controller: messNameController,
            ),
            const SizedBox(height: 16),
            _FormField(
              label: 'ঠিকানা',
              controller: addressController,
              suffixIcon: Icons.my_location_outlined,
            ),
          ] else ...[
            _FormField(
              label: 'মেস কোড (৬ ডিজিট)',
              controller: joinCodeController,
              hint: 'যেমন: 482916',
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                disabledBackgroundColor:
                    AppColors.primaryGreen.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mode == MessSetupMode.create
                              ? 'মেস তৈরি করুন'
                              : 'মেসে যোগ দিন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.suffixIcon,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final IconData? suffixIcon;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.notoSansBengali(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: AppColors.textGrey, size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}

class _InfoFooter extends StatelessWidget {
  const _InfoFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBoxBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, size: 14, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'মেস তৈরির পর ৬ ডিজিটের কোড পাবেন। অন্য ইউজার লগইন করে «মেসে যোগ দিন» থেকে সেই কোড দিয়ে জয়েন করবে।',
              style: GoogleFonts.notoSansBengali(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
