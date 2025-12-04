enum DominoPips {
  p0(0),
  p1(1),
  p2(2),
  p3(3),
  p4(4),
  p5(5),
  p6(6),
  p7(7),
  p8(8),
  p9(9),
  p10(10),
  p11(11),
  p12(12),
  p13(13),
  p14(14),
  p15(15);

  final int value;
  const DominoPips(this.value);

  /// Numeric value for this pip enum (0..15).
  int get asInt => value;

  /// Short label string (e.g. "0", "1", ...).
  String get label => value.toString();

  /// Convert an int (0..15) to the matching enum, throws RangeError for invalid values.
  static DominoPips fromInt(int value) => DominoPips.values.firstWhere(
    (e) => e.value == value,
    orElse: () => throw RangeError('Invalid DominoPips value: $value'),
  );

  /// Convert an int (0..15) to the matching enum, returns null for invalid values.
  static DominoPips? tryFromInt(int value) {
    for (final p in DominoPips.values) {
      if (p.value == value) return p;
    }
    return null;
  }

  @override
  String toString() => label;
}
