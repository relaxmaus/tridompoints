import 'dart:math';

import 'package:flutter/material.dart';

class StrikedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  StrikedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StrikedCircleWidget extends StatelessWidget {
  final Color color;
  final double size;
  final double strokeWidth;

  const StrikedCircleWidget({super.key, required this.color, required this.size, required this.strokeWidth});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StrikedCirclePainter(color: color, strokeWidth: strokeWidth),
      size: Size(size, size),
    );
  }
}