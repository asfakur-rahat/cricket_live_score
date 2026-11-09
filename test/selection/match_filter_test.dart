import 'dart:io';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter_test/flutter_test.dart';

CricketMatch _match(
  String id, {
  String type = 'T20',
  String status = '',
  bool isLive = false,
  bool scored = false,
}) {
  return CricketMatch(
    id: id,
    matchType: type,
    venue: 'v',
    status: status,
    team1: const TeamInfo(name: 'A', logoUrl: ''),
    team2: const TeamInfo(name: 'B', logoUrl: ''),
    teamScores: scored ? const [TeamScore(teamName: 'A')] : const [],
    isLive: isLive,
  );
}

List<String> _ids(List<CricketMatch> matches) => [
      for (final m in matches) m.id,
    ];

void main() {
  group('CricketMatch.phase', () {
    test('live when isLive is set', () {
      expect(_match('m', isLive: true, scored: true).phase, MatchPhase.live);
    });

    test('finished when the status reports a result', () {
      for (final status in [
        'India won by 5 wkts',
        'Match tied',
        'Match drawn',
        'No result',
        'Match Abandoned',
      ]) {
        expect(
          _match('m', status: status).phase,
          MatchPhase.finished,
          reason: status,
        );
      }
    });

    test('finished when it has a score but is not live', () {
      expect(_match('m', scored: true).phase, MatchPhase.finished);
    });

    test('upcoming with no score and no result', () {
      expect(
        _match('m', status: 'Match starts at 10:00 GMT').phase,
        MatchPhase.upcoming,
      );
    });

    test('every match in the recorded feed gets a phase', () {
      final matches = CricketDataHtmlParser.parseMultiple(
        File('test/fixtures/live_feed_2026-11-09.html').readAsStringSync(),
      );
      final live = matches.where((m) => m.isLive).toList();
      expect(live, isNotEmpty);
      for (final match in matches) {
        expect(match.phase == MatchPhase.live, match.isLive);
      }
    });
  });

  group('CricketMatchFilter', () {
    final matches = [
      _match('t20-live', isLive: true, scored: true),
      _match('odi-done', type: 'ODI', status: 'A won by 2 wkts', scored: true),
      _match('test-next', type: 'TEST'),
      _match('t20-next'),
      _match('t10-live', type: 't10', isLive: true, scored: true),
    ];

    test('the default filter lets everything through unchanged', () {
      expect(CricketMatchFilter.all.isAll, isTrue);
      expect(filterMatches(matches, CricketMatchFilter.all), same(matches));
    });

    test('filters by phase', () {
      const filter = CricketMatchFilter(phases: {MatchPhase.live});
      expect(_ids(filterMatches(matches, filter)), ['t20-live', 't10-live']);
    });

    test('filters by type, ignoring case', () {
      const filter = CricketMatchFilter(types: {'t20', 'T10'});
      expect(
        _ids(filterMatches(matches, filter)),
        ['t20-live', 't20-next', 't10-live'],
      );
    });

    test('a match must pass both type and phase', () {
      const filter = CricketMatchFilter(
        types: {'T20'},
        phases: {MatchPhase.upcoming, MatchPhase.finished},
      );
      expect(_ids(filterMatches(matches, filter)), ['t20-next']);
    });

    test('several phases at once', () {
      const filter = CricketMatchFilter(
        phases: {MatchPhase.upcoming, MatchPhase.finished},
      );
      expect(
        _ids(filterMatches(matches, filter)),
        ['odi-done', 'test-next', 't20-next'],
      );
    });

    test('copyWith, equality and hashCode', () {
      const filter = CricketMatchFilter(types: {'T20'});
      final copy = filter.copyWith(phases: {MatchPhase.live});
      expect(copy.types, {'T20'});
      expect(copy.phases, {MatchPhase.live});
      expect(copy.isAll, isFalse);
      expect(
        copy,
        const CricketMatchFilter(types: {'T20'}, phases: {MatchPhase.live}),
      );
      expect(
        copy.hashCode,
        const CricketMatchFilter(types: {'T20'}, phases: {MatchPhase.live})
            .hashCode,
      );
      expect(copy == filter, isFalse);
      expect(copy.copyWith(), copy);
      expect(copy.toString(), contains('T20'));
    });
  });

  group('matchTypesOf', () {
    test('common formats first, then the rest alphabetically', () {
      final types = matchTypesOf([
        _match('a', type: 'Hundred'),
        _match('b', type: 't10'),
        _match('c', type: 'TEST'),
        _match('d', type: 'ODI'),
        _match('e', type: 'List A'),
        _match('f'),
        _match('g', type: 't20'),
        _match('h', type: ' '),
      ]);
      expect(types, ['T20', 'ODI', 'TEST', 'T10', 'HUNDRED', 'LIST A']);
    });

    test('empty input gives no types', () {
      expect(matchTypesOf(const []), isEmpty);
    });
  });
}
