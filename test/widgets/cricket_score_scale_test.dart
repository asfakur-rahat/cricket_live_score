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
    expect(a.toString(), contains('Size(1.0, 2.0)'));
  });

  group('of', () {
    Future<CricketScoreScale> scaleFor(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late CricketScoreScale scale;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            scale = CricketScoreScale.of(context);
            return const SizedBox();
          },
        ),
      );
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
}
