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
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness:
            Brightness.dark //or set color with: Color(0xFF0000FF)
        ));
    return Scaffold(
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
                        onTap: () => setState(_calcHistory.clear),
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
                        onTap: () => Navigator.pushNamed(context, '/settings'),
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
                    // const SizedBox(
                    //   width: 5,
                    // ),
                    // Expanded(
                    //   child: GestureDetector(
                    //     onTap: () async {
                    //       await Navigator.pushNamed(context, '/camera');
                    //     },
                    //     child: Container(
                    //       decoration: BoxDecoration(
                    //         color: HSLColor.fromColor(context
                    //                 .watch<SettingsProvider>()
                    //                 .appAccentColor)
                    //             .withLightness(.4)
                    //             .toColor(),
                    //         borderRadius: BorderRadius.circular(
                    //           Global.ui.cornerRadius,
                    //         ),
                    //       ),
                    //       child: const Center(
                    //         child: Icon(
                    //           Icons.camera_alt_rounded,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
