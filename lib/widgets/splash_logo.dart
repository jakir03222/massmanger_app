import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, this.size = 108});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: const CustomPaint(
            painter: _LogoPainter(),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()
      ..color = AppColors.logoGreen
      ..style = PaintingStyle.fill;

    _drawFork(canvas, Offset(size.width * 0.34, size.height * 0.02), green);
    _drawKnife(canvas, Offset(size.width * 0.58, size.height * 0.02), green);

    final calcSize = size.width * 0.46;
    final calcTop = size.height * 0.48;
  final calcLeft = (size.width - calcSize) / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(calcLeft, calcTop, calcSize, calcSize * 0.82),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.calculatorOrange,
    );

    _drawCalcSymbol(canvas, calcLeft + calcSize * 0.28, calcTop + calcSize * 0.22, '−');
    _drawCalcSymbol(canvas, calcLeft + calcSize * 0.72, calcTop + calcSize * 0.22, '×');
    _drawCalcSymbol(canvas, calcLeft + calcSize * 0.28, calcTop + calcSize * 0.58, '+');
    _drawCalcSymbol(canvas, calcLeft + calcSize * 0.72, calcTop + calcSize * 0.58, '=');
  }

  void _drawCalcSymbol(Canvas canvas, double x, double y, String symbol) {
    final painter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(x - painter.width / 2, y - painter.height / 2),
    );
  }

  void _drawFork(Canvas canvas, Offset c, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 14), width: 4, height: 22),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx - 4.5, c.dy - 2, 2, 9),
        const Radius.circular(1),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx - 1, c.dy - 2, 2, 9),
        const Radius.circular(1),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx + 2.5, c.dy - 2, 2, 9),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  void _drawKnife(Canvas canvas, Offset c, Paint paint) {
    final blade = Path()
      ..moveTo(c.dx - 1, c.dy)
      ..lineTo(c.dx + 6, c.dy + 3)
      ..lineTo(c.dx + 2, c.dy + 20)
      ..lineTo(c.dx - 2, c.dy + 20)
      ..close();
    canvas.drawPath(blade, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 26), width: 5, height: 10),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
