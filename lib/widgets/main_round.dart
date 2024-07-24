import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tridompoints/widgets/player_overview.dart';
import 'package:tridompoints/widgets/player_score_bar_chart.dart';
import 'package:tridompoints/widgets/positioned_triangle.dart';
import 'package:tridompoints/widgets/start_page.dart';
import 'package:tridompoints/widgets/striced_circle.dart';
import 'package:tridompoints/widgets/triangle.dart';

import '../blocs/bloc_player.dart';
import '../events/event_player.dart';
import '../events/state_player.dart';
import '../models/player.dart';
import '../models/rules.dart';
import 'about.dart';
import 'expandable_fab.dart';
import 'first_round.dart';
import 'last_round.dart';

class MainRound extends StatefulWidget {
  final String title;

  const MainRound({super.key, required this.title});

  @override
  State<MainRound> createState() => _MainRoundState();

  static bool processPlayer(BuildContext context, PlayerState state, int value) {
    if(value == 0x7fffffff) {
      debugPrint("caswi: ERROR in undoLastAction: value is 0x7fffffff");
      return false;
    }
    bool anyActive = false;
    if (state is PlayerLoaded) {
      for (var player in state.players) {
        if (player.isActive) {
          anyActive = true;
          player.retries = 0;
          player.stackOfPoints.add(Point(player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.x : 1,
              player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y + (value) : 0));
          BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: player.id));
          int numberOfTiles = player.stackOfTiles.isNotEmpty ? player.stackOfTiles.last : 0;
          if (player.stackOfPoints.length > 2 &&
              numberOfTiles != Rules.startTiles[state.players.length] &&
              (value == Rules.bridgeValue || value == Rules.hexagonValue || value == Rules.doubleHexagonValue || value == Rules.tripleHexagonValue)) {
            //print("Bonus: $value (${player.stackOfPoints.length}) for ${player.name}; Rounds: ${player.stackOfPoints.last.x}; Number of tiles: $numberOfTiles (${Rules.startTiles[state.players.length]})");
            //continue
          } else if (player.stackOfTiles.isNotEmpty && player.stackOfTiles.last > 1) {
            player.stackOfTiles.add(player.stackOfTiles.last - 1);
            int nextPlayerIndex = (player.id % state.players.length);
            BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.playerChanged, player: state.players[nextPlayerIndex]));
          } else {
            if (player.stackOfTiles.isNotEmpty && player.stackOfTiles.last > 0) {
              player.stackOfTiles.add(player.stackOfTiles.last - 1);
            }
            if (ModalRoute.of(context)?.settings.name != 'LastRound') {
              player.stackOfPoints
                  .add(Point(player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.x : 1, player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y + Rules.finishBonus : Rules.finishBonus));
              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: player.id));
              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.lastRound));
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LastRound(title: 'Tridom Points'),
                  settings: const RouteSettings(name: 'LastRound'),
                ),
              );
            }
          }
          while(player.stackOfTiles.isNotEmpty && player.stackOfTiles.length < player.stackOfPoints.length) {
            player.stackOfTiles.add(player.stackOfTiles.last);
          }
          break;
        }
      }
    }
    if (!anyActive) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('mainRound.no_active_player')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          showCloseIcon: true,
        ),
      );
    }
    return anyActive;
  }

  static void resetAction(BuildContext context, PlayerState state) {
    if (state is PlayerLoaded && state.players.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(4),
            title: Text(context.tr('mainRound.reset')),
            content: Text(context.tr('mainRound.reset_question')),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('mainRound.cancel')),
              ),
              TextButton(
                onPressed: () {
                  state.players.clear();
                  Navigator.of(dialogContext).pop();
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setString('players', '').then((value) {
                      prefs.setString('currentPage', '').then((value) {
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StartPage(title: 'Tridom Points'),
                              settings: const RouteSettings(name: 'StartPage'),
                            ),
                          );
                        }
                      });
                    });
                  });
                },
                child: Text(context.tr('mainRound.confirm')),
              ),
            ],
          );
        },
      );
    } else if (state is PlayerLoaded) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('players', '').then((value) {
          prefs.setString('currentPage', '').then((value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StartPage(title: 'Tridom Points'),
                settings: const RouteSettings(name: 'StartPage'),
              ),
            );
          });
        });
      });
    }
  }

  static void undoLastAction(BuildContext context, PlayerState state) {
    if ((state is! PlayerLoaded) || state.players.isEmpty) {
      debugPrint("caswi: ERROR in undoLastAction: state is not PlayerLoaded or players is empty");
      return;
    }
    List<Player> players = state.players;
    Player? previousPlayer, currentPlayer;
    bool wasLastTile = false;
    bool wasRetry = false;
    bool wasRetryFailed = false;
    bool wasBonus = false;
    bool firstScoreCurrentPlayer = false;
    bool firstScorePreviousPlayer = false;
    int scoreDifferenceCurrentPlayer = 0;
    int scoreDifferencePreviousPlayer = 0;
    int penultimateScoreDifference = 0;
    for (var player in state.players) {
      if (player.isActive) {
        currentPlayer = player;
        if (players.first == player) {
          previousPlayer = players.isNotEmpty ? players.last : null;
        } else {
          previousPlayer = players[players.indexOf(player) - 1];
        }
        break;
      }
    }
    if (currentPlayer == null || previousPlayer == null) {
      debugPrint("caswi: ERROR in undoLastAction: currentPlayer or previousPlayer is null");
      return;
    }
    scoreDifferenceCurrentPlayer =
        currentPlayer.stackOfPoints.length > 1 ? currentPlayer.stackOfPoints.last.y.ceil() - currentPlayer.stackOfPoints[currentPlayer.stackOfPoints.length - 2].y.ceil() : 0x7fffffff;
    scoreDifferencePreviousPlayer =
        previousPlayer.stackOfPoints.length > 1 ? previousPlayer.stackOfPoints.last.y.ceil() - previousPlayer.stackOfPoints[previousPlayer.stackOfPoints.length - 2].y.ceil() : 0x7fffffff;
    penultimateScoreDifference = previousPlayer.stackOfPoints.length > 2 ? previousPlayer.stackOfPoints[previousPlayer.stackOfPoints.length - 2].y.ceil() - previousPlayer.stackOfPoints[previousPlayer.stackOfPoints.length - 3].y.ceil() : 0x7fffffff;
    firstScoreCurrentPlayer = currentPlayer.stackOfPoints.length == 2;
    firstScorePreviousPlayer = previousPlayer.stackOfPoints.length == 2;
    if(currentPlayer.stackOfTiles.isNotEmpty && currentPlayer.stackOfTiles.last == 0) {
      wasLastTile = true;
    }
    if (!firstScoreCurrentPlayer && scoreDifferenceCurrentPlayer == Rules.bridgeValue ||
        scoreDifferenceCurrentPlayer == Rules.hexagonValue ||
        scoreDifferenceCurrentPlayer == Rules.doubleHexagonValue ||
        scoreDifferenceCurrentPlayer == Rules.tripleHexagonValue) {
      wasBonus = true;
    }
    if (!firstScorePreviousPlayer && scoreDifferencePreviousPlayer == Rules.retryFailed) {
      wasRetry = true;
      wasRetryFailed = true;
    } else if (scoreDifferenceCurrentPlayer == Rules.retryFee) {
      wasRetry = true;
    }
    debugPrint("caswi: firstScoreCurrentPlayer: $firstScoreCurrentPlayer; firstScorePreviousPlayer: $scoreDifferencePreviousPlayer ;scoreDifferenceCurrentPlayer: $scoreDifferenceCurrentPlayer; scoreDifferencyPreviousPlayer: $scoreDifferencePreviousPlayer; penultimateScoreDifference: $penultimateScoreDifference;wasBonus: $wasBonus; wasRetry: $wasRetry; wasRetryFailed: $wasRetryFailed; previousName ${previousPlayer.name}; currentName: ${currentPlayer.name};");
    if(wasLastTile) {
      //print("caswi: Wollen Sie den letzten Zug mit $scoreDifferenceCurrentPlayer Punkten für ${currentPlayer.name} rückgängig machen?");
      String postFix = scoreDifferenceCurrentPlayer == Rules.finishBonus ? "=Bonus" : "";
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(context.tr('undo.title')),
            content: Text(context.tr('undo.question', namedArgs: {'name': currentPlayer!.name, 'points': '$scoreDifferenceCurrentPlayer', 'bonus': postFix})),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.no')),
              ),
              TextButton(
                onPressed: () {
                  currentPlayer!.stackOfPoints.removeLast();
                  currentPlayer.stackOfTiles.removeLast();
                  BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: currentPlayer.id));
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.yes')),
              ),
            ],
          );
        },
      );
    }
    else if (wasBonus) {
      //print("caswi: Wollen Sie den Bonus $scoreDifferenceCurrentPlayer für ${currentPlayer.name} rückgängig machen?");
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(context.tr('undo.title')),
            content: Text(context.tr('undo.question', namedArgs: {'name': currentPlayer!.name, 'points': scoreDifferenceCurrentPlayer.toString(), 'bonus': ''})),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.no')),
              ),
              TextButton(
                  onPressed: () {
                    currentPlayer!.stackOfPoints.removeLast();
                    currentPlayer.stackOfTiles.removeLast();
                    BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: currentPlayer.id));
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(context.tr('undo.yes'))),
            ],
          );
        },
      );
    } else if (wasRetryFailed) {
      //print("caswi: Wollen Sie den letzten Zug mit $scoreDifferencePreviousPlayer Punkten ${previousPlayer.name} rückgängig machen?");
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(context.tr('undo.title')),
            content: Text(context.tr('undo.question', namedArgs: {'name': previousPlayer!.name, 'points': scoreDifferencePreviousPlayer.toString(), 'bonus': ''})),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.no')),
              ),
              TextButton(
                onPressed: () {
                  previousPlayer!.stackOfPoints.removeLast();
                  previousPlayer.stackOfTiles.removeLast();
                  previousPlayer.retries = 3;
                  currentPlayer!.isActive = false;
                  previousPlayer.isActive = true;
                  BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: previousPlayer.id));
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.yes')),
              ),
            ],
          );
        },
      );
    } else if (wasRetry) {
      //print("caswi: Wollen Sie den Versuch mit $scoreDifferenceCurrentPlayer Punkten für ${currentPlayer.name} rückgängig machen?");
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(context.tr('undo.title')),
            content: Text(context.tr('undo.question', namedArgs: {'name': currentPlayer!.name, 'points': scoreDifferenceCurrentPlayer.toString(), 'bonus': ''})),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.no')),
              ),
              TextButton(
                onPressed: () {
                  currentPlayer!.stackOfPoints.removeLast();
                  currentPlayer.stackOfTiles.removeLast();
                  currentPlayer.retries--;
                  BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: currentPlayer.id));
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.yes')),
              ),
            ],
          );
        },
      );
    } else {
      //print("caswi: Wollen Sie den letzten Zug mit $scoreDifferencePreviousPlayer Punkten für ${previousPlayer.name} rückgängig machen?");
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(context.tr('undo.title')),
            content: Text(context.tr('undo.question', namedArgs: {'name': previousPlayer!.name, 'points': scoreDifferencePreviousPlayer.toString(), 'bonus': ''})),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.no')),
              ),
              TextButton(
                onPressed: () {
                  previousPlayer!.stackOfPoints.removeLast();
                  previousPlayer.stackOfTiles.removeLast();
                  currentPlayer!.isActive = false;
                  previousPlayer.isActive = true;
                  BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: previousPlayer.id));
                  Navigator.of(dialogContext).pop();
                },
                child: Text(context.tr('undo.yes')),
              ),
            ],
          );
        },
      );
    }
  }

  static void editPlayer(BuildContext context, PlayerState state) {
    if (state is PlayerLoaded) {
      for (var player in state.players) {
        if (player.isActive) {
          var name = player.name;
          var points = player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y.toString() : '0';
          var tiles = player.stackOfTiles.isNotEmpty ? player.stackOfTiles.last.toString() : '0';
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                contentPadding: const EdgeInsets.all(4),
                title: Text(context.tr('mainRound.edit')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TextField for name of player
                    TextField(
                      controller: TextEditingController(text: name),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: context.tr(context.tr("name")),
                      ),
                      onChanged: (value) {
                        player.name = value;
                        BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: player.id));
                      },
                    ),
                    TextField(
                      controller: TextEditingController(text: points),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: context.tr("points"),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        player.stackOfPoints.isNotEmpty
                            ? player.stackOfPoints.last = Point(player.stackOfPoints.last.x, int.tryParse(value) ?? player.stackOfPoints.last.y)
                            : player.stackOfPoints.add(Point(1, int.tryParse(value) ?? 0));
                        BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: player.id));
                      },
                    ),
                    TextField(
                      controller: TextEditingController(text: tiles),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: context.tr("tiles"),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        player.stackOfTiles.isNotEmpty ? player.stackOfTiles.last = int.tryParse(value) ?? player.stackOfTiles.last : player.stackOfTiles.add(int.tryParse(value) ?? 0);
                        BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: player.id));
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }
}

class _MainRoundState extends State<MainRound> {
  final myController = TextEditingController();
  final myFocusNode = FocusNode();
  final rng = Random();
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  final GlobalKey _three = GlobalKey();
  final GlobalKey _four = GlobalKey();
  final GlobalKey _five = GlobalKey();
  final GlobalKey _six = GlobalKey();

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<PlayerBloc>(context);
    double triangleBorderWidth = 2;
    double triangleSideLength = 50 + triangleBorderWidth;
    double triangleHeight = triangleSideLength * sqrt(3) / 2;
    Color stdColor = const Color(0xFFCAB2A0);
    Color stdColor2 = const Color(0xFFCB5959);
    List<List<int>> matchingCorners = [];
    Set<List<int>> uniqueSets = {};
    while (uniqueSets.length < 10) {
      var set = [rng.nextInt(6), rng.nextInt(6), rng.nextInt(6)];
      if (set.toSet().length == set.length) {
        uniqueSets.add(set);
      }
    }
    matchingCorners = uniqueSets.toList();
    return BlocBuilder<PlayerBloc, PlayerState>(builder: (context, state) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: (state is PlayerLoaded && state.players.isNotEmpty && state.players.last.stackOfPoints.isNotEmpty)
                ? Text('${widget.title} - ${context.tr("round")} ${state.players.last.stackOfPoints.last.x}')
                : Text(widget.title),
            actions: [
              // go back to the first round
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.firstRound));
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FirstRound(title: 'Tridom Points'),
                      settings: const RouteSettings(name: 'FirstRound'),
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
              // go forward to the last round
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  if (state is PlayerLoaded) {
                    BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.lastRound));
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LastRound(title: 'Tridom Points'),
                        settings: const RouteSettings(name: 'LastRound'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Column(
                    children: [
                      Showcase(
                          key: _six,
                          title: context.tr('showCase.scoreChartTitle'),
                          description: context.tr('showCase.scoreChartDescription'),
                          onToolTipClick: () {
                            ShowCaseWidget.of(context).next();
                          },
                          child: PlayerScoreBarChart(state: state)),
                      Showcase(
                        key: _one,
                        title: context.tr('showCase.changeCurrentPlayerTitle'),
                        description: context.tr('showCase.changeCurrentPlayerDescription'),
                        onToolTipClick: () {
                          ShowCaseWidget.of(context).next();
                        },
                        child: Showcase(
                          key: _two,
                          title: context.tr("showCase.editPlayerTitle"),
                          description: context.tr("showCase.editPlayerDescription"),
                          onToolTipClick: () {
                            ShowCaseWidget.of(context).next();
                          },
                          child: const PlayerOverview(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(context.tr(
                    'mainRound.enter_points',
                    args: [
                      state is PlayerLoaded && state.players.isNotEmpty
                          ? state.players.firstWhere((player) => player.isActive, orElse: () => Player.simple(name: 'No Active Player', id: -1, color: Colors.grey)).name
                          : 'No Active Player'
                    ],
                  )),
                  const SizedBox(height: 5),
                  TextField(
                    controller: myController,
                    focusNode: myFocusNode,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      label: Text(
                        context.tr("mainRound.points"),
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (value) {
                      MainRound.processPlayer(context, state, int.tryParse(value) ?? 0x7fffffff);
                      myController.clear();
                      myFocusNode.requestFocus();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        if (state is PlayerLoaded) {
                          for (var player in state.players) {
                            if (player.isActive) {
                              player.retries++;
                              if (player.retries <= Rules.retries) {
                                player.stackOfTiles.add(player.stackOfTiles.isNotEmpty ? player.stackOfTiles.last + 1 : 1);
                                player.stackOfPoints.add(Point(player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.x : 1,
                                    player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y + Rules.retryFee : Rules.retryFee));
                                BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.load, id: player.id));
                              } else {
                                player.retries = 0;
                                player.stackOfTiles.add(player.stackOfTiles.isNotEmpty ? player.stackOfTiles.last : 0);
                                player.stackOfPoints.add(Point(player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.x : 1,
                                    player.stackOfPoints.isNotEmpty ? player.stackOfPoints.last.y + Rules.retryFailed : Rules.retryFailed));
                                int nextPlayerIndex = (player.id % state.players.length);
                                BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.playerChanged, player: state.players[nextPlayerIndex]));
                              }
                            }
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              width: 1 * (triangleSideLength + 1.7 * triangleBorderWidth),
                              height: 1.2 * (triangleHeight + triangleBorderWidth) + 20,
                              alignment: Alignment.topLeft,
                              child: Stack(
                                children: [
                                  PositionedTriangle(
                                    position: 'pos11',
                                    triangleSideLength: 50,
                                    triangleBorderWidth: 2,
                                    color: stdColor,
                                    number1: 1,
                                    number2: 2,
                                    number3: 3,
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Showcase(
                                      key: _three,
                                      title: context.tr('showCase.retryTitle'),
                                      description: context.tr('showCase.retryDescription'),
                                      onToolTipClick: () {
                                        ShowCaseWidget.of(context).next();
                                      },
                                      child: StrikedCircleWidget(
                                        color: stdColor2,
                                        size: 40,
                                        strokeWidth: 5,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 50,
                                    left: 18,
                                    child: Text('${Rules.retryFee}'),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Builder(
                            builder: (BuildContext context) {
                              String retriesText = '';
                              int retries = 0;
                              if (state is PlayerLoaded) {
                                for (var player in state.players) {
                                  if (player.isActive) {
                                    retries = player.retries;
                                    if ((Rules.retries - retries) == 0) {
                                      retriesText = context.tr('mainRound.cant_retry', args: ["${Rules.retryFailed}"]);
                                    } else {
                                      retriesText = context.tr('mainRound.retry', args: ["${Rules.retries - retries}"]);
                                    }
                                    break;
                                  }
                                }
                              }
                              if (retries != 0) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: stdColor2,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    retriesText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Wrap(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: GestureDetector(
                              onTap: () {
                                MainRound.processPlayer(context, state, Rules.tripleValues[0]);
                                myFocusNode.requestFocus();
                              },
                              child: Column(
                                children: [
                                  TriangleWidget(
                                    size: triangleSideLength,
                                    triangleBorderWidth: triangleBorderWidth,
                                    color: stdColor,
                                    number1: 0,
                                    number2: 0,
                                    number3: 0,
                                  ),
                                  Text('${Rules.tripleValues[0]}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: GestureDetector(
                              onTap: () {
                                String name = state is PlayerLoaded ? state.players.firstWhere((player) => player.isActive).name : 'No Active Player';
                                bonusMessage(name: name, points: Rules.bridgeValue);
                                MainRound.processPlayer(context, state, Rules.bridgeValue);
                                myFocusNode.requestFocus();
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 3 * (triangleSideLength + 1.7 * triangleBorderWidth),
                                    height: 2 * (triangleHeight + triangleBorderWidth),
                                    alignment: Alignment.topLeft,
                                    child: Showcase(
                                      key: _four,
                                      title: context.tr('showCase.bridgeTitle'),
                                      description: context.tr('showCase.bridgeDescription'),
                                      tooltipPosition: TooltipPosition.top,
                                      onToolTipClick: () {
                                        ShowCaseWidget.of(context).next();
                                      },
                                      child: Stack(
                                        children: [
                                          PositionedTriangle(
                                            position: 'pos11',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor,
                                            number1: matchingCorners[0][0],
                                            number2: matchingCorners[0][1],
                                            number3: matchingCorners[0][2],
                                          ),
                                          PositionedTriangle(
                                            position: 'pos12',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor,
                                            number1: matchingCorners[0][0],
                                            number2: matchingCorners[1][1],
                                            number3: matchingCorners[0][1],
                                          ),
                                          PositionedTriangle(
                                            position: 'pos13',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor,
                                            number1: matchingCorners[1][1],
                                            number2: matchingCorners[2][1],
                                            number3: matchingCorners[0][1],
                                          ),
                                          PositionedTriangle(
                                            position: 'pos14',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor,
                                            number1: matchingCorners[1][1],
                                            number2: matchingCorners[3][1],
                                            number3: matchingCorners[2][1],
                                          ),
                                          PositionedTriangle(
                                            position: 'pos15',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor,
                                            number1: matchingCorners[3][1],
                                            number2: matchingCorners[4][1],
                                            number3: matchingCorners[2][1],
                                          ),
                                          PositionedTriangle(
                                            position: 'pos21',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor,
                                            number1: matchingCorners[0][2],
                                            number2: matchingCorners[0][1],
                                            number3: matchingCorners[5][1],
                                          ),
                                          PositionedTriangle(
                                            position: 'pos22',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor,
                                            number1: matchingCorners[0][1],
                                            number2: matchingCorners[6][1],
                                            number3: matchingCorners[5][1],
                                          ),
                                          PositionedTriangle(
                                            position: 'pos24',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor2,
                                            number1: matchingCorners[2][1],
                                            number2: matchingCorners[7][1],
                                            number3: matchingCorners[6][1],
                                          ),
                                          PositionedTriangle(
                                            position: 'pos25',
                                            triangleSideLength: 50,
                                            triangleBorderWidth: 2,
                                            color: stdColor,
                                            number1: matchingCorners[2][1],
                                            number2: matchingCorners[4][1],
                                            number3: matchingCorners[7][1],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text('${Rules.bridgeValue}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: GestureDetector(
                              onTap: () {
                                String name = state is PlayerLoaded ? state.players.firstWhere((player) => player.isActive).name : 'No Active Player';
                                bonusMessage(name: name, points: Rules.hexagonValue);
                                MainRound.processPlayer(context, state, Rules.hexagonValue);
                                myFocusNode.requestFocus();
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 2 * (triangleSideLength + 1.7 * triangleBorderWidth),
                                    height: 2 * (triangleHeight + triangleBorderWidth),
                                    alignment: Alignment.topLeft,
                                    child: Stack(
                                      children: [
                                        // oben links
                                        PositionedTriangle(
                                          position: 'pos11',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][0],
                                          number2: matchingCorners[0][1],
                                          number3: matchingCorners[0][2],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos12',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][0],
                                          number2: matchingCorners[1][1],
                                          number3: matchingCorners[0][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos13',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[1][1],
                                          number2: matchingCorners[2][1],
                                          number3: matchingCorners[0][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos21',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][2],
                                          number2: matchingCorners[0][1],
                                          number3: matchingCorners[5][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos22',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][1],
                                          number2: matchingCorners[6][1],
                                          number3: matchingCorners[5][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos23',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor2,
                                          number1: matchingCorners[0][1],
                                          number2: matchingCorners[2][1],
                                          number3: matchingCorners[6][1],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('${Rules.hexagonValue}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: GestureDetector(
                              onTap: () {
                                String name = state is PlayerLoaded ? state.players.firstWhere((player) => player.isActive).name : 'No Active Player';
                                bonusMessage(name: name, points: Rules.doubleHexagonValue);
                                MainRound.processPlayer(context, state, Rules.doubleHexagonValue);
                                myFocusNode.requestFocus();
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 3 * (triangleSideLength + 1.7 * triangleBorderWidth),
                                    height: 2 * (triangleHeight + triangleBorderWidth),
                                    alignment: Alignment.topLeft,
                                    child: Stack(
                                      children: [
                                        PositionedTriangle(
                                          position: 'pos11',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][0],
                                          number2: matchingCorners[0][1],
                                          number3: matchingCorners[0][2],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos12',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][0],
                                          number2: matchingCorners[1][1],
                                          number3: matchingCorners[0][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos13',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[1][1],
                                          number2: matchingCorners[2][1],
                                          number3: matchingCorners[0][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos14',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[1][1],
                                          number2: matchingCorners[3][1],
                                          number3: matchingCorners[2][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos15',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[3][1],
                                          number2: matchingCorners[4][1],
                                          number3: matchingCorners[2][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos21',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][2],
                                          number2: matchingCorners[0][1],
                                          number3: matchingCorners[5][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos22',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][1],
                                          number2: matchingCorners[6][1],
                                          number3: matchingCorners[5][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos23',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor2,
                                          number1: matchingCorners[0][1],
                                          number2: matchingCorners[2][1],
                                          number3: matchingCorners[6][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos24',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[2][1],
                                          number2: matchingCorners[7][1],
                                          number3: matchingCorners[6][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos25',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[2][1],
                                          number2: matchingCorners[4][1],
                                          number3: matchingCorners[7][1],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('${Rules.doubleHexagonValue}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: GestureDetector(
                              onTap: () {
                                String name = state is PlayerLoaded ? state.players.firstWhere((player) => player.isActive).name : 'No Active Player';
                                bonusMessage(name: name, points: Rules.tripleHexagonValue);
                                MainRound.processPlayer(context, state, Rules.tripleHexagonValue);
                                myFocusNode.requestFocus();
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 3 * (triangleSideLength + 1.7 * triangleBorderWidth),
                                    height: 3 * (triangleHeight + triangleBorderWidth),
                                    alignment: Alignment.topLeft,
                                    child: Stack(
                                      children: [
                                        PositionedTriangle(
                                          position: 'pos11',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][0],
                                          number2: matchingCorners[0][1],
                                          number3: matchingCorners[0][2],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos12',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][0],
                                          number2: matchingCorners[1][1],
                                          number3: matchingCorners[0][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos13',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[1][1],
                                          number2: matchingCorners[2][1],
                                          number3: matchingCorners[0][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos14',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[1][1],
                                          number2: matchingCorners[3][1],
                                          number3: matchingCorners[2][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos15',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[3][1],
                                          number2: matchingCorners[4][1],
                                          number3: matchingCorners[2][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos21',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][2],
                                          number2: matchingCorners[0][1],
                                          number3: matchingCorners[5][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos22',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[0][1],
                                          number2: matchingCorners[6][1],
                                          number3: matchingCorners[5][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos23',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor2,
                                          number1: matchingCorners[0][1],
                                          number2: matchingCorners[2][1],
                                          number3: matchingCorners[6][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos24',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[2][1],
                                          number2: matchingCorners[7][1],
                                          number3: matchingCorners[6][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos25',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[2][1],
                                          number2: matchingCorners[4][1],
                                          number3: matchingCorners[7][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos32',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[5][1],
                                          number2: matchingCorners[6][1],
                                          number3: matchingCorners[8][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos33',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[6][1],
                                          number2: matchingCorners[9][1],
                                          number3: matchingCorners[8][1],
                                        ),
                                        PositionedTriangle(
                                          position: 'pos34',
                                          triangleSideLength: 50,
                                          triangleBorderWidth: 2,
                                          color: stdColor,
                                          number1: matchingCorners[6][1],
                                          number2: matchingCorners[7][1],
                                          number3: matchingCorners[9][1],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('${Rules.tripleHexagonValue}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

  void bonusMessage({required int points, required String name}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(context.tr('mainRound.bonus', namedArgs: {'name': name, 'points': points.toString()})),
          duration: const Duration(seconds: 5),
          showCloseIcon: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          )),
    );
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      bool? showCaseMainRound = prefs.getBool('showCaseMainRound');
      if (showCaseMainRound == null || showCaseMainRound) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(seconds: 1), () => ShowCaseWidget.of(context).startShowCase([_one, _two, _three, _four, _five, _six]));
        });
        prefs.setBool('showCaseMainRound', false);
      }
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
