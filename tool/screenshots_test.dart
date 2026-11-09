// Renders the README / pub.dev screenshots with real fonts.
//
//   fvm flutter test --update-goldens tool/screenshots_test.dart
//
// Not part of the test suite: it lives outside test/ and writes into
// screenshots/.
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

Widget _logo(BuildContext context, TeamInfo team, double radius) {
  final colors = {
    'Bangladesh': const Color(0xFF006A4E),
    'Sri Lanka': const Color(0xFF0D47A1),
  };
  return CircleAvatar(
    radius: radius,
    backgroundColor: colors[team.name] ?? Colors.blueGrey,
    child: Text(
      team.name.split(' ').map((w) => w[0]).join(),
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * 0.7,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

final _match = CricketMatch(
  id: 'demo-1',
  matchType: 'T20',
  venue: 'Sher-e-Bangla National Stadium, Mirpur',
  status: 'Sri Lanka need 38 runs in 24 balls',
  team1: const TeamInfo(name: 'Bangladesh', logoUrl: 'demo://ban'),
  team2: const TeamInfo(name: 'Sri Lanka', logoUrl: 'demo://sl'),
  startTimeText: '9 Dec 2026, Wed 09:30 GMT',
  startTime: DateTime.utc(2026, 12, 9, 9, 30),
  teamScores: const [
    TeamScore(teamName: 'Bangladesh', scoreText: '168/6 (20)'),
    TeamScore(teamName: 'Sri Lanka', scoreText: '131/4 (16)'),
  ],
  isLive: true,
);

class _Source implements CricketScoreSource {
  @override
  Future<List<CricketMatch>> fetchMatches() async => [_match];
}

Widget _screen({required Widget body, Widget? fab}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.green, fontFamily: 'Roboto'),
    home: Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: body,
      floatingActionButton: fab,
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    Widget app,
    String name,
  ) async {
    debugDisableShadows = false;
    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 3;
    await tester.pumpWidget(app);
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/$name.png'),
    );
    tester.view.reset();
    debugDisableShadows = true;
  }

  testWidgets('carousel', (tester) async {
    await shoot(
      tester,
      _screen(
        body: ColoredBox(
          color: Colors.black54,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CricketLiveScoreCarousel(
                source: _Source(),
                logoBuilder: _logo,
                maxHeight: 420,
                onClose: () {},
              ),
            ),
          ),
        ),
      ),
      'carousel',
    );
  });

  testWidgets('fab', (tester) async {
    await shoot(
      tester,
      _screen(
        body: const Center(child: Text('Your app content')),
        fab: CricketMatchFab(match: _match, logoBuilder: _logo, onTap: () {}),
      ),
      'fab',
    );
  });
}
