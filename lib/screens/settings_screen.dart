import 'package:dominoes/global/global.dart';
import 'package:dominoes/providers/settings_provider.dart';
import 'package:dominoes/screens/widgets/accent_color_picker_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key, this.controller}) : super(key: key);

  final ScrollController? controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo _packageInfo = PackageInfo(
      appName: 'Unknown',
      packageName: 'Unknown',
      version: 'Unknown',
      buildNumber: 'Unknown',
      buildSignature: 'Unknown');

  @override
  void initState() {
    _initPackageInfo();
    super.initState();
  }

  Future<void> _initPackageInfo() async {
    await PackageInfo.fromPlatform()
        .then((value) => setState(() => _packageInfo = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Options',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: Visibility(
          visible: widget.controller == null,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        controller: widget.controller,
        children: [
          ListTile(
            title: Text(
              'Personalize',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          ListTile(
            title: Text('Accent Color'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 10.0),
            child: SizedBox(
              height: 50,
              child: Row(
                children: Global.colors.accentColors
                    .map<AccentColorPickerItem>(
                      (e) => AccentColorPickerItem(
                        colorIndex: Global.colors.accentColors.indexOf(e),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: context.watch<SettingsProvider>().isDarkMode,
              onChanged: (bool value) =>
                  context.read<SettingsProvider>().setIsDarkMode(value),
            ),
          ),
          ListTile(
            title: Text('Dark Dominoes'),
            trailing: Switch(
              value: context.watch<SettingsProvider>().isDarkDominoes,
              onChanged: (bool value) =>
                  context.read<SettingsProvider>().setIsDarkDominoes(value),
            ),
          ),
          ListTile(
            title: Text('Domino Display'),
            trailing: CupertinoSlidingSegmentedControl(
              thumbColor: context.watch<SettingsProvider>().appAccentColor,
              groupValue: context.watch<SettingsProvider>().isPips ? 1 : 0,
              onValueChanged: (value) =>
                  context.read<SettingsProvider>().setIsPips(value == 1),
              children: const {
                0: Text('Number'),
                1: Text('Pips'),
              },
            ),
          ),
          ListTile(
            title: Text('Double Zero Value'),
            trailing: GestureDetector(
              onDoubleTap: () =>
                  context.read<SettingsProvider>().setDoubleZeroValue(50),
              child: Text(
                context.watch<SettingsProvider>().doubleZeroValue.toString(),
              ),
            ),
          ),
          Slider(
            onChanged: (value) => context
                .read<SettingsProvider>()
                .setDoubleZeroValue(value.toInt()),
            value: context.watch<SettingsProvider>().doubleZeroValue.toDouble(),
            divisions: 20,
            min: 1,
            max: 200,
          ),
          ListTile(
            title: Text(
              'FAQ',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.twitter),
            title: Text('@ChrisStayte'),
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'https',
                path: 'www.twitter.com/ChrisStayte',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).catchError(
                  (error) {
                    print(error);
                    return false;
                  },
                );
              }
            },
          ),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.envelope),
            title: Text('dominoes@chrisstayte.com'),
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'mailto',
                path: 'cashew@chrisstayte.com',
                query: 'subject=App Feedback (${_packageInfo.version})',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          const AboutListTile(
            icon: FaIcon(FontAwesomeIcons.fileLines),
            child: Text('License'),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacy Policy'),
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'https',
                path: 'www.chrisstayte.app/dominoes/privacy',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).catchError(
                  (error) {
                    print(error);
                    return false;
                  },
                );
              }
            },
          ),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.github),
            title: Text('Repo'),
            onTap: () async {
              final Uri uri = Uri(
                scheme: 'https',
                path: 'www.github.com/ChrisStayte/DominoCounter',
              );

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).catchError(
                  (error) {
                    print(error);
                    return false;
                  },
                );
              }
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.circleInfo),
            title:
                Text('${_packageInfo.version} (${_packageInfo.buildNumber})'),
          ),
          const ListTile(
            leading: Icon(Icons.flutter_dash_outlined),
            title: Text('Made with flutter!'),
          ),
        ],
      ),
    );
  }
}
