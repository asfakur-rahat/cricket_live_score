import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:cricket_live_score/src/widgets/page_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('loading, then loaded', (tester) async {
    final source = FakeSource()..pending = true;
    await tester.pumpWidget(
      app(CricketLiveScoreCarousel(source: source, onClose: () {})),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PageView), findsNothing);

    source.complete([finishedMatch(), liveMatch()]);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CricketMatchCard), findsOneWidget);
    expect(find.text('At McLean Park'), findsOneWidget);
  });

  testWidgets('a custom loadingBuilder replaces the spinner', (tester) async {
    final source = FakeSource()..pending = true;
    await tester.pumpWidget(
      app(
        CricketLiveScoreCarousel(
          source: source,
          loadingBuilder: (_) => const Text('Fetching…'),
        ),
      ),
    );
    expect(find.text('Fetching…'), findsOneWidget);
    source.complete(const []);
  });

  testWidgets('no matches shows the empty card, not a spinner', (tester) async {
    await tester
        .pumpWidget(app(CricketLiveScoreCarousel(source: FakeSource())));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('No matches right now'), findsOneWidget);

    await tester.pumpWidget(
      app(
        CricketLiveScoreCarousel(
          source: FakeSource(),
          emptyBuilder: (_) => const Text('Nothing on'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Nothing on'), findsOneWidget);
  });

  testWidgets('a first failure shows the error card, and retry recovers',
      (tester) async {
    final source = FakeSource([finishedMatch()])
      ..error = const CricketScoreException('down');
    await tester.pumpWidget(app(CricketLiveScoreCarousel(source: source)));
    await tester.pump();
    expect(find.text("Couldn't load scores"), findsOneWidget);

    source.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CricketMatchCard), findsOneWidget);
  });

  testWidgets('a custom errorBuilder gets the error and a retry callback',
      (tester) async {
    const failure = CricketScoreException('down');
    final source = FakeSource()..error = failure;
    Object? shownError;
    await tester.pumpWidget(
      app(
        CricketLiveScoreCarousel(
          source: source,
          errorBuilder: (context, error, retry) {
            shownError = error;
            return TextButton(onPressed: retry, child: const Text('Again'));
          },
        ),
      ),
    );
    await tester.pump();
    expect(shownError, failure);
    await tester.tap(find.text('Again'));
    await tester.pump();
    expect(source.calls, 2);
  });

  testWidgets('a later failure keeps showing the last matches', (tester) async {
    final source = FakeSource([finishedMatch()]);
    final controller = CricketScoreController(source: source)..start();
    await tester
        .pumpWidget(app(CricketLiveScoreCarousel(controller: controller)));
    await tester.pump();
    expect(find.byType(CricketMatchCard), findsOneWidget);

    source.error = const CricketScoreException('down');
    await controller.refresh();
    await tester.pump();
    expect(controller.state, isA<CricketScoreFailure>());
    expect(find.byType(CricketMatchCard), findsOneWidget);
    expect(find.text("Couldn't load scores"), findsNothing);
    controller.dispose();
  });

  testWidgets('close button calls onClose and is hidden when null',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var closed = 0;
    await tester.pumpWidget(
      app(
        CricketLiveScoreCarousel(
          source: FakeSource([finishedMatch()]),
          onClose: () => closed++,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    expect(closed, 1);
    expect(find.bySemanticsLabel('Close'), findsOneWidget);

    await tester.pumpWidget(
      app(CricketLiveScoreCarousel(source: FakeSource([finishedMatch()]))),
    );
    await tester.pump();
    expect(find.byIcon(Icons.close), findsNothing);
    semantics.dispose();
  });

  testWidgets('the loading card has a close button too', (tester) async {
    var closed = 0;
    final source = FakeSource()..pending = true;
    await tester.pumpWidget(
      app(CricketLiveScoreCarousel(source: source, onClose: () => closed++)),
    );
    await tester.tap(find.byIcon(Icons.close));
    expect(closed, 1);
    source.complete(const []);
  });

  testWidgets('onMatchTap receives the tapped match', (tester) async {
    CricketMatch? tapped;
    await tester.pumpWidget(
      app(
        CricketLiveScoreCarousel(
          source: FakeSource([finishedMatch()]),
          onMatchTap: (match) => tapped = match,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('At McLean Park'));
    expect(tapped, finishedMatch());
  });

  group('auto-scroll', () {
    Future<void> pumpCarousel(
      WidgetTester tester, {
      required bool autoScroll,
      int count = 3,
      FakeSource? source,
    }) async {
      await tester.pumpWidget(
        app(
          CricketLiveScoreCarousel(
            source: source ??
                FakeSource([
                  for (var i = 0; i < count; i++) finishedMatch(id: '$i'),
                ]),
            autoScroll: autoScroll,
          ),
        ),
      );
      await tester.pump();
    }

    double page(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView)).controller!.page!;

    testWidgets('advances after the interval and wraps around', (tester) async {
      await pumpCarousel(tester, autoScroll: true, count: 2);
      expect(page(tester), 0);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(page(tester), 1);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(page(tester), 0);
    });

    testWidgets('does nothing when off', (tester) async {
      await pumpCarousel(tester, autoScroll: false);
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(page(tester), 0);
    });

    testWidgets('waits while the user drags', (tester) async {
      await pumpCarousel(tester, autoScroll: true);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();

      await tester.pump(const Duration(seconds: 6));
      // Still held at the drag offset, not animated to the next page.
      expect(page(tester), lessThan(0.5));

      await gesture.moveBy(const Offset(20, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(page(tester), 0);

      // The interval restarts after the drag ends.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(page(tester), 1);
    });

    testWidgets('can be turned on and off after the first build',
        (tester) async {
      final source = FakeSource([
        for (var i = 0; i < 3; i++) finishedMatch(id: '$i'),
      ]);
      await pumpCarousel(tester, autoScroll: false, source: source);
      await pumpCarousel(tester, autoScroll: true, source: source);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(page(tester), 1);

      await pumpCarousel(tester, autoScroll: false, source: source);
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(page(tester), 1);
    });
  });

  testWidgets('clamps the page when the match list shrinks', (tester) async {
    final source = FakeSource([
      for (var i = 0; i < 3; i++) finishedMatch(id: '$i'),
    ]);
    final controller = CricketScoreController(source: source)..start();
    await tester
        .pumpWidget(app(CricketLiveScoreCarousel(controller: controller)));
    await tester.pump();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    pageView.controller!.jumpToPage(2);
    await tester.pump();

    source.matches = [finishedMatch(id: 'only')];
    await controller.refresh();
    await tester.pumpAndSettle();
    expect(pageView.controller!.page, 0);
    expect(find.byType(CricketMatchCard), findsOneWidget);
    controller.dispose();
  });

  testWidgets('pauses polling in the background and refreshes on resume',
      (tester) async {
    final source = FakeSource([finishedMatch()]);
    await tester.pumpWidget(app(CricketLiveScoreCarousel(source: source)));
    await tester.pump();
    expect(source.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));
    expect(source.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(source.calls, 2);

    await tester.pump(const Duration(seconds: 30));
    expect(source.calls, 3);
  });

  testWidgets('an injected controller is neither started nor disposed',
      (tester) async {
    final source = FakeSource([finishedMatch()]);
    final controller = CricketScoreController(source: source);
    await tester
        .pumpWidget(app(CricketLiveScoreCarousel(controller: controller)));
    expect(source.calls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(app(const SizedBox()));
    // Still usable: a disposed ChangeNotifier would throw here.
    controller
      ..addListener(() {})
      ..dispose();
  });

  testWidgets('switching from a source to a controller', (tester) async {
    final owned = FakeSource([finishedMatch()]);
    await tester.pumpWidget(app(CricketLiveScoreCarousel(source: owned)));
    await tester.pump();

    final controller = CricketScoreController(
      source: FakeSource([liveMatch()]),
    );
    addTearDown(controller.dispose);
    await tester
        .pumpWidget(app(CricketLiveScoreCarousel(controller: controller)));
    await controller.refresh();
    await tester.pump();
    expect(find.text('At Bert Sutcliffe Oval'), findsOneWidget);

    // The owned controller was disposed and stops polling.
    await tester.pump(const Duration(minutes: 1));
    expect(owned.calls, 1);
  });

  testWidgets('maxWidth and maxHeight cap the carousel', (tester) async {
    await tester.pumpWidget(
      app(
        Align(
          child: CricketLiveScoreCarousel(
            source: FakeSource([finishedMatch()]),
            maxWidth: 300,
            maxHeight: 400,
          ),
        ),
        width: 600,
      ),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(PageView)), const Size(300, 400));
  });

  testWidgets('without maxWidth, a phone keeps the full width', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(CricketLiveScoreCarousel(source: FakeSource([finishedMatch()]))),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(PageView)).width, 360);
  });

  testWidgets('without maxWidth, a wide window caps it at the dialog width',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        Align(
          child:
              CricketLiveScoreCarousel(source: FakeSource([finishedMatch()])),
        ),
        width: 1000,
      ),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(PageView)).width, 560);
  });

  testWidgets('passes theme, labels, logoBuilder and centerBadge to cards',
      (tester) async {
    await tester.pumpWidget(
      app(
        CricketLiveScoreCarousel(
          source: FakeSource([liveMatch()]),
          theme: const CricketScoreThemeData(liveColor: Color(0xFF00FF00)),
          labels: const CricketScoreLabels(live: 'EN DIRECT'),
          logoBuilder: fakeLogoBuilder,
          centerBadge: const Text('vs'),
        ),
      ),
    );
    await tester.pump();
    final live = tester.widget<Text>(find.text('- EN DIRECT -'));
    expect(live.style!.color, const Color(0xFF00FF00));
    expect(find.byKey(const ValueKey('logo:India A')), findsOneWidget);
    expect(find.text('vs'), findsOneWidget);
  });

  group('page dots', () {
    List<CricketMatch> matches(int count) => [
          for (var i = 0; i < count; i++)
            finishedMatch(id: '$i').copyWith(venue: 'Ground $i'),
        ];

    Future<void> pumpDots(
      WidgetTester tester, {
      int count = 3,
      bool show = true,
      CricketScoreLabels labels = const CricketScoreLabels(),
    }) async {
      await tester.pumpWidget(
        app(
          CricketLiveScoreCarousel(
            source: FakeSource(matches(count)),
            showPageIndicator: show,
            labels: labels,
          ),
        ),
      );
      await tester.pump();
    }

    String position(WidgetTester tester) =>
        tester.getSemantics(find.byType(PageDots)).getSemanticsData().value;

    testWidgets('are off by default', (tester) async {
      await pumpDots(tester, show: false);
      expect(find.byType(PageDots), findsNothing);
    });

    testWidgets('are hidden for a single match', (tester) async {
      await pumpDots(tester, count: 1);
      expect(find.byType(PageDots), findsNothing);
    });

    testWidgets('sit just under the card', (tester) async {
      await pumpDots(tester);
      expect(find.byType(PageDots), findsOneWidget);
      final card = tester.getRect(find.byType(CricketMatchCard));
      final dots = tester.getRect(find.byType(PageDots));
      expect(dots.top, greaterThan(card.bottom));
      expect(dots.top - card.bottom, lessThan(20));
      expect(dots.center.dx, moreOrLessEquals(card.center.dx));
    });

    testWidgets('follow swipes and tell screen readers the position',
        (tester) async {
      await pumpDots(tester);
      expect(position(tester), 'Match 1 of 3');

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('At Ground 1'), findsOneWidget);
      expect(find.byType(PageDots), findsOneWidget);
      expect(position(tester), 'Match 2 of 3');
    });

    testWidgets('stay in place while the pages slide', (tester) async {
      await pumpDots(tester);
      final before = tester.getRect(find.byType(PageDots));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      // Both pages' dots are on screen, at the same place.
      final dots = find.byType(PageDots);
      expect(dots, findsNWidgets(2));
      expect(tester.getRect(dots.first).center.dx, before.center.dx);
      expect(tester.getRect(dots.last).center.dx, before.center.dx);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a tap on a dot jumps to its match', (tester) async {
      await pumpDots(tester, count: 5);
      final dots = tester.getRect(find.byType(PageDots));
      await tester.tapAt(dots.centerRight - const Offset(2, 0));
      await tester.pumpAndSettle();
      expect(find.text('At Ground 4'), findsOneWidget);
      expect(position(tester), 'Match 5 of 5');

      await tester.tapAt(
        tester.getRect(find.byType(PageDots)).centerLeft + const Offset(2, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('At Ground 0'), findsOneWidget);
    });

    testWidgets('screen-reader increase and decrease change the match',
        (tester) async {
      await pumpDots(tester);
      void act(SemanticsAction action) {
        final node = tester.getSemantics(find.byType(PageDots));
        node.owner!.performAction(node.id, action);
      }

      expect(
        tester
            .getSemantics(find.byType(PageDots))
            .getSemanticsData()
            .increasedValue,
        'Match 2 of 3',
      );
      act(SemanticsAction.increase);
      await tester.pumpAndSettle();
      expect(position(tester), 'Match 2 of 3');
      act(SemanticsAction.decrease);
      await tester.pumpAndSettle();
      expect(position(tester), 'Match 1 of 3');
    });

    testWidgets('show at most seven dots however many matches', (tester) async {
      await pumpDots(tester, count: 7);
      final seven = tester.getSize(find.byType(PageDots)).width;
      await pumpDots(tester, count: 26);
      expect(tester.getSize(find.byType(PageDots)).width, seven);
      await pumpDots(tester, count: 4);
      expect(tester.getSize(find.byType(PageDots)).width, lessThan(seven));
    });

    testWidgets('with many matches the row reaches the last one',
        (tester) async {
      await pumpDots(tester, count: 26);
      // The last dot showing is the seventh match's.
      await tester.tapAt(
        tester.getRect(find.byType(PageDots)).centerRight - const Offset(2, 0),
      );
      await tester.pumpAndSettle();
      expect(position(tester), 'Match 7 of 26');
      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(25);
      await tester.pumpAndSettle();
      expect(position(tester), 'Match 26 of 26');
      expect(find.text('At Ground 25'), findsOneWidget);
    });

    testWidgets('use the position formatter', (tester) async {
      await pumpDots(
        tester,
        labels: CricketScoreLabels(
          formatPagePosition: (page, count) => '$page / $count',
        ),
      );
      expect(position(tester), '1 / 3');
    });
  });
}
