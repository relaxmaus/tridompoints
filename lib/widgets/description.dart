import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Description extends StatefulWidget {
  final String description;

  const Description({required this.description, super.key});

  @override
  DescriptionState createState() => DescriptionState();
}

class DescriptionState extends State<Description> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black, width: 2.0),
            ),
            child: Text(
              isExpanded ? context.tr('firstRound.hideExplanations') : context.tr('firstRound.explanations'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.0,
              ),),
          ),
        ),
        Visibility(
          visible: isExpanded,
          child: Container(
            height: 200,
            margin:  const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black, width: 2.0),
            ),
            child: SingleChildScrollView(
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
