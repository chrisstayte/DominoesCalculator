import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class AccentColorPickerItem extends StatelessWidget {
  const AccentColorPickerItem({Key? key, required this.colorIndex})
      : super(key: key);

  final colorIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: GestureDetector(
          onTap: () => context.read<SettingsProvider>().setAppAccentColor(
              Global.colors.accentColors.elementAt(colorIndex)),
          child: Container(
            decoration: BoxDecoration(
              color: Global.colors.accentColors.elementAt(colorIndex),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: context.read<SettingsProvider>().appAccentColor ==
                      Global.colors.accentColors.elementAt(colorIndex)
                  ? FaIcon(
                      FontAwesomeIcons.circleCheck,
                      color: context.watch<SettingsProvider>().isDarkMode
                          ? Global.colors.darkThemeColor
                          : Colors.white,
                    )
                  : null,
              // : FaIcon(
              //     FontAwesomeIcons.circle,
              //     color: context.watch<SettingsProvider>().isDarkMode
              //         ? Global.colors.darkThemeColor
              //         : Colors.white,
              //   ),
            ),
          ),
        ),
      ),
    );
  }
}
