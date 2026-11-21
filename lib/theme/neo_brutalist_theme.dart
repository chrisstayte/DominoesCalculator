import 'package:flutter/material.dart';

class NeoBrutalistTheme extends ThemeExtension<NeoBrutalistTheme> {
  final Color borderColor;
  final Color shadowColor;
  final Color cardColor;
  final Color headerColor;
  final Color headerTextColor;
  final Color bodyTextColor;
  final Color secondaryTextColor;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color unselectedColor;
  final Color unselectedTextColor;
  final Color dotGridBackground;
  final Color dotGridDotColor;
  final Color accentYellow;
  final Color accentRed;
  final Color accentGreen;
  final Color iconColor;

  const NeoBrutalistTheme({
    required this.borderColor,
    required this.shadowColor,
    required this.cardColor,
    required this.headerColor,
    required this.headerTextColor,
    required this.bodyTextColor,
    required this.secondaryTextColor,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.unselectedColor,
    required this.unselectedTextColor,
    required this.dotGridBackground,
    required this.dotGridDotColor,
    required this.accentYellow,
    required this.accentRed,
    required this.accentGreen,
    required this.iconColor,
  });

  factory NeoBrutalistTheme.light() => NeoBrutalistTheme(
    borderColor: Colors.black,
    shadowColor: Colors.black,
    cardColor: Colors.white,
    headerColor: Colors.black,
    headerTextColor: Colors.white,
    bodyTextColor: Colors.black,
    secondaryTextColor: Colors.black54,
    selectedColor: Colors.black,
    selectedTextColor: Colors.white,
    unselectedColor: Colors.white,
    unselectedTextColor: Colors.black,
    dotGridBackground: Colors.white,
    dotGridDotColor: Colors.grey.shade300,
    accentYellow: Colors.yellow.shade600,
    accentRed: const Color(0xFFFF4344),
    accentGreen: const Color(0xFF45FF45),
    iconColor: Colors.black,
  );

  factory NeoBrutalistTheme.dark() {
    const muted = Color(0xFFAAAAAA);
    const text = Color(0xFFD5D5D5);
    return NeoBrutalistTheme(
      borderColor: muted,
      shadowColor: muted.withValues(alpha: 0.15),
      cardColor: Colors.black,
      headerColor: muted,
      headerTextColor: Colors.black,
      bodyTextColor: text,
      secondaryTextColor: const Color(0xFF888888),
      selectedColor: muted,
      selectedTextColor: Colors.black,
      unselectedColor: Colors.black,
      unselectedTextColor: text,
      dotGridBackground: Colors.black,
      dotGridDotColor: const Color(0xFF333333),
      accentYellow: Colors.yellow.shade600,
      accentRed: const Color(0xFFFF4344),
      accentGreen: const Color(0xFF45FF45),
      iconColor: muted,
    );
  }

  static NeoBrutalistTheme of(BuildContext context) {
    return Theme.of(context).extension<NeoBrutalistTheme>()!;
  }

  @override
  NeoBrutalistTheme copyWith({
    Color? borderColor,
    Color? shadowColor,
    Color? cardColor,
    Color? headerColor,
    Color? headerTextColor,
    Color? bodyTextColor,
    Color? secondaryTextColor,
    Color? selectedColor,
    Color? selectedTextColor,
    Color? unselectedColor,
    Color? unselectedTextColor,
    Color? dotGridBackground,
    Color? dotGridDotColor,
    Color? accentYellow,
    Color? accentRed,
    Color? accentGreen,
    Color? iconColor,
  }) {
    return NeoBrutalistTheme(
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      cardColor: cardColor ?? this.cardColor,
      headerColor: headerColor ?? this.headerColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      bodyTextColor: bodyTextColor ?? this.bodyTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedTextColor: selectedTextColor ?? this.selectedTextColor,
      unselectedColor: unselectedColor ?? this.unselectedColor,
      unselectedTextColor: unselectedTextColor ?? this.unselectedTextColor,
      dotGridBackground: dotGridBackground ?? this.dotGridBackground,
      dotGridDotColor: dotGridDotColor ?? this.dotGridDotColor,
      accentYellow: accentYellow ?? this.accentYellow,
      accentRed: accentRed ?? this.accentRed,
      accentGreen: accentGreen ?? this.accentGreen,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  @override
  NeoBrutalistTheme lerp(covariant NeoBrutalistTheme? other, double t) {
    if (other is! NeoBrutalistTheme) return this;
    return NeoBrutalistTheme(
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      headerColor: Color.lerp(headerColor, other.headerColor, t)!,
      headerTextColor: Color.lerp(headerTextColor, other.headerTextColor, t)!,
      bodyTextColor: Color.lerp(bodyTextColor, other.bodyTextColor, t)!,
      secondaryTextColor: Color.lerp(secondaryTextColor, other.secondaryTextColor, t)!,
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t)!,
      selectedTextColor: Color.lerp(selectedTextColor, other.selectedTextColor, t)!,
      unselectedColor: Color.lerp(unselectedColor, other.unselectedColor, t)!,
      unselectedTextColor: Color.lerp(unselectedTextColor, other.unselectedTextColor, t)!,
      dotGridBackground: Color.lerp(dotGridBackground, other.dotGridBackground, t)!,
      dotGridDotColor: Color.lerp(dotGridDotColor, other.dotGridDotColor, t)!,
      accentYellow: Color.lerp(accentYellow, other.accentYellow, t)!,
      accentRed: Color.lerp(accentRed, other.accentRed, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
    );
  }
}
