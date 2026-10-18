import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleGMark extends StatelessWidget {
  const GoogleGMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _GoogleGMarkPainter(),
      );
}

class _GoogleGMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final strokeWidth = size.shortestSide * 0.16;
    const gap = 0.045;
    final segments = <(Color, double)>[
      (const Color(0xFFEA4335), -3 * math.pi / 4),
      (const Color(0xFF4285F4), -math.pi / 4),
      (const Color(0xFF34A853), math.pi / 4),
      (const Color(0xFFFBBC05), 3 * math.pi / 4),
    ];

    for (final (color, startAngle) in segments) {
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        math.pi / 2 - gap,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    canvas.drawLine(
      center,
      Offset(center.dx + radius, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
