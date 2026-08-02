import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LoginHeroCard extends StatelessWidget {
  const LoginHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: const CustomPaint(
        painter: _DiningIllustrationPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _DiningIllustrationPainter extends CustomPainter {
  const _DiningIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFFFF8F0);
    canvas.drawRect(Offset.zero & size, bg);

    _drawWall(canvas, size);
    _drawWindow(canvas, size);
    _drawTable(canvas, size);
    _drawPerson(
      canvas,
      size,
      const Offset(0.22, 0.52),
      const Color(0xFF5C6BC0),
      true,
    );
    _drawPerson(
      canvas,
      size,
      const Offset(0.42, 0.48),
      const Color(0xFFEF5350),
      false,
    );
    _drawPerson(
      canvas,
      size,
      const Offset(0.62, 0.48),
      const Color(0xFF66BB6A),
      false,
    );
    _drawPerson(
      canvas,
      size,
      const Offset(0.82, 0.52),
      const Color(0xFFFFA726),
      true,
    );
    _drawFood(canvas, size);
  }

  void _drawWall(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.55),
      Paint()..color = const Color(0xFFF5EDE3),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.12,
        size.width * 0.18,
        size.height * 0.22,
      ),
      Paint()..color = const Color(0xFFE8DDD0),
    );
  }

  void _drawWindow(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.68,
      size.height * 0.08,
      size.width * 0.22,
      size.height * 0.24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFB3E5FC),
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      Offset(rect.center.dx, rect.bottom),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  void _drawTable(Canvas canvas, Size size) {
    final tableTop = size.height * 0.62;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          tableTop,
          size.width * 0.64,
          size.height * 0.08,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.28,
        tableTop + size.height * 0.08,
        8,
        size.height * 0.12,
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.64,
        tableTop + size.height * 0.08,
        8,
        size.height * 0.12,
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
  }

  void _drawPerson(
    Canvas canvas,
    Size size,
    Offset pos,
    Color shirtColor,
    bool facingIn,
  ) {
    final x = size.width * pos.dx;
    final y = size.height * pos.dy;

    canvas.drawCircle(
      Offset(x, y - 18),
      10,
      Paint()..color = const Color(0xFFFFCC80),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 4), width: 22, height: 28),
        const Radius.circular(8),
      ),
      Paint()..color = shirtColor,
    );

    if (facingIn) {
      canvas.drawCircle(
        Offset(x + (pos.dx < 0.5 ? 6 : -6), y - 2),
        4,
        Paint()..color = const Color(0xFFFFCC80),
      );
    }
  }

  void _drawFood(Canvas canvas, Size size) {
    final centerY = size.height * 0.64;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, centerY),
        width: 28,
        height: 12,
      ),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, centerY),
        width: 22,
        height: 10,
      ),
      Paint()..color = const Color(0xFFA5D6A7),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, centerY),
        width: 26,
        height: 11,
      ),
      Paint()..color = const Color(0xFFFFAB91),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
