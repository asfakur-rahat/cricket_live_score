import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fills a size × size square', (tester) async {
    await tester.pumpWidget(
      const Center(child: CricketBatsIcon(color: Colors.black, size: 48)),
    );
    expect(tester.getSize(find.byType(CricketBatsIcon)), const Size(48, 48));
  });

  testWidgets('repaints only when the colour changes', (tester) async {
    await tester.pumpWidget(
      const Center(child: CricketBatsIcon(color: Colors.black, size: 48)),
    );
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(CricketBatsIcon),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;

    await tester.pumpWidget(
      const Center(child: CricketBatsIcon(color: Colors.white, size: 48)),
    );
    final whitePainter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(CricketBatsIcon),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;
    expect(whitePainter.shouldRepaint(painter), isTrue);
    expect(painter.shouldRepaint(painter), isFalse);
  });
}
