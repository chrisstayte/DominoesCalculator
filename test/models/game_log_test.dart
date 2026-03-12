import 'package:dominoes/models/game_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameLog', () {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    final log = GameLog(
      id: 'abc123',
      timestamp: timestamp,
      pips: [3, 6, 12],
      freePointValue: 50,
      total: 21,
    );

    group('constructor', () {
      test('stores all fields correctly', () {
        expect(log.id, 'abc123');
        expect(log.timestamp, timestamp);
        expect(log.pips, [3, 6, 12]);
        expect(log.freePointValue, 50);
        expect(log.total, 21);
      });
    });

    group('toJson', () {
      test('serialises id', () {
        expect(log.toJson()['id'], 'abc123');
      });

      test('serialises timestamp as milliseconds since epoch', () {
        expect(log.toJson()['timestamp'], 1700000000000);
      });

      test('serialises pips list', () {
        expect(log.toJson()['pips'], [3, 6, 12]);
      });

      test('serialises freePointValue', () {
        expect(log.toJson()['freePointValue'], 50);
      });

      test('serialises total', () {
        expect(log.toJson()['total'], 21);
      });
    });

    group('fromJson', () {
      final json = {
        'id': 'xyz789',
        'timestamp': 1700000001000,
        'pips': [1, 2, 3],
        'freePointValue': 25,
        'total': 6,
      };

      final fromJson = GameLog.fromJson(json);

      test('parses id', () {
        expect(fromJson.id, 'xyz789');
      });

      test('parses timestamp from milliseconds', () {
        expect(
          fromJson.timestamp,
          DateTime.fromMillisecondsSinceEpoch(1700000001000),
        );
      });

      test('parses pips list', () {
        expect(fromJson.pips, [1, 2, 3]);
      });

      test('parses freePointValue', () {
        expect(fromJson.freePointValue, 25);
      });

      test('parses total', () {
        expect(fromJson.total, 6);
      });
    });

    group('round-trip serialisation', () {
      test('toJson then fromJson restores the original object', () {
        final json = log.toJson();
        final restored = GameLog.fromJson(json);

        expect(restored.id, log.id);
        expect(restored.timestamp, log.timestamp);
        expect(restored.pips, log.pips);
        expect(restored.freePointValue, log.freePointValue);
        expect(restored.total, log.total);
      });
    });
  });
}
