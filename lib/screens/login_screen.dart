import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/google_logo.dart';
import '../widgets/login_hero_card.dart';
import 'email_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const LoginHeroCard(),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'স্বাগতম',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'গুগল বা ইমেইল দিয়ে লগইন করুন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _LoginCard(),
              const SizedBox(height: 28),
              const _FeatureBadges(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'লগইন করে আপনি শর্তাবলী এবং গোপনীয়তা নীতি মেনে নিচ্ছেন',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _authService = AuthService();
  bool _googleLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await _authService.signInWithGoogle();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.notoSansBengali())),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
        children: [
          _OutlinedLoginButton(
            onPressed: _googleLoading ? null : _signInWithGoogle,
            child: _googleLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryGreen,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(),
                      const SizedBox(width: 12),
                      Text(
                        'গুগল দিয়ে লগইন করুন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          const _OrDivider(),
          const SizedBox(height: 20),
          _FilledLoginButton(
            onPressed: _googleLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EmailLoginScreen(),
                      ),
                    );
                  },
            icon: Icons.mail_outline_rounded,
            label: 'ইমেইল দিয়ে লগইন করুন',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _googleLoading
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
              icon: const Icon(
                Icons.person_add_alt_1_outlined,
                size: 20,
                color: AppColors.primaryGreen,
              ),
              label: Text(
                'ইমেইল দিয়ে অ্যাকাউন্ট তৈরি করুন',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedLoginButton extends StatelessWidget {
  const _OutlinedLoginButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.borderGrey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _FilledLoginButton extends StatelessWidget {
  const _FilledLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          disabledBackgroundColor: AppColors.primaryGreen.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderGrey, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'অথবা',
            style: GoogleFonts.notoSansBengali(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textGrey,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderGrey, height: 1)),
      ],
    );
  }
}

class _FeatureBadges extends StatelessWidget {
  const _FeatureBadges();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _FeatureBadge(
              backgroundColor: AppColors.featureGreenBg,
              iconColor: AppColors.primaryGreen,
              icon: Icons.shield_outlined,
              label: 'সুরক্ষিত লগইন',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FeatureBadge(
              backgroundColor: AppColors.featureOrangeBg,
              iconColor: AppColors.featureOrangeIcon,
              icon: Icons.groups_outlined,
              label: 'সহজ মেস ম্যানেজমেন্ট',
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.label,
  });

  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSansBengali(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
