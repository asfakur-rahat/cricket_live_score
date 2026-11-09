import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the design size leaves lengths unscaled', () {
    const scale = CricketScoreScale();
    expect(scale.width(12), 12);
    expect(scale.height(55), 55);
  });

  test('lengths scale with the canvas', () {
    const scale = CricketScoreScale(canvas: Size(780, 1700));
    expect(scale.width(12), 24);
    expect(scale.height(55), 110);
  });

  test('fontSize averages the width and height scale plus a density boost', () {
    const scale = CricketScoreScale(devicePixelRatio: 3);
    expect(scale.fontSize(14), (14 + 14 + 3 * 390 / 850) / 2.4);
  });

  test('turned off, lengths and text sizes are the design values', () {
    const scale = CricketScoreScale(
      canvas: Size(780, 1700),
      devicePixelRatio: 3,
      enabled: false,
    );
    expect(scale.width(12), 12);
    expect(scale.height(55), 55);
    expect(scale.fontSize(14), 14);
  });

  test('another design size scales from that size', () {
    const scale = CricketScoreScale(
      canvas: Size(750, 1624),
      design: Size(375, 812),
    );
    expect(scale.width(12), 24);
    expect(scale.height(10), 20);
    expect(
      scale.fontSize(14),
      (28 + 28 + 1 * 750 / 1624) / 2.4,
    );
  });

  test('dialogWidth fills a phone and caps a wide window', () {
    const scale = CricketScoreScale();
    expect(scale.dialogWidth(390), 390 - 32);
    expect(scale.dialogWidth(500), 500 - 32);
    expect(scale.dialogWidth(1280), CricketScoreScale.maxDialogWidth);
  });

  test('equality and hashCode', () {
    const a = CricketScoreScale(canvas: Size(1, 2), devicePixelRatio: 2);
    const b = CricketScoreScale(canvas: Size(1, 2), devicePixelRatio: 2);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const CricketScoreScale(), isFalse);
    expect(
      const CricketScoreScale() == const CricketScoreScale(enabled: false),
      isFalse,
    );
    expect(
      const CricketScoreScale() ==
          const CricketScoreScale(design: Size(375, 812)),
      isFalse,
    );
    expect(a.toString(), contains('Size(1.0, 2.0)'));
  });

  group('of', () {
    Future<CricketScoreScale> scaleFor(
      WidgetTester tester,
      Size size, {
      Widget Function(Widget child)? wrap,
      Size? wideCanvas,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late CricketScoreScale scale;
      final child = Builder(
        builder: (context) {
          scale = CricketScoreScale.of(context, wideCanvas: wideCanvas);
          return const SizedBox();
        },
      );
      await tester.pumpWidget(wrap?.call(child) ?? child);
      return scale;
    }

    testWidgets('a compact window is its own canvas', (tester) async {
      final scale = await scaleFor(tester, const Size(360, 780));
      expect(scale.canvas, const Size(360, 780));
      expect(scale.devicePixelRatio, 1);
    });

    testWidgets('a wide window gets the phone-sized canvas', (tester) async {
      final scale = await scaleFor(tester, const Size(1280, 800));
      expect(scale.canvas, CricketScoreScale.defaultWideCanvas);
    });
  });

  group('CricketScoreScaleScope', () {
    Future<CricketScoreScale> scaleFor(
      WidgetTester tester,
      Size size, {
      required CricketScoreScaleScope Function(Widget child) scope,
      Size? wideCanvas,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late CricketScoreScale scale;
      await tester.pumpWidget(
        scope(
          Builder(
            builder: (context) {
              scale = CricketScoreScale.of(context, wideCanvas: wideCanvas);
              return const SizedBox();
            },
          ),
        ),
      );
      return scale;
    }

    testWidgets('turns scaling off', (tester) async {
      final scale = await scaleFor(
        tester,
        const Size(360, 780),
        scope: (child) => CricketScoreScaleScope(enabled: false, child: child),
      );
      expect(scale.enabled, isFalse);
      expect(scale.width(12), 12);
    });

    testWidgets('sets the design size', (tester) async {
      final scale = await scaleFor(
        tester,
        const Size(375, 812),
        scope: (child) => CricketScoreScaleScope(
          designSize: const Size(375, 812),
          child: child,
        ),
      );
      expect(scale.design, const Size(375, 812));
      expect(scale.width(12), 12);
    });

    testWidgets('sets the wide canvas, unless of() is given one',
        (tester) async {
      CricketScoreScaleScope scope(Widget child) => CricketScoreScaleScope(
            wideCanvas: const Size(600, 1300),
            child: child,
          );
      var scale = await scaleFor(tester, const Size(1280, 800), scope: scope);
      expect(scale.canvas, const Size(600, 1300));
      scale = await scaleFor(
        tester,
        const Size(1280, 800),
        scope: scope,
        wideCanvas: const Size(500, 1000),
      );
      expect(scale.canvas, const Size(500, 1000));
    });

    testWidgets('the widgets follow the scope when it changes', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late double padding;
      late double? nameSize;
      late double? themeSize;
      final theme = ThemeData.light();
      Widget app({required bool enabled}) => MaterialApp(
            theme: theme,
            builder: (context, child) =>
                CricketScoreScaleScope(enabled: enabled, child: child!),
            home: Builder(
              builder: (context) {
                final resolved = CricketScoreThemeData.resolve(context);
                padding = resolved.outerPadding!;
                nameSize = resolved.teamNameStyle!.fontSize;
                themeSize = Theme.of(context).textTheme.titleSmall!.fontSize;
                return const SizedBox();
              },
            ),
          );

      await tester.pumpWidget(app(enabled: true));
      expect(padding, closeTo(12 * 360 / 390, 1e-9));

      await tester.pumpWidget(app(enabled: false));
      expect(padding, 12);
      // Text keeps the text theme's own size.
      expect(nameSize, themeSize);
    });
  });
}
