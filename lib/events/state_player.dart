import '../models/player.dart';

class PlayerError extends PlayerState {
  PlayerError() : super(players: []);
}

class PlayerInitial extends PlayerState {
  PlayerInitial() : super(players: []);
}

class PlayerLoaded extends PlayerState {
  PlayerLoaded(List<Player> players) : super(players: players);
}

class PlayerLoading extends PlayerState {
  PlayerLoading() : super(players: []);
}

abstract class PlayerState {
  final List<Player> players;

  PlayerState({required this.players});

  int get count => players.length;
}
