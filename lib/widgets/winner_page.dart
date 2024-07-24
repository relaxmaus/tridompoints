import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/bloc_player.dart';
import '../events/event_player.dart';
import '../events/state_player.dart';
import '../misk.dart';
import '../models/player.dart';
import '../models/rules.dart';
import 'about.dart';
import 'first_round.dart';

class WinnerPage extends StatefulWidget {
  final String title;
  const WinnerPage({super.key, required this.title});

  @override
  State<WinnerPage> createState() => _WinnerPageState();
}

class _WinnerPageState extends State<WinnerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(builder: (context, state) {
      List<Player> sortedPlayers = [];
      if (state is PlayerLoaded) {
        sortedPlayers = List.from(state.players)..sort((a, b) => b.stackOfPoints.isNotEmpty ? b.stackOfPoints.last.y.compareTo(a.stackOfPoints.last.y) : 0);
      }
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const About()));
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text( context.tr("winnerPage.congratulations", args: [(sortedPlayers.isNotEmpty ? sortedPlayers.first.name : "")]),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedPlayers.length,
                    itemBuilder: (context, index) {
                      Color backgroundColor = sortedPlayers[index].color;
                      Color textColor = getHighContrastComplementaryColor(backgroundColor);
                      return Container(
                        color: backgroundColor,
                        child: ListTile(
                          title: Text(
                            sortedPlayers[index].name,
                            style: TextStyle(
                              fontSize: 24,
                              color: textColor,
                            ),
                          ),
                          trailing: Text(
                            '${sortedPlayers[index].stackOfPoints.isNotEmpty ? sortedPlayers[index].stackOfPoints.last.y : 0} ${context.tr('points')}',
                            style: TextStyle(
                              fontSize: 24,
                              color: textColor,
                            ),
                          ),
                          leading: index == 0 ? RotationTransition(
                            turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
                            child: Icon(
                              Icons.star,
                              color: textColor,
                              size: 30,
                            ),) : const Icon(
                            Icons.star,
                            color:Colors.grey,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  )
                ),
              ],
            ),
          ),
          floatingActionButton: GestureDetector(
            onTap: () => startNewGame(context, sortedPlayers),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                FloatingActionButton(
                  onPressed: () => startNewGame(context, sortedPlayers),
                  tooltip: context.tr('winnerPage.newGame'),
                  child: const Icon(Icons.refresh),
                ),
                Positioned(
                  top: 3,
                  child: Text(context.tr("winnerPage.newGame1"), style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void startNewGame(BuildContext context, List<Player> players) {
    for (var player in players) {
      player.stackOfPoints.clear();
      player.stackOfPoints.add(const Point(1, 0));
      player.stackOfTiles.clear();
      player.stackOfTiles.add(Rules.startTiles[players.length]);
      player.isActive = false;
    }
    // Navigieren zur FirstRound-Seite
    BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID:PageID.firstRound));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const FirstRound(
          title: 'Tridom Points',
        ),
      ),
    );
  }
}
