import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Rules {
  static int maxPlayers = 6;
  static List<int> startTiles = [0, 11, 11, 9, 9, 8, 8];
  static int startBonusTriple = 20;
  static int startBonusNoTriple = 20;
  static List<int> tripleValues = [20, 3 * 1, 3 * 2, 3 * 3, 3 * 4, 3 * 5];
  static int bridgeValue = 40;
  static int hexagonValue = 50;
  static int doubleHexagonValue = 60;
  static int tripleHexagonValue = 70;
  static int finishMinimum = 400;
  static int retries = 3;
  static int retryFee = -5;
  static int retryFailed = -10;
  static int finishBonus = 25;

  static Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String? serializedRules = prefs.getString('rules');
    debugPrint("caswi: rules = $serializedRules");
    if (serializedRules != null && serializedRules.isNotEmpty) {
      Map<String, dynamic> rulesMap = jsonDecode(serializedRules);
      maxPlayers = rulesMap['maxPlayers'];
      startTiles = List<int>.from(rulesMap['startTiles']);
      startBonusTriple = rulesMap['startBonus'];
      startBonusNoTriple = rulesMap['startBonusNoTriple'];
      tripleValues = List<int>.from(rulesMap['tripleValues']);
      bridgeValue = rulesMap['bridgeValue'];
      hexagonValue = rulesMap['hexagonValue'];
      doubleHexagonValue = rulesMap['doubleHexagonValue'];
      tripleHexagonValue = rulesMap['tripleHexagonValue'];
      finishMinimum = rulesMap['finishMinimum'];
      retries = rulesMap['retries'];
      retryFee = rulesMap['retryFee'];
      retryFailed = rulesMap['retryFailed'];
      finishBonus = rulesMap['finishBonus'];
    }
  }

  static Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String serializedRules = await serializeRules();
    await prefs.setString('rules', serializedRules);
  }
}

// serialize class Rules
Future<String> serializeRules() async {
  Map<String, dynamic> rulesMap = {
    'maxPlayers': Rules.maxPlayers,
    'startTiles': Rules.startTiles,
    'startBonus': Rules.startBonusTriple,
    'startBonusNoTriple': Rules.startBonusNoTriple,
    'tripleValues': Rules.tripleValues,
    'bridgeValue': Rules.bridgeValue,
    'hexagonValue': Rules.hexagonValue,
    'doubleHexagonValue': Rules.doubleHexagonValue,
    'tripleHexagonValue': Rules.tripleHexagonValue,
    'finishMinimum': Rules.finishMinimum,
    'retries': Rules.retries,
    'retryFee': Rules.retryFee,
    'retryFailed': Rules.retryFailed,
    'finishBonus': Rules.finishBonus,
  };
  return jsonEncode(rulesMap);
}
