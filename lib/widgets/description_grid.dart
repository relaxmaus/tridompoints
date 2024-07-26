import 'package:flutter/material.dart';

import '../models/grit_item.dart';

class DescriptionGrid extends StatefulWidget {
  DescriptionGrid({super.key});

  @override
  State<DescriptionGrid> createState() => _DescriptionGridState();
}

class _DescriptionGridState extends State<DescriptionGrid> {
  final List<String> descriptionTexts = [
    "1a. Ermittle den Spieler mit dem höchsten Triple.",
    "2a. Tippe den entsprechenden Spielernamen an.",
    "3a. Tippe den passenden Triple an.",
    "ODER Wenn kein Triple vorhanden ist:",
    "1b. Ermitteln Sie den Spieler mit dem höchsten Steinwert.",
    "2b. Tippe den entsprechenden Spielernamen an.",
    "3b. Tippe auf den Button 'Punkte des Startsteins'.",
    "4b. Trage die Steinwewert ein.",
    "5b. Tippe auf den Button 'Punkte des Startsteins'. Tippe auf den Button 'Punkte des Startsteins'.",
  ];
  late List<GridItem> items;

  @override
  void initState() {
    items = [];
    for (int i = 0; i < descriptionTexts.length; i++) {
      items.add(GridItem(
        descriptionTexts[i],
        Color.fromRGBO(255 - ((i * 200) / 8).round(), 255 - ((i * 200) / 8).round(), 255 - ((i * 255) / 8).round(), .8),
      ));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cellWidth = 150;
        int crossAxisCount = (constraints.maxWidth / cellWidth).floor();
        int rows = (items.length / crossAxisCount).ceil();
        List<GridItem> reorderedItems = List<GridItem>.filled(items.length, GridItem("", Colors.transparent), growable: false);
        for (int i = 0; i < items.length; i++) {
          int row = i % rows;
          int col = i ~/ rows;
          int newIndex = row * crossAxisCount + col;
          reorderedItems[newIndex] = items[i];
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.0,
          ),
          itemCount: reorderedItems.length,
          itemBuilder: (context, index) {
            Color backgroundColor = reorderedItems[index].backgroundColor;
            Color textColor = Colors.black;

            return LayoutBuilder(
              builder: (context, constraints) {
                double fontSize = _calculateFontSize(reorderedItems[index].text, constraints.maxWidth, constraints.maxHeight);
                return Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(4.0),
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: Text(
                    reorderedItems[index].text,
                    style: TextStyle(color: textColor, fontSize: fontSize, decoration: TextDecoration.none),
                    textAlign: TextAlign.left,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  double _calculateFontSize(String text, double maxWidth, double maxHeight) {
    double fontSize = 20.0;
    TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );

    while (true) {
      painter.layout(maxWidth: maxWidth);
      if (painter.height <= maxHeight) {
        break;
      }
      fontSize -= 1.0;
      painter.text = TextSpan(text: text, style: TextStyle(fontSize: fontSize));
    }

    return fontSize;
  }
}