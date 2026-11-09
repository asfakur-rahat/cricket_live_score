import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:cricket_live_score/src/widgets/page_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// [count] finished matches at different grounds.
List<CricketMatch> _matches(int count) => [
      for (var i = 0; i < count; i++)
        finishedMatch(id: '$i').copyWith(venue: 'Ground $i'),
    ];

/// Shows [carousel] at the top of a scrolling page in a window [width]
/// wide, with scaling off so sizes are the plain design values: 16 padding
/// at the sides, 12 between cards, cards up to 330 wide, a 32 peek.
Future<void> _pump(
  WidgetTester tester,
  Widget carousel, {
  double width = 360,
  TextDirection textDirection = TextDirection.ltr,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: CricketScoreScaleScope(enabled: false, child: child!),
      ),
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: ListView(
            children: [
              const SizedBox(height: 50, child: Text('Above')),
              carousel,
              const SizedBox(height: 50, child: Text('Below')),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _card(int i) => find.ancestor(
      of: find.text('At Ground $i'),
      matching: find.byType(CricketMatchCard),
    );

ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CricketInlineScoreCarousel),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

void main() {
  group('states', () {
    testWidgets('loading, then the cards', (tester) async {
      final source = FakeSource()..pending = true;
      await _pump(tester, CricketInlineScoreCarousel(source: source));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The loading card spans the width inside the padding.
      expect(
        tester.getSize(find.byType(Material).last).width,
        360 - 32,
      );

      source.complete(_matches(2));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(CricketMatchCard), findsNWidgets(2));
    });

    testWidgets('empty, with the default text or a builder', (tester) async {
      await _pump(tester, CricketInlineScoreCarousel(source: FakeSource()));
      await tester.pump();
      expect(find.text('No matches right now'), findsOneWidget);

      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(),
          emptyBuilder: (_) => const Text('Nothing on'),
        ),
      );
      await tester.pump();
      expect(find.text('Nothing on'), findsOneWidget);
    });

    testWidgets('a first failure shows the error card, and retry recovers',
        (tester) async {
      final source = FakeSource(_matches(1))
        ..error = const CricketScoreException('down');
      await _pump(tester, CricketInlineScoreCarousel(source: source));
      await tester.pump();
      expect(find.text("Couldn't load scores"), findsOneWidget);

      source.error = null;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.byType(CricketMatchCard), findsOneWidget);
    });
  });

  group('height', () {
    testWidgets('fits the tallest card, and shorter cards stretch',
        (tester) async {
      final tall = finishedMatch(id: 'tall').copyWith(
        venue: 'Ground 1',
        status: 'A very long result line that wraps over several lines '
            'of the card, because it goes on and on about the match',
      );
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource([_matches(1).single, tall]),
        ),
      );
      final short = tester.getRect(_card(0));
      final tallRect = tester.getRect(_card(1));
      expect(short.height, tallRect.height);

      // The page goes on right under the cards and their padding.
      expect(tester.getTopLeft(find.text('Below')).dy, tallRect.bottom + 8);
      expect(tester.getBottomLeft(find.text('Above')).dy, tallRect.top - 8);
    });

    testWidgets('follows the cards when the matches change', (tester) async {
      final source = FakeSource(_matches(2));
      final controller = CricketScoreController(source: source)..start();
      await _pump(tester, CricketInlineScoreCarousel(controller: controller));
      final before = tester.getSize(_card(0)).height;

      source.matches = [
        _matches(1).single.copyWith(
              status: 'A very long result line that wraps over several lines '
                  'of the card, because it goes on and on about the match',
            ),
        _matches(2).last,
      ];
      await controller.refresh();
      await tester.pump();
      expect(tester.getSize(_card(0)).height, greaterThan(before));
      expect(tester.getSize(_card(1)).height, tester.getSize(_card(0)).height);
      controller.dispose();
    });
  });

  group('snap', () {
    testWidgets('a phone shows one card and the edge of the next',
        (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: FakeSource(_matches(3))),
      );
      final first = tester.getRect(_card(0));
      expect(first.left, 16);
      expect(first.width, 360 - 16 - 32 - 12);
      // The next card peeks in by 32.
      expect(tester.getRect(_card(1)).left, 360 - 32);
    });

    testWidgets('a swipe moves one card and settles on it', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: FakeSource(_matches(4))),
      );
      await tester.fling(_card(0), const Offset(-120, 0), 800);
      await tester.pumpAndSettle();
      // Settled with card 1 [spacing] from the edge, so nothing of card 0
      // shows.
      expect(tester.getRect(_card(1)).left, 12);
      expect(tester.getRect(_card(0)).right, 0);

      // A short drag back that isn't a fling settles on the nearest card.
      final gesture = await tester.startGesture(tester.getCenter(_card(1)));
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(_card(1)).left, 12);
    });

    testWidgets('the last card ends at the padding', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: FakeSource(_matches(3))),
      );
      for (var i = 0; i < 3; i++) {
        await tester.fling(
          find.byType(CricketInlineScoreCarousel),
          const Offset(-200, 0),
          800,
        );
        await tester.pumpAndSettle();
      }
      expect(tester.getRect(_card(2)).right, 360 - 16);
      expect(_position(tester).pixels, _position(tester).maxScrollExtent);
    });

    testWidgets('a wide window shows several cards', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: FakeSource(_matches(6))),
        width: 1000,
      );
      // (1000 - 16 - 32) / (330 + 12) rounds up to 3 cards.
      const width = (1000 - 16 - 32 - 3 * 12) / 3;
      expect(tester.getSize(_card(0)).width, moreOrLessEquals(width));
      expect(
        tester.getRect(_card(2)).right,
        moreOrLessEquals(16 + 3 * width + 2 * 12),
      );
      expect(tester.getRect(_card(3)).left, moreOrLessEquals(1000 - 32));
    });

    testWidgets('a single match fills the width', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: FakeSource(_matches(1))),
      );
      expect(tester.getSize(_card(0)).width, 360 - 32);
      expect(_position(tester).maxScrollExtent, 0);
    });

    testWidgets('settles back on a card when the width changes',
        (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: FakeSource(_matches(6))),
      );
      await tester.fling(_card(0), const Offset(-120, 0), 800);
      await tester.pumpAndSettle();
      expect(tester.getRect(_card(1)).left, 12);

      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();
      expect(tester.getRect(_card(1)).left, moreOrLessEquals(12));
    });

    testWidgets('right to left starts at the right', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: FakeSource(_matches(3))),
        textDirection: TextDirection.rtl,
      );
      expect(tester.getRect(_card(0)).right, 360 - 16);
      expect(tester.getRect(_card(1)).right, 32);

      await tester.fling(_card(0), const Offset(120, 0), 800);
      await tester.pumpAndSettle();
      expect(tester.getRect(_card(1)).right, 360 - 12);
    });
  });

  group('free scrolling', () {
    testWidgets('cards are cardWidth wide and stop anywhere', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(5)),
          snap: false,
          cardWidth: 200,
          showPageIndicator: true,
          autoScroll: true,
        ),
      );
      expect(tester.getSize(_card(0)).width, 200);
      expect(find.byType(PageDots), findsNothing);

      await tester.drag(_card(0), const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, moreOrLessEquals(150, epsilon: 25));

      // Auto-scroll is for snapping only.
      final offset = _position(tester).pixels;
      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, offset);
    });

    testWidgets('turning snapping on settles on a card', (tester) async {
      final source = FakeSource(_matches(5));
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: source, snap: false),
      );
      await tester.drag(_card(0), const Offset(-100, 0));
      await tester.pumpAndSettle();

      await _pump(tester, CricketInlineScoreCarousel(source: source));
      await tester.pumpAndSettle();
      expect(tester.getRect(_card(0)).left, 16);
    });
  });

  group('page dots', () {
    String position(WidgetTester tester) =>
        tester.getSemantics(find.byType(PageDots)).getSemanticsData().value;

    testWidgets('are off by default, and hidden when nothing scrolls',
        (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(source: FakeSource(_matches(3))),
      );
      expect(find.byType(PageDots), findsNothing);

      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(1)),
          showPageIndicator: true,
        ),
      );
      expect(find.byType(PageDots), findsNothing);
    });

    testWidgets('sit under the cards and follow swipes', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(3)),
          showPageIndicator: true,
        ),
      );
      final dots = tester.getRect(find.byType(PageDots));
      expect(dots.top, greaterThan(tester.getRect(_card(0)).bottom));
      expect(dots.center.dx, 180);
      expect(position(tester), 'Match 1 of 3');

      await tester.fling(_card(0), const Offset(-120, 0), 800);
      await tester.pumpAndSettle();
      expect(position(tester), 'Match 2 of 3');
    });

    testWidgets('there is one for each place the row stops', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(6)),
          showPageIndicator: true,
        ),
        width: 1000,
      );
      // Three cards show at once, so the row stops at cards 1 to 4.
      expect(position(tester), 'Match 1 of 4');
    });

    testWidgets('a tap on a dot scrolls to its card', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(5)),
          showPageIndicator: true,
        ),
      );
      await tester.tapAt(
        tester.getRect(find.byType(PageDots)).centerRight - const Offset(2, 0),
      );
      await tester.pumpAndSettle();
      expect(position(tester), 'Match 5 of 5');
      expect(tester.getRect(_card(4)).right, 360 - 16);
    });

    testWidgets('screen-reader increase moves on a card', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(3)),
          showPageIndicator: true,
        ),
      );
      final node = tester.getSemantics(find.byType(PageDots));
      node.owner!.performAction(node.id, SemanticsAction.increase);
      await tester.pumpAndSettle();
      expect(position(tester), 'Match 2 of 3');
      expect(tester.getRect(_card(1)).left, 12);
    });
  });

  group('auto-scroll', () {
    double offset(WidgetTester tester) => _position(tester).pixels;

    testWidgets('moves on a card each interval and wraps', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(2)),
          autoScroll: true,
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(offset(tester), _position(tester).maxScrollExtent);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(offset(tester), 0);
    });

    testWidgets('waits while a finger is on the cards', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(3)),
          autoScroll: true,
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(_card(0)));
      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(offset(tester), 0);

      await gesture.up();
      await tester.pumpAndSettle();
      // The interval starts over when the finger lifts.
      await tester.pump(const Duration(seconds: 4));
      expect(offset(tester), 0);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(tester.getRect(_card(1)).left, 12);
    });

    testWidgets('jumps instead of sliding with reduce motion', (tester) async {
      await _pump(
        tester,
        CricketInlineScoreCarousel(
          source: FakeSource(_matches(3)),
          autoScroll: true,
        ),
        reduceMotion: true,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.getRect(_card(1)).left, 12);
    });
  });

  testWidgets('onMatchTap receives the tapped match', (tester) async {
    CricketMatch? tapped;
    await _pump(
      tester,
      CricketInlineScoreCarousel(
        source: FakeSource(_matches(2)),
        onMatchTap: (match) => tapped = match,
      ),
    );
    await tester.tap(_card(0));
    expect(tapped?.id, '0');
    // No close button inline.
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('pauses polling in the background', (tester) async {
    final source = FakeSource(_matches(1));
    await _pump(tester, CricketInlineScoreCarousel(source: source));
    expect(source.calls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(source.calls, 2);
  });
}
