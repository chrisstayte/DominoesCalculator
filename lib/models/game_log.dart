class GameLog {
  final String id;
  final DateTime timestamp;
  final List<int> pips;
  final int freePointValue;
  final int total;

  GameLog({
    required this.id,
    required this.timestamp,
    required this.pips,
    required this.freePointValue,
    required this.total,
  });

  factory GameLog.fromJson(Map<String, dynamic> json) {
    return GameLog(
      id: json['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      pips: (json['pips'] as List<dynamic>).cast<int>(),
      freePointValue: json['freePointValue'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'pips': pips,
    'freePointValue': freePointValue,
    'total': total,
  };
}
