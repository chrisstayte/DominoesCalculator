import 'package:dominoes/global/feature_flags.dart';
import 'package:dominoes/widgets/adaptive_workspace.dart';
import 'package:dominoes/providers/camera_provider.dart';
import 'package:dominoes/services/sfx_service.dart';
import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
    required this.branchNavigatorKeys,
    this.showLabels = false,
  });

  final StatefulNavigationShell navigationShell;
  final List<GlobalKey<NavigatorState>> branchNavigatorKeys;

  final bool showLabels;

  static const _tabs = [
    (svg: 'assets/images/nav/calc.svg', label: 'CALC', name: 'Calculator'),
    (svg: 'assets/images/nav/logs.svg', label: 'LOGS', name: 'Logs'),
    (svg: 'assets/images/nav/camera.svg', label: 'CAM', name: 'Camera'),
    (svg: 'assets/images/nav/settings.svg', label: 'SET', name: 'Settings'),
  ];

  static const _branches = [0, 1, if (cameraScanningEnabled) 2, 3];

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final selected = navigationShell.currentIndex;

    void select(int tab) {
      final i = _branches[tab];
      if (i == selected) {
        branchNavigatorKeys[i].currentState?.popUntil((route) => route.isFirst);
      } else {
        context.read<SfxService>().playNavigate();
      }

      const cameraIndex = 2;
      final camera = context.read<CameraProvider>();
      if (selected == cameraIndex && i != cameraIndex) {
        camera.pausePreview();
      } else if (selected != cameraIndex && i == cameraIndex) {
        camera.resumePreview();
      }

      navigationShell.goBranch(i, initialLocation: i == selected);
    }

    if (hasWorkspace(context)) {
      return Provider<WorkspaceNavigation>.value(
        value: WorkspaceNavigation(
          tabs: [for (final branch in _branches) _tabs[branch]],
          selected: _branches.indexOf(selected),
          onSelect: select,
        ),
        child: navigationShell,
      );
    }
    final navigation = Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: nbt.borderColor, width: 3)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(_branches.length, (i) {
            final branch = _branches[i];
            final isSelected = branch == selected;
            final bottomPadding = MediaQuery.paddingOf(context).bottom;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  select(i);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? nbt.selectedColor : nbt.unselectedColor,
                    border: i > 0
                        ? Border(
                            left: BorderSide(color: nbt.borderColor, width: 3),
                          )
                        : null,
                  ),
                  padding: EdgeInsets.only(top: 8, bottom: 8 + bottomPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        _tabs[branch].svg,
                        width: 28,
                        height: 28,
                        colorFilter: ColorFilter.mode(
                          isSelected
                              ? nbt.selectedTextColor
                              : nbt.unselectedTextColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      if (showLabels) ...[
                        const SizedBox(height: 4),
                        Text(
                          _tabs[branch].label,
                          style: TextStyle(
                            color: isSelected
                                ? nbt.selectedTextColor
                                : nbt.unselectedTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
    return Scaffold(body: navigationShell, bottomNavigationBar: navigation);
  }
}

class WorkspaceNavigation extends StatelessWidget {
  const WorkspaceNavigation({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });
  final List<({String svg, String label, String name})> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  static List<Widget> actions(BuildContext context) {
    final navigation = context.watch<WorkspaceNavigation?>();
    return [if (navigation != null) navigation];
  }

  @override
  Widget build(BuildContext context) {
    final theme = NeoBrutalistTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tabs.length; i++)
            IconButton(
              tooltip: tabs[i].name,
              isSelected: selected == i,
              style: IconButton.styleFrom(
                backgroundColor: selected == i ? theme.selectedColor : null,
                foregroundColor: selected == i
                    ? theme.selectedTextColor
                    : Theme.of(context).appBarTheme.foregroundColor,
                shape: const RoundedRectangleBorder(),
              ),
              icon: Builder(
                builder: (context) => SvgPicture.asset(
                  tabs[i].svg,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    IconTheme.of(context).color ?? theme.unselectedTextColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              onPressed: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}
