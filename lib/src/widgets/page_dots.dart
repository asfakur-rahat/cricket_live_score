import 'dart:math' as math;

import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:flutter/material.dart';

/// The most page dots shown at once; with more pages the row slides along
/// with the current page.
const maxPageDots = 7;

/// A capsule of dots for [count] pages, where the dot for [page] stretches
/// into a pill.
///
/// [page] is fractional while the pages scroll, so the pill and the row
/// move with the finger. With more than [maxPageDots] pages, the row shows
/// a window of dots around the current page and shrinks the dots at an
/// edge that has more beyond it. Tapping a dot calls [onSelect] with its
/// index.
class PageDots extends StatelessWidget {
  /// Creates the dots; [count] must be at least 1.
  const PageDots({
    required this.count,
    required this.page,
    required this.theme,
    required this.positionLabel,
    required this.onSelect,
    super.key,
  }) : assert(count > 0, 'PageDots needs at least one page.');

  /// The number of pages.
  final int count;

  /// The current page, fractional while scrolling.
  final double page;

  /// Supplies the sizes and colours.
  final CricketScoreThemeData theme;

  /// The screen-reader description of the page at an index.
  final String Function(int index) positionLabel;

  /// Called with the index of the page to show.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final geometry = _DotGeometry(count: count, page: page, theme: theme);
    final current = page.round().clamp(0, count - 1);
    final padX = theme.pageDotSize!;
    return Semantics(
      container: true,
      value: positionLabel(current),
      increasedValue: current < count - 1 ? positionLabel(current + 1) : null,
      decreasedValue: current > 0 ? positionLabel(current - 1) : null,
      onIncrease: current < count - 1 ? () => onSelect(current + 1) : null,
      onDecrease: current > 0 ? () => onSelect(current - 1) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) =>
            onSelect(geometry.indexAt(details.localPosition.dx - padX)),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: theme.pageIndicatorBackground,
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: padX,
              vertical: theme.pageDotSize!,
            ),
            child: CustomPaint(
              size: Size(geometry.viewportWidth, theme.pageDotSize!),
              painter: _DotsPainter(geometry, theme),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where each dot sits along the row, and which part of the row shows.
class _DotGeometry {
  _DotGeometry({
    required this.count,
    required double page,
    required CricketScoreThemeData theme,
  })  : page = page.clamp(0, count - 1).toDouble(),
        dot = theme.pageDotSize!,
        gap = theme.pageDotGap! {
    final active = theme.pageDotActiveWidth!;
    for (var i = 0; i < count; i++) {
      weights.add(math.max(0, 1 - (this.page - i).abs()));
      widths.add(dot + (active - dot) * weights[i]);
      lefts.add(i == 0 ? 0 : lefts[i - 1] + widths[i - 1] + gap);
    }
    final visible = math.min(count, maxPageDots);
    viewportWidth = visible * dot + (active - dot) + (visible - 1) * gap;
    totalWidth = lefts.last + widths.last;
    // Keep the current page in the middle of the window, where it can be.
    offset = (_centreAt(this.page) - viewportWidth / 2)
        .clamp(0, math.max(0, totalWidth - viewportWidth))
        .toDouble();
  }

  final int count;
  final double page;
  final double dot;
  final double gap;

  /// How much each dot is the current one: 1 for the current page, shared
  /// between two pages while scrolling between them.
  final weights = <double>[];
  final widths = <double>[];
  final lefts = <double>[];
  late final double viewportWidth;
  late final double totalWidth;

  /// How far the row has slid left to keep the current page in view.
  late final double offset;

  double _centre(int i) => lefts[i] + widths[i] / 2;

  double _centreAt(double page) {
    final i = page.floor();
    if (i + 1 >= count) return _centre(i);
    final t = page - i;
    return _centre(i) * (1 - t) + _centre(i + 1) * t;
  }

  bool get hiddenBefore => offset > 0.5;

  bool get hiddenAfter => offset < totalWidth - viewportWidth - 0.5;

  /// The index of the dot nearest [x], measured from the window's left edge.
  /// A tap in the capsule's padding picks the nearest dot showing, not a
  /// hidden one beyond it.
  int indexAt(double x) {
    final rowX = x.clamp(0, viewportWidth) + offset;
    for (var i = 0; i < count - 1; i++) {
      if (rowX < lefts[i] + widths[i] + gap / 2) return i;
    }
    return count - 1;
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.geometry, this.theme);

  final _DotGeometry geometry;
  final CricketScoreThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    // Dots within this distance of an edge with more dots beyond it shrink.
    final fadeZone = 1.5 * (g.dot + g.gap);
    canvas.clipRect(Offset.zero & size);
    final paint = Paint();
    for (var i = 0; i < g.count; i++) {
      final cx = g._centre(i) - g.offset;
      if (cx < -g.dot || cx > size.width + g.dot) continue;
      var scale = 1.0;
      if (g.hiddenBefore) {
        scale = math.min(scale, 0.3 + 0.7 * (cx / fadeZone).clamp(0, 1));
      }
      if (g.hiddenAfter) {
        final fromEnd = size.width - cx;
        scale = math.min(scale, 0.3 + 0.7 * (fromEnd / fadeZone).clamp(0, 1));
      }
      paint.color = Color.lerp(
        theme.pageDotColor,
        theme.pageDotActiveColor,
        g.weights[i],
      )!;
      final height = g.dot * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, size.height / 2),
            width: g.widths[i] * scale,
            height: height,
          ),
          Radius.circular(height / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) =>
      oldDelegate.geometry.page != geometry.page ||
      oldDelegate.geometry.count != geometry.count ||
      oldDelegate.theme != theme;
}
