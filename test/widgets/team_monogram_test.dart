import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const _australia = TeamInfo(name: 'Australia', logoUrl: '');
const _newZealand = TeamInfo(name: 'New Zealand', logoUrl: '');

Color _colorOf(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(TeamMonogram),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as ShapeDecoration).color!;
}

/// The contrast ratio of white text on [color].
double _contrastWithWhite(Color color) =>
    1.05 / (color.computeLuminance() + 0.05);

void main() {
  testWidgets('shows the initials in a circle of the radius', (tester) async {
    await tester.pumpWidget(
      app(const Center(child: TeamMonogram(team: _australia, radius: 24))),
    );
    expect(find.text('AUS'), findsOneWidget);
    expect(tester.getSize(find.byType(TeamMonogram)), const Size(48, 48));
    final text = tester.getRect(find.text('AUS'));
    final circle = tester.getRect(find.byType(TeamMonogram));
    expect(circle.contains(text.topLeft), isTrue);
    expect(circle.contains(text.bottomRight), isTrue);
  });

  testWidgets('three letters shrink to fit a small circle', (tester) async {
    await tester.pumpWidget(
      app(const Center(child: TeamMonogram(team: _australia, radius: 9))),
    );
    final text = tester.getRect(find.text('AUS'));
    final circle = tester.getRect(find.byType(TeamMonogram));
    expect(text.width, lessThan(circle.width));
    expect(tester.takeException(), isNull);
  });

  test('a team always gets the same palette colour', () {
    expect(TeamMonogram.palette, hasLength(12));
    final colour = TeamMonogram.colorOf(_australia);
    expect(TeamMonogram.palette, contains(colour));
    expect(TeamMonogram.colorOf(_australia), colour);
    expect(
      TeamMonogram.colorOf(const TeamInfo(name: ' australia ', logoUrl: '')),
      colour,
    );
    // Spread over the palette rather than all one colour.
    final colours = {
      for (final name in [
        'Australia',
        'Bangladesh',
        'England',
        'India',
        'New Zealand',
        'Pakistan',
        'South Africa',
        'Sri Lanka',
        'West Indies',
        'Ireland',
      ])
        TeamMonogram.colorOf(TeamInfo(name: name, logoUrl: '')),
    };
    expect(colours.length, greaterThan(5));
  });

  test('the two sides of a match never share a colour', () {
    const names = [
      'Australia',
      'Bangladesh',
      'England',
      'India',
      'New Zealand',
      'Pakistan',
      'South Africa',
      'Sri Lanka',
      'West Indies',
      'Ireland',
      'Zimbabwe',
      'Afghanistan',
      'Netherlands',
      'Scotland',
      'Nepal',
    ];
    final teams = [for (final n in names) TeamInfo(name: n, logoUrl: '')];
    var clashes = 0;
    for (final a in teams) {
      for (final b in teams) {
        if (a == b) continue;
        final colourA = TeamMonogram.colorOf(a, opponent: b);
        final colourB = TeamMonogram.colorOf(b, opponent: a);
        expect(colourA, isNot(colourB), reason: '${a.name} v ${b.name}');
        if (TeamMonogram.colorOf(a) == TeamMonogram.colorOf(b)) {
          clashes++;
          // The name that sorts first keeps its own colour.
          final first =
              a.name.toLowerCase().compareTo(b.name.toLowerCase()) < 0 ? a : b;
          final second = first == a ? b : a;
          expect(
            TeamMonogram.colorOf(first, opponent: second),
            TeamMonogram.colorOf(first),
          );
        }
      }
    }
    // The list has at least one pair that shares a palette colour.
    expect(clashes, greaterThan(0));
  });

  test('white letters are readable on every palette colour', () {
    for (final colour in TeamMonogram.palette) {
      expect(_contrastWithWhite(colour), greaterThanOrEqualTo(4.5));
    }
  });

  testWidgets('uses the team colour, or the theme colour when set',
      (tester) async {
    await tester.pumpWidget(
      app(const Center(child: TeamMonogram(team: _newZealand, radius: 24))),
    );
    expect(_colorOf(tester), TeamMonogram.colorOf(_newZealand));
    final style = tester.widget<Text>(find.text('NZ')).style!;
    expect(style.color, const Color(0xFFFFFFFF));
    expect(style.fontWeight, FontWeight.w700);

    await tester.pumpWidget(
      app(
        const Center(
          child: TeamMonogram(
            team: _newZealand,
            radius: 24,
            theme: CricketScoreThemeData(
              monogramBackground: Color(0xFFFFEB3B),
              monogramForeground: Color(0xFF000000),
              monogramTextStyle: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
    expect(_colorOf(tester), const Color(0xFFFFEB3B));
    final custom = tester.widget<Text>(find.text('NZ')).style!;
    expect(custom.color, const Color(0xFF000000));
    expect(custom.fontWeight, FontWeight.w400);
  });

  testWidgets('formatTeamInitials replaces the rule', (tester) async {
    await tester.pumpWidget(
      app(
        Center(
          child: TeamMonogram(
            team: const TeamInfo(name: 'Bangladesh', logoUrl: ''),
            radius: 24,
            labels: CricketScoreLabels(
              formatTeamInitials: (name) => name == 'Bangladesh' ? 'BNG' : '',
            ),
          ),
        ),
      ),
    );
    expect(find.text('BNG'), findsOneWidget);
  });

  testWidgets('screen readers skip it', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(const Center(child: TeamMonogram(team: _australia, radius: 24))),
    );
    expect(find.bySemanticsLabel('AUS'), findsNothing);
    semantics.dispose();
  });

  testWidgets('the default builder shows initials without a URL',
      (tester) async {
    await tester.pumpWidget(
      app(
        Center(
          child: Builder(
            builder: (context) =>
                defaultTeamLogoBuilder(context, _australia, 24),
          ),
        ),
      ),
    );
    expect(find.text('AUS'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the default builder shows initials while a logo loads',
      (tester) async {
    await tester.pumpWidget(
      app(
        Center(
          child: Builder(
            builder: (context) => defaultTeamLogoBuilder(
              context,
              const TeamInfo(
                name: 'Australia',
                logoUrl: 'https://example.com/aus.png',
              ),
              24,
            ),
          ),
        ),
      ),
    );
    // Before the request has failed or loaded.
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('AUS'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('AUS'), findsOneWidget);
  });

  group('ticker', () {
    Future<void> pump(WidgetTester tester, {bool showLogos = true}) async {
      final live = finishedMatch().copyWith(isLive: true);
      await tester.pumpWidget(
        app(
          CricketScoreTicker(
            source: FakeSource([live]),
            showLogos: showLogos,
          ),
          width: 400,
        ),
      );
      // The LIVE dot pulses, so pumpAndSettle would never return.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    testWidgets('shows initials for teams without a logo', (tester) async {
      await pump(tester);
      expect(find.byType(TeamMonogram), findsNWidgets(2));
      expect(find.text('CAN'), findsOneWidget);
      expect(find.text('CS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows none with showLogos off', (tester) async {
      await pump(tester, showLogos: false);
      expect(find.byType(TeamMonogram), findsNothing);
    });
  });
}
