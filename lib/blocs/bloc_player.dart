import 'dart:convert';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../events/event_player.dart';
import '../events/state_player.dart';
import '../models/player.dart';
import '../models/rules.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final List<Player> players = [];
  bool gameStarted = false;
  PageID currentPage = PageID.startPage;

  PlayerBloc() : super(PlayerInitial()) {
    on<PlayerEvent>((event, emit) async {
      switch (event.type) {
        case PlayerEventType.load:
          emit(PlayerLoading()); // Show loading indicator
          try {
            // Load player data here
            emit(PlayerLoaded(players)); // Show player data
          } catch (_) {
            emit(PlayerError()); // Show error message
          }
          break;
        case PlayerEventType.newRound:
          for (var player in players) {
            player.stackOfTiles.add(Rules.startTiles[players.length]);
            player.stackOfPoints.add(Point(player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.x + 1 : 0,  player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y : 0));
          }
          emit(PlayerLoaded(players));
          break;
        case PlayerEventType.playerAdded:
          players.add(event.player!);
          emit(PlayerLoaded(players));
          break;
        case PlayerEventType.playerRemoved:
          players.removeWhere((player) => player.id == event.id);
          emit(PlayerLoaded(players));
          break;
        case PlayerEventType.startGame:
          for (Player player in players) {
            player.stackOfTiles.add(Rules.startTiles[players.length]);
            player.stackOfPoints.add(const Point(1, 0));
          }
          gameStarted = true;
          break;
        case PlayerEventType.playerChanged:
          for (var player in players) {
            if (event.player != null && player.id == event.player!.id) {
              player.isActive = true;
            } else {
              player.isActive = false;
            }
          }
          await savePlayersToPrefs(currentPage: currentPage.name);
          emit(PlayerLoaded(players));
          break;
        case PlayerEventType.pageChanged:
          currentPage = event.pageID??PageID.startPage;
          await savePlayersToPrefs(currentPage: currentPage.name);
          break;
      }
    });
  }
  Future<String> serializePlayers() async {
    List<Map<String, dynamic>> playersJson = players.map((player) => player.toJson()).toList();
    return jsonEncode(playersJson);
  }

  Future<void> savePlayersToPrefs({required String currentPage}) async {
    final prefs = await SharedPreferences.getInstance();
    String playersJsonString = await serializePlayers();
    await prefs.setString('players', playersJsonString);
    await prefs.setString('currentPage', currentPage);
  }
}
