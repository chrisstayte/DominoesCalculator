import 'package:auto_size_text/auto_size_text.dart';
import 'package:dominoes/global/global.dart';
import 'package:dominoes/models/calc_list_item.dart';
import 'package:dominoes/models/tile_enum.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:dominoes/screens/settings_screen.dart';
import 'package:flutter/material.dart';
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
  List<CalcListItem> calcListItems = [];

  @override
  void initState() {
    calcListItems.add(CalcListItem(title: '1', tile: Tile.one));
    calcListItems.add(CalcListItem(title: '2', tile: Tile.two));
    calcListItems.add(CalcListItem(title: '3', tile: Tile.three));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     'Domino Counter',
      //   ),
      //   actions: [
      //     IconButton(
      //       onPressed: () {},
      //       icon: FaIcon(
      //         FontAwesomeIcons.gear,
      //       ),
      //     )
      //   ],
      // ),
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
                                  calcListItems
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
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: context
                                      .watch<SettingsProvider>()
                                      .appAccentColor,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(
                                    Global.ui.cornerRadius),
                              ),
                            ),
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
                          color: HSLColor.fromColor(context
                                  .watch<SettingsProvider>()
                                  .appAccentColor)
                              .withLightness(.9)
                              .toColor(),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListView.separated(
                            reverse: true,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => setState(() {
                                  calcListItems.removeAt(index);
                                }),
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    color: Colors.white,
                                  ),
                                  child: Center(
                                    child: Text(calcListItems[index].title),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return Icon(Icons.add);
                            },
                            itemCount: calcListItems.length,
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
                        onTap: () => setState(() {
                          calcListItems.clear();
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(
                              25.0,
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
                        onTap: () {
                          showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SettingsScreen());
                          // Navigator.pushNamed(context, '/settings');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: HSLColor.fromColor(context
                                    .watch<SettingsProvider>()
                                    .appAccentColor)
                                .withLightness(.2)
                                .toColor(),
                            borderRadius: BorderRadius.circular(
                              25.0,
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
                        onTap: () => setState(() {
                          calcListItems.add(
                            CalcListItem(
                              title: '${calcListItems.length + 1}',
                              tile: Tile.five,
                            ),
                          );
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: HSLColor.fromColor(context
                                    .watch<SettingsProvider>()
                                    .appAccentColor)
                                .withLightness(.2)
                                .toColor(),
                            borderRadius: BorderRadius.circular(
                              25.0,
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
