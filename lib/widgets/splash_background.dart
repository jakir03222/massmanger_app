import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.splashBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [const _DecorativeCircles(), child],
      ),
    );
  }
}

class _DecorativeCircles extends StatelessWidget {
  const _DecorativeCircles();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CirclePatternPainter());
  }
}

class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.splashCircle.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(
      Offset(-size.width * 0.08, size.height * 0.06),
      size.width * 0.34,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.78),
      size.width * 0.55,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
