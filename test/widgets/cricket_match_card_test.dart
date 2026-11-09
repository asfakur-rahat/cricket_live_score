import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('a finished match shows its start time, venue and scores',
      (tester) async {
    await tester.pumpWidget(app(CricketMatchCard(match: finishedMatch())));
    expect(find.text('ODI'), findsOneWidget);
    expect(find.text('08 Nov 2026, Sun 21:30 GMT'), findsOneWidget);
    expect(find.textContaining('LIVE'), findsNothing);
    expect(find.text('At McLean Park'), findsOneWidget);
    expect(find.text('Canterbury won by 2 wkts'), findsOneWidget);
    expect(find.text('129/10 (41.2)'), findsOneWidget);
    expect(find.text('130/8 (33.2)'), findsOneWidget);
  });

  testWidgets('a live match shows the LIVE heading, not the start time',
      (tester) async {
    await tester.pumpWidget(
      app(CricketMatchCard(match: liveMatch(), logoBuilder: fakeLogoBuilder)),
    );
    expect(find.text('- LIVE -'), findsOneWidget);
    expect(find.text('07 Nov 2026, Sun 21:30 GMT'), findsNothing);
  });

  testWidgets('a missing score shows notAvailable', (tester) async {
    await tester.pumpWidget(
      app(
        CricketMatchCard(
          match: liveMatch(),
          logoBuilder: fakeLogoBuilder,
          labels: const CricketScoreLabels(notAvailable: '—'),
        ),
      ),
    );
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('a team without a logo URL shows no logo', (tester) async {
    await tester.pumpWidget(
      app(
        CricketMatchCard(match: finishedMatch(), logoBuilder: fakeLogoBuilder),
      ),
    );
    expect(find.byKey(const ValueKey('logo:Canterbury')), findsNothing);

    await tester.pumpWidget(
      app(CricketMatchCard(match: liveMatch(), logoBuilder: fakeLogoBuilder)),
    );
    expect(find.byKey(const ValueKey('logo:India A')), findsOneWidget);
    expect(find.byKey(const ValueKey('logo:New Zealand A')), findsOneWidget);
  });

  testWidgets('a logo that fails to load shows the initials', (tester) async {
    // Network images fail in widget tests, which exercises the fallback.
    await tester.pumpWidget(app(CricketMatchCard(match: liveMatch())));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byType(TeamMonogram), findsNWidgets(2));
    expect(find.text('IND'), findsOneWidget);
    expect(find.text('NZ'), findsOneWidget);
  });

  testWidgets('teams without a logo show their initials', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        CricketMatchCard(
          match: finishedMatch(),
          logoBuilder: (context, team, radius) {
            calls++;
            return const SizedBox();
          },
        ),
      ),
    );
    // Canterbury and Central Stags have no logo URL.
    expect(find.text('CAN'), findsOneWidget);
    expect(find.text('CS'), findsOneWidget);
    // A custom builder is only asked for logos it can load.
    expect(calls, 0);
  });

  testWidgets('the default centre badge is crossed bats filling the badge',
      (tester) async {
    await tester.pumpWidget(
      app(
        CricketMatchCard(
          match: finishedMatch(),
          theme: const CricketScoreThemeData(
            badgeRadius: 20,
            badgeForeground: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
    final icon = tester.widget<CricketBatsIcon>(find.byType(CricketBatsIcon));
    expect(icon.size, 40);
    expect(icon.color, const Color(0xFFFFFFFF));
    expect(tester.getSize(find.byType(CricketBatsIcon)), const Size(40, 40));

    await tester.pumpWidget(
      app(
        CricketMatchCard(
          match: finishedMatch(),
          centerBadge: const Text('badge'),
        ),
      ),
    );
    expect(find.byType(CricketBatsIcon), findsNothing);
    expect(find.text('badge'), findsOneWidget);
  });

  testWidgets('formatVenue can reorder the venue line', (tester) async {
    await tester.pumpWidget(
      app(
        CricketMatchCard(
          match: finishedMatch(),
          labels: CricketScoreLabels(formatVenue: (venue) => '$venue-এ'),
        ),
      ),
    );
    expect(find.text('McLean Park-এ'), findsOneWidget);
  });

  testWidgets('has a screen-reader label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(CricketMatchCard(match: liveMatch(), logoBuilder: fakeLogoBuilder)),
    );
    expect(
      find.bySemanticsLabel('India A versus New Zealand A, live'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('onTap is called when the card is tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      app(CricketMatchCard(match: finishedMatch(), onTap: () => taps++)),
    );
    await tester.tap(find.text('At McLean Park'));
    expect(taps, 1);
  });

  group('theme resolution', () {
    Text liveText(WidgetTester tester) =>
        tester.widget<Text>(find.text('- LIVE -'));

    testWidgets('defaults come from the colour scheme', (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(
        app(
          CricketMatchCard(match: liveMatch(), logoBuilder: fakeLogoBuilder),
          theme: theme,
        ),
      );
      expect(liveText(tester).style!.color, theme.colorScheme.error);
    });

    testWidgets('a ThemeData extension overrides the defaults', (tester) async {
      await tester.pumpWidget(
        app(
          CricketMatchCard(match: liveMatch(), logoBuilder: fakeLogoBuilder),
          theme: ThemeData.light().copyWith(
            extensions: const [
              CricketScoreThemeData(liveColor: Color(0xFF00AA00)),
            ],
          ),
        ),
      );
      expect(liveText(tester).style!.color, const Color(0xFF00AA00));
    });

    testWidgets('the theme argument overrides the extension', (tester) async {
      await tester.pumpWidget(
        app(
          CricketMatchCard(
            match: liveMatch(),
            logoBuilder: fakeLogoBuilder,
            theme: const CricketScoreThemeData(liveColor: Color(0xFFAA0000)),
          ),
          theme: ThemeData.light().copyWith(
            extensions: const [
              CricketScoreThemeData(
                liveColor: Color(0xFF00AA00),
                accentColor: Color(0xFF0000AA),
              ),
            ],
          ),
        ),
      );
      expect(liveText(tester).style!.color, const Color(0xFFAA0000));
      // Fields the argument leaves unset still come from the extension.
      expect(
        tester.widget<Text>(find.text('TEST')).style!.color,
        const Color(0xFF0000AA),
      );
    });
  });
}
