import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tridompoints/models/rules.dart';

class RulesEditor extends StatefulWidget {
  const RulesEditor({super.key});

  @override
  RulesEditorState createState() => RulesEditorState();
}

class RulesEditorState extends State<RulesEditor> {
  final TextEditingController _maxPlayersController = TextEditingController();
  final TextEditingController _startBonusControllerTriple = TextEditingController();
  final TextEditingController _startBonusControllerNoTriple = TextEditingController();
  final TextEditingController _finishMinimum = TextEditingController();
  final TextEditingController _finishBonusController = TextEditingController();
  final TextEditingController _bridgeValueController = TextEditingController();
  final TextEditingController _hexagonValueController = TextEditingController();
  final TextEditingController _doubleHexagonValueController = TextEditingController();
  final TextEditingController _tripleHexagonValueController = TextEditingController();
  final TextEditingController _maxRetriesController = TextEditingController();
  final TextEditingController _retryFeeController = TextEditingController();
  final TextEditingController _retryFailedController = TextEditingController();
  List<TextEditingController> _startTilesControllers = [];
  List<TextEditingController> _tripleValuesControllers = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await Rules.loadPreferences();
    _maxPlayersController.text = Rules.maxPlayers.toString();
    _startBonusControllerTriple.text = Rules.startBonusTriple.toString();
    _startBonusControllerNoTriple.text = Rules.startBonusNoTriple.toString();
    _finishMinimum.text = Rules.finishMinimum.toString();
    _finishBonusController.text = Rules.finishBonus.toString();
    _bridgeValueController.text = Rules.bridgeValue.toString();
    _hexagonValueController.text = Rules.hexagonValue.toString();
    _doubleHexagonValueController.text = Rules.doubleHexagonValue.toString();
    _tripleHexagonValueController.text = Rules.tripleHexagonValue.toString();
    _maxRetriesController.text = Rules.retries.toString();
    _retryFeeController.text = Rules.retryFee.toString();
    _retryFailedController.text = Rules.retryFailed.toString();
    setState(() {
      _startTilesControllers = Rules.startTiles.map((tile) => TextEditingController(text: tile.toString())).toList();
      _tripleValuesControllers = Rules.tripleValues.map((value) => TextEditingController(text: value.toString())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('editRules.title')),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              title: TextField(
                controller: _maxPlayersController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.maxPlayers'),
                    softWrap: true,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.maxPlayers = int.tryParse(value) ?? Rules.maxPlayers;
                  Rules.savePreferences().then((_) {
                    // resize Rules.startTiles
                    if (Rules.maxPlayers + 1 > Rules.startTiles.length) {
                      Rules.startTiles.addAll(List<int>.generate(Rules.maxPlayers + 1 - Rules.startTiles.length, (index) => 0));
                    } else if (Rules.maxPlayers + 1 < Rules.startTiles.length) {
                      Rules.startTiles.removeRange(Rules.maxPlayers + 1, Rules.startTiles.length);
                    }
                    if (mounted) {
                      setState(() {
                        _startTilesControllers = Rules.startTiles.map((tile) => TextEditingController(text: tile.toString())).toList();
                      });
                    }
                  });
                },
              ),
            ),
            ..._buildStartTilesFields(),
            ListTile(
              title: TextField(
                controller: _startBonusControllerTriple,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.startBonus'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.startBonusTriple = int.tryParse(value) ?? Rules.startBonusTriple;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _startBonusControllerNoTriple,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.startBonusNoTriple'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.startBonusNoTriple = int.tryParse(value) ?? Rules.startBonusNoTriple;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _finishMinimum,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.finishMinimum'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.finishMinimum = int.tryParse(value) ?? Rules.finishMinimum;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _finishBonusController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.finishBonus'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.finishBonus = int.tryParse(value) ?? Rules.finishBonus;
                  Rules.savePreferences();
                },
              ),
            ),
            ..._buildTripleValuesFields(),
            ListTile(
              title: TextField(
                controller: _bridgeValueController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.bridgeValue'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.bridgeValue = int.tryParse(value) ?? Rules.bridgeValue;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _hexagonValueController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.hexagonValue'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.hexagonValue = int.tryParse(value) ?? Rules.hexagonValue;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _doubleHexagonValueController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.doubleHexagonValue'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.doubleHexagonValue = int.tryParse(value) ?? Rules.doubleHexagonValue;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _tripleHexagonValueController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.tripleHexagonValue'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.tripleHexagonValue = int.tryParse(value) ?? Rules.tripleHexagonValue;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _maxRetriesController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.maxRetries'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.retries = int.tryParse(value) ?? Rules.retries;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _retryFeeController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.retryFee'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.retryFee = int.tryParse(value) ?? Rules.retryFee;
                  Rules.savePreferences();
                },
              ),
            ),
            ListTile(
              title: TextField(
                controller: _retryFailedController,
                decoration: InputDecoration(
                  label: Text(
                    context.tr('editRules.retryFailed'),
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  Rules.retryFailed = int.tryParse(value) ?? Rules.retryFailed;
                  Rules.savePreferences();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.close),
        ),
      ),
    );
  }

  List<Widget> _buildStartTilesFields() {
    return List<Widget>.generate(_startTilesControllers.length, (index) {
      if (index < 2) return Container(); // will not show the first two fields
      return ListTile(
        title: TextField(
          controller: _startTilesControllers[index],
          decoration: InputDecoration(
            label: Text(
              context.tr('editRules.tilesPerPlayer', args: ['$index']),
              softWrap: true,
              maxLines: 2,
            ),
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            int? newValue = int.tryParse(value);
            if (newValue != null) {
              Rules.startTiles[index] = newValue;
              Rules.savePreferences();
            }
          },
        ),
      );
    }).where((widget) => widget != Container()).toList(); // remove empty containers
  }

  List<Widget> _buildTripleValuesFields() {
    return List<Widget>.generate(_tripleValuesControllers.length, (index) {
      return ListTile(
        title: TextField(
          controller: _tripleValuesControllers[index],
          decoration: InputDecoration(
            label: Text(
              context.tr('editRules.tripleValue', args: ['$index']),
              softWrap: true,
              maxLines: 2,
            ),
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            int? newValue = int.tryParse(value);
            if (newValue != null) {
              Rules.tripleValues[index] = newValue;
              Rules.savePreferences();
            }
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _maxPlayersController.dispose();
    _startBonusControllerTriple.dispose();
    _finishMinimum.dispose();
    _finishBonusController.dispose();
    _bridgeValueController.dispose();
    _hexagonValueController.dispose();
    _doubleHexagonValueController.dispose();
    _tripleHexagonValueController.dispose();
    _maxRetriesController.dispose();
    _retryFeeController.dispose();
    _retryFailedController.dispose();
    for (var controller in _startTilesControllers) {
      controller.dispose();
    }
    for (var controller in _tripleValuesControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
