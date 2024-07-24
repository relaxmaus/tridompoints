import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tridompoints/widgets/rules_editor.dart';
import 'package:tridompoints/widgets/winner_page.dart';

import '../blocs/bloc_player.dart';
import '../events/event_player.dart';
import '../events/state_player.dart';
import '../misk.dart';
import '../models/player.dart';
import '../models/rules.dart';
import 'about.dart';
import 'first_round.dart';
import 'last_round.dart';
import 'main_round.dart';

class StartPage extends StatefulWidget {
  final String title;

  const StartPage({super.key, required this.title});

  @override
  StartPageState createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  TextEditingController _nameController = TextEditingController();
  late Color _color;
  late Map<Color, String> _colorMap;
  late List<DropdownMenuItem<Color>> _colorMenuItems;
  bool _colorChanged = false;
  bool _isInitialized = false;
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();

/*List<DropdownMenuItem<Color>> get _colorMenuItems {
    List<DropdownMenuItem<Color>> items = [];
    _colorMap.forEach((color, name) {
      items.add(
        DropdownMenuItem(
          value: color,
          child: Container(
            color: color,
            child: Text(
              name,
              style: TextStyle(color: getHighContrastComplementaryColor(color)),
            ),
          ),
        ),
      );
    });
    return items;
  }*/

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(builder: (context, state) {
      if (state is PlayerLoaded) {
        var colorMenuItems = _colorMenuItems;
        bool isOk = colorMenuItems.where((DropdownMenuItem<Color> item) {
              return item.value == _color;
            }).length ==
            1;
        if (!isOk) {
          /*debugPrint('Tridom: Is color in list is ok?: $isOk (${colorMenuItems.where((DropdownMenuItem<Color> item) {
            return item.value == _color;
          }).length})');*/
          try {
            _colorMenuItems.removeWhere((DropdownMenuItem<Color> item) {
              return item.value?.value == _color.value;
            });
            _color = _colorMenuItems.isNotEmpty ? _colorMenuItems.first.value! : Colors.white;
            isOk = colorMenuItems.where((DropdownMenuItem<Color> item) {
                  //debugPrint('Tridom: item color ${colorToName(item.value!)} == ${colorToName(_color)}');
                  return item.value == _color;
                }).length ==
                1;
            if (!isOk) {
              debugPrint('Tridom: error changing color');
            }
          } catch (e) {
            debugPrint('Tridom: Error changing color: $e');
          }
        }
        /*debugPrint('Tridom: Is color in list is ok?: $isOk (${colorMenuItems.where((DropdownMenuItem<Color> item) {
          return item.value == _color;
        }).length})');*/
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                Showcase(
                  key: _one,
                  title: context.tr('showCase.languageTitle'),
                  description: context.tr('showCase.languageDescription'),
                  targetShapeBorder: const CircleBorder(),
                  onToolTipClick: () {
                    ShowCaseWidget.of(context).next();
                  },
                  child: DropdownButton<Locale>(
                    onChanged: (Locale? newValue) {
                      if (newValue != null) {
                        _changeLanguage(newValue);
                      }
                    },
                    items: <Locale>[const Locale('en'), const Locale('de')].map<DropdownMenuItem<Locale>>((Locale value) {
                      return DropdownMenuItem<Locale>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ),
                Showcase(
                  key: _two,
                  title: context.tr('showCase.rulesTitle'),
                  description: context.tr('showCase.rulesDescription'),
                  onToolTipClick: () {
                    ShowCaseWidget.of(context).next();
                  },
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RulesEditor()));
                    },
                    tooltip: 'Regeln bearbeiten',
                  ),
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
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        context.tr('startPage.enterPlayers'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Visibility(
                        visible: state.players.length < Rules.maxPlayers,
                        child: buildNameInputField(state),
                      ),
                      Visibility(
                        visible: state.players.length < Rules.maxPlayers,
                        child: DropdownButton<Color>(
                          value: _color,
                          items: colorMenuItems,
                          onChanged: (Color? value) {
                            setState(() {
                              _color = value!;
                              _colorChanged = true;
                              if (_name.isNotEmpty) {
                                savePlayerInfo(_name, _color);
                              }
                            });
                          },
                        ),
                      ),
                      Visibility(
                        visible: state.players.length < Rules.maxPlayers,
                        child: ElevatedButton(
                          onPressed: () {
                            _colorChanged = false;
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              Player newPlayer = Player.simple(name: _name, color: _color, id: state.count + 1);
                              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.playerAdded, player: newPlayer));
                              savePlayerInfo(_name, _color);
                              //_colorMap.remove(newPlayer.color);
                              //_color = _colorMap.keys.first;
                              _colorMenuItems.removeWhere((DropdownMenuItem<Color> item) {
                                return item.value?.value == _color.value;
                              });
                              _color = _colorMenuItems.isNotEmpty ? _colorMenuItems.first.value! : Colors.white;
                              _formKey.currentState!.reset();
                              _nameController.text = '';
                            }
                          },
                          child: Text(
                            context.tr('startPage.addPlayer'),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
                        child: ElevatedButton(
                          onPressed: state.players.length >= 2
                              ? () {
                                  _colorChanged = false;
                                  if (_nameController.text.isNotEmpty) {
                                    Player newPlayer = Player.simple(name: _nameController.text, color: _color, id: state.count + 1);
                                    BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.playerAdded, player: newPlayer));
                                  }
                                  BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.startGame));
                                  BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.firstRound));
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const FirstRound(title: 'Tridom Points')),
                                  );
                                }
                              : null,
                          child: Text(
                            context.tr('startPage.startGame'),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 30,
                          right: 30,
                        ),
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 400),
                            child: Column(
                              children: [
                                _buildPlayerList(state.players),
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('players', '').then((value) {
                    prefs.setString('currentPage', '').then((value) {
                      state.players.clear();
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
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    });
  }

  Widget buildNameInputField(PlayerState state) {
    return FutureBuilder<Map<String, Color>>(
      future: getPlayerNamesAndColors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final playerNamesAndColors = snapshot.data ?? {};
        final playerNames = playerNamesAndColors.keys.toList();
        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty || textEditingValue.text.length < 3) {
              return const Iterable<String>.empty();
            }
            return playerNames.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            //debugPrint('You just selected $selection and color ${colorToName(playerNamesAndColors[selection]!)}');
            setState(() {
              _nameController.text = selection;
              _name = selection;
              _color = playerNamesAndColors[selection] ?? _colorMap.keys.first;
              _colorChanged = false;
              Player newPlayer = Player.simple(name: _name, color: _color, id: state.count + 1);
              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.playerAdded, player: newPlayer));
              //_colorMap.remove(newPlayer.color);
              //_color = _colorMap.keys.first;
              _colorMenuItems.removeWhere((DropdownMenuItem<Color> item) {
                return item.value?.value == _color.value;
              });
              _color = _colorMap.isNotEmpty ? _colorMap.keys.first : Colors.white;
              _formKey.currentState!.reset();
              _nameController.text = '';
              //debugPrint('Tridom: selected name $_name; included color ${colorToName(_color)}');
            });
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            _nameController = textEditingController;
            if (_colorChanged) {
              textEditingController.text = _name;
            }
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr("startPage.enterName");
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) _name = value.trim();
              },
              onChanged: (value) {
                if (value.length > 2) {
                  _name = value.trim();
                }
              },
              onTapOutside: (value) {
                if (_name.isNotEmpty) {
                  savePlayerInfo(_name, _color);
                }
              },
            );
          },
        );
      },
    );
  }

  String colorToName(Color color) {
    bool isDe = context.locale.languageCode == 'de';
    Map<int, String> colorMap = {
      Colors.red.value: isDe ? 'Rot' : 'Red',
      Colors.yellow.value: isDe ? 'Gelb' : 'Yellow',
      Colors.blue.value: isDe ? 'Blau' : 'Blue',
      Colors.green.value: isDe ? 'Grün' : 'Green',
      Colors.purple.value: isDe ? 'Lila' : 'Purple',
      Colors.orange.value: isDe ? 'Orange' : 'Orange',
      Colors.pink.value: isDe ? 'Rosa' : 'Pink',
      Colors.teal.value: isDe ? 'Türkisblau' : 'Teal',
      Colors.brown.value: isDe ? 'Braun' : 'Brown',
      Colors.grey.value: isDe ? 'Grau' : 'Grey',
      Colors.cyan.value: isDe ? 'Cyan' : 'Cyan',
      Colors.lime.value: isDe ? 'Limette' : 'Lime',
      Colors.amber.value: isDe ? 'Bernstein' : 'Amber',
      Colors.indigo.value: isDe ? 'Indigo' : 'Indigo',
      Colors.black.value: isDe ? 'Schwarz' : 'Black',
      Colors.white.value: isDe ? 'Weiß' : 'White',
    };
    return colorMap[color.value] ?? color.toString();
  }

  @override
  void didChangeDependencies() {
    if (mounted) {
      super.didChangeDependencies();
      if (!_isInitialized) {
        _initializeColorMap();
        _initializeColorMenuItems();
        _color = _colorMenuItems.isNotEmpty ? _colorMenuItems.first.value! : Colors.white;
        _isInitialized = true;
      }
    }
  }

  Future<Map<String, Color>> getPlayerNamesAndColors() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playersJson = prefs.getString('playersInfo');
    Map<String, Color> playerNamesAndColors = {};
    if (playersJson != null) {
      final List<dynamic> playersList = json.decode(playersJson);
      for (var player in playersList) {
        String name = player['name'];
        String hexColorString = player['color'];
        Color color = hexToColor(hexColorString);
        playerNamesAndColors[name] = color;
      }
    }
    return playerNamesAndColors;
  }

  Color hexToColor(String hexColorString) {
    return Color(int.parse(hexColorString));
  }

  @override
  void initState() {
    super.initState();
    //debugPrint('Tridom: StartPageState.initState');
    SharedPreferences.getInstance().then((prefs) {
      bool? showCaseStartPage = prefs.getBool('showCaseStartPage');
      if (showCaseStartPage == null || showCaseStartPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          prefs.setBool('showCaseStartPage', false);
          Future.delayed(const Duration(milliseconds: 500), () {
            ShowCaseWidget.of(context).startShowCase([_one, _two]);
          });
        });
      }
      String? playersJsonString = prefs.getString('players');
      //debugPrint("caswi: players = $playersJsonString");
      String? currentPage = prefs.getString('currentPage');
      //debugPrint("caswi: currentPage = $currentPage");
      if (playersJsonString != null && playersJsonString.isNotEmpty && currentPage != null && currentPage.isNotEmpty && currentPage != 'startPage') {
        try {
          List<dynamic> playersJson = jsonDecode(playersJsonString);
          List players = playersJson.map((playerJson) => Player.fromJson(playerJson as Map<String, dynamic>)).toList();
          if (players.isNotEmpty) {
            for (Player player in players) {
              context.read<PlayerBloc>().add(PlayerEvent(type: PlayerEventType.playerAdded, player: player));
            }
            if (currentPage == 'firstRound') {
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
            } else if (currentPage == 'startPage') {
              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.startPage));
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StartPage(
                    title: 'Tridom Points',
                  ),
                  settings: const RouteSettings(name: 'startPage'),
                ),
              );
            } else if (currentPage == 'mainRound') {
              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.mainRound));
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainRound(
                    title: 'Tridom Points',
                  ),
                  settings: const RouteSettings(name: 'mainRound'),
                ),
              );
            } else if (currentPage == 'lastRound') {
              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.lastRound));
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LastRound(
                    title: 'Tridom Points',
                  ),
                  settings: const RouteSettings(name: 'lastRound'),
                ),
              );
            } else if (currentPage == 'winnerPage') {
              BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.pageChanged, pageID: PageID.winnerPage));
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const WinnerPage(
                    title: 'Tridom Points',
                  ),
                  settings: const RouteSettings(name: 'winnerPage'),
                ),
              );
            } else {
              debugPrint('Tridom: Current page is unknown $currentPage');
            }
          }
        } catch (e) {
          debugPrint("Error parsing players JSON: $e");
        }
      }
    });
    context.read<PlayerBloc>().add(PlayerEvent(type: PlayerEventType.load));
  }

  void savePlayerInfo(String name, Color color) async {
    //debugPrint('Tridom: savePlayerInfo $name, ${colorToName(color)}');
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> playersList = [];

    String? playersJson = prefs.getString('playersInfo');
    if (playersJson != null) {
      playersList = List<Map<String, dynamic>>.from(json.decode(playersJson));
    }

    int index = playersList.indexWhere((player) => player['name'] == name);
    if (index != -1) {
      playersList[index] = {
        'name': name,
        'color': color.value.toString(),
      };
    } else {
      playersList.add({
        'name': name,
        'color': color.value.toString(),
      });
    }
    await prefs.setString('playersInfo', json.encode(playersList));
  }

  Widget _buildPlayerList(List<Player> players) {
    return players.isEmpty
        ? Text(
            context.tr('startPage.noPlayers'),
            style: const TextStyle(fontSize: 18),
          )
        : Expanded(
            child: ListView(
              children: players.map((player) {
                TextStyle textCol = TextStyle(
                  color: getHighContrastComplementaryColor(player.color),
                );
                return Container(
                  width: 180,
                  color: player.color,
                  child: ListTile(
                    title: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(
                        player.name,
                        style: textCol,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          players.remove(player);
                          BlocProvider.of<PlayerBloc>(context).add(PlayerEvent(type: PlayerEventType.playerRemoved, player: player));
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          );
  }

  void _changeLanguage(Locale newValue) {
    _isInitialized = false;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('language', newValue.languageCode);
    });
    EasyLocalization.of(context)!.setLocale(newValue);
  }

  void _initializeColorMap() {
    _colorMap = {
      Colors.red: colorToName(Colors.red),
      Colors.yellow: colorToName(Colors.yellow),
      Colors.blue: colorToName(Colors.blue),
      Colors.green: colorToName(Colors.green),
      Colors.purple: colorToName(Colors.purple),
      Colors.orange: colorToName(Colors.orange),
      Colors.pink: colorToName(Colors.pink),
      Colors.teal: colorToName(Colors.teal),
      Colors.brown: colorToName(Colors.brown),
      Colors.grey: colorToName(Colors.grey),
      Colors.cyan: colorToName(Colors.cyan),
      Colors.lime: colorToName(Colors.lime),
      Colors.amber: colorToName(Colors.amber),
      Colors.indigo: colorToName(Colors.indigo),
      Colors.black: colorToName(Colors.black),
      Colors.white: colorToName(Colors.white),
    };
  }

  void _initializeColorMenuItems() {
    _colorMenuItems = _colorMap.entries.map((entry) {
      return DropdownMenuItem<Color>(
        value: entry.key,
        child: Container(
          color: entry.key,
          child: Text(
            entry.value,
            style: TextStyle(color: getHighContrastComplementaryColor(entry.key)),
          ),
        ),
      );
    }).toList();
  }
}
