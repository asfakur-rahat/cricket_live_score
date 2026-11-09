import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// A live match whose first team is called `Team $i`.
CricketMatch _live(int i) => liveMatch(id: '$i').copyWith(
      team1: TeamInfo(name: 'Team $i', logoUrl: ''),
      teamScores: [TeamScore(teamName: 'team $i', scoreText: '$i/0 (1)')],
    );

/// A match that has not started: no scores, not live.
CricketMatch _upcoming() => liveMatch(id: 'soon').copyWith(
      isLive: false,
      status: 'Starts at 14:00',
      teamScores: const [],
    );

Future<void> _pump(
  WidgetTester tester, {
  CricketScoreSource? source,
  CricketScoreController? controller,
  CricketMatchFilter filter = CricketScoreTicker.liveOnly,
  void Function(CricketMatch match)? onMatchTap,
  WidgetBuilder? emptyBuilder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            CricketScoreTicker(
              source: controller == null ? source : null,
              controller: controller,
              filter: filter,
              onMatchTap: onMatchTap,
              emptyBuilder: emptyBuilder,
              logoBuilder: fakeLogoBuilder,
            ),
          ],
        ),
      ),
    ),
  );
  await _settle(tester);
}

/// Lets a fetch land and the strip grow or shrink; the pulsing LIVE dot
/// never settles, so pumpAndSettle would time out.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Waits out [seconds] of the ticker's interval, plus a second for the
/// slide after it.
Future<void> _wait(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds * 2 + 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

double _height(WidgetTester tester) =>
    tester.getSize(find.byType(CricketScoreTicker)).height;

String _label(WidgetTester tester) => tester
    .getSemantics(
      find.descendant(
        of: find.byType(CricketScoreTicker),
        matching: find.byType(Material),
      ),
    )
    .label;

void main() {
  testWidgets('shows a live match with its type, scores and chip',
      (tester) async {
    await _pump(tester, source: FakeSource([finishedMatch(), liveMatch()]));
    expect(find.text('India A'), findsOneWidget);
    expect(find.text('464/5 (146)'), findsOneWidget);
    expect(find.text('TEST'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Canterbury'), findsNothing);
    expect(find.byKey(const ValueKey('logo:India A')), findsOneWidget);
  });

  testWidgets('collapses while loading and when nothing is live',
      (tester) async {
    final source = FakeSource()..pending = true;
    await _pump(tester, source: source);
    expect(_height(tester), 0);

    source.complete([finishedMatch()]);
    await _settle(tester);
    expect(_height(tester), 0);
    expect(find.text('Canterbury'), findsNothing);
  });

  testWidgets('grows in when a live match arrives', (tester) async {
    final source = FakeSource()..pending = true;
    await _pump(tester, source: source);
    source.complete([liveMatch()]);
    await _settle(tester);
    expect(_height(tester), greaterThan(0));
  });

  testWidgets('emptyBuilder replaces the collapse', (tester) async {
    await _pump(
      tester,
      source: FakeSource([finishedMatch()]),
      emptyBuilder: (_) => const Text('Nothing live'),
    );
    expect(find.text('Nothing live'), findsOneWidget);
  });

  testWidgets('moves to the next match every interval and wraps around',
      (tester) async {
    await _pump(tester, source: FakeSource([_live(0), _live(1), _live(2)]));
    expect(find.text('Team 0'), findsOneWidget);
    await _wait(tester, 5);
    expect(find.text('Team 0'), findsNothing);
    expect(find.text('Team 1'), findsOneWidget);
    await _wait(tester, 5);
    expect(find.text('Team 2'), findsOneWidget);
    await _wait(tester, 5);
    expect(find.text('Team 0'), findsOneWidget);
  });

  testWidgets('a single match stays put', (tester) async {
    await _pump(tester, source: FakeSource([_live(0)]));
    await _wait(tester, 12);
    expect(find.text('Team 0'), findsOneWidget);
  });

  testWidgets('holding it pauses, and lifting after a hold is not a tap',
      (tester) async {
    final tapped = <CricketMatch>[];
    await _pump(
      tester,
      source: FakeSource([_live(0), _live(1)]),
      onMatchTap: tapped.add,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CricketScoreTicker)),
    );
    await _wait(tester, 12);
    expect(find.text('Team 0'), findsOneWidget);

    // Pointer events carry the time they happened; a test gesture's are
    // zero unless given.
    await gesture.up(timeStamp: const Duration(seconds: 6));
    await tester.pump();
    expect(tapped, isEmpty);
    await _wait(tester, 5);
    expect(find.text('Team 1'), findsOneWidget);
  });

  testWidgets('a tap calls onMatchTap with the match on show', (tester) async {
    final tapped = <CricketMatch>[];
    await _pump(
      tester,
      source: FakeSource([_live(0), _live(1)]),
      onMatchTap: tapped.add,
    );
    await _wait(tester, 5);
    await tester.tap(find.byType(CricketScoreTicker));
    expect(tapped.single.id, '1');
  });

  testWidgets('keeps the match on show when a refresh reorders the list',
      (tester) async {
    final source = FakeSource([_live(0), _live(1), _live(2)]);
    final controller = CricketScoreController(source: source)..start();
    await _pump(tester, controller: controller);
    await _wait(tester, 5);
    expect(find.text('Team 1'), findsOneWidget);

    source.matches = [_live(2), _live(1), _live(0)];
    await controller.refresh();
    await tester.pump();
    expect(find.text('Team 1'), findsOneWidget);
    await _wait(tester, 5);
    // The next after Team 1 in the new order.
    expect(find.text('Team 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('another filter shows other matches; status without scores',
      (tester) async {
    await _pump(
      tester,
      source: FakeSource([_upcoming()]),
      filter: const CricketMatchFilter(phases: {MatchPhase.upcoming}),
    );
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('Starts at 14:00'), findsOneWidget);
  });

  testWidgets('scores go with their team, whatever the batting order',
      (tester) async {
    await _pump(
      tester,
      source: FakeSource([finishedMatch()]),
      filter: CricketMatchFilter.all,
    );
    expect(
      _label(tester),
      'ODI, Canterbury 130/8 (33.2) versus Central Stags 129/10 (41.2)',
    );
  });

  testWidgets('screen readers hear the match and its position', (tester) async {
    await _pump(tester, source: FakeSource([liveMatch(), _live(1)]));
    expect(
      _label(tester),
      'TEST, India A 464/5 (146) versus New Zealand A, live, Match 1 of 2',
    );
  });

  testWidgets('stops moving while the app is in the background',
      (tester) async {
    await _pump(tester, source: FakeSource([_live(0), _live(1)]));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _wait(tester, 12);
    expect(find.text('Team 0'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _wait(tester, 5);
    expect(find.text('Team 1'), findsOneWidget);
  });

  testWidgets('an injected controller is neither started nor disposed',
      (tester) async {
    final source = FakeSource([liveMatch()]);
    final controller = CricketScoreController(source: source);
    await _pump(tester, controller: controller);
    expect(source.calls, 0);
    await tester.pumpWidget(const SizedBox());
    await controller.refresh();
    expect(source.calls, 1);
    controller.dispose();
  });
}
