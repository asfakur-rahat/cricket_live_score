// Golden images are platform-sensitive (font rasterisation differs between
// macOS and Linux). Regenerate with `fvm flutter test --update-goldens
// test/widgets/goldens_test.dart` on the platform that runs CI.
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
}
