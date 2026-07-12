import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/splash_background.dart';
import '../widgets/splash_loading_indicator.dart';
import '../widgets/splash_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
  });

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    final titleStyle = GoogleFonts.notoSansBengali(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.15,
      letterSpacing: 0.2,
    );

    final subtitleStyle = GoogleFonts.notoSansBengali(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.subtitle,
      height: 1.35,
    );

    return Scaffold(
      body: SplashBackground(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: screenHeight * 0.30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SplashLogo(),
                  const SizedBox(height: 24),
                  Text('মেস ম্যানেজার', style: titleStyle),
                  const SizedBox(height: 8),
                  Text('মেসের হিসাব, সহজে', style: subtitleStyle),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SplashLoadingIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    'অ্যাপ লোড হচ্ছে…',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
