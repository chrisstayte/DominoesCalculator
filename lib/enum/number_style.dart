/// Enum that represents how domino values are rendered: as pips (dots) or numbers.
enum NumberStyle { pips, numbers }

extension NumberStyleX on NumberStyle {
  /// Human readable label for UI.
  String get label {
    switch (this) {
      case NumberStyle.pips:
        return 'Pips';
      case NumberStyle.numbers:
        return 'Numbers';
    }
  }

  /// JSON-friendly string representation (matches enum name).
  String toJson() => name;
}

/// Parse a JSON/value string back to a NumberStyle.
NumberStyle numberStyleFromJson(String? value) {
  if (value == null || value.isEmpty) return NumberStyle.pips;
  return NumberStyle.values.firstWhere(
    (e) => e.name == value,
    orElse: () => NumberStyle.pips,
  );
}
