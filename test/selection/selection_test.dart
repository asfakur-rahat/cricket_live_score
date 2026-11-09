import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter_test/flutter_test.dart';

CricketMatch _match(
  String id, {
  bool isLive = false,
  bool scored = false,
  bool logos = false,
  DateTime? startTime,
}) {
  final logo = logos ? 'https://example.com/$id.png' : '';
  return CricketMatch(
    id: id,
    matchType: 'T20',
    venue: 'v',
    status: 's',
    team1: TeamInfo(name: 'A', logoUrl: logo),
    team2: TeamInfo(name: 'B', logoUrl: logo),
    startTime: startTime,
    teamScores: scored ? const [TeamScore(teamName: 'A')] : const [],
    isLive: isLive,
  );
}

List<String> _ids(List<CricketMatch> matches) => [
      for (final m in matches) m.id,
    ];

void main() {
  group('sortMatches', () {
    test('live first, then live with scores before live without', () {
      final sorted = sortMatches([
        _match('done'),
        _match('live-unscored', isLive: true),
        _match('live-scored', isLive: true, scored: true),
      ]);
      expect(_ids(sorted), ['live-scored', 'live-unscored', 'done']);
    });

    test('scores do not reorder matches that are not live', () {
      final t = DateTime.utc(2026);
      final sorted = sortMatches([
        _match('a', startTime: t),
        _match('b', scored: true, startTime: t),
      ]);
      expect(_ids(sorted), ['a', 'b']);
    });

    test('orders by start time, newest first (regression: string sort)', () {
      // As strings, "9 Aug 2026…" sorts after "19 Jul 2026…", so the old
      // comparator put July first.
      final sorted = sortMatches([
        _match('19-jul', startTime: DateTime.utc(2026, 7, 19, 10)),
        _match('9-aug', startTime: DateTime.utc(2026, 8, 9, 10)),
        _match('1-jan', startTime: DateTime.utc(2026)),
      ]);
      expect(_ids(sorted), ['9-aug', '19-jul', '1-jan']);
    });

    test('unknown start times go last', () {
      final sorted = sortMatches([
        _match('unknown'),
        _match('known', startTime: DateTime.utc(2020)),
      ]);
      expect(_ids(sorted), ['known', 'unknown']);
    });

    test('ties keep their input order', () {
      final sorted = sortMatches([
        for (var i = 0; i < 20; i++) _match('$i', isLive: true),
      ]);
      expect(_ids(sorted), [for (var i = 0; i < 20; i++) '$i']);
    });

    test('is consistent regardless of input order', () {
      final matches = [
        _match('live', isLive: true, startTime: DateTime.utc(2020)),
        _match('new', startTime: DateTime.utc(2026)),
        _match('old', startTime: DateTime.utc(2021)),
        _match('none'),
      ];
      expect(_ids(sortMatches(matches)), ['live', 'new', 'old', 'none']);
      expect(
        _ids(sortMatches(matches.reversed)),
        ['live', 'new', 'old', 'none'],
      );
    });

    test('accepts any iterable and returns a new list', () {
      expect(sortMatches(const <CricketMatch>[]), isEmpty);
      final input = [_match('a')];
      expect(identical(sortMatches(input), input), isFalse);
    });
  });

  group('pickFeaturedMatch', () {
    test('null for no matches', () {
      expect(pickFeaturedMatch(const []), isNull);
    });

    test('prefers a live match with both logos', () {
      final featured = pickFeaturedMatch([
        _match('done', logos: true),
        _match('live', isLive: true),
        _match('live-logos', isLive: true, logos: true),
      ]);
      expect(featured!.id, 'live-logos');
    });

    test('then any live match', () {
      final featured = pickFeaturedMatch([
        _match('done', logos: true),
        _match('live', isLive: true),
      ]);
      expect(featured!.id, 'live');
    });

    test('then the first match, which may not be live', () {
      final featured = pickFeaturedMatch([_match('first'), _match('second')]);
      expect(featured!.id, 'first');
      expect(featured.isLive, isFalse);
    });
  });
}
