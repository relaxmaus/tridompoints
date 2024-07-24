import 'dart:math';

import 'package:flutter/material.dart';

class Player {
  final int id; // player id
  String name; // player name
  final Color color; // player color
  List<int> stackOfTiles; // number of tiles in each round
  int retries; // 0-3
  List<Point> stackOfPoints; // x=round, y=score
  bool isActive = false; // it is the player's turn

  Player({
    required this.id,
    required this.name,
    required this.color,
    required this.stackOfTiles,
    required this.retries,
    required this.isActive,
    required this.stackOfPoints,
  });

  Player.simple({
    required this.id,
    required this.name,
    required this.color,
  })  : stackOfTiles = [],
        retries = 0,
        stackOfPoints = [];

  void setActive(bool isActive) {
    this.isActive = isActive;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'isActive': isActive,
        'retries': retries,
        'round': stackOfPoints.isNotEmpty ? stackOfPoints.last.x : 1,
        'points': stackOfPoints.isNotEmpty ? stackOfPoints.last.y : 0,
        'tiles': stackOfTiles.isNotEmpty ? stackOfTiles.last : 0,
      };

  static fromJson(playerJson) {
    return Player(
      id: playerJson['id'],
      name: playerJson['name'],
      color: Color(playerJson['color']),
      stackOfTiles: [playerJson['tiles']],
      retries: playerJson['retries'],
      isActive: playerJson['isActive'],
      stackOfPoints: [Point(playerJson['round'], playerJson['points'])],
    );
  }
}
