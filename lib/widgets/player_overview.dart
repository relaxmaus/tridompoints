import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/bloc_player.dart';
import '../events/event_player_changed.dart';
import '../events/state_player.dart';
import '../misk.dart';
import '../models/rules.dart';
import 'main_round.dart';

class PlayerOverview extends StatelessWidget {
  const PlayerOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is PlayerLoaded) {
          return GestureDetector(
            onLongPress: () {
              MainRound.editPlayer(context, state);
            },
            child: Align(
              alignment: Alignment.topCenter,
              child: Wrap(
                alignment: WrapAlignment.center,
                children: state.players.map((player) {
                  TextStyle textCol = TextStyle(
                    color: player.isActive ? getHighContrastComplementaryColor(player.color) : Colors.black.withOpacity(.6),
                    overflow: TextOverflow.ellipsis,
                    height: 1,
                  );
                  BoxDecoration boxDecoration1 = BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: player.stackOfPoints.isNotEmpty && player.stackOfPoints.last.y >= Rules.finishMinimum
                          ? Colors.green
                          : player.isActive
                              ? Colors.red
                              : Colors.grey,
                      width: player.isActive
                          ? 4 : 2,
                    ),
                  );
                  BoxDecoration boxDecoration2 = BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: player.isActive ? player.color : player.color.withOpacity(.1),
                    border: Border.all(
                      color: player.isActive ? player.color : Colors.grey,
                      width: 1,
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: GestureDetector(
                      onTapDown: (_) {
                        player.setActive(true);
                        BlocProvider.of<PlayerBloc>(context).add(
                          PlayerChanged(player: player),
                        );
                      },
                      child: Container(
                        decoration: boxDecoration2,
                        padding: const EdgeInsets.only(top: 0),
                        child: Container(
                          padding: const EdgeInsets.only(top: 0),
                          width: 120,
                          decoration: boxDecoration1,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(left: 5.0, top: 0.0),
                            horizontalTitleGap: 0.0,
                            visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
                            title: Text(
                              player.name,
                              style: textCol.copyWith(fontSize: 22),
                              softWrap: true,
                              maxLines: 2,
                            ),
                            subtitle: Text(
                              player.stackOfPoints.isNotEmpty && player.stackOfTiles.isNotEmpty ? 'Ρ: ${player.stackOfPoints.last.y} (Δ: ${player.stackOfTiles.last})' : 'Ρ: 0 (Δ: 0)',
                              style: textCol.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
