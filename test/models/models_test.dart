import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const india = TeamInfo(
    name: 'India',
    logoUrl: 'https://example.com/ind.png',
    isWinner: true,
  );
  const england = TeamInfo(name: 'England', logoUrl: '');

  final match = CricketMatch(
    id: '42',
    matchType: 'T20',
    venue: 'Lord’s, London',
    status: 'India won by 5 wickets',
    team1: india,
    team2: england,
    startTimeText: '19 Jul 2026, Sun 10:00 GMT',
    startTime: DateTime.utc(2026, 7, 19, 10),
    fullScorecardUrl: 'https://example.com/scorecard/42',
    teamScores: const [
      TeamScore(teamName: 'England', scoreText: '160/8 (20 ov)'),
      TeamScore(teamName: 'India'),
    ],
    isLive: true,
  );

  group('TeamInfo', () {
    test('defaults isWinner to false', () {
      expect(england.isWinner, isFalse);
    });

    test('equality and hashCode are value based', () {
      const copy = TeamInfo(
        name: 'India',
        logoUrl: 'https://example.com/ind.png',
        isWinner: true,
      );
      expect(copy, india);
      expect(copy.hashCode, india.hashCode);
      expect(india == england, isFalse);
    });

    test('copyWith replaces only the given fields', () {
      expect(india.copyWith(), india);
      expect(
        india.copyWith(name: 'IND', logoUrl: 'x', isWinner: false),
        const TeamInfo(name: 'IND', logoUrl: 'x'),
      );
    });

    test('JSON round trip', () {
      expect(TeamInfo.fromJson(india.toJson()), india);
      expect(
        TeamInfo.fromJson(const {'name': 'A', 'logoUrl': ''}),
        const TeamInfo(name: 'A', logoUrl: ''),
      );
    });

    test('toString names every field', () {
      expect(
        india.toString(),
        'TeamInfo(name: India, logoUrl: https://example.com/ind.png, '
        'isWinner: true)',
      );
    });
  });

  group('TeamScore', () {
    const score = TeamScore(teamName: 'India', scoreText: '120/3');

    test('equality and hashCode are value based', () {
      const copy = TeamScore(teamName: 'India', scoreText: '120/3');
      expect(copy, score);
      expect(copy.hashCode, score.hashCode);
      expect(score == const TeamScore(teamName: 'India'), isFalse);
    });

    test('copyWith replaces only the given fields', () {
      expect(score.copyWith(), score);
      expect(
        score.copyWith(teamName: 'England', scoreText: '1/0'),
        const TeamScore(teamName: 'England', scoreText: '1/0'),
      );
    });

    test('JSON round trip, including a null score', () {
      expect(TeamScore.fromJson(score.toJson()), score);
      const noScore = TeamScore(teamName: 'India');
      expect(TeamScore.fromJson(noScore.toJson()), noScore);
    });

    test('toString names every field', () {
      expect(score.toString(), 'TeamScore(teamName: India, scoreText: 120/3)');
    });
  });

  group('CricketMatch', () {
    test('defaults', () {
      const bare = CricketMatch(
        id: '1',
        matchType: 'ODI',
        venue: 'v',
        status: 's',
        team1: india,
        team2: england,
      );
      expect(bare.startTimeText, '');
      expect(bare.startTime, isNull);
      expect(bare.fullScorecardUrl, isNull);
      expect(bare.teamScores, isEmpty);
      expect(bare.isLive, isFalse);
    });

    test('hasBothLogos needs a logo URL on both teams', () {
      expect(match.hasBothLogos, isFalse);
      expect(match.copyWith(team2: india).hasBothLogos, isTrue);
    });

    test('equality and hashCode are value based, including teamScores', () {
      final copy = match.copyWith(teamScores: [...match.teamScores]);
      expect(identical(copy.teamScores, match.teamScores), isFalse);
      expect(copy, match);
      expect(copy.hashCode, match.hashCode);
      expect(match == match.copyWith(teamScores: const []), isFalse);
      expect(match == match.copyWith(isLive: false), isFalse);
    });

    test('copyWith replaces only the given fields', () {
      expect(match.copyWith(), match);
      final changed = match.copyWith(
        id: '7',
        matchType: 'TEST',
        venue: 'Eden Gardens',
        status: 'Stumps',
        team1: england,
        team2: india,
        startTimeText: '1 Jan 2027, Fri 04:00 GMT',
        startTime: DateTime.utc(2027),
        fullScorecardUrl: 'u',
        teamScores: const [],
        isLive: false,
      );
      expect(
        changed,
        CricketMatch(
          id: '7',
          matchType: 'TEST',
          venue: 'Eden Gardens',
          status: 'Stumps',
          team1: england,
          team2: india,
          startTimeText: '1 Jan 2027, Fri 04:00 GMT',
          startTime: DateTime.utc(2027),
          fullScorecardUrl: 'u',
        ),
      );
    });

    test('JSON round trip', () {
      expect(CricketMatch.fromJson(match.toJson()), match);
      const bare = CricketMatch(
        id: '1',
        matchType: 'ODI',
        venue: 'v',
        status: 's',
        team1: india,
        team2: england,
      );
      expect(CricketMatch.fromJson(bare.toJson()), bare);
    });

    test('fromJson tolerates missing optional keys', () {
      final parsed = CricketMatch.fromJson({
        'id': '1',
        'matchType': 'ODI',
        'venue': 'v',
        'status': 's',
        'team1': india.toJson(),
        'team2': england.toJson(),
      });
      expect(parsed.startTimeText, '');
      expect(parsed.teamScores, isEmpty);
      expect(parsed.isLive, isFalse);
    });

    test('startTime is stored as UTC in JSON', () {
      final local = match.copyWith(startTime: DateTime.utc(2026).toLocal());
      expect(local.toJson()['startTime'], '2026-01-01T00:00:00.000Z');
      expect(CricketMatch.fromJson(local.toJson()).startTime!.isUtc, isTrue);
    });

    test('toString names every field', () {
      final text = match.toString();
      for (final field in [
        'id: 42',
        'matchType: T20',
        'venue: ',
        'status: ',
        'team1: TeamInfo(',
        'team2: TeamInfo(',
        'startTimeText: 19 Jul 2026',
        'startTime: 2026-07-19',
        'fullScorecardUrl: ',
        'teamScores: [TeamScore(',
        'isLive: true',
      ]) {
        expect(text, contains(field));
      }
    });
  });
}
