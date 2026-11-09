import 'dart:async';

import 'package:cricket_live_score/src/controller/cricket_score_controller.dart';
import 'package:cricket_live_score/src/controller/cricket_score_state.dart';
import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:cricket_live_score/src/widgets/close_badge.dart';
import 'package:cricket_live_score/src/widgets/cricket_match_card.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_scale.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/score_controller_host.dart';
import 'package:cricket_live_score/src/widgets/score_error_body.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:flutter/material.dart';

/// Builds the body of the error card for [error]; call [retry] to fetch
/// again.
typedef CricketScoreErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  VoidCallback retry,
);

/// A swipeable carousel of [CricketMatchCard]s that keeps itself up to date.
///
/// Give it either a [source], and the carousel creates, starts and disposes
/// its own [CricketScoreController] (pausing it while the app is in the
/// background), or a [controller] that you start, pause and dispose
/// yourself.
///
/// Until the first fetch finishes the carousel shows a loading card; when
/// there are no matches, or the first fetch fails, it shows an empty or
/// error card. A later failed fetch keeps showing the last matches.
///
/// The carousel needs a bounded height: pass [maxHeight] or place it where
/// the height is constrained, such as a dialog.
class CricketLiveScoreCarousel extends StatefulWidget {
  /// Creates a carousel. Exactly one of [controller] and [source] must be
  /// given.
  const CricketLiveScoreCarousel({
    super.key,
    this.controller,
    this.source,
    this.autoScroll = false,
    this.autoScrollInterval = const Duration(seconds: 5),
    this.onClose,
    this.maxWidth,
    this.maxHeight,
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

  /// Whether to advance to the next match every [autoScrollInterval].
  ///
  /// Auto-scroll waits while the user is scrolling.
  final bool autoScroll;

  /// Time between automatic page changes.
  final Duration autoScrollInterval;

  /// Called by the close button on every card; `null` hides the button.
  final VoidCallback? onClose;

  /// Maximum width of the carousel.
  ///
  /// `null` uses the incoming width on a phone and caps it at the Material
  /// dialog width on a wider window ([CricketScoreScale.dialogWidth]).
  final double? maxWidth;

  /// Maximum height of the carousel; `null` uses the incoming constraints.
  ///
  /// Each card is only as tall as its content, centred in this height, and
  /// scrolls when its content does not fit.
  final double? maxHeight;

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
  State<CricketLiveScoreCarousel> createState() =>
      _CricketLiveScoreCarouselState();
}

class _CricketLiveScoreCarouselState extends State<CricketLiveScoreCarousel>
    with WidgetsBindingObserver, ScoreControllerHost {
  @override
  CricketScoreController? get widgetController => widget.controller;

  @override
  CricketScoreSource? get widgetSource => widget.source;

  final _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  // Read only by the auto-scroll timer, never by build, so changing it must
  // not trigger a rebuild.
  bool _isUserInteracting = false;

  List<CricketMatch> get _matches => controller.state.matches;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(CricketLiveScoreCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll != oldWidget.autoScroll ||
        widget.autoScrollInterval != oldWidget.autoScrollInterval) {
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  void onScoreStateChanged() {
    final count = _matches.length;
    if (count > 0 && _currentPage >= count) {
      // The list shrank under the current page: move to the new last page.
      _currentPage = count - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      });
    }
    setState(() {});
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (!widget.autoScroll || inBackground) return;
    _autoScrollTimer = Timer.periodic(widget.autoScrollInterval, (_) {
      final matches = _matches;
      if (!_isUserInteracting &&
          matches.isNotEmpty &&
          _pageController.hasClients) {
        _currentPage = (_currentPage + 1) % matches.length;
        unawaited(
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          ),
        );
      }
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _isUserInteracting = true;
    } else if (notification is ScrollEndNotification) {
      _isUserInteracting = false;
      _startAutoScroll();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, widget.theme);
    final state = controller.state;
    final matches = state.matches;

    if (matches.isEmpty) {
      return _statusCard(
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
      );
    }

    final windowWidth = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      // PageView fills the width it is offered, so cap it to the popup
      // width on wider windows; a phone keeps the full padded width.
      constraints: BoxConstraints(
        maxHeight: widget.maxHeight ?? double.infinity,
        maxWidth: widget.maxWidth ??
            (CricketScoreScale.isCompactWidth(windowWidth)
                ? double.infinity
                : CricketScoreScale.of(context).dialogWidth(windowWidth)),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (page) => _currentPage = page,
          itemCount: matches.length,
          itemBuilder: (_, index) {
            final match = matches[index];
            return Center(
              child: Padding(
                // Room for the close button, which overhangs the card by
                // closeButtonOffset and would be clipped by the PageView
                // viewport.
                padding: EdgeInsets.all(theme.outerPadding!),
                child: CricketMatchCard(
                  match: match,
                  onClose: widget.onClose,
                  onTap: widget.onMatchTap == null
                      ? null
                      : () => widget.onMatchTap!(match),
                  theme: theme,
                  labels: widget.labels,
                  logoBuilder: widget.logoBuilder,
                  centerBadge: widget.centerBadge,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statusCard(CricketScoreThemeData theme, Widget body) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          type: MaterialType.card,
          color: theme.cardColor,
          elevation: theme.cardElevation!,
          shadowColor: theme.shadowColor,
          borderRadius: BorderRadius.circular(theme.cardBorderRadius!),
          clipBehavior: Clip.antiAlias,
          child: SizedBox.square(
            dimension: theme.loadingCardSize,
            child: Padding(
              padding: EdgeInsets.all(theme.cardPadding!),
              child: Center(child: body),
            ),
          ),
        ),
        if (widget.onClose != null)
          CloseBadge(
            onClose: widget.onClose!,
            theme: theme,
            label: widget.labels.close,
          ),
      ],
    );
  }
}
