import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('CricketScoreThemeData', () {
    final fallback = CricketScoreThemeData.fallback(ThemeData.light());

    test('fallback sets every field', () {
      // Every field is reachable through copyWith; a null left in the
      // fallback would survive a merge onto an empty theme.
      final empty = const CricketScoreThemeData().merge(fallback);
      expect(empty, fallback);
      expect(fallback.cardColor, ThemeData.light().colorScheme.surface);
      expect(fallback.closeButtonSize, 40);
      expect(fallback.teamNameStyle!.fontWeight, FontWeight.w700);
    });

    test('merge keeps fields the other theme leaves unset', () {
      const other = CricketScoreThemeData(cardPadding: 20);
      final merged = fallback.merge(other);
      expect(merged.cardPadding, 20);
      expect(merged.closeButtonSize, fallback.closeButtonSize);
      expect(fallback.merge(null), same(fallback));
    });

    test('copyWith replaces only the given fields', () {
      final copy = fallback.copyWith(fabHeight: 60);
      expect(copy.fabHeight, 60);
      expect(copy.copyWith(fabHeight: fallback.fabHeight), fallback);
    });

    test('lerp interpolates every kind of field', () {
      final other = fallback.copyWith(
        cardColor: const Color(0xFF000000),
        cardPadding: 32,
        fabPadding: EdgeInsets.zero,
        venueStyle: const TextStyle(fontSize: 40),
      );
      final start = fallback.lerp(other, 0);
      expect(start.cardColor, fallback.cardColor);
      expect(start.cardPadding, fallback.cardPadding);
      expect(start.fabPadding, fallback.fabPadding);
      final end = fallback.lerp(other, 1);
      expect(end.cardColor, const Color(0xFF000000));
      expect(end.cardPadding, 32);
      expect(end.fabPadding, EdgeInsets.zero);
      expect(end.venueStyle!.fontSize, 40);
      expect(fallback.lerp(other, 0.5).cardPadding, 22);
      expect(fallback.lerp(null, 0.5), same(fallback));
    });

    test('equality and hashCode', () {
      final a = CricketScoreThemeData.fallback(ThemeData.light());
      expect(a, fallback);
      expect(a.hashCode, fallback.hashCode);
      expect(a == a.copyWith(cardPadding: 1), isFalse);
    });

    testWidgets('resolve layers argument over extension over fallback',
        (tester) async {
      late CricketScoreThemeData resolved;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              resolved = CricketScoreThemeData.resolve(
                context,
                const CricketScoreThemeData(cardPadding: 3),
              );
              return const SizedBox();
            },
          ),
          theme: ThemeData.light().copyWith(
            extensions: const [
              CricketScoreThemeData(cardPadding: 2, outerPadding: 2),
            ],
          ),
        ),
      );
      expect(resolved.cardPadding, 3);
      expect(resolved.outerPadding, 2);
      // The 800-wide test window is not compact, so the fallback is scaled
      // to the wide canvas.
      expect(resolved.closeButtonSize, 40 * 430 / 390);
    });

    test('on a dark scheme, cards are raised off the page', () {
      final light = ThemeData(colorSchemeSeed: Colors.green);
      final dark = ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
      );
      final lightFallback = CricketScoreThemeData.fallback(light);
      final darkFallback = CricketScoreThemeData.fallback(dark);
      expect(lightFallback.cardColor, light.colorScheme.surface);
      expect(darkFallback.cardColor, dark.colorScheme.surfaceContainerHigh);
      expect(
        darkFallback.closeButtonBackground,
        dark.colorScheme.surfaceContainerHighest,
      );
      expect(darkFallback.cardColor, isNot(dark.colorScheme.surface));
    });

    test('fallback scales sizes and text sizes with the scale', () {
      const half = CricketScoreScale(canvas: Size(195, 425));
      final small = CricketScoreThemeData.fallback(ThemeData.light(), half);
      expect(small.closeButtonSize, 20);
      expect(small.cardBorderRadius, 6 + 2);
      expect(small.fabHeight, 27.5);
      expect(small.mediumVerticalGap, 8);
      expect(
        small.fabPadding,
        const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      );
      expect(small.scoreStyle!.fontSize, half.fontSize(14));
      expect(
        small.scoreStyle!.fontSize,
        lessThan(fallback.scoreStyle!.fontSize!),
      );
    });
  });

  group('CricketScoreLabels', () {
    test('English defaults', () {
      const labels = CricketScoreLabels();
      expect(labels.live, 'LIVE');
      expect(labels.notAvailable, 'N/A');
      expect(labels.venuePrefix, 'At');
      expect(labels.versus, 'VS');
      expect(labels.venueLine('Lord’s'), 'At Lord’s');
    });

    test('copyWith replaces only the given labels', () {
      String format(String venue) => '[$venue]';
      final labels = const CricketScoreLabels().copyWith(
        live: 'লাইভ',
        notAvailable: 'x',
        venuePrefix: 'In',
        versus: 'v',
        close: 'c',
        noMatches: 'n',
        loadFailed: 'f',
        retry: 'r',
        spokenVersus: 'বনাম',
        spokenLive: 'লাইভ',
        formatVenue: format,
      );
      expect(labels.live, 'লাইভ');
      expect(labels.notAvailable, 'x');
      expect(labels.venuePrefix, 'In');
      expect(labels.versus, 'v');
      expect(labels.close, 'c');
      expect(labels.noMatches, 'n');
      expect(labels.loadFailed, 'f');
      expect(labels.retry, 'r');
      expect(labels.venueLine('Mirpur'), '[Mirpur]');
      expect(
        labels.matchSemantics(liveMatch()),
        'India A বনাম New Zealand A, লাইভ',
      );
      expect(labels.copyWith().live, 'লাইভ');
    });

    test('matchSemantics mentions live only for live matches', () {
      const labels = CricketScoreLabels();
      expect(
        labels.matchSemantics(finishedMatch()),
        'Canterbury versus Central Stags',
      );
      expect(
        labels.matchSemantics(liveMatch()),
        'India A versus New Zealand A, live',
      );
    });

    test('pagePosition counts from one and can be reworded', () {
      expect(const CricketScoreLabels().pagePosition(3, 26), 'Match 3 of 26');
      final labels = const CricketScoreLabels().copyWith(
        formatPagePosition: (page, count) => '$count এর $page',
      );
      expect(labels.pagePosition(3, 26), '26 এর 3');
    });
  });
}
