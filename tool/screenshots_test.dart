// Renders the README / pub.dev screenshots with real fonts and made-up
// matches.
//
//   fvm flutter test --update-goldens tool/screenshots_test.dart
//
// Not part of the test suite: it lives outside test/ and writes into
// screenshots/.
import 'dart:async';
import 'dart:io';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFonts() async {
  // flutter_tester lives under <flutter>/bin/cache/…; the fonts sit beside it.
  var dir = File(Platform.resolvedExecutable).parent;
  while (!Directory('${dir.path}/bin/cache').existsSync()) {
    dir = dir.parent;
  }
  final fonts = '${dir.path}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(File('$fonts/$name').readAsBytesSync());

  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(read('Roboto-$weight.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')
        ..addFont(read('MaterialIcons-Regular.otf')))
      .load();
}

/// Short codes and colours for the made-up logos.
const _teams = {
  'Bangladesh': ('BAN', Color(0xFF006A4E)),
  'Sri Lanka': ('SL', Color(0xFF0D47A1)),
  'India': ('IND', Color(0xFFEF6C00)),
  'Australia': ('AUS', Color(0xFF00843D)),
  'England': ('ENG', Color(0xFF1A237E)),
  'New Zealand': ('NZ', Color(0xFF212121)),
  'Pakistan': ('PAK', Color(0xFF01411C)),
  'South Africa': ('SA', Color(0xFF00695C)),
  'West Indies': ('WI', Color(0xFF7B1E3A)),
  'Afghanistan': ('AFG', Color(0xFF1565C0)),
  'Ireland': ('IRE', Color(0xFF43A047)),
  'Zimbabwe': ('ZIM', Color(0xFFC62828)),
};

/// A coloured disc with the team's short code, instead of a network logo.
Widget _logo(BuildContext context, TeamInfo team, double radius) {
  final (code, color) = _teams[team.name] ?? ('?', Colors.blueGrey);
  return CircleAvatar(
    radius: radius,
    backgroundColor: color,
    child: Text(
      code,
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * (code.length > 2 ? 0.55 : 0.7),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

TeamInfo _team(String name, {bool winner = false}) =>
    TeamInfo(name: name, logoUrl: 'demo://$name', isWinner: winner);

final _matches = [
  CricketMatch(
    id: 'ban-sl',
    matchType: 'T20',
    venue: 'Sher-e-Bangla National Stadium, Mirpur',
    status: 'Sri Lanka need 38 runs in 24 balls',
    team1: _team('Bangladesh'),
    team2: _team('Sri Lanka'),
    startTimeText: '9 Dec 2026, Wed 09:30 GMT',
    startTime: DateTime.utc(2026, 12, 9, 9, 30),
    teamScores: const [
      TeamScore(teamName: 'Bangladesh', scoreText: '168/6 (20)'),
      TeamScore(teamName: 'Sri Lanka', scoreText: '131/4 (16)'),
    ],
    isLive: true,
  ),
  CricketMatch(
    id: 'ind-aus',
    matchType: 'ODI',
    venue: 'Wankhede Stadium, Mumbai',
    status: 'India need 74 runs in 62 balls',
    team1: _team('India'),
    team2: _team('Australia'),
    startTimeText: '9 Dec 2026, Wed 08:00 GMT',
    startTime: DateTime.utc(2026, 12, 9, 8),
    teamScores: const [
      TeamScore(teamName: 'Australia', scoreText: '287/8 (50)'),
      TeamScore(teamName: 'India', scoreText: '214/4 (39.4)'),
    ],
    isLive: true,
  ),
  CricketMatch(
    id: 'eng-nz',
    matchType: 'TEST',
    venue: "Lord's, London",
    status: 'Day 2: Lunch - England lead by 112 runs',
    team1: _team('England'),
    team2: _team('New Zealand'),
    startTimeText: '8 Dec 2026, Tue 10:00 GMT',
    startTime: DateTime.utc(2026, 12, 8, 10),
    teamScores: const [
      TeamScore(teamName: 'England', scoreText: '342 (98.3)'),
      TeamScore(teamName: 'New Zealand', scoreText: '230/6 (61)'),
    ],
    isLive: true,
  ),
  CricketMatch(
    id: 'pak-sa',
    matchType: 'T20',
    venue: 'Gaddafi Stadium, Lahore',
    status: 'Pakistan won by 6 wkts',
    team1: _team('Pakistan', winner: true),
    team2: _team('South Africa'),
    startTimeText: '8 Dec 2026, Tue 14:00 GMT',
    startTime: DateTime.utc(2026, 12, 8, 14),
    teamScores: const [
      TeamScore(teamName: 'South Africa', scoreText: '158/7 (20)'),
      TeamScore(teamName: 'Pakistan', scoreText: '161/4 (18.2)'),
    ],
  ),
  CricketMatch(
    id: 'ire-zim',
    matchType: 'ODI',
    venue: 'Harare Sports Club',
    status: 'Zimbabwe won by 27 runs',
    team1: _team('Zimbabwe', winner: true),
    team2: _team('Ireland'),
    startTimeText: '7 Dec 2026, Mon 08:30 GMT',
    startTime: DateTime.utc(2026, 12, 7, 8, 30),
    teamScores: const [
      TeamScore(teamName: 'Zimbabwe', scoreText: '254/9 (50)'),
      TeamScore(teamName: 'Ireland', scoreText: '227 (47.1)'),
    ],
  ),
  CricketMatch(
    id: 'wi-afg',
    matchType: 'ODI',
    venue: 'Kensington Oval, Bridgetown',
    status: 'Match starts at 10 Dec, 13:30 GMT',
    team1: _team('West Indies'),
    team2: _team('Afghanistan'),
    startTimeText: '10 Dec 2026, Thu 13:30 GMT',
    startTime: DateTime.utc(2026, 12, 10, 13, 30),
  ),
];

class _Source implements CricketScoreSource {
  @override
  Future<List<CricketMatch>> fetchMatches() async => _matches;
}

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return ThemeData(
    colorSchemeSeed: Colors.green,
    brightness: brightness,
    fontFamily: 'Roboto',
    extensions: [
      if (dark)
        const CricketScoreThemeData(
          liveColor: Color(0xFFFF6B6B),
          liveChipColor: Color(0xFFE53935),
          liveChipForeground: Color(0xFFFFFFFF),
        )
      else
        const CricketScoreThemeData(
          liveColor: Color(0xFFD32F2F),
          liveChipColor: Color(0xFFD32F2F),
          cardElevation: 2,
        ),
    ],
  );
}

Widget _app(Widget home, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _theme(brightness),
    home: home,
  );
}

/// A home page with a ticker, a "Live now" section and the floating button.
Widget _home(BuildContext context) {
  final text = Theme.of(context).textTheme;
  return Scaffold(
    appBar: AppBar(title: const Text('Cricket')),
    body: ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: CricketScoreTicker(source: _Source(), logoBuilder: _logo),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(child: Text('Live now', style: text.titleMedium)),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
        ),
        CricketInlineScoreCarousel(
          source: _Source(),
          logoBuilder: _logo,
          showPageIndicator: true,
        ),
        const SizedBox(height: 8),
        for (final (icon, title) in const [
          (Icons.event_outlined, 'Fixtures'),
          (Icons.leaderboard_outlined, 'Standings'),
          (Icons.newspaper_outlined, 'News'),
        ])
          ListTile(leading: Icon(icon), title: Text(title)),
      ],
    ),
    floatingActionButton: CricketMatchFab(
      match: _matches.first,
      logoBuilder: _logo,
      onTap: () {},
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  const phone = Size(1080, 2340); // 360 × 780 at 3×
  const tablet = Size(2400, 1500); // 1200 × 750 at 2×

  /// Pumps [app] on a [size] screen, lets the matches load, and saves it as
  /// screenshots/[name].png. With [of], only that widget is saved; it must
  /// sit under a RepaintBoundary.
  Future<void> shoot(
    WidgetTester tester,
    Widget app,
    String name, {
    Size size = phone,
    double pixelRatio = 3,
    Finder? of,
    Future<void> Function()? before,
  }) async {
    debugDisableShadows = false;
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = pixelRatio;
    await tester.pumpWidget(app);
    await tester.pump();
    await before?.call();
    // Let the pulsing and sliding settle into a frame.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      of ?? find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/$name.png'),
    );
    tester.view.reset();
    debugDisableShadows = true;
  }

  /// [child] alone on the page colour, for a close-up.
  Widget panel(Widget child, {Brightness brightness = Brightness.light}) {
    return _app(
      Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              key: const ValueKey('panel'),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: child,
              ),
            ),
          ),
        ),
      ),
      brightness: brightness,
    );
  }

  testWidgets('home', (tester) async {
    await shoot(tester, _app(const Builder(builder: _home)), 'home');
  });

  testWidgets('home, dark', (tester) async {
    await shoot(
      tester,
      _app(const Builder(builder: _home), brightness: Brightness.dark),
      'home_dark',
    );
  });

  testWidgets('carousel', (tester) async {
    await shoot(
      tester,
      _app(
        Scaffold(
          appBar: AppBar(title: const Text('Cricket')),
          body: ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CricketLiveScoreCarousel(
                  source: _Source(),
                  logoBuilder: _logo,
                  showPageIndicator: true,
                  maxHeight: 520,
                  onClose: () {},
                ),
              ),
            ),
          ),
        ),
      ),
      'carousel',
    );
  });

  testWidgets('inline carousel on a tablet', (tester) async {
    await shoot(
      tester,
      panel(
        Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Live now',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              CricketInlineScoreCarousel(
                source: _Source(),
                logoBuilder: _logo,
                showPageIndicator: true,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      'inline_tablet',
      size: tablet,
      pixelRatio: 2,
      of: find.byKey(const ValueKey('panel')),
    );
  });

  testWidgets('ticker', (tester) async {
    Widget label(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
    await shoot(
      tester,
      panel(
        SizedBox(
          width: 430,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label('CricketTickerMode.rotate'),
                CricketScoreTicker(source: _Source(), logoBuilder: _logo),
                label('CricketTickerMode.crawl'),
                CricketScoreTicker(
                  source: _Source(),
                  logoBuilder: _logo,
                  mode: CricketTickerMode.crawl,
                ),
              ],
            ),
          ),
        ),
      ),
      'ticker',
      size: const Size(1290, 2796), // a larger phone, 430 wide
      of: find.byKey(const ValueKey('panel')),
      // Let the crawl move off its start.
      before: () async {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    );
  });

  testWidgets('score screen', (tester) async {
    await shoot(
      tester,
      _app(
        Scaffold(
          appBar: AppBar(title: const Text('Live scores')),
          body: CricketLiveScoreView(source: _Source(), logoBuilder: _logo),
        ),
      ),
      'screen',
    );
  });

  testWidgets('score screen on a tablet', (tester) async {
    await shoot(
      tester,
      _app(
        Scaffold(
          appBar: AppBar(title: const Text('Live scores')),
          body: CricketLiveScoreView(source: _Source(), logoBuilder: _logo),
        ),
      ),
      'screen_tablet',
      size: tablet,
      pixelRatio: 2,
    );
  });

  testWidgets('sheet', (tester) async {
    await shoot(
      tester,
      _app(const Builder(builder: _home)),
      'sheet',
      before: () async {
        unawaited(
          showCricketLiveScoreSheet(
            tester.element(find.byType(ListView)),
            source: _Source(),
            title: 'Live scores',
            logoBuilder: _logo,
          ),
        );
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    );
  });

  testWidgets('fab', (tester) async {
    await shoot(
      tester,
      _app(
        Scaffold(
          appBar: AppBar(title: const Text('Cricket')),
          body: const Center(child: Text('Your app content')),
          floatingActionButton: CricketMatchFab(
            match: _matches.first,
            logoBuilder: _logo,
            onTap: () {},
          ),
        ),
      ),
      'fab',
    );
  });
}
