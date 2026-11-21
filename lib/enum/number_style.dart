/// Enum that represents how domino values are rendered: as pips (dots) or numbers.
enum NumberStyle {
  pips('Pips'),
  numbers('Numbers');

  final String label;
  const NumberStyle(this.label);

  /// JSON-friendly string representation (matches enum name).
  String toJson() => name;

  /// Parse a JSON/value string back to a NumberStyle.
  static NumberStyle fromJson(String? value) {
    if (value == null || value.isEmpty) return NumberStyle.pips;
    return NumberStyle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NumberStyle.pips,
    );
  }
}
