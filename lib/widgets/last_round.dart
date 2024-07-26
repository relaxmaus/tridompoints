import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tridompoints/widgets/description.dart';
import 'package:tridompoints/widgets/main_round.dart';
import 'package:tridompoints/widgets/player_overview.dart';
import 'package:tridompoints/widgets/player_score_bar_chart.dart';
import 'package:tridompoints/widgets/winner_page.dart';

import '../blocs/bloc_player.dart';
import '../events/event_player.dart';
import '../events/state_player.dart';
import '../models/rules.dart';
import 'about.dart';
import 'expandable_fab.dart';
import 'first_round.dart';

class LastRound extends StatefulWidget {
  final String title;

  const LastRound({super.key, required this.title});

  @override
  State<LastRound> createState() => _LastRoundState();
}

class _LastRoundState extends State<LastRound> {
  final myController = TextEditingController();
  final myFocusNode = FocusNode();
  final rng = Random();
  final GlobalKey _one = GlobalKey();
  final GlobalKey _five = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(myFocusNode);
    });
    SharedPreferences.getInstance().then((prefs) {
      bool? showCaseLastRound = prefs.getBool('showCaseLastRound');
      if (showCaseLastRound == null || showCaseLastRound) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ShowCaseWidget.of(context).startShowCase([_one]);
        });
        prefs.setBool('showCaseLastRound', false);
      }
    });
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<PlayerBloc>(context);
    Set<List<int>> uniqueSets = {};
    while (uniqueSets.length < 10) {
      var set = [rng.nextInt(6), rng.nextInt(6), rng.nextInt(6)];
      if (set.toSet().length == set.length) {
        uniqueSets.add(set);
      }
    }
    return BlocBuilder<PlayerBloc, PlayerState>(builder: (context, state) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: (state is PlayerLoaded && state.players.isNotEmpty && state.players.last.stackOfPoints.isNotEmpty)
                ? Text('${widget.title} - ${context.tr("round")} ${state.players.last.stackOfPoints.isNotEmpty ? state.players.last.stackOfPoints.last.x : 1}')
                : Text(widget.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.mainRound));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainRound(
                        title: 'Tridom Points',
                      ),
                      settings: const RouteSettings(name: 'MainRound'),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const About()));
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(context.tr('lastRound.title'), style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      PlayerScoreBarChart(state: state),
                      const PlayerOverview(),
                    ],
                  ),
                  Description(
                    description: context.tr('lastRound.description'),
                  ),
                  Text(
                    context.tr('lastRound.sets'),
                    style: const TextStyle(fontSize: 18),
                    softWrap: true,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: myController,
                    focusNode: myFocusNode,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: context.tr("lastRound.points"),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (value) {
                      MainRound.processPlayer(context, state, int.tryParse(value) ?? 0x7fffffff);
                      myController.clear();
                      myFocusNode.requestFocus();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF548824),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      if (state is PlayerLoaded) {
                        bool hasPlayerReachedFinishMinimum = state.players.any((player) => player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y >= Rules.finishMinimum : false);
                        if (hasPlayerReachedFinishMinimum) {
                          BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.winnerPage));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WinnerPage(title: context.tr("lastRound.winners")),
                              settings: const RouteSettings(name: 'WinnerPage'),
                            ),
                          );
                        } else {
                          for (var player in state.players) {
                            player.stackOfTiles.add(Rules.startTiles[state.players.length]);
                            player.stackOfPoints.add(Point(player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.x + 1 : 1, player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y : 0));
                            player.setActive(false);
                          }
                          BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.firstRound));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FirstRound(
                                title: 'Tridom Points',
                              ),
                              settings: const RouteSettings(name: 'FirstRound'),
                            ),
                          );
                        }
                      }
                    },
                    child: Showcase(
                      key: _one,
                      title: context.tr('showCase.finishRoundTitle'),
                      description: context.tr('showCase.finishRoundDescription'),
                      onToolTipClick: () {
                        ShowCaseWidget.of(context).next();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.casino,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    state.players.any((player) => player.stackOfPoints.isNotEmpty && player.stackOfPoints.last.y >= Rules.finishMinimum)
                                        ? context.tr('lastRound.toWinner')
                                        : context.tr('lastRound.newRound'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.casino_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 500),
                ],
              ),
            ),
          ),
          floatingActionButton: ExpandableFab(
            distance: 112,
            showCaseKey: _five,
            children: [
              FloatingActionButton(
                onPressed: () => _menuAction(context, 0),
                heroTag: 'undoActionButton',
                child: Text(
                  context.tr('mainRound.undo'),
                  textAlign: TextAlign.center,
                ), //
              ),
              FloatingActionButton(
                onPressed: () => _menuAction(context, 1),
                heroTag: 'restartActionButton',
                child: Text(
                  context.tr('mainRound.restart'),
                  textAlign: TextAlign.center,
                ), //
              ),
            ],
          ),
        ),
      );
    });
  }

  void _menuAction(BuildContext context, int index) {
    BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.firstRound));
    PlayerState state = BlocProvider.of<PlayerBloc>(context).state;
    if (state is PlayerLoaded) {
      if (index == 0) {
        MainRound.undoLastAction(context, state);
      } else if (index == 1) {
        MainRound.resetAction(context, state);
      }
    }
  }
}
