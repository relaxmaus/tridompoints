import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tridompoints/widgets/player_overview.dart';
import 'package:tridompoints/widgets/start_page.dart';
import 'package:tridompoints/widgets/triangle.dart';

import '../blocs/bloc_player.dart';
import '../events/event_player.dart';
import '../events/state_player.dart';
import '../models/rules.dart';
import 'about.dart';
import 'main_round.dart';

class FirstRound extends StatefulWidget {
  final String title;

  const FirstRound({super.key, required this.title});

  @override
  State<FirstRound> createState() => _FirstRoundState();
}

class _FirstRoundState extends State<FirstRound> {
  bool showSnackBar = true;
  final GlobalKey _one = GlobalKey();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      bool? showCaseFirstRound = prefs.getBool('showCaseFirstRound');
      if (showCaseFirstRound == null || showCaseFirstRound) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ShowCaseWidget.of(context).startShowCase([_one]);
        });
        prefs.setBool('showCaseFirstRound', false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<PlayerBloc>(context);
    double triangleBorderWidth = 2;
    double triangleSideLength = 50 + triangleBorderWidth;
    Color stdColor = const Color(0xFFCAB2A0);
    final state = context.watch<PlayerBloc>().state;
    if (state is PlayerLoaded && state.players.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (showSnackBar) {
          showSnackBar = false;
          Future.delayed(const Duration(seconds: 2), () {
            if(mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(context.tr('firstRound.text2', args: [(state.players.isNotEmpty) ? "${state.players.last.stackOfTiles.last}" : "???"]),
                        style: const TextStyle(fontSize: 20, color: Colors.yellow)),
                  ),
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(days: 365),
                showCloseIcon: true,
              ),
            );
            }
          });
        }
      });
    }
    return BlocBuilder<PlayerBloc, PlayerState>(builder: (context, state) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              (state is PlayerLoaded && state.players.isNotEmpty) ? '${widget.title} - ${context.tr("round")} ${state.players.last.stackOfPoints.isNotEmpty ? state.players.last.stackOfPoints.last.x : 1}' : widget.title,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const About()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  bool success = MainRound.processPlayer(context, state, 0);
                  if (success) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.mainRound));
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainRound(title: widget.title)),
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
                  Text(context.tr('firstRound.title'), style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 10),
                  Showcase(
                    key: _one,
                    title: context.tr('showCase.selectCurrentPlayerTitle'),
                    description: context.tr('showCase.selectCurrentPlayerDescription'),
                    onToolTipClick: () {
                      ShowCaseWidget.of(context).next();
                    },
                    child: const PlayerOverview(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('firstRound.text1'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: List.generate(6, (index) {
                      int number = index == 0 ? 0 : 6 - index;
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: GestureDetector(
                          onTap: () {
                            bool success = MainRound.processPlayer(context, state, Rules.tripleValues[number] + Rules.startBonusTriple);
                            if (success) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.mainRound));
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => MainRound(title: widget.title)),
                              );
                            }
                          },
                          child: Column(
                            children: [
                              TriangleWidget(
                                size: triangleSideLength,
                                triangleBorderWidth: triangleBorderWidth,
                                color: stdColor,
                                number1: number,
                                number2: number,
                                number3: number,
                              ),
                              Text('${Rules.tripleValues[number]} + ${Rules.startBonusTriple}'),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: context.tr('firstRound.text3'),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (value) {
                      bool success = MainRound.processPlayer(context, state, int.parse(value) + Rules.startBonusNoTriple);
                      if (success) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.mainRound));
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainRound(title: widget.title)),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 500),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              SharedPreferences.getInstance().then((prefs) {
                prefs.setString('players', '').then((value) {
                  prefs.setString('currentPage', '').then((value) {
                    if (state is PlayerLoaded) {
                      state.players.clear();
                    }
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.firstRound));
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
            },
            tooltip: context.tr('startPage.resetPlayerSelection'),
            child: const Text("Reset"),
          ),
        ),
      );
    });
  }
}
