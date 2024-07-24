import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tridompoints/widgets/triangle.dart';

class PositionedTriangle extends StatelessWidget {
  final String position;
  final double triangleSideLength;
  final double triangleBorderWidth;
  final int number1;
  final int number2;
  final int number3;
  final Color color;

  const PositionedTriangle({
    super.key,
    required this.position,
    required this.triangleSideLength,
    required this.triangleBorderWidth,
    required this.color,
    required this.number1,
    required this.number2,
    required this.number3,
  });

  @override
  Widget build(BuildContext context) {
    double triangleHeight = triangleSideLength * sqrt(3) / 2;
    double top, left;
    Offset offset;
    double angle;
    int newNumber1 = number1;
    int newNumber2 = number2;
    int newNumber3 = number3;

    switch (position) {
      case 'pos11':
        top = triangleBorderWidth;
        left = triangleBorderWidth;
        offset = const Offset(0, 0);
        angle = 0;
        newNumber1 = number1;
        newNumber2 = number3;
        newNumber3 = number2;
        break;
      case 'pos12':
        top = triangleBorderWidth;
        left = (triangleSideLength + 2 * triangleBorderWidth) / 2;
        offset = Offset(triangleBorderWidth * 1.5, -3.75 * triangleBorderWidth);
        angle = pi;
        newNumber1 = number3;
        newNumber2 = number2;
        newNumber3 = number1;
        break;
      case 'pos13':
        top = triangleBorderWidth;
        left = triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 2, 0);
        angle = 0;
        newNumber1 = number1;
        newNumber2 = number3;
        newNumber3 = number2;
        break;
      case 'pos14':
        top = triangleBorderWidth;
        left = 1.5 * triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 3.5, -3.75 * triangleBorderWidth);
        angle = pi;
        newNumber1 = number3;
        newNumber2 = number2;
        newNumber3 = number1;
        break;
      case 'pos15':
        top = triangleBorderWidth;
        left = 2 * triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 5, 0);
        angle = 0;
        newNumber1 = number1;
        newNumber2 = number3;
        newNumber3 = number2;
        break;
      case 'pos21':
        top = triangleHeight + triangleBorderWidth * 2;
        left = triangleBorderWidth;
        offset = Offset(0, -3.0 * triangleBorderWidth);
        angle = pi;
        newNumber1 = number3;
        newNumber2 = number2;
        newNumber3 = number1;
        break;
      case 'pos22':
        top = triangleHeight + triangleBorderWidth * 2;
        left = (triangleSideLength + 2 * triangleBorderWidth) / 2;
        offset = Offset(triangleBorderWidth * 1.5, .75 * triangleBorderWidth);
        angle = 0;
        newNumber1 = number1;
        newNumber2 = number3;
        newNumber3 = number2;
        break;
      case 'pos23':
        top = triangleHeight + triangleBorderWidth * 2;
        left = triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 2, -3.0 * triangleBorderWidth);
        angle = pi;
        newNumber1 = number3;
        newNumber2 = number2;
        newNumber3 = number1;
        break;
      case 'pos24':
        top = triangleHeight + triangleBorderWidth * 2;
        left = 1.5 * triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 3.5, .75 * triangleBorderWidth);
        angle = 0;
        newNumber1 = number1;
        newNumber2 = number3;
        newNumber3 = number2;
        break;
      case 'pos25':
        top = triangleHeight + triangleBorderWidth * 2;
        left = 2 * triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 5, -3.0 * triangleBorderWidth);
        angle = pi;
        newNumber1 = number3;
        newNumber2 = number2;
        newNumber3 = number1;
        break;
      case 'pos31':
        top = 2 * triangleHeight + triangleBorderWidth * 3;
        left = triangleBorderWidth;
        offset = Offset(0, 2 * triangleBorderWidth);
        angle = 0;
        newNumber1 = number1;
        newNumber2 = number3;
        newNumber3 = number2;
        break;
      case 'pos32':
        top = 2 * triangleHeight + triangleBorderWidth * 3;
        left = (triangleSideLength + 2 * triangleBorderWidth) / 2;
        offset = Offset(triangleBorderWidth * 1.5, -2.0 * triangleBorderWidth);
        angle = pi;
        newNumber1 = number3;
        newNumber2 = number2;
        newNumber3 = number1;
        break;
      case 'pos33':
        top = 2 * triangleHeight + triangleBorderWidth * 3;
        left = triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 2, 2 * triangleBorderWidth);
        angle = 0;
        newNumber1 = number1;
        newNumber2 = number3;
        newNumber3 = number2;
        break;
      case 'pos34':
        top = 2 * triangleHeight + triangleBorderWidth * 3;
        left = 1.5 * triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 3.5, -2.0 * triangleBorderWidth);
        angle = pi;
        newNumber1 = number3;
        newNumber2 = number2;
        newNumber3 = number1;
        break;
      case 'pos35':
        top = 2 * triangleHeight + triangleBorderWidth * 3;
        left = 2 * triangleSideLength + 2 * triangleBorderWidth;
        offset = Offset(triangleBorderWidth * 5, 2 * triangleBorderWidth);
        angle = 0;
        newNumber1 = number1;
        newNumber2 = number3;
        newNumber3 = number2;
        break;
      default:
        var pos = position.split(",");
        int xPos = int.parse(pos[1]);
        int yPos = int.parse(pos[0]);
        bool isUpperTriangle = (xPos + yPos) % 2 == 0;
        top = isUpperTriangle ? yPos * (triangleHeight + triangleBorderWidth) + 1 : yPos * (triangleHeight + triangleBorderWidth) - 6;
        left = (xPos * (triangleSideLength + triangleBorderWidth)) / 2 + 1;
        //offset = isUpperTriangle ? Offset(triangleBorderWidth, -3.0 * triangleBorderWidth) : Offset(triangleBorderWidth, 2 * triangleBorderWidth);
        offset = const Offset(0, 0);
        angle = isUpperTriangle ? 0 : pi;
        newNumber1 = isUpperTriangle ? number1 : number3;
        newNumber2 = isUpperTriangle ? number3 : number2;
        newNumber3 = isUpperTriangle ? number2 : number1;
        //debugPrint("top: $top, left: $left, offset: $offset, angle: $angle, isUpperTriangle: $isUpperTriangle");
    }
    return Positioned(
      top: top,
      left: left,
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          alignment: Alignment.center,
          angle: angle,
          child: TriangleWidget(
            triangleBorderWidth: triangleBorderWidth,
            size: triangleSideLength,
            color: color,
            number1: newNumber1,
            number2: newNumber2,
            number3: newNumber3,
          ),
        ),
      ),
    );
  }
}
