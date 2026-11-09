import 'package:cricket_live_score/src/parsing/match_date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMatchStartTime', () {
    test('parses a two-digit day as UTC', () {
      final result = parseMatchStartTime('19 Jul 2026, Sun 10:00 GMT');
      expect(result, DateTime.utc(2026, 7, 19, 10));
      expect(result!.isUtc, isTrue);
    });

    test('parses a single-digit day and hour', () {
      expect(
        parseMatchStartTime('9 Aug 2026, Sun 9:05 GMT'),
        DateTime.utc(2026, 8, 9, 9, 5),
      );
    });

    test('accepts a zero-padded day and surrounding whitespace', () {
      expect(
        parseMatchStartTime('  08 Nov 2026, Sun 21:30 GMT\n'),
        DateTime.utc(2026, 11, 8, 21, 30),
      );
    });

    test('is case-insensitive on the month', () {
      expect(
        parseMatchStartTime('1 DEC 2026, Tue 00:00 GMT'),
        DateTime.utc(2026, 12),
      );
    });

    test('every month abbreviation maps to its month', () {
      const names = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      for (var i = 0; i < names.length; i++) {
        expect(
          parseMatchStartTime('1 ${names[i]} 2026, Mon 12:00 GMT')!.month,
          i + 1,
        );
      }
    });

    test('returns null for text it does not understand', () {
      for (final text in [
        '',
        'Match starts soon',
        '19 Jly 2026, Sun 10:00 GMT',
        '19 Jul 2026 10:00 GMT',
        '19 Jul 2026, Sun 10:00 IST',
        '31 Feb 2026, Tue 10:00 GMT',
        '0 Jul 2026, Sun 10:00 GMT',
        '19 Jul 2026, Sun 24:00 GMT',
        '19 Jul 2026, Sun 10:60 GMT',
      ]) {
        expect(parseMatchStartTime(text), isNull, reason: text);
      }
    });
  });
}
