import 'package:cricket_live_score/cricket_live_score.dart';

/// Offline sample data, so the example runs without network access.
class FakeSource implements CricketScoreSource {
  @override
  Future<List<CricketMatch>> fetchMatches() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return sortMatches([
      CricketMatch(
        id: 'demo-1',
        matchType: 'T20',
        venue: 'Sher-e-Bangla National Stadium, Mirpur',
        status: 'Sri Lanka need 38 runs in 24 balls',
        team1: const TeamInfo(name: 'Bangladesh', logoUrl: ''),
        team2: const TeamInfo(name: 'Sri Lanka', logoUrl: ''),
        startTimeText: '9 Dec 2026, Wed 09:30 GMT',
        startTime: DateTime.utc(2026, 12, 9, 9, 30),
        teamScores: const [
          TeamScore(teamName: 'Bangladesh', scoreText: '168/6 (20)'),
          TeamScore(teamName: 'Sri Lanka', scoreText: '131/4 (16)'),
        ],
        isLive: true,
      ),
      CricketMatch(
        id: 'demo-2',
        matchType: 'ODI',
        venue: 'McLean Park',
        status: 'Canterbury won by 2 wkts',
        team1: const TeamInfo(name: 'Canterbury', logoUrl: '', isWinner: true),
        team2: const TeamInfo(name: 'Central Stags', logoUrl: ''),
        startTimeText: '08 Nov 2026, Sun 21:30 GMT',
        startTime: DateTime.utc(2026, 11, 8, 21, 30),
        teamScores: const [
          TeamScore(teamName: 'Central Stags', scoreText: '129/10 (41.2)'),
          TeamScore(teamName: 'Canterbury', scoreText: '130/8 (33.2)'),
        ],
      ),
    ]);
  }
}
