import 'dart:async';
import 'dart:math' as math;

import 'package:cricket_live_score/src/controller/cricket_score_controller.dart';
import 'package:cricket_live_score/src/controller/cricket_score_state.dart';
import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:cricket_live_score/src/widgets/cricket_live_score_carousel.dart';
import 'package:cricket_live_score/src/widgets/cricket_match_card.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_scale.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/page_dots.dart';
import 'package:cricket_live_score/src/widgets/score_controller_host.dart';
import 'package:cricket_live_score/src/widgets/score_error_body.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:flutter/material.dart';

/// A row of [CricketMatchCard]s that scrolls sideways, for a section of a
/// page, and keeps itself up to date.
///
/// Unlike [CricketLiveScoreCarousel], which fills a dialog, it needs no
/// height: it is as tall as its tallest card, and shorter cards stretch to
/// match. Put it straight into a `ListView`, a `Column`, or a
/// `CustomScrollView` through a `SliverToBoxAdapter`. It needs a bounded
/// width.
///
/// With [snap], the default, one card at a time snaps into place and the
/// next card peeks in at the edge. On a wide window cards keep about a
/// phone card's width, so two or three show at once and a swipe moves one
/// card. Without [snap], cards [cardWidth] wide scroll freely.
///
/// Give it either a [source], and it creates, starts and disposes its own
/// [CricketScoreController] (pausing it while the app is in the
/// background), or a [controller] that you start, pause and dispose
/// yourself. Until the first fetch finishes, and when there are no
/// matches or the first fetch fails, one full-width card shows the
/// loading, empty or error state.
class CricketInlineScoreCarousel extends StatefulWidget {
  /// Creates an inline carousel. Exactly one of [controller] and [source]
  /// must be given.
  const CricketInlineScoreCarousel({
    super.key,
    this.controller,
    this.source,
    this.snap = true,
    this.cardWidth,
    this.spacing,
    this.padding,
    this.showPageIndicator = false,
    this.autoScroll = false,
    this.autoScrollInterval = const Duration(seconds: 5),
    this.theme,
    this.labels = const CricketScoreLabels(),
    this.logoBuilder = defaultTeamLogoBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.centerBadge,
    this.onMatchTap,
  }) : assert(
          (controller == null) != (source == null),
          'Pass exactly one of controller and source.',
        );

  /// Supplies the matches; started, paused and disposed by the caller.
  final CricketScoreController? controller;

  /// Supplies the matches through a controller owned by the carousel.
  final CricketScoreSource? source;

  /// Whether cards snap into place one at a time; otherwise they scroll
  /// freely.
  final bool snap;

  /// The width of a card.
  ///
  /// Without [snap] every card is this wide. With [snap] it is the widest a
  /// card gets while more cards wait off screen: a phone shows one card
  /// and the edge of the next, and a wider window shows as many cards of
  /// up to this width as fit. `null` uses a phone card's width.
  final double? cardWidth;

  /// The space between cards; `null` uses 12, scaled.
  final double? spacing;

  /// The space around the cards, inside the scrolling area, so the first
  /// card lines up with the rest of the page while cards scroll edge to
  /// edge. `null` uses 16 at the sides and 8 at the top and bottom, scaled,
  /// which leaves room for the card shadows.
  final EdgeInsetsGeometry? padding;

  /// Whether to show page dots under the cards, one for each place the
  /// row snaps to, when it scrolls at all.
  ///
  /// Tapping a dot scrolls to its card. Only used with [snap].
  final bool showPageIndicator;

  /// Whether to move on one card every [autoScrollInterval], going back to
  /// the first card after the last.
  ///
  /// Auto-scroll waits while the user is touching or scrolling the cards,
  /// and stops while the app is in the background. With "reduce motion"
  /// on, it jumps instead of sliding. Only used with [snap].
  final bool autoScroll;

  /// Time between automatic moves.
  final Duration autoScrollInterval;

  /// Overrides the ambient [CricketScoreThemeData].
  final CricketScoreThemeData? theme;

  /// The text shown by the carousel.
  final CricketScoreLabels labels;

  /// Builds the team logos.
  final TeamLogoBuilder logoBuilder;

  /// Builds the body of the loading card; defaults to a progress indicator.
  final WidgetBuilder? loadingBuilder;

  /// Builds the body of the card shown when there are no matches.
  final WidgetBuilder? emptyBuilder;

  /// Builds the body of the card shown when the first fetch failed.
  final CricketScoreErrorBuilder? errorBuilder;

  /// Shown inside the badge between the teams on every card.
  final Widget? centerBadge;

  /// Called when a match card is tapped.
  final void Function(CricketMatch match)? onMatchTap;

  @override
  State<CricketInlineScoreCarousel> createState() =>
      _CricketInlineScoreCarouselState();
}

class _CricketInlineScoreCarouselState extends State<CricketInlineScoreCarousel>
    with WidgetsBindingObserver, ScoreControllerHost {
  @override
  CricketScoreController? get widgetController => widget.controller;

  @override
  CricketScoreSource? get widgetSource => widget.source;

  final _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  /// The place the row last settled at, as an index into [_stops].
  int _stop = 0;

  /// The offsets the row snaps to, from the last layout.
  ///
  /// Read by the scroll physics and the auto-scroll timer, which outlive a
  /// single build.
  List<double> _stops = const [0];

  // Read only by the auto-scroll timer, never by build, so changing them
  // must not trigger a rebuild.
  bool _isScrolling = false;
  bool _isTouching = false;

  bool get _snaps => widget.snap;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(CricketInlineScoreCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll != oldWidget.autoScroll ||
        widget.autoScrollInterval != oldWidget.autoScrollInterval ||
        widget.snap != oldWidget.snap) {
      _startAutoScroll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasInBackground = inBackground;
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _autoScrollTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && wasInBackground) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (!widget.autoScroll || !_snaps || inBackground) return;
    _autoScrollTimer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (_isScrolling || _isTouching || _stops.length < 2) return;
      _moveTo((_stop + 1) % _stops.length, const Duration(milliseconds: 800));
    });
  }

  void _moveTo(int stop, Duration duration) {
    if (!_scrollController.hasClients) return;
    _stop = stop;
    final offset = _stops[stop];
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(offset);
    } else {
      _scrollController.animateTo(
        offset,
        duration: duration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _showStop(int stop) {
    _moveTo(stop, const Duration(milliseconds: 400));
    // A tap starts the auto-scroll interval over.
    _startAutoScroll();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // Ignore the cards' own vertical scrolling.
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) {
      _isScrolling = true;
    } else if (notification is ScrollEndNotification) {
      _isScrolling = false;
      _stop = _stopAt(notification.metrics.pixels).round();
      _startAutoScroll();
    }
    return false;
  }

  void _onTouch({required bool down}) {
    _isTouching = down;
    if (!down) _startAutoScroll();
  }

  /// The fractional stop index at a scroll [offset].
  double _stopAt(double offset) {
    final stops = _stops;
    if (offset <= stops.first) return 0;
    for (var i = 1; i < stops.length; i++) {
      if (offset <= stops[i]) {
        return i - 1 + (offset - stops[i - 1]) / (stops[i] - stops[i - 1]);
      }
    }
    return stops.length - 1.0;
  }

  /// Keeps [_stops] in step with the layout.
  ///
  /// When the stops move, such as after a rotation, the scroll position
  /// settles again through [_SnapScrollPhysics], onto the nearest stop.
  void _setStops(List<double> stops) {
    if (_sameStops(stops, _stops)) return;
    _stops = stops;
    _stop = math.min(_stop, stops.length - 1);
  }

  static bool _sameStops(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.5) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, widget.theme);
    final scale = CricketScoreScale.of(context);
    final direction = Directionality.of(context);
    final padding = (widget.padding ??
            EdgeInsets.symmetric(
              horizontal: scale.width(16),
              vertical: scale.width(8),
            ))
        .resolve(direction);
    final state = controller.state;
    final matches = state.matches;

    if (matches.isEmpty) {
      return Padding(
        padding: padding,
        child: _statusCard(
          theme,
          switch (state) {
            CricketScoreFailure(:final error) => widget.errorBuilder?.call(
                  context,
                  error,
                  controller.refresh,
                ) ??
                ScoreErrorBody(
                  labels: widget.labels,
                  style: theme.messageStyle,
                  onRetry: controller.refresh,
                ),
            CricketScoreEmpty() => widget.emptyBuilder?.call(context) ??
                Text(
                  widget.labels.noMatches,
                  style: theme.messageStyle,
                  textAlign: TextAlign.center,
                ),
            _ => widget.loadingBuilder?.call(context) ??
                const CircularProgressIndicator.adaptive(),
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'CricketInlineScoreCarousel needs a bounded width.',
        );
        final layout = _RowLayout(
          viewport: constraints.maxWidth,
          count: matches.length,
          padding: padding,
          leading:
              direction == TextDirection.rtl ? padding.right : padding.left,
          spacing: widget.spacing ?? scale.width(12),
          cardWidth: widget.cardWidth ?? scale.width(330),
          peek: scale.width(32),
          snap: _snaps,
        );
        _setStops(layout.stops);

        final row = NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: Listener(
            onPointerDown: (_) => _onTouch(down: true),
            onPointerUp: (_) => _onTouch(down: false),
            onPointerCancel: (_) => _onTouch(down: false),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              physics: _snaps ? _SnapScrollPhysics(stops: () => _stops) : null,
              padding: padding,
              // Every card is as tall as the tallest.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < matches.length; i++) ...[
                      if (i > 0) SizedBox(width: layout.spacing),
                      SizedBox(
                        key: ValueKey(matches[i].id),
                        width: layout.card,
                        child: _card(theme, matches[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

        final showDots =
            _snaps && widget.showPageIndicator && layout.stops.length > 1;
        // Always a Column, so the row keeps its place in the tree, and its
        // scroll position, as the dots come and go.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row,
            if (showDots) SizedBox(height: theme.smallVerticalGap),
            if (showDots)
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, _) {
                  final position = _scrollController.hasClients
                      ? _scrollController.position
                      : null;
                  final stop = position != null && position.haveDimensions
                      ? _stopAt(position.pixels)
                      : _stop.toDouble();
                  final count = layout.stops.length;
                  return PageDots(
                    count: count,
                    page: stop,
                    theme: theme,
                    positionLabel: (i) =>
                        widget.labels.pagePosition(i + 1, count),
                    onSelect: _showStop,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _card(CricketScoreThemeData theme, CricketMatch match) {
    return CricketMatchCard(
      match: match,
      onTap: widget.onMatchTap == null ? null : () => widget.onMatchTap!(match),
      theme: theme,
      labels: widget.labels,
      logoBuilder: widget.logoBuilder,
      centerBadge: widget.centerBadge,
    );
  }

  Widget _statusCard(CricketScoreThemeData theme, Widget body) {
    return Material(
      type: MaterialType.card,
      color: theme.cardColor,
      elevation: theme.cardElevation!,
      shadowColor: theme.shadowColor,
      borderRadius: BorderRadius.circular(theme.cardBorderRadius!),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: theme.loadingCardSize! / 2,
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.cardPadding!),
          child: Center(child: body),
        ),
      ),
    );
  }
}

/// The card width and snap offsets of a row of cards in a viewport.
class _RowLayout {
  factory _RowLayout({
    required double viewport,
    required int count,
    required EdgeInsets padding,
    required double leading,
    required double spacing,
    required double cardWidth,
    required double peek,
    required bool snap,
  }) {
    final inside = viewport - padding.horizontal;
    var card = math.min(cardWidth, inside);
    if (snap) {
      // At rest: the leading padding, then [shown] cards and gaps, then the
      // edge of the next card.
      final room = viewport - leading - peek;
      double widthFor(int shown) => (room - shown * spacing) / shown;
      var shown = math.max(1, (room / (cardWidth + spacing)).ceil());
      while (shown > 1 && widthFor(shown) < cardWidth * 0.75) {
        shown--;
      }
      card = widthFor(shown);
      if (count <= shown) {
        // Everything fits: share the whole width, without a peek, but not
        // wider than a popup card.
        final fill = (inside - (count - 1) * spacing) / count;
        card = math.min(fill, math.max(card, CricketScoreScale.maxDialogWidth));
      }
      card = math.max(0, card);
    }

    final content = padding.horizontal + count * card + (count - 1) * spacing;
    final double maxOffset = math.max(0, content - viewport);
    final stops = <double>[0];
    // A card at rest sits [spacing] from the leading edge, so no sliver of
    // the card before it shows; the first card lines up with the padding.
    final double shift = math.max(0, leading - spacing);
    for (var i = 1; i < count && stops.last < maxOffset; i++) {
      stops.add(math.min(i * (card + spacing) + shift, maxOffset));
    }
    return _RowLayout._(card, spacing, stops);
  }

  _RowLayout._(this.card, this.spacing, this.stops);

  /// The width of each card.
  final double card;

  /// The space between cards.
  final double spacing;

  /// The scroll offsets the row snaps to, in order; the first is 0 and the
  /// last is the end of the row.
  final List<double> stops;
}

/// Settles a scroll on the nearest stop, or the next one in the direction
/// of a fling.
class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({required this.stops, super.parent});

  /// The current stops. A function, because the scrollable keeps its first
  /// physics while only the stops change.
  final List<double> Function() stops;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapScrollPhysics(stops: stops, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _target(position.pixels, velocity, tolerance.velocity)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < tolerance.distance) {
      return super.createBallisticSimulation(position, velocity);
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  double _target(double pixels, double velocity, double minVelocity) {
    final stops = this.stops();
    // The stops either side of [pixels].
    final after = stops.indexWhere((stop) => stop >= pixels);
    if (after == -1) return stops.last;
    if (after == 0) return stops.first;
    final before = stops[after - 1];
    final next = stops[after];
    if (velocity > minVelocity) return next;
    if (velocity < -minVelocity) return before;
    return pixels - before < next - pixels ? before : next;
  }

  @override
  bool get allowImplicitScrolling => false;
}
