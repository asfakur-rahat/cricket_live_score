// Golden images are platform-sensitive: anti-aliasing differs between
// operating systems and even macOS versions. They run locally and CI skips
// them (`--exclude-tags golden`). Regenerate with
// `fvm flutter test --update-goldens test/widgets/goldens_test.dart`.
@Tags(['golden'])
library;

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('crossed bats icon', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: RepaintBoundary(
          child: ColoredBox(
            color: Color(0xFF2E7D32),
            child: CricketBatsIcon(color: Color(0xFFFFFFFF), size: 128),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/bats_icon.png'),
    );
  });

  testWidgets('match card with team initials at 360 dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(
        Padding(
          padding: const EdgeInsets.all(16),
          // Neither team has a logo URL.
          child: CricketMatchCard(match: finishedMatch()),
        ),
      ),
    );
    await expectLater(
      find.byType(CricketMatchCard),
      matchesGoldenFile('goldens/card_initials_360.png'),
    );
  });

  for (final width in [360.0, 600.0]) {
    final size = width.toInt();

    testWidgets('match card at $size dp', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: CricketLiveScoreCarousel(
              source: FakeSource([liveMatch(), finishedMatch()]),
              logoBuilder: fakeLogoBuilder,
              onClose: () {},
            ),
          ),
          width: width,
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(CricketLiveScoreCarousel),
        matchesGoldenFile('goldens/card_$size.png'),
      );
    });

    testWidgets('match FAB at $size dp', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CricketMatchFab(
                    match: liveMatch(),
                    logoBuilder: fakeLogoBuilder,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/fab_$size.png'),
      );
    });
  }

  group('dark', () {
    // An app's own dark colours, as in the README.
    final dark = ThemeData(
      colorSchemeSeed: Colors.green,
      brightness: Brightness.dark,
      extensions: const [
        CricketScoreThemeData(
          liveColor: Color(0xFFFF6B6B),
          liveChipColor: Color(0xFFE53935),
          liveChipForeground: Color(0xFFFFFFFF),
        ),
      ],
    );

    testWidgets('match card at 360 dp', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: CricketLiveScoreCarousel(
              source: FakeSource([liveMatch(), finishedMatch()]),
              logoBuilder: fakeLogoBuilder,
              onClose: () {},
              showPageIndicator: true,
            ),
          ),
          theme: dark,
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/card_360_dark.png'),
      );
    });

    testWidgets('match FAB and ticker at 360 dp', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 240));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: dark,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CricketScoreTicker(
                    source: FakeSource([liveMatch()]),
                    logoBuilder: fakeLogoBuilder,
                  ),
                  const SizedBox(height: 24),
                  CricketMatchFab(
                    match: liveMatch(),
                    logoBuilder: fakeLogoBuilder,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Let the fetch land and the ticker grow in.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/fab_ticker_360_dark.png'),
      );
    });
  });
}
