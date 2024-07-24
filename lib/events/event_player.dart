import '../models/player.dart';

enum PlayerEventType {
  load,
  newRound,
  playerAdded,
  playerRemoved,
  startGame,
  playerChanged,
  pageChanged,
}
 enum PageID {
  startPage,
  firstRound,
   mainRound,
  lastRound,
  winnerPage,
}

class PlayerEvent {
  final PlayerEventType type;
  final Player? player;
  final int? id;
  final PageID? pageID;

  PlayerEvent({required this.type, this.player, this.id, this.pageID});
}
