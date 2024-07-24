import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AnimatedIntroMessage extends StatefulWidget {
  const AnimatedIntroMessage({super.key, required this.height, required this.width});
  final double height;
  final double width;
  @override
  AnimatedIntroMessageState createState() => AnimatedIntroMessageState();
}

class AnimatedIntroMessageState extends State<AnimatedIntroMessage> {
  double topPosition = -100.0;
  double leftPosition = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => calculateTextPosition());
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        topPosition = MediaQuery.of(context).size.height / 2 - 100;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: OverflowBox(
        maxHeight: widget.height,
        maxWidth: widget.width,
        alignment: Alignment.center,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              left: leftPosition,
              top: topPosition,
              child: Container(
                color: Colors.yellow,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    context.tr('intro_message'),
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void calculateTextPosition() {
    final text = context.tr('intro_message');
    const textStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(maxWidth: widget.width);
    setState(() {
      topPosition = MediaQuery.of(context).size.height / 2 - 100;
      leftPosition =  (widget.width - textPainter.width) / 2;
    });
  }
}