import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dominoes/enums/domino_type.dart';
import 'package:dominoes/global/global.dart';

import 'package:dominoes/providers/settings_provider.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:dominoes/screens/widgets/keypad_key.dart';
import 'package:flutter/cupertino.dart';
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

  List<DominoType> _calcHistory = [];

  void addCalculation(DominoType dominoType) {
    setState(() {
      _calcHistory.insert(0, dominoType);
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
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: context
                                    .watch<SettingsProvider>()
                                    .appAccentColor,
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
                                              previousValue + 1)
                                      .toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 52,
                                  ),
                                ),
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
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.two,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.three,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.four,
                                            onTap: addCalculation,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          KeypadKey(
                                            dominoType: DominoType.five,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.six,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.seven,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.eight,
                                            onTap: addCalculation,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          KeypadKey(
                                            dominoType: DominoType.nine,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.ten,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.eleven,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.twelve,
                                            onTap: addCalculation,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          KeypadKey(
                                            dominoType: DominoType.thirteen,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.fourteen,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.fifteen,
                                            onTap: addCalculation,
                                          ),
                                          KeypadKey(
                                            dominoType: DominoType.custom,
                                            onTap: addCalculation,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: _gapBetweenAreas,
                    ),
                    Container(
                      width: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(Global.ui.cornerRadius),
                          color: Colors.grey.shade300,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListView.separated(
                            reverse: true,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _calcHistory.removeAt(index),
                                ),
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    color: Colors.white,
                                  ),
                                  child: Center(
                                    child: Text('test'),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return Icon(
                                Icons.add,
                                size: 18,
                              );
                            },
                            itemCount: _calcHistory.length,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                        onTap: () async {
                          if (Platform.isIOS) {
                            showCupertinoModalBottomSheet(
                                context: context,
                                builder: (context) => const SettingsScreen());
                          } else {
                            Navigator.pushNamed(context, '/settings');
                            // DraggableScrollableController controller =
                            //     new DraggableScrollableController();
                            // await showModalBottomSheet(
                            //   backgroundColor: Colors.transparent,
                            //   isScrollControlled: true,
                            //   context: context,
                            //   builder: (context) => DraggableScrollableSheet(
                            //     controller: controller,
                            //     builder: ((context, scrollController) =>
                            //         SettingsScreen(
                            //           controller: scrollController,
                            //         )),
                            //   ),
                            // );
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
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {}),
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
                            child: Icon(
                              Icons.camera_alt_rounded,
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
    );
  }
}
