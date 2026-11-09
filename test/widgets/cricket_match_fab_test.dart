import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  Widget fab(
    CricketMatch match, {
    VoidCallback? onTap,
    VoidCallback? onHorizontalSwipe,
  }) {
    return app(
      Center(
        child: CricketMatchFab(
          match: match,
          onTap: onTap,
          onHorizontalSwipe: onHorizontalSwipe,
          logoBuilder: fakeLogoBuilder,
        ),
      ),
    );
  }

  testWidgets('shows both logos around VS', (tester) async {
    await tester.pumpWidget(fab(liveMatch()));
    expect(find.byKey(const ValueKey('logo:India A')), findsOneWidget);
    expect(find.byKey(const ValueKey('logo:New Zealand A')), findsOneWidget);
    expect(find.text('VS'), findsOneWidget);
  });

  testWidgets('the LIVE chip shows only for a live match', (tester) async {
    await tester.pumpWidget(fab(liveMatch()));
    expect(find.text('LIVE'), findsOneWidget);

    await tester.pumpWidget(fab(finishedMatch()));
    expect(find.text('LIVE'), findsNothing);
  });

  testWidgets('tap calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(fab(liveMatch(), onTap: () => taps++));
    await tester.tap(find.text('VS'));
    expect(taps, 1);
  });

  testWidgets('a horizontal swipe either way calls onHorizontalSwipe',
      (tester) async {
    var swipes = 0;
    await tester.pumpWidget(
      fab(liveMatch(), onHorizontalSwipe: () => swipes++),
    );
    await tester.drag(find.text('VS'), const Offset(80, 0));
    expect(swipes, 1);
    await tester.drag(find.text('VS'), const Offset(-80, 0));
    expect(swipes, 2);
  });

  testWidgets('short or vertical drags are not swipes', (tester) async {
    var swipes = 0;
    var taps = 0;
    await tester.pumpWidget(
      fab(
        liveMatch(),
        onTap: () => taps++,
        onHorizontalSwipe: () => swipes++,
      ),
    );
    await tester.drag(find.text('VS'), const Offset(40, 0));
    await tester.drag(find.text('VS'), const Offset(60, 90));
    expect(swipes, 0);
    expect(taps, 0);
  });

  testWidgets('the default logo builder is used for every team',
      (tester) async {
    await tester.pumpWidget(
      app(Center(child: CricketMatchFab(match: finishedMatch()))),
    );
    // Neither team has a logo URL, so both show their initials.
    expect(find.byType(TeamMonogram), findsNWidgets(2));
    expect(find.text('CAN'), findsOneWidget);
    expect(find.text('CS'), findsOneWidget);
  });

  testWidgets('has a screen-reader label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(fab(finishedMatch()));
    expect(
      find.bySemanticsLabel('Canterbury versus Central Stags'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
