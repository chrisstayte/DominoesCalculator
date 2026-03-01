import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dominoes/enums/domino_type.dart';
import 'package:dominoes/global/global.dart';

import 'package:dominoes/providers/settings_provider.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:dominoes/screens/widgets/keypad_key.dart';
import 'package:dominoes/screens/widgets/tile_history.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _gapBetweenAreas = 5.0;
  final ScrollController _controller = ScrollController();

  final List<DominoType> _calcHistory = [];

  void _addCalculation(DominoType dominoType) {
    setState(() {
      _calcHistory.insert(0, dominoType);
    });
    _controller.animateTo(
      _controller.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _removeTileHistory(int index) {
    setState(() {
      _calcHistory.removeAt(index);
    });
  }

  void _undoLast() {
    if (_calcHistory.isNotEmpty) {
      setState(() {
        _calcHistory.removeAt(0);
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text(
            'Are you sure you want to clear all entries? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(_calcHistory.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.watch<SettingsProvider>().appAccentColor,
                    borderRadius: BorderRadius.circular(
                      Global.ui.cornerRadius,
                    ),
                  ),
                  alignment: const Alignment(1, 1),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: AutoSizeText(
                      _calcHistory
                          .fold<int>(
                              0,
                              (previousValue, element) =>
                                  previousValue +
                                  (Global.values.dominoValues[element] ??
                                      context
                                          .watch<SettingsProvider>()
                                          .doubleZeroValue))
                          .toString(),
                      minFontSize: 32,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 92,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: _gapBetweenAreas,
              ),
              Container(
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Global.ui.cornerRadius),
                  color: Colors.grey.shade300,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ListView.separated(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemBuilder: (context, index) {
                      return TileHistory(
                        index: index,
                        dominoType: _calcHistory[index],
                        onTap: _removeTileHistory,
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Icon(
                        Icons.add,
                        size: 18,
                      );
                    },
                    itemCount: _calcHistory.length,
                  ),
                ),
              ),
              SizedBox(
                height: _gapBetweenAreas,
              ),
              Expanded(
                flex: 3,
                child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Global.ui.cornerRadius,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              KeypadKey(
                                dominoType: DominoType.one,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.two,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.three,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.four,
                                onTap: _addCalculation,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              KeypadKey(
                                dominoType: DominoType.five,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.six,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.seven,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.eight,
                                onTap: _addCalculation,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              KeypadKey(
                                dominoType: DominoType.nine,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.ten,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.eleven,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.twelve,
                                onTap: _addCalculation,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              KeypadKey(
                                dominoType: DominoType.thirteen,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.fourteen,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.fifteen,
                                onTap: _addCalculation,
                              ),
                              KeypadKey(
                                dominoType: DominoType.blank,
                                onTap: _addCalculation,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
              ),
              SizedBox(
                height: _gapBetweenAreas,
              ),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: _confirmClear,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(
                              Global.ui.cornerRadius,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _gapBetweenAreas,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _undoLast,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            borderRadius: BorderRadius.circular(
                              Global.ui.cornerRadius,
                            ),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.rotateLeft,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _gapBetweenAreas,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          if (kIsWeb) {
                            Navigator.pushNamed(context, '/settings');
                          } else if (!kIsWeb && Platform.isIOS) {
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SettingsScreen(),
                            );
                          } else {
                            Navigator.pushNamed(context, '/settings');
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: HSLColor.fromColor(context
                                    .watch<SettingsProvider>()
                                    .appAccentColor)
                                .withLightness(.4)
                                .toColor(),
                            borderRadius: BorderRadius.circular(
                              Global.ui.cornerRadius,
                            ),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.screwdriverWrench,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
