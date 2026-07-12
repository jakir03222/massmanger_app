import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessSetupBanner extends StatelessWidget {
  const MessSetupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _KitchenBannerPainter(),
            child: SizedBox.expand(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'নতুন মেস শুরু করুন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'সহজেই হিসাব রাখুন সবার সাথে',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenBannerPainter extends CustomPainter {
  const _KitchenBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF5EDE3),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.45),
      Paint()..color = const Color(0xFFECEFF1),
    );

    _drawWindow(canvas, Rect.fromLTWH(size.width * 0.1, size.height * 0.08, size.width * 0.25, size.height * 0.22));
    _drawWindow(canvas, Rect.fromLTWH(size.width * 0.65, size.height * 0.06, size.width * 0.28, size.height * 0.24));

    final tableY = size.height * 0.58;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, tableY, size.width * 0.76, size.height * 0.07),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );

    _drawPerson(canvas, size.width * 0.22, tableY - 8, const Color(0xFF5C6BC0));
    _drawPerson(canvas, size.width * 0.4, tableY - 12, const Color(0xFFEF5350));
    _drawPerson(canvas, size.width * 0.58, tableY - 12, const Color(0xFF66BB6A));
    _drawPerson(canvas, size.width * 0.76, tableY - 8, const Color(0xFFFFA726));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.42, tableY + 2), width: 24, height: 10),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.55, tableY + 2), width: 20, height: 9),
      Paint()..color = const Color(0xFFA5D6A7),
    );
  }

  void _drawWindow(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = const Color(0xFFB3E5FC),
    );
  }

  void _drawPerson(Canvas canvas, double x, double y, Color shirt) {
    canvas.drawCircle(Offset(x, y - 14), 8, Paint()..color = const Color(0xFFFFCC80));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 2), width: 18, height: 22),
        const Radius.circular(6),
      ),
      Paint()..color = shirt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
