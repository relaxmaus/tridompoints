import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../events/state_player.dart';

class PlayerScoreBarChart extends StatelessWidget {
  final PlayerState state;

  const PlayerScoreBarChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final tapPosition = renderBox.globalToLocal(details.globalPosition);
        showPointsHistoryDialog(context, tapPosition, state);
      },
      child: CustomPaint(
        size: const Size(300, 200),
        painter: _BarChartPainter(state),
      ),
    );
  }

  void showPointsHistoryDialog(BuildContext context, Offset tapPosition, PlayerState state) {
    if (state is PlayerLoaded) {
      var players = (state).players;
      double spaceBetweenBars = 5.0;
      var barWidth = (300 - (spaceBetweenBars * (players.length - 1))) / players.length;
      int tappedBarIndex = tapPosition.dx ~/ (barWidth + spaceBetweenBars);
      if (tappedBarIndex < players.length) {
        var tappedPlayer = players[tappedBarIndex];
        int round = 0;
        int value = 0;
        int prevValue = 0x0fffffff;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            debugPrint('Tapped player: ${tappedPlayer.name} has ${tappedPlayer.stackOfTiles.length} tiles and ${tappedPlayer.stackOfPoints.length} points');
            return AlertDialog(
              title: Text(context.tr('playerScoreBarChart.pointsHistoryOf', args: [tappedPlayer.name])),
              content: SingleChildScrollView(
                child: ListBody(
                  children: tappedPlayer.stackOfPoints.skip(1).map((point) {
                    round++;
                    if (prevValue != 0x0fffffff) {
                      value = point.y.ceil() - prevValue;
                    } else {
                      value = point.y.ceil();
                    }
                    prevValue = point.y.ceil();
                    return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                            '${context.tr('round')} $round: ${point.y} ${context.tr('points')} (P: ${value >= 0 ? '+' : ''}$value;  Δ: ${tappedPlayer.stackOfTiles.length > round ? tappedPlayer.stackOfTiles[round] : 0})'),
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }
}

class _BarChartPainter extends CustomPainter {
  final PlayerState state;

  _BarChartPainter(this.state);

  @override
  paint(Canvas canvas, Size size) {
    if (state is PlayerLoaded) {
      var players = (state as PlayerLoaded).players;
      if (players.isNotEmpty && players.every((player) => player.stackOfPoints.isNotEmpty)) {
        var maxPoints = players.map((player) => player.stackOfPoints.last.y).reduce(max);
        if (maxPoints == 0) return;
        double spaceBetweenBars = 5.0;
        var barWidth = (size.width - (spaceBetweenBars * (players.length - 1))) / players.length;
        var scaleFactor = size.height / maxPoints;

        for (var i = 0; i < players.length; i++) {
          var player = players[i];
          var barHeight = player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y * scaleFactor : 0.0;
          var xCoordinate = i * (barWidth + spaceBetweenBars);
          var barRect = Rect.fromLTWH(xCoordinate, size.height - barHeight, barWidth, barHeight);

          // Fill the bar with player's color
          var fillPaint = Paint()
            ..color = player.color
            ..style = PaintingStyle.fill;
          canvas.drawRect(barRect, fillPaint);

          // Draw black border around the bar
          var borderPaint = Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0; // Adjust the stroke width as needed
          canvas.drawRect(barRect, borderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return true; // For now, always repaint
  }
}
