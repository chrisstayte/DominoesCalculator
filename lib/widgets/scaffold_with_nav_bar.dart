import 'package:dominoes/providers/camera_provider.dart';
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
    (svg: 'assets/images/nav/calc.svg', label: 'CALC'),
    (svg: 'assets/images/nav/logs.svg', label: 'LOGS'),
    (svg: 'assets/images/nav/camera.svg', label: 'CAM'),
    (svg: 'assets/images/nav/settings.svg', label: 'SET'),
  ];

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    final selected = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: nbt.borderColor, width: 3)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_tabs.length, (i) {
              final isSelected = i == selected;
              final bottomPadding = MediaQuery.of(context).padding.bottom;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (i == selected) {
                      branchNavigatorKeys[i]
                          .currentState
                          ?.popUntil((route) => route.isFirst);
                    }

                    const cameraIndex = 2;
                    final camera = context.read<CameraProvider>();
                    if (selected == cameraIndex && i != cameraIndex) {
                      camera.pausePreview();
                    } else if (selected != cameraIndex && i == cameraIndex) {
                      camera.resumePreview();
                    }

                    navigationShell.goBranch(
                      i,
                      initialLocation: i == selected,
                    );
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
                          _tabs[i].svg,
                          width: 28,
                          height: 28,
                          colorFilter: ColorFilter.mode(
                            isSelected ? nbt.selectedTextColor : nbt.unselectedTextColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        if (showLabels) ...[
                          const SizedBox(height: 4),
                          Text(
                            _tabs[i].label,
                            style: TextStyle(
                              color: isSelected ? nbt.selectedTextColor : nbt.unselectedTextColor,
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
      ),
    );
  }
}
