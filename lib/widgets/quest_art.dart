import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sidequests/models/quest.dart';

/// Painted cover art per category. No image files, always crisp.
class QuestArt extends StatelessWidget {
  const QuestArt({super.key, required this.category, required this.height});

  final QuestCategory category;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CategoryArtPainter(category)),
    );
  }
}

class _CategoryArtPainter extends CustomPainter {
  _CategoryArtPainter(this.category);

  final QuestCategory category;

  @override
  void paint(Canvas canvas, Size size) {
    switch (category) {
      case QuestCategory.outdoors:
        _outdoors(canvas, size);
      case QuestCategory.culture:
        _culture(canvas, size);
      case QuestCategory.food:
        _food(canvas, size);
      case QuestCategory.water:
        _water(canvas, size);
      case QuestCategory.night:
        _night(canvas, size);
      case QuestCategory.social:
        _social(canvas, size);
      case QuestCategory.quiet:
        _quiet(canvas, size);
    }
  }

  void _outdoors(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF2D8A0),
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.32),
      size.height * 0.2,
      Paint()..color = const Color(0xFFD95D39),
    );
    final back = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.42,
        size.width * 0.62,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.86,
        size.width,
        size.height * 0.62,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFF7FB069));
    final front = Path()
      ..moveTo(0, size.height * 0.88)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.66,
        size.width * 0.7,
        size.height * 0.9,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF1E4D3F));
  }

  void _culture(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFEAD9B8),
    );
    final paint = Paint()..color = const Color(0xFFB4552D);
    final pediment = Path()
      ..moveTo(size.width * 0.18, size.height * 0.34)
      ..lineTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.82, size.height * 0.34)
      ..close();
    canvas.drawPath(pediment, paint);
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.24 + i * 0.17);
      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          size.height * 0.4,
          x + size.width * 0.07,
          size.height * 0.88,
          const Radius.circular(6),
        ),
        paint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.88,
        size.width * 0.68,
        size.height * 0.07,
      ),
      paint,
    );
  }

  void _food(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF6E3C5),
    );
    final bowl = Path()
      ..moveTo(size.width * 0.2, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.05,
        size.width * 0.8,
        size.height * 0.55,
      )
      ..close();
    canvas.drawPath(bowl, Paint()..color = const Color(0xFF1E4D3F));
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.17,
        size.height * 0.5,
        size.width * 0.66,
        size.height * 0.06,
      ),
      Paint()..color = const Color(0xFFD95D39),
    );
    final steam = Paint()
      ..color = const Color(0xFFD95D39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.38 + i * 0.12);
      final wave = Path()
        ..moveTo(x, size.height * 0.42)
        ..cubicTo(
          x - 10,
          size.height * 0.32,
          x + 10,
          size.height * 0.24,
          x,
          size.height * 0.14,
        );
      canvas.drawPath(wave, steam);
    }
  }

  void _water(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFBFDCD8),
    );
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.3),
      size.height * 0.14,
      Paint()..color = const Color(0xFFE9A13B),
    );
    final wave = Paint()
      ..color = const Color(0xFF1E6F6B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 3; row++) {
      final y = size.height * (0.55 + row * 0.16);
      final path = Path()..moveTo(size.width * 0.08, y);
      for (var x = 0.08; x < 0.92; x += 0.14) {
        path.quadraticBezierTo(
          size.width * (x + 0.035),
          y - 12,
          size.width * (x + 0.07),
          y,
        );
      }
      canvas.drawPath(path, wave);
    }
  }

  void _night(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF16233A),
    );
    final random = Random(7);
    final star = Paint()..color = const Color(0xFFF1ECE0);
    for (var i = 0; i < 26; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        1 + random.nextDouble() * 1.6,
        star,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.38),
      size.height * 0.24,
      Paint()..color = const Color(0xFFE9A13B),
    );
    canvas.drawCircle(
      Offset(size.width * 0.79, size.height * 0.3),
      size.height * 0.2,
      Paint()..color = const Color(0xFF16233A),
    );
  }

  void _social(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF0C6A8),
    );
    final paint = Paint()..color = const Color(0xFF1E4D3F);
    canvas.drawCircle(
      Offset(size.width * 0.38, size.height * 0.4),
      size.height * 0.16,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.4),
      size.height * 0.16,
      Paint()..color = const Color(0xFFD95D39),
    );
    final shoulders = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.62,
        size.width * 0.38,
        size.height * 0.62,
      )
      ..lineTo(size.width * 0.38, size.height)
      ..close();
    canvas.drawPath(shoulders, paint);
    final shoulders2 = Path()
      ..moveTo(size.width * 0.44, size.height)
      ..quadraticBezierTo(
        size.width * 0.44,
        size.height * 0.62,
        size.width * 0.62,
        size.height * 0.62,
      )
      ..lineTo(size.width * 0.8, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.62,
        size.width * 0.8,
        size.height,
      )
      ..close();
    canvas.drawPath(shoulders2, Paint()..color = const Color(0xFFD95D39));
  }

  void _quiet(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFDCE8D4),
    );
    final leaf = Path()
      ..moveTo(size.width * 0.5, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.42,
        size.width * 0.5,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.42,
        size.width * 0.5,
        size.height * 0.18,
      )
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF1E4D3F));
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.76),
      Paint()
        ..color = const Color(0xFFDCE8D4)
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
