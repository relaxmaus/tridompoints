import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tridompoints/widgets/animated_intro_message.dart';
import 'package:tridompoints/widgets/positioned_triangle.dart';
import 'package:tridompoints/widgets/start_page.dart';

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() {
    return _IntroState();
  }
}

class PlacedTiles extends StatelessWidget {
  final List<Widget> placedTiles;

  const PlacedTiles({
    super.key,
    required this.placedTiles,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: placedTiles,
    );
  }
}

class Tile {
  int number1, number2, number3;
  bool isUpperTriangle; // true für Typ A, false für Typ B
  Tile(this.number1, this.number2, this.number3, this.isUpperTriangle);
}

class _IntroState extends State<Intro> {
  static const triangleSideLength = 50.0;
  double triangleBorderWidth = 2;
  var stdColor = const Color(0xFFCAB2A0);
  final rng = Random();
  late List<List<Tile>> gameBoard;
  late int xCount;
  late int yCount;
  int oldXCount = 0x7fffffff;
  int oldYCount = 0x7fffffff;
  late List<Widget> placedTiles;
  double triangleHeight = triangleSideLength * sqrt(3) / 2;
  bool gameBoardGenerated = false;
  bool showMessage = false;
  bool layoutReady = false;
  bool stopped = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          xCount = 2 * (constraints.maxWidth / (triangleSideLength + 2 * triangleBorderWidth)).floor();
          yCount = (constraints.maxHeight / (triangleHeight + 2 * triangleBorderWidth)).floor();
          if(oldXCount != 0x7fffffff && oldYCount != 0x7fffffff && (oldXCount != xCount || oldYCount != yCount)) {
            stopped = true;
            gameBoardGenerated = false;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!layoutReady) {
              if (xCount == 0 || yCount == 0) {
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) setState(() {});
                });
              } else {
                oldXCount = xCount;
                oldYCount = yCount;
                layoutReady = true;
                play();
              }
            }
          });
          double calculatedLeft = constraints.maxWidth / 2 - 140;
          if (calculatedLeft <= 0) {
            calculatedLeft = 0;
          }
          double calculatedTop = constraints.maxHeight / 2 - 100;
          if (calculatedTop <= 0) {
            calculatedTop = 0;
          }
          return Wrap(
            alignment: WrapAlignment.center,
            children: [
              Row(
                children: [
                  Stack(children: [
                    GestureDetector(
                      onTapDown: (details) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const StartPage(title: 'Tridom Scorekeeper')));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue.shade100, Colors.blue.shade400],
                          ),
                        ),
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        alignment: Alignment.topLeft,
                        child: gameBoardGenerated ? PlacedTiles(placedTiles: placedTiles) : const CircularProgressIndicator(),
                      ),
                    ),
                    showMessage
                        ? AnimatedIntroMessage(
                            height: constraints.maxHeight,
                            width: constraints.maxWidth,
                          )
                        : Container(),
                  ]),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  List<List<Tile>> generateTiles(int rows, int columns) {
    Random rand = Random();
    List<List<Tile>> gameBoard = List.generate(rows, (_) => []);
    int number1, number2, number3;
    bool isUpperTriangle; // Δ
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (i == 0) {
          isUpperTriangle = (i + j) % 2 == 0;
        } else {
          isUpperTriangle = !gameBoard[i - 1][j].isUpperTriangle;
        }
        if (i == 0 && j == 0) {
          // start tile
          number1 = rand.nextInt(6);
          number2 = rand.nextInt(6);
          number3 = rand.nextInt(6);
        } else if (i == 0 && isUpperTriangle) {
          // first row and upper triangle
          number1 = gameBoard[i][j - 1].number2;
          number3 = gameBoard[i][j - 1].number3;
          do {
            number2 = rand.nextInt(6);
          } while (number2 == number1 || number2 == number3);
        } else if (i == 0 && !isUpperTriangle) {
          // first row and lower triangle
          number1 = gameBoard[i][j - 1].number1;
          number3 = gameBoard[i][j - 1].number2;
          do {
            number2 = rand.nextInt(6);
          } while (number2 == number1 || number2 == number3);
        } else if (i > 0 && j == 0) {
          // first column and not first row
          number1 = gameBoard[i - 1][j].number3;
          number2 = gameBoard[i - 1][j].number2;
          do {
            number3 = rand.nextInt(6);
          } while (number3 == number1 || number3 == number2);
        } else if (i > 0 && isUpperTriangle) {
          // not first column and upper triangle
          number1 = gameBoard[i][j - 1].number2;
          number3 = gameBoard[i][j - 1].number3;
          do {
            number2 = rand.nextInt(6);
          } while (number2 == number1 || number2 == number3);
        } else if (i > 0 && !isUpperTriangle) {
          // not first column and lower triangle
          number1 = gameBoard[i - 1][j].number3;
          number2 = gameBoard[i - 1][j].number2;
          number3 = gameBoard[i][j - 1].number2;
        } else {
          throw Exception('Unexpected case');
        }
        gameBoard[i].add(Tile(number1, number2, number3, isUpperTriangle));
      }
    }
    return gameBoard;
  }

  List<Widget> generateTriangleWidgets(List<List<Tile>> gameboard, double triangleHeight, double triangleSideLength, double triangleBorderWidth) {
    List<Widget> widgets = [];
    for (int i = 0; i < gameboard.length; i++) {
      for (int j = 0; j < gameboard[i].length; j++) {
        Tile tile = gameboard[i][j];
        widgets.add(PositionedTriangle(
          position: '$i,$j',
          triangleSideLength: triangleSideLength,
          triangleBorderWidth: triangleBorderWidth,
          color: stdColor,
          number1: tile.number1,
          number2: tile.number2,
          number3: tile.number3,
        ));
      }
    }
    return widgets;
  }

  void play() async {
    placedTiles = [];
    gameBoard = generateTiles(yCount, xCount);
    int duration = 500;
    try {
      for (int y = 0; !stopped && !stopped && y < yCount; y++) {
            if (y == (yCount / 20).ceil()) {
              showMessage = true;
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const StartPage(title: 'Tridom Scorekeeper')));
                }
              });
            }
            for (int x = 0; !stopped && x < xCount; x++) {
              var currentTileWidget = PositionedTriangle(
                position: '$y,$x',
                triangleSideLength: triangleSideLength,
                triangleBorderWidth: triangleBorderWidth,
                color: stdColor,
                number1: gameBoard[y][x].number1,
                number2: gameBoard[y][x].number2,
                number3: gameBoard[y][x].number3,
              );
              placedTiles.add(currentTileWidget);
              gameBoardGenerated = true;
              if (mounted) {
                setState(() {});
              }
              await Future.delayed(Duration(milliseconds: duration));
              duration = duration ~/ 1.1;
            }
          }
    } catch (e) {
      debugPrint(e.toString());
    }
    if(stopped) {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const StartPage(title: 'Tridom Scorekeeper')));
      }
    }
  }
}
