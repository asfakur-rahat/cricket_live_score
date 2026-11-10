import 'dart:ui' show ImageFilter;

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Pumps an app whose button opens the sheet through [open], in a phone
/// window unless [window] says otherwise, and taps the button.
Future<void> _open(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open, {
  Size window = const Size(400, 900),
  Widget Function(BuildContext context, Widget child)? wrap,
}) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final button = Builder(
              builder: (context) => TextButton(
                onPressed: () => open(context),
                child: const Text('open'),
              ),
            );
            return wrap?.call(context, button) ?? button;
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await _settle(tester);
}

/// Lets route and sheet animations finish; the pulsing Live dot never
/// settles, so pumpAndSettle would time out.
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
  testWidgets('opens with a title, the filters and the cards', (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(
        context,
        source: FakeSource([liveMatch(), finishedMatch()]),
      ),
    );
    expect(find.text('Live scores'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byType(CricketMatchCard), findsWidgets);
    // Pulling down drags the sheet, so there is no pull to refresh.
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('the close button closes it and completes the future',
      (tester) async {
    var closed = false;
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(
        context,
        source: FakeSource([finishedMatch()]),
      ).then((_) => closed = true),
    );
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester);
    expect(find.text('Live scores'), findsNothing);
    expect(closed, isTrue);
  });

  testWidgets('the refresh button fetches and spins until done',
      (tester) async {
    final source = FakeSource([finishedMatch()]);
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(context, source: source),
    );
    expect(source.calls, 1);

    source.pending = true;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(source.calls, 2);
    expect(find.byTooltip('Refresh'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CricketLiveScoreSheet),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    source.complete([finishedMatch()]);
    await tester.pump();
    expect(find.byTooltip('Refresh'), findsOneWidget);
  });

  testWidgets('closing stops the polling it started', (tester) async {
    final source = FakeSource([finishedMatch()]);
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(context, source: source),
    );
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester);
    final calls = source.calls;
    await tester.pump(const Duration(minutes: 2));
    expect(source.calls, calls);
  });

  testWidgets('an injected controller is neither started nor disposed',
      (tester) async {
    final source = FakeSource([finishedMatch()]);
    final controller = CricketScoreController(source: source)..start();
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(context, controller: controller),
    );
    expect(source.calls, 1);
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester);
    await controller.refresh();
    expect(source.calls, 2);
    controller.dispose();
  });

  testWidgets('a custom title and labels', (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(
        context,
        source: FakeSource([finishedMatch()]),
        title: 'Scores',
        labels: const CricketScoreLabels(refresh: 'Actualiser'),
      ),
    );
    expect(find.text('Scores'), findsOneWidget);
    expect(find.byTooltip('Actualiser'), findsOneWidget);
  });

  testWidgets('dragging it down closes it', (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(
        context,
        source: FakeSource([finishedMatch()]),
      ),
    );
    await tester.drag(find.text('Live scores'), const Offset(0, 700));
    await _settle(tester);
    expect(find.text('Live scores'), findsNothing);
  });

  testWidgets('a tap outside closes it', (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(
        context,
        source: FakeSource([finishedMatch()]),
      ),
    );
    await tester.tapAt(const Offset(200, 20));
    await _settle(tester);
    expect(find.text('Live scores'), findsNothing);
  });

  group('when it can only be closed on purpose', () {
    Future<void> openFixed(WidgetTester tester, {void Function()? onDone}) =>
        _open(
          tester,
          (context) => showCricketLiveScoreSheet(
            context,
            source: FakeSource([finishedMatch()]),
            isDismissible: false,
            enableDrag: false,
          ).then((_) => onDone?.call()),
        );

    testWidgets('a tap outside does nothing', (tester) async {
      await openFixed(tester);
      await tester.tapAt(const Offset(200, 20));
      await _settle(tester);
      expect(find.text('Live scores'), findsOneWidget);
    });

    testWidgets('dragging or flinging it down stops at its smallest size',
        (tester) async {
      await openFixed(tester);
      final opened = tester.getTopLeft(find.text('Live scores')).dy;
      await tester.drag(find.text('Live scores'), const Offset(0, 700));
      await _settle(tester);
      expect(find.text('Live scores'), findsOneWidget);
      // minChildSize is 0.3 of the 900-high window.
      final lowest = tester.getTopLeft(find.text('Live scores')).dy;
      expect(lowest, greaterThan(opened));
      expect(lowest, lessThan(900 - 0.3 * 900 + 40));

      await tester.fling(
        find.text('Live scores'),
        const Offset(0, 400),
        3000,
      );
      await _settle(tester);
      expect(find.text('Live scores'), findsOneWidget);
    });

    testWidgets('it still resizes upwards', (tester) async {
      await openFixed(tester);
      final before = tester.getTopLeft(find.text('Live scores')).dy;
      await tester.drag(find.text('Live scores'), const Offset(0, -300));
      await _settle(tester);
      expect(tester.getTopLeft(find.text('Live scores')).dy, lessThan(before));
    });

    testWidgets('the close button closes it', (tester) async {
      var closed = false;
      await openFixed(tester, onDone: () => closed = true);
      await tester.tap(find.byTooltip('Close'));
      await _settle(tester);
      expect(find.text('Live scores'), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('the back button closes it', (tester) async {
      await openFixed(tester);
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.text('Live scores'), findsNothing);
    });
  });

  testWidgets(
      'opened by the app inside a PopScope, back is blocked and the close '
      'button still works', (tester) async {
    await _open(
      tester,
      (context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => PopScope(
          canPop: false,
          child: SizedBox(
            height: 600,
            child: CricketLiveScoreSheet(
              source: FakeSource([finishedMatch()]),
              onClose: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('Live scores'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester);
    expect(find.text('Live scores'), findsNothing);
  });

  testWidgets('dragging it up expands it', (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(
        context,
        source: FakeSource([finishedMatch()]),
      ),
    );
    final before = tester.getTopLeft(find.text('Live scores')).dy;
    await tester.drag(find.text('Live scores'), const Offset(0, -300));
    await _settle(tester);
    expect(tester.getTopLeft(find.text('Live scores')).dy, lessThan(before));
  });

  testWidgets('a phone gets a full-width sheet', (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(
        context,
        source: FakeSource([finishedMatch()]),
      ),
    );
    expect(tester.getSize(find.byType(CricketLiveScoreSheet)).width, 400);
  });

  testWidgets('a wide window gets a centred, dialog-width sheet',
      (tester) async {
    await _open(
      tester,
      (context) => showCricketLiveScoreSheet(
        context,
        source: FakeSource([liveMatch(), finishedMatch()]),
      ),
      window: const Size(1280, 800),
    );
    final sheet = tester.getRect(find.byType(CricketLiveScoreSheet));
    expect(sheet.width, 560);
    expect(sheet.center.dx, 640);
  });

  group('with barrierBlur', () {
    Future<void> openBlurred(
      WidgetTester tester, {
      bool isDismissible = true,
      bool enableDrag = true,
      Color? barrierColor,
      void Function()? onDone,
    }) =>
        _open(
          tester,
          (context) => showCricketLiveScoreSheet(
            context,
            source: FakeSource([finishedMatch()]),
            barrierBlur: 6,
            barrierColor: barrierColor,
            isDismissible: isDismissible,
            enableDrag: enableDrag,
          ).then((_) => onDone?.call()),
        );

    testWidgets('there is no blur by default', (tester) async {
      await _open(
        tester,
        (context) => showCricketLiveScoreSheet(
          context,
          source: FakeSource([finishedMatch()]),
        ),
      );
      expect(_barrierBlur(tester), isNull);
    });

    testWidgets('the page behind is blurred once it is open', (tester) async {
      await openBlurred(tester);
      final blur = _barrierBlur(tester)!;
      expect(blur.enabled, isTrue);
      expect(blur.filter, ImageFilter.blur(sigmaX: 6, sigmaY: 6));
      // The sheet looks the same as without a blur.
      expect(find.text('Live scores'), findsOneWidget);
      expect(tester.getSize(find.byType(CricketLiveScoreSheet)).width, 400);
    });

    testWidgets('the blur fades out as it closes', (tester) async {
      var closed = false;
      await openBlurred(tester, onDone: () => closed = true);
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        _barrierBlur(tester)!.filter,
        isNot(ImageFilter.blur(sigmaX: 6, sigmaY: 6)),
      );
      await _settle(tester);
      expect(find.text('Live scores'), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('a tap outside and a drag down still close it', (tester) async {
      await openBlurred(tester);
      await tester.tapAt(const Offset(200, 20));
      await _settle(tester);
      expect(find.text('Live scores'), findsNothing);

      await tester.tap(find.text('open'));
      await _settle(tester);
      await tester.drag(find.text('Live scores'), const Offset(0, 700));
      await _settle(tester);
      expect(find.text('Live scores'), findsNothing);
    });

    testWidgets('isDismissible and enableDrag false still hold',
        (tester) async {
      await openBlurred(tester, isDismissible: false, enableDrag: false);
      await tester.tapAt(const Offset(200, 20));
      await _settle(tester);
      await tester.drag(find.text('Live scores'), const Offset(0, 700));
      await _settle(tester);
      expect(find.text('Live scores'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.text('Live scores'), findsNothing);
    });

    testWidgets('a wide window still gets a dialog-width sheet',
        (tester) async {
      await _open(
        tester,
        (context) => showCricketLiveScoreSheet(
          context,
          source: FakeSource([finishedMatch()]),
          barrierBlur: 6,
        ),
        window: const Size(1280, 800),
      );
      expect(tester.getSize(find.byType(CricketLiveScoreSheet)).width, 560);
    });
  });

  for (final blur in [0.0, 6.0]) {
    testWidgets('barrierColor tints the barrier (blur $blur)', (tester) async {
      await _open(
        tester,
        (context) => showCricketLiveScoreSheet(
          context,
          source: FakeSource([finishedMatch()]),
          barrierBlur: blur,
          barrierColor: const Color(0x1A1925A6),
        ),
      );
      expect(
        tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
        const Color(0x1A1925A6),
      );
    });

    testWidgets('the theme where it opens reaches the sheet (blur $blur)',
        (tester) async {
      const primary = Color(0xFF123456);
      await _open(
        tester,
        (context) => showCricketLiveScoreSheet(
          context,
          source: FakeSource([finishedMatch()]),
          barrierBlur: blur,
        ),
        wrap: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(primary: primary),
          ),
          child: child,
        ),
      );
      final sheet = tester.element(find.byType(CricketLiveScoreSheet));
      expect(Theme.of(sheet).colorScheme.primary, primary);
    });
  }
}
