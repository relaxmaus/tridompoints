import '../models/player.dart';
import 'event_player.dart';

class PlayerChanged extends PlayerEvent {
  PlayerChanged({required Player player})
      : super(type: PlayerEventType.playerChanged, player: player);
}