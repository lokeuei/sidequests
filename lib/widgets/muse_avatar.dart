import 'package:flutter/material.dart';

/// Muse's companion: a round cream face with dark eyes, a smile,
/// and rosy cheeks. Drawn in code, in the spirit of Jolly.
class MuseAvatar extends StatelessWidget {
  const MuseAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MuseFacePainter()),
    );
  }
}

class _MuseFacePainter extends CustomPainter {
  static const _cream = Color(0xFFF7EDDA);
  static const _shade = Color(0xFFE7D6B8);
  static const _ink = Color(0xFF26221C);
  static const _cheek = Color(0xFFF0A0A0);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    final body = Path()
      ..addOval(Rect.fromCenter(
        center: center,
        width: s * 0.92,
        height: s * 0.98,
      ));
    canvas.drawShadow(body, Colors.black.withValues(alpha: 0.18), 4, false);
    canvas.drawPath(
      body,
      Paint()
        ..color = _shade
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, -s * 0.03),
        width: s * 0.92,
        height: s * 0.92,
      ),
      Paint()..color = _cream,
    );

    final cheekPaint = Paint()
      ..color = _cheek.withValues(alpha: 0.8);
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.62),
      s * 0.085,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.62),
      s * 0.085,
      cheekPaint,
    );

    final eyePaint = Paint()..color = _ink;
    for (final fx in [0.37, 0.63]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * fx, size.height * 0.44),
            width: s * 0.11,
            height: s * 0.15,
          ),
          Radius.circular(s * 0.055),
        ),
        eyePaint,
      );
    }

    final smile = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.56),
          width: s * 0.36,
          height: s * 0.26,
        ),
        0.15 * 3.14159,
        0.7 * 3.14159,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
