import 'dart:async';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';

/// A finished match with no logos, so no network images are requested.
CricketMatch finishedMatch({String id = 'done'}) => CricketMatch(
      id: id,
      matchType: 'ODI',
      venue: 'McLean Park',
      status: 'Canterbury won by 2 wkts',
      team1: const TeamInfo(name: 'Canterbury', logoUrl: '', isWinner: true),
      team2: const TeamInfo(name: 'Central Stags', logoUrl: ''),
      startTimeText: '08 Nov 2026, Sun 21:30 GMT',
      startTime: DateTime.utc(2026, 11, 8, 21, 30),
      teamScores: const [
        TeamScore(teamName: 'central stags', scoreText: '129/10 (41.2)'),
        TeamScore(teamName: 'canterbury', scoreText: '130/8 (33.2)'),
      ],
    );

/// A live match whose teams have logo URLs.
CricketMatch liveMatch({String id = 'live'}) => CricketMatch(
      id: id,
      matchType: 'TEST',
      venue: 'Bert Sutcliffe Oval',
      status: 'Day 3: Stumps - New Zealand A trail by 428 runs',
      team1: const TeamInfo(
        name: 'India A',
        logoUrl: 'https://example.com/ind.webp',
      ),
      team2: const TeamInfo(
        name: 'New Zealand A',
        logoUrl: 'https://example.com/nz.webp',
      ),
      startTimeText: '07 Nov 2026, Sat 21:30 GMT',
      startTime: DateTime.utc(2026, 11, 7, 21, 30),
      teamScores: const [
        TeamScore(teamName: 'india a', scoreText: '464/5 (146)'),
        TeamScore(teamName: 'new zealand a'),
      ],
      isLive: true,
    );

/// Draws a logo as a coloured square tagged with the team name, without
/// touching the network.
Widget fakeLogoBuilder(BuildContext context, TeamInfo team, double radius) =>
    SizedBox.square(
      key: ValueKey('logo:${team.name}'),
      dimension: radius * 2,
      child: const ColoredBox(color: Color(0xFF1565C0)),
    );

/// A source whose fetches are answered by the test.
class FakeSource implements CricketScoreSource {
  /// Answers every fetch immediately with [matches].
  FakeSource([this.matches = const []]);

  /// What the next fetch returns, unless [error] or [pending] is set.
  List<CricketMatch> matches;

  /// Thrown by the next fetch when set.
  Object? error;

  /// When true, fetches wait until [complete] is called.
  bool pending = false;

  /// Number of fetches so far.
  int calls = 0;

  final _waiting = <Completer<List<CricketMatch>>>[];

  @override
  Future<List<CricketMatch>> fetchMatches() async {
    calls++;
    if (pending) {
      final completer = Completer<List<CricketMatch>>();
      _waiting.add(completer);
      return completer.future;
    }
    final error = this.error;
    if (error != null) return Future.error(error);
    return matches;
  }

  /// Completes every waiting fetch with [result].
  void complete(List<CricketMatch> result) {
    for (final completer in _waiting) {
      completer.complete(result);
    }
    _waiting.clear();
  }
}

/// Wraps [child] in a light-theme app with a bounded box, like a dialog.
Widget app(Widget child, {ThemeData? theme, double width = 360}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: 640, child: child),
      ),
    ),
  );
}
