import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter {
  final int number1;
  final int number2;
  final int number3;
  final double triangleBorderWidth;
  final Color color;

  TrianglePainter({required this.triangleBorderWidth, required this.color, required this.number1, required this.number2, required this.number3});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = triangleBorderWidth;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height * 0.866);
    path.lineTo(size.width, size.height * 0.866);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    final textPainter1 = TextPainter(
      text: TextSpan(text: '$number1', style: const TextStyle(color: Colors.black, fontSize: 20)),
      textDirection: TextDirection.ltr,
    );
    textPainter1.layout();
    canvas.save();
    canvas.translate(size.width / 2, textPainter1.height / 1.7);
    canvas.rotate(3.14159); // 180 Grad in Bogenmaß
    textPainter1.paint(canvas, Offset(-textPainter1.width / 2, -textPainter1.height / 1.5));
    canvas.restore();

    final textPainter2 = TextPainter(
      text: TextSpan(text: '$number2', style: const TextStyle(color: Colors.black, fontSize: 20)),
      textDirection: TextDirection.ltr,
    );
    textPainter2.layout();
    canvas.save();
    canvas.translate(textPainter2.width / .7, size.height - textPainter2.height / 1.3);
    canvas.rotate(1); // -120 Grad in Bogenmaß
    textPainter2.paint(canvas, Offset(-textPainter2.width / 2.5, -textPainter2.height / 2));
    canvas.restore();

    final textPainter3 = TextPainter(
      text: TextSpan(text: '$number3', style: const TextStyle(color: Colors.black, fontSize: 20)),
      textDirection: TextDirection.ltr,
    );
    textPainter3.layout();
    canvas.save();
    canvas.translate(size.width - textPainter3.width / .75, size.height - textPainter3.height / 1.6);
    canvas.rotate(5.3); // 270 Grad in Bogenmaß
    textPainter3.paint(canvas, Offset(-textPainter3.width / 2.5, -textPainter3.height / 1.75));
    canvas.restore();
    }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TriangleWidget extends StatelessWidget {
  final int number1;
  final int number2;
  final int number3;
  final double size;
  final double triangleBorderWidth;
  final Color color;

  const TriangleWidget({super.key, required this.size, required this.triangleBorderWidth, required this.color, required this.number1, required this.number2, required this.number3});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TrianglePainter(triangleBorderWidth: triangleBorderWidth, color: color, number1: number1, number2: number2, number3: number3),
      size: Size(size, size),
    );
  }
}