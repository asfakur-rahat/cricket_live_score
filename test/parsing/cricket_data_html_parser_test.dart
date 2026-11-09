import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter_test/flutter_test.dart';

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

// The `.expected.json` files were produced by running the app's original
// `CricketMatchParser` over the same fixtures, with its fields renamed to the
// package model (`matchId` → `id`, `dateTime` → `startTimeText`). The only
// intended difference since is `startTime`, which the original did not have;
// its expected values were computed independently with Python's `strptime`.
List<CricketMatch> _expected(String name) => [
      for (final json in jsonDecode(_fixture(name)) as List<dynamic>)
        CricketMatch.fromJson(json as Map<String, dynamic>),
    ];

void main() {
  group('parseMultiple matches the original parser plus startTime', () {
    for (final name in ['live_feed_2026-11-09', 'hand_built_states']) {
      test(name, () {
        final matches = CricketDataHtmlParser.parseMultiple(
          _fixture('$name.html'),
        );
        expect(matches, _expected('$name.expected.json'));
      });
    }
  });

  group('live feed', () {
    final matches = CricketDataHtmlParser.parseMultiple(
      _fixture('live_feed_2026-11-09.html'),
    );

    test('parses every slab', () {
      expect(matches, hasLength(26));
    });

    test('finished match with logos and a starred winner', () {
      expect(
        matches.first,
        CricketMatch(
          id: '03fa5b0e-8c0a-45c7-b998-d2082fa85673',
          matchType: 'ODI',
          venue: 'McLean Park',
          status: 'Canterbury won by 2 wkts',
          team1: const TeamInfo(
            name: 'Canterbury',
            logoUrl:
                'https://cdorgapi.b-cdn.net/iapi/15-637993523929449827.webp?w=48',
            isWinner: true,
          ),
          team2: const TeamInfo(
            name: 'Central Stags',
            logoUrl:
                'https://cdorgapi.b-cdn.net/iapi/133-637957472586275153.webp?w=48',
          ),
          startTimeText: '08 Nov 2026, Sun 21:30 GMT',
          startTime: DateTime.utc(2026, 11, 8, 21, 30),
          fullScorecardUrl:
              'https://cricketdata.org/cricket-data-formats/matches/central-stags-vs-canterbury-12th-match-the-ford-trophy-2026-27-03fa5b0e-8c0a-45c7-b998-d2082fa85673',
          teamScores: const [
            TeamScore(teamName: 'central stags', scoreText: '129/10 (41.2)'),
            TeamScore(teamName: 'canterbury', scoreText: '130/8 (33.2)'),
          ],
        ),
      );
    });

    test('finished match without logos', () {
      final match = matches.firstWhere(
        (m) => m.id == '000cee00-1deb-409b-a5f6-bd44c3d571b7',
      );
      expect(
        match.team1,
        const TeamInfo(
          name: 'Northern Districts',
          logoUrl: '',
          isWinner: true,
        ),
      );
      expect(match.team2, const TeamInfo(name: 'Otago', logoUrl: ''));
      expect(match.hasBothLogos, isFalse);
      expect(match.isLive, isFalse);
    });

    test('in-progress match with a score is live', () {
      final live = matches.where((m) => m.isLive).toList();
      expect(live, hasLength(1));
      expect(live.single.id, '9bdb29a3-e23d-4400-b4d9-86a8f857d0ba');
      expect(live.single.matchType, 'TEST');
      expect(
        live.single.status,
        'Day 3: Stumps - New Zealand A trail by 428 runs',
      );
      expect(live.single.team1.name, 'India A');
      expect(live.single.team2.name, 'New Zealand A');
      expect(live.single.hasBothLogos, isTrue);
      expect(live.single.teamScores, const [
        TeamScore(teamName: 'india a', scoreText: '464/5 (146)'),
        TeamScore(teamName: 'new zealand a', scoreText: '36/2 (14)'),
      ]);
    });
  });

  group('hand-built states', () {
    final matches = {
      for (final m in CricketDataHtmlParser.parseMultiple(
        _fixture('hand_built_states.html'),
      ))
        m.id: m,
    };

    test('upcoming match in the table-cell format', () {
      final match = matches['hb-upcoming']!;
      expect(match.isLive, isFalse);
      expect(match.teamScores, isEmpty);
      expect(match.startTimeText, '9 Dec 2026, Wed 09:30 GMT');
      expect(match.team1.name, 'Bangladesh');
      expect(match.team2.name, 'Sri Lanka');
      expect(match.hasBothLogos, isTrue);
      expect(
        match.fullScorecardUrl,
        'https://example.com/scorecard/hb-upcoming',
      );
    });

    test('a tied match with scores is not live', () {
      expect(matches['hb-tied']!.isLive, isFalse);
      expect(matches['hb-tied']!.teamScores, hasLength(2));
    });

    test('teams fall back to the score table', () {
      final match = matches['hb-table-only']!;
      expect(
        match.team1,
        const TeamInfo(
          name: 'nepal',
          logoUrl: '',
          isWinner: true,
        ),
      );
      expect(match.team2, const TeamInfo(name: 'oman', logoUrl: ''));
    });

    test('a single team div is padded with an unknown team', () {
      final match = matches['hb-one-team']!;
      expect(match.isLive, isTrue);
      expect(match.team1.name, 'Scotland');
      expect(match.team2, const TeamInfo(name: 'Unknown Team', logoUrl: ''));
    });

    test('an empty slab falls back to defaults', () {
      expect(
        matches['hb-empty'],
        const CricketMatch(
          id: 'hb-empty',
          matchType: '',
          venue: '',
          status: '',
          team1: TeamInfo(name: 'Team 1', logoUrl: ''),
          team2: TeamInfo(name: 'Team 2', logoUrl: ''),
        ),
      );
    });
  });

  test('parse reads a single slab', () {
    final match = CricketDataHtmlParser.parse(
      _fixture('hand_built_states.html'),
    );
    expect(match.id, 'hb-upcoming');
  });

  test('parseMultiple returns nothing for HTML without slabs', () {
    expect(CricketDataHtmlParser.parseMultiple('<p>maintenance</p>'), isEmpty);
  });

  test('startTime is parsed from startTimeText, null when absent', () {
    final matches = CricketDataHtmlParser.parseMultiple(
      _fixture('hand_built_states.html'),
    );
    expect(matches.first.startTimeText, '9 Dec 2026, Wed 09:30 GMT');
    expect(matches.first.startTime, DateTime.utc(2026, 12, 9, 9, 30));
    expect(matches.last.startTimeText, isEmpty);
    expect(matches.last.startTime, isNull);
  });

  test('parseMultiple reports to onLog and never prints', () {
    final printed = <String>[];
    final logged = <String>[];
    runZoned(
      () => CricketDataHtmlParser.parseMultiple(
        _fixture('live_feed_2026-11-09.html'),
        onLog: logged.add,
      ),
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) => printed.add(line),
      ),
    );
    expect(printed, isEmpty);
    expect(logged, ['Parsed 26 of 26 matches']);
  });
}
