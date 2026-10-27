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

  void _pine(Canvas canvas, Offset base, double h, Color color) {
    final paint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromCenter(center: base + Offset(0, -h * 0.08), width: h * 0.09, height: h * 0.22),
      paint,
    );
    for (var i = 0; i < 3; i++) {
      final w = h * (0.42 - i * 0.1);
      final y = base.dy - h * (0.16 + i * 0.22);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - w / 2, y)
          ..lineTo(base.dx, y - h * 0.3)
          ..lineTo(base.dx + w / 2, y)
          ..close(),
        paint,
      );
    }
  }

  void _bird(Canvas canvas, Offset at, double s, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - s, at.dy)
        ..quadraticBezierTo(at.dx - s / 2, at.dy - s * 0.7, at.dx, at.dy)
        ..quadraticBezierTo(at.dx + s / 2, at.dy - s * 0.7, at.dx + s, at.dy),
      paint,
    );
  }

  void _outdoors(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFF2D8A0));
    canvas.drawCircle(Offset(w * 0.76, h * 0.3), h * 0.26, Paint()..color = const Color(0xFFF6E7C4));
    canvas.drawCircle(Offset(w * 0.76, h * 0.3), h * 0.18, Paint()..color = const Color(0xFFD95D39));
    _bird(canvas, Offset(w * 0.2, h * 0.26), 12, const Color(0xFF8A6B45));
    _bird(canvas, Offset(w * 0.32, h * 0.36), 9, const Color(0xFF8A6B45));
    _ridge(canvas, size, 0.66, 0.5, const Color(0xFFA9C795));
    _ridge(canvas, size, 0.78, 0.62, const Color(0xFF7FB069));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), Paint()..color = const Color(0xFF1E4D3F));
    _pine(canvas, Offset(w * 0.14, h * 0.9), h * 0.5, const Color(0xFF14332A));
    _pine(canvas, Offset(w * 0.26, h * 0.92), h * 0.38, const Color(0xFF14332A));
    _pine(canvas, Offset(w * 0.88, h * 0.9), h * 0.44, const Color(0xFF14332A));
  }

  void _ridge(Canvas canvas, Size size, double base, double dip, Color color) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * base)
        ..quadraticBezierTo(w * 0.25, h * (base - dip * 0.5), w * 0.45, h * base)
        ..quadraticBezierTo(w * 0.62, h * (base - dip * 0.62), w * 0.8, h * base)
        ..quadraticBezierTo(w * 0.9, h * (base - dip * 0.2), w, h * base)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = color,
    );
  }

  void _culture(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFEAD9B8));
    canvas.drawCircle(Offset(w * 0.85, h * 0.22), h * 0.1, Paint()..color = const Color(0xFFE9A13B));
    final clay = Paint()..color = const Color(0xFFB4552D);
    final dark = Paint()..color = const Color(0xFF7E3A1D);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * (0.22 - i * 0.04), h * (0.82 + i * 0.05), w * (0.56 + i * 0.08), h * 0.05),
        i.isEven ? clay : dark,
      );
    }
    for (var i = 0; i < 4; i++) {
      final x = w * (0.27 + i * 0.15);
      canvas.drawRRect(
        RRect.fromLTRBR(x, h * 0.4, x + w * 0.06, h * 0.82, const Radius.circular(5)),
        clay,
      );
      canvas.drawRect(Rect.fromLTWH(x - 6, h * 0.36, w * 0.06 + 12, 8), dark);
      canvas.drawRect(Rect.fromLTWH(x - 6, h * 0.78, w * 0.06 + 12, 8), dark);
      for (var f = 0; f < 3; f++) {
        canvas.drawLine(
          Offset(x + (w * 0.06) * (0.25 + f * 0.25), h * 0.44),
          Offset(x + (w * 0.06) * (0.25 + f * 0.25), h * 0.76),
          Paint()
            ..color = const Color(0xFF7E3A1D)
            ..strokeWidth = 2,
        );
      }
    }
    canvas.drawRect(Rect.fromLTWH(w * 0.2, h * 0.3, w * 0.6, h * 0.06), dark);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.18, h * 0.3)
        ..lineTo(w * 0.5, h * 0.1)
        ..lineTo(w * 0.82, h * 0.3)
        ..close(),
      clay,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.24), 7, dark);
    _pine(canvas, Offset(w * 0.08, h), h * 0.5, const Color(0xFF5C6E4C));
    _pine(canvas, Offset(w * 0.93, h), h * 0.55, const Color(0xFF5C6B45));
  }

  void _food(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFF6E3C5));
    canvas.drawCircle(Offset(w * 0.5, h * 0.46), h * 0.4, Paint()..color = const Color(0xFFF0D3A6));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), Paint()..color = const Color(0xFF8A5A33));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, 5), Paint()..color = const Color(0xFF6E4526));
    final bowl = Path()
      ..moveTo(w * 0.24, h * 0.56)
      ..quadraticBezierTo(w * 0.5, h * 1.02, w * 0.76, h * 0.56)
      ..close();
    canvas.drawPath(bowl, Paint()..color = const Color(0xFF1E4D3F));
    canvas.drawRect(Rect.fromLTWH(w * 0.21, h * 0.51, w * 0.58, h * 0.06), Paint()..color = const Color(0xFFD95D39));
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * (0.4 + i * 0.1), h * 0.52),
        7,
        Paint()..color = const Color(0xFFE9A13B),
      );
    }
    canvas.save();
    canvas.translate(w * 0.72, h * 0.3);
    canvas.rotate(0.5);
    canvas.drawRRect(
      RRect.fromLTRBR(-3, -h * 0.3, 3, h * 0.1, const Radius.circular(3)),
      Paint()..color = const Color(0xFF6E4526),
    );
    canvas.restore();
    final steam = Paint()
      ..color = const Color(0xFFB4552D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final x = w * (0.4 + i * 0.1);
      canvas.drawPath(
        Path()
          ..moveTo(x, h * 0.42)
          ..cubicTo(x - 10, h * 0.32, x + 10, h * 0.24, x, h * 0.14),
        steam,
      );
    }
  }

  void _water(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFBFDCD8));
    canvas.drawCircle(Offset(w * 0.22, h * 0.28), h * 0.13, Paint()..color = const Color(0xFFE9A13B));
    _bird(canvas, Offset(w * 0.6, h * 0.22), 10, const Color(0xFF3E6B68));
    _bird(canvas, Offset(w * 0.72, h * 0.3), 8, const Color(0xFF3E6B68));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.52, w, h * 0.48), Paint()..color = const Color(0xFF3E8E8A));
    final boatX = w * 0.58;
    final boatY = h * 0.52;
    canvas.drawPath(
      Path()
        ..moveTo(boatX - 26, boatY)
        ..lineTo(boatX + 26, boatY)
        ..lineTo(boatX + 16, boatY + 14)
        ..lineTo(boatX - 16, boatY + 14)
        ..close(),
      Paint()..color = const Color(0xFF7E3A1D),
    );
    canvas.drawLine(Offset(boatX, boatY), Offset(boatX, boatY - h * 0.3), Paint()
      ..color = const Color(0xFF7E3A1D)
      ..strokeWidth = 4);
    canvas.drawPath(
      Path()
        ..moveTo(boatX, boatY - h * 0.3)
        ..lineTo(boatX, boatY - 4)
        ..lineTo(boatX + 30, boatY - 4)
        ..close(),
      Paint()..color = const Color(0xFFF6F1E3),
    );
    final wave = Paint()
      ..color = const Color(0xFFDFF0ED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 3; row++) {
      final y = h * (0.66 + row * 0.12);
      final path = Path()..moveTo(w * 0.06, y);
      for (var x = 0.06; x < 0.94; x += 0.11) {
        path.quadraticBezierTo(w * (x + 0.027), y - 9, w * (x + 0.055), y);
      }
      canvas.drawPath(path, wave);
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w * 0.18, h * (0.58 + i * 0.06)),
        Offset(w * 0.26, h * (0.58 + i * 0.06)),
        Paint()
          ..color = const Color(0xFFE9A13B)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _night(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF16233A));
    final random = Random(7);
    for (var i = 0; i < 34; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * w, random.nextDouble() * h * 0.7),
        0.8 + random.nextDouble() * 1.8,
        Paint()..color = const Color(0xFFF1ECE0).withValues(alpha: 0.5 + random.nextDouble() * 0.5),
      );
    }
    canvas.drawCircle(Offset(w * 0.72, h * 0.36), h * 0.3, Paint()..color = const Color(0xFFE9A13B).withValues(alpha: 0.25));
    canvas.drawCircle(Offset(w * 0.72, h * 0.36), h * 0.22, Paint()..color = const Color(0xFFE9A13B));
    canvas.drawCircle(Offset(w * 0.68, h * 0.3), h * 0.05, Paint()..color = const Color(0xFFD1942F));
    canvas.drawCircle(Offset(w * 0.76, h * 0.42), h * 0.035, Paint()..color = const Color(0xFFD1942F));
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.78)
        ..quadraticBezierTo(w * 0.3, h * 0.5, w * 0.55, h * 0.76)
        ..quadraticBezierTo(w * 0.75, h * 0.94, w, h * 0.7)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFF0C1424),
    );
    _pine(canvas, Offset(w * 0.12, h), h * 0.5, const Color(0xFF0C1424));
    _pine(canvas, Offset(w * 0.22, h), h * 0.38, const Color(0xFF0C1424));
    canvas.drawLine(
      Offset(w * 0.6, h * 0.9),
      Offset(w * 0.84, h * 0.9),
      Paint()
        ..color = const Color(0xFFE9A13B).withValues(alpha: 0.6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _social(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFF0C6A8));
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.12)
        ..quadraticBezierTo(w * 0.5, h * 0.42, w, h * 0.12),
      Paint()
        ..color = const Color(0xFF7E3A1D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final random = Random(11);
    for (var i = 0; i < 6; i++) {
      final t = 0.08 + i * 0.15;
      final x = w * t;
      final y = h * (0.12 + 0.3 * 4 * t * (1 - t));
      canvas.drawCircle(Offset(x, y + 10), 7 + random.nextDouble() * 2, Paint()..color = const Color(0xFFE9A13B));
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), Paint()
        ..color = const Color(0xFF7E3A1D)
        ..strokeWidth = 2);
    }
    final people = [0.3, 0.5, 0.7];
    final colors = [const Color(0xFF1E4D3F), const Color(0xFFD95D39), const Color(0xFF3E6B68)];
    for (var i = 0; i < 3; i++) {
      final x = w * people[i];
      canvas.drawCircle(Offset(x, h * 0.52), h * 0.11, Paint()..color = colors[i]);
      canvas.drawPath(
        Path()
          ..moveTo(x - w * 0.11, h)
          ..quadraticBezierTo(x - w * 0.11, h * 0.68, x, h * 0.68)
          ..lineTo(x + w * 0.11, h * 0.68)
          ..quadraticBezierTo(x + w * 0.11, h * 0.68, x + w * 0.11, h)
          ..close(),
        Paint()..color = colors[i],
      );
    }
    canvas.drawRect(Rect.fromLTWH(w * 0.36, h * 0.8, w * 0.28, 6), Paint()..color = const Color(0xFF7E3A1D));
    canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.7, 10, h * 0.1), Paint()..color = const Color(0xFFF6F1E3));
    canvas.drawRect(Rect.fromLTWH(w * 0.56, h * 0.7, 10, h * 0.1), Paint()..color = const Color(0xFFF6F1E3));
  }

  void _quiet(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFDCE8D4));
    canvas.drawCircle(Offset(w * 0.5, h * 0.46), h * 0.36, Paint()..color = const Color(0xFFD2E2C6));
    final leaf = Path()
      ..moveTo(w * 0.5, h * 0.16)
      ..quadraticBezierTo(w * 0.76, h * 0.42, w * 0.5, h * 0.74)
      ..quadraticBezierTo(w * 0.24, h * 0.42, w * 0.5, h * 0.16)
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF1E4D3F));
    final vein = Paint()
      ..color = const Color(0xFFDCE8D4)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(w * 0.5, h * 0.18), Offset(w * 0.5, h * 0.72), vein);
    for (var i = 0; i < 4; i++) {
      final y = h * (0.3 + i * 0.11);
      canvas.drawLine(Offset(w * 0.5, y), Offset(w * 0.4, y - h * 0.06), vein);
      canvas.drawLine(Offset(w * 0.5, y), Offset(w * 0.6, y - h * 0.06), vein);
    }
    canvas.drawCircle(Offset(w * 0.72, h * 0.24), 5, Paint()..color = const Color(0xFF7FB069));
    canvas.drawCircle(Offset(w * 0.26, h * 0.7), 4, Paint()..color = const Color(0xFF7FB069));
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * (0.32 + i * 0.1), h * 0.88), width: 26 - i * 5, height: 10),
        Paint()..color = const Color(0xFF9DB49A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
