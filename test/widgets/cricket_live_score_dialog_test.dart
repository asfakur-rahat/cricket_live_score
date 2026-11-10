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
}
