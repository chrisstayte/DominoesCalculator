import 'package:dominoes/theme/neo_brutalist_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<T> options;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final nbt = NeoBrutalistTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: nbt.borderColor, width: 3),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(options.length, (i) {
            final isSelected = options[i] == selected;
            return GestureDetector(
              onTap: () => onSelected(options[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? nbt.selectedColor : nbt.unselectedColor,
                  border: i > 0
                      ? Border(
                          left: BorderSide(color: nbt.borderColor, width: 3),
                        )
                      : null,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(
                  labels[i],
                  style: GoogleFonts.bricolageGrotesque(
                    color: isSelected ? nbt.selectedTextColor : nbt.unselectedTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
