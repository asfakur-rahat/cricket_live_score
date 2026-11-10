import 'dart:ui' show ImageFilter;

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Pumps an app whose button opens the dialog through [open], in a phone
/// window unless [window] says otherwise, and taps the button.
Future<void> _open(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open, {
  Size window = const Size(400, 900),
}) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await _settle(tester);
}

/// Lets the route animations finish; the pulsing Live dot never settles,
/// so pumpAndSettle would time out.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// The blur over the route's barrier, or `null` when there is none.
BackdropFilter? _barrierBlur(WidgetTester tester) {
  final filters = find.ancestor(
    of: find.byType(ModalBarrier).last,
    matching: find.byType(BackdropFilter),
  );
  if (filters.evaluate().isEmpty) return null;
  return tester.widget<BackdropFilter>(filters.first);
}

void main() {
  testWidgets('shows the cards with a close button and page dots',
      (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreDialog(
        context,
        source: FakeSource([liveMatch(), finishedMatch()]),
        showPageIndicator: true,
      ),
    );
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(CricketMatchCard), findsWidgets);
    expect(find.byIcon(Icons.close), findsWidgets);
    expect(find.byType(CricketLiveScoreCarousel), findsOneWidget);
    expect(
      tester
          .widget<CricketLiveScoreCarousel>(
            find.byType(CricketLiveScoreCarousel),
          )
          .showPageIndicator,
      isTrue,
    );
  });

  testWidgets('the close button closes it and completes the future',
      (tester) async {
    var closed = false;
    await _open(
      tester,
      (context) => showCricketLiveScoreDialog(
        context,
        source: FakeSource([finishedMatch()]),
      ).then((_) => closed = true),
    );
    await tester.tap(find.byIcon(Icons.close).first);
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(closed, isTrue);
  });

  testWidgets('a tap outside closes it', (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreDialog(
        context,
        source: FakeSource([finishedMatch()]),
      ),
    );
    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
  });

  group('with barrierDismissible false', () {
    Future<void> openFixed(WidgetTester tester) => _open(
          tester,
          (context) => showCricketLiveScoreDialog(
            context,
            source: FakeSource([finishedMatch()]),
            barrierDismissible: false,
          ),
        );

    testWidgets('a tap outside does nothing', (tester) async {
      await openFixed(tester);
      await tester.tapAt(const Offset(5, 5));
      await _settle(tester);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('the close button closes it', (tester) async {
      await openFixed(tester);
      await tester.tap(find.byIcon(Icons.close).first);
      await _settle(tester);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('the back button closes it', (tester) async {
      await openFixed(tester);
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.byType(Dialog), findsNothing);
    });
  });

  testWidgets(
      'opened by the app inside a PopScope, back is blocked and the close '
      'button still works', (tester) async {
    await _open(
      tester,
      (context) => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: PopScope(
            canPop: false,
            child: CricketLiveScoreCarousel(
              source: FakeSource([finishedMatch()]),
              onClose: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).first);
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('the loading card can be closed too', (tester) async {
    final source = FakeSource([finishedMatch()])..pending = true;
    await _open(
      tester,
      (context) => showCricketLiveScoreDialog(
        context,
        source: source,
        barrierDismissible: false,
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await _settle(tester);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('closing stops the polling it started', (tester) async {
    final source = FakeSource([finishedMatch()]);
    await _open(
      tester,
      (context) => showCricketLiveScoreDialog(context, source: source),
    );
    await tester.tap(find.byIcon(Icons.close).first);
    await _settle(tester);
    final calls = source.calls;
    await tester.pump(const Duration(minutes: 2));
    expect(source.calls, calls);
  });

  testWidgets('a custom barrier colour and the carousel options pass through',
      (tester) async {
    Object? tapped;
    await _open(
      tester,
      (context) => showCricketLiveScoreDialog(
        context,
        source: FakeSource([finishedMatch()]),
        barrierColor: const Color(0x80FF0000),
        autoScroll: true,
        autoScrollInterval: const Duration(seconds: 9),
        maxWidth: 300,
        labels: const CricketScoreLabels(close: 'Fermer'),
        onMatchTap: (match) => tapped = match,
      ),
    );
    final barrier = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(barrier.color, const Color(0x80FF0000));
    final carousel = tester.widget<CricketLiveScoreCarousel>(
      find.byType(CricketLiveScoreCarousel),
    );
    expect(carousel.autoScroll, isTrue);
    expect(carousel.autoScrollInterval, const Duration(seconds: 9));
    expect(carousel.labels.close, 'Fermer');
    expect(tester.getSize(find.byType(CricketLiveScoreCarousel)).width, 300);
    await tester.tap(find.byType(CricketMatchCard));
    expect(tapped, isNotNull);
  });

  group('with barrierBlur', () {
    Future<void> openBlurred(
      WidgetTester tester, {
      bool barrierDismissible = true,
      void Function()? onDone,
    }) =>
        _open(
          tester,
          (context) => showCricketLiveScoreDialog(
            context,
            source: FakeSource([finishedMatch()]),
            barrierBlur: 20,
            barrierDismissible: barrierDismissible,
          ).then((_) => onDone?.call()),
        );

    testWidgets('there is no blur by default', (tester) async {
      await _open(
        tester,
        (context) => showCricketLiveScoreDialog(
          context,
          source: FakeSource([finishedMatch()]),
        ),
      );
      expect(_barrierBlur(tester), isNull);
    });

    testWidgets('the blur fades in with the popup and out as it closes',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCricketLiveScoreDialog(
                context,
                source: FakeSource([finishedMatch()]),
                barrierBlur: 20,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final opening = _barrierBlur(tester)!;
      expect(opening.enabled, isTrue);
      expect(opening.filter, isNot(ImageFilter.blur(sigmaX: 20, sigmaY: 20)));

      await _settle(tester);
      final open = _barrierBlur(tester)!;
      expect(open.enabled, isTrue);
      expect(open.filter, ImageFilter.blur(sigmaX: 20, sigmaY: 20));

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        _barrierBlur(tester)!.filter,
        isNot(ImageFilter.blur(sigmaX: 20, sigmaY: 20)),
      );
      await _settle(tester);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('a tap outside closes it and completes the future',
        (tester) async {
      var closed = false;
      await openBlurred(tester, onDone: () => closed = true);
      await tester.tapAt(const Offset(5, 5));
      await _settle(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('barrierDismissible false still holds', (tester) async {
      await openBlurred(tester, barrierDismissible: false);
      await tester.tapAt(const Offset(5, 5));
      await _settle(tester);
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close).first);
      await _settle(tester);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('the back button closes it', (tester) async {
      await openBlurred(tester, barrierDismissible: false);
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('the barrier colour still applies', (tester) async {
      await _open(
        tester,
        (context) => showCricketLiveScoreDialog(
          context,
          source: FakeSource([finishedMatch()]),
          barrierBlur: 20,
          barrierColor: const Color(0x1AFFFFFF),
        ),
      );
      expect(
        tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
        const Color(0x1AFFFFFF),
      );
    });
  });

  for (final blur in [0.0, 20.0]) {
    testWidgets('the theme where it opens reaches the cards (blur $blur)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const primary = Color(0xFF123456);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme:
                    Theme.of(context).colorScheme.copyWith(primary: primary),
              ),
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showCricketLiveScoreDialog(
                    context,
                    source: FakeSource([finishedMatch()]),
                    barrierBlur: blur,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      final card = tester.element(find.byType(CricketMatchCard));
      expect(Theme.of(card).colorScheme.primary, primary);
    });
  }
}
