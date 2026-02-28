import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.calculate_outlined, label: 'CALC'),
    (icon: Icons.list_alt, label: 'LOGS'),
    (icon: Icons.camera_alt_outlined, label: 'CAM'),
    (icon: Icons.settings_outlined, label: 'SET'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 3)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_tabs.length, (i) {
              final isSelected = i == selected;
              final bottomPadding = MediaQuery.of(context).padding.bottom;
              return Expanded(
                child: GestureDetector(
                  onTap: () => navigationShell.goBranch(
                    i,
                    initialLocation: i == selected,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      border: i > 0
                          ? Border(
                              left: BorderSide(color: Colors.black, width: 3),
                            )
                          : null,
                    ),
                    padding: EdgeInsets.only(top: 8, bottom: 8 + bottomPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabs[i].icon,
                          color: isSelected ? Colors.white : Colors.black,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabs[i].label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
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
