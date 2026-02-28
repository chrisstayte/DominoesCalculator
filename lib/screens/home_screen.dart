import 'package:dominoes/enum/domino_pips.dart';
import 'package:dominoes/enum/number_style.dart';
import 'package:dominoes/providers/local_settings_provider.dart';
import 'package:dominoes/widgets/domino_pip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<Widget> _buildDominoTiles(NumberStyle numberStyle) {
    final orderedPips = [
      ...DominoPips.values.skip(12).take(4), // Row 1 (top): 12, 13, 14, 15
      ...DominoPips.values.skip(8).take(4), // Row 2: 8, 9, 10, 11
      ...DominoPips.values.skip(4).take(4), // Row 3: 4, 5, 6, 7
      ...DominoPips.values.take(4), // Row 4 (bottom): 0, 1, 2, 3
    ];

    return orderedPips.map((pip) {
      return DominoPip(pip: pip, numberStyle: numberStyle, onTap: () {});
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<LocalSettingsProvider>().localSettings;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: Container(color: Colors.red)),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.yellow.shade600),
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: EdgeInsets.all(1),

                    child: GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      crossAxisCount: 4,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      children: [..._buildDominoTiles(settings.numberStyle)],
                    ),
                  ),
                ),
                // Expanded(
                //   child: Container(
                //     padding: EdgeInsets.symmetric(horizontal: 8),
                //     color: Colors.green,
                //     child: Row(
                //       crossAxisAlignment: .start,
                //       spacing: 4,
                //       children: [
                //         Expanded(
                //           flex: 2,
                //           child: ElevatedButton(
                //             onPressed: () {},
                //             child: Text('Clear'),
                //           ),
                //         ),
                //         Expanded(
                //           child: ElevatedButton(
                //             onPressed: () {},
                //             child: Text('-'),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
