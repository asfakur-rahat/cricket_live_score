import 'package:cricket_live_score/src/controller/cricket_score_controller.dart';
import 'package:cricket_live_score/src/controller/cricket_score_state.dart';
import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/selection/match_filter.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:cricket_live_score/src/widgets/cricket_live_score_carousel.dart';
import 'package:cricket_live_score/src/widgets/cricket_match_card.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_scale.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/score_controller_host.dart';
import 'package:cricket_live_score/src/widgets/score_error_body.dart';
import 'package:cricket_live_score/src/widgets/score_filter_bar.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:flutter/material.dart';

/// How [CricketLiveScoreView] lays out its cards.
enum CricketScoreLayout {
  /// As many columns as fit: one on a phone, two or more on a tablet, a
  /// foldable's inner display or a large landscape window. Cards in a row
  /// share its height.
  adaptive,

  /// Always one column, phone width, centred on wide windows.
  phone,
}

/// The most columns the adaptive grid uses, however wide the window.
const _maxColumns = 4;

/// The body of a live score screen: filter chips above a list of
/// [CricketMatchCard]s that keeps itself up to date.
///
/// It has no `Scaffold` or route of its own, so place it wherever the app
/// wants, for example as a `Scaffold` body:
///
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: const Text('Live scores')),
///   body: CricketLiveScoreView(source: CricketDataWidgetSource()),
/// );
/// ```
///
/// Give it either a [source], and the view creates, starts and disposes its
/// own [CricketScoreController] (pausing it while the app is in the
/// background), or a [controller] that you start, pause and dispose
/// yourself.
///
/// A frosted header filters the list: a capsule of phases (All, Live,
/// Upcoming, Done), then tabs of match types. It scrolls away as the list
/// scrolls down and slides back in on the way up. Pulling down from the top
/// fetches straight away. The view needs a bounded height.
///
/// On a phone it is one column filling the width it is given. On a wider
/// window the [layout] decides: by default a grid of as many columns as
/// fit, with the filters on one row; [CricketScoreLayout.phone] keeps one
/// centred, phone-width column.
class CricketLiveScoreView extends StatefulWidget {
  /// Creates a score view. Exactly one of [controller] and [source] must be
  /// given.
  const CricketLiveScoreView({
    super.key,
    this.controller,
    this.source,
    this.layout = CricketScoreLayout.adaptive,
    this.scrollController,
    this.pinnedHeader,
    this.enablePullToRefresh = true,
    this.initialFilter = CricketMatchFilter.all,
    this.filter,
    this.onFilterChanged,
    this.showPhaseFilter = true,
    this.showTypeFilter = true,
    this.onMatchTap,
    this.theme,
    this.labels = const CricketScoreLabels(),
    this.logoBuilder = defaultTeamLogoBuilder,
    this.centerBadge,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  }) : assert(
          (controller == null) != (source == null),
          'Pass exactly one of controller and source.',
        );

  /// Supplies the matches; started, paused and disposed by the caller.
  final CricketScoreController? controller;

  /// Supplies the matches through a controller owned by the view.
  final CricketScoreSource? source;

  /// How the cards are laid out on a window wider than a phone.
  final CricketScoreLayout layout;

  /// Controls the view's scrolling, for example a
  /// `DraggableScrollableSheet`'s controller so dragging the list resizes
  /// the sheet.
  final ScrollController? scrollController;

  /// Shown above the filters and kept there while the list scrolls, for
  /// example a title bar. Give it an opaque or frosted background: the
  /// cards scroll under it.
  final Widget? pinnedHeader;

  /// Whether pulling down from the top fetches straight away.
  ///
  /// Turn it off where the pull means something else, such as in a
  /// draggable sheet, where it resizes the sheet.
  final bool enablePullToRefresh;

  /// The filter applied when the view first shows, while [filter] is `null`.
  final CricketMatchFilter initialFilter;

  /// The filter to apply, when the app keeps the filter itself.
  ///
  /// When set, tapping a chip only calls [onFilterChanged]; rebuild the view
  /// with the new filter to apply it. When `null`, the view keeps the filter
  /// itself, starting from [initialFilter].
  final CricketMatchFilter? filter;

  /// Called with the new filter when the user taps a chip.
  final ValueChanged<CricketMatchFilter>? onFilterChanged;

  /// Whether to show the row of phase chips: All, Live, Upcoming, Done.
  final bool showPhaseFilter;

  /// Whether to show the row of match-type chips: All, T20, ODI, Test…
  ///
  /// The types come from the matches, so the row appears once they load.
  final bool showTypeFilter;

  /// Called when a match card is tapped.
  final void Function(CricketMatch match)? onMatchTap;

  /// Overrides the ambient [CricketScoreThemeData].
  final CricketScoreThemeData? theme;

  /// The text shown by the view.
  final CricketScoreLabels labels;

  /// Builds the team logos.
  final TeamLogoBuilder logoBuilder;

  /// Shown inside the badge between the teams on every card.
  final Widget? centerBadge;

  /// Builds what shows until the first fetch finishes; defaults to a
  /// progress indicator.
  final WidgetBuilder? loadingBuilder;

  /// Builds what shows when the source has no matches.
  final WidgetBuilder? emptyBuilder;

  /// Builds what shows when the first fetch failed.
  final CricketScoreErrorBuilder? errorBuilder;

  @override
  State<CricketLiveScoreView> createState() => _CricketLiveScoreViewState();
}

class _CricketLiveScoreViewState extends State<CricketLiveScoreView>
    with WidgetsBindingObserver, ScoreControllerHost {
  @override
  CricketScoreController? get widgetController => widget.controller;

  @override
  CricketScoreSource? get widgetSource => widget.source;

  late CricketMatchFilter _ownFilter = widget.initialFilter;

  CricketMatchFilter get _filter => widget.filter ?? _ownFilter;

  void _setFilter(CricketMatchFilter filter) {
    if (widget.filter == null) setState(() => _ownFilter = filter);
    widget.onFilterChanged?.call(filter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, widget.theme);
    final matches = controller.state.matches;
    final types =
        widget.showTypeFilter ? _typeChoices(matches) : const <String>[];
    final windowWidth = MediaQuery.sizeOf(context).width;
    final compact = CricketScoreScale.isCompactWidth(windowWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth, theme, compact);
        // One column on a wide window is capped at phone width; a grid
        // uses all of it.
        final maxWidth = compact || columns > 1
            ? double.infinity
            : CricketScoreScale.of(context).dialogWidth(windowWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _withPullToRefresh(
              CustomScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (widget.pinnedHeader != null)
                    PinnedHeaderSliver(child: widget.pinnedHeader),
                  if (widget.showPhaseFilter || types.isNotEmpty)
                    SliverFloatingHeader(
                      child: ScoreFilterBar(
                        inline: columns > 1,
                        filter: _filter,
                        types: types,
                        showPhases: widget.showPhaseFilter,
                        hasLive: matches.any((m) => m.isLive),
                        theme: theme,
                        labels: widget.labels,
                        onChanged: _setFilter,
                      ),
                    ),
                  _content(context, theme, matches, columns),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _withPullToRefresh(Widget scrollView) => widget.enablePullToRefresh
      ? RefreshIndicator(onRefresh: controller.refresh, child: scrollView)
      : scrollView;

  int _columnsFor(double width, CricketScoreThemeData theme, bool compact) {
    if (compact ||
        widget.layout == CricketScoreLayout.phone ||
        !width.isFinite) {
      return 1;
    }
    final available = width - 2 * theme.outerPadding!;
    return (available ~/ theme.gridTileMinWidth!).clamp(1, _maxColumns);
  }

  // The types in the data, plus any selected type the data no longer has,
  // so a selected chip never disappears from under the user.
  List<String> _typeChoices(List<CricketMatch> matches) {
    final types = matchTypesOf(matches);
    return [
      ...types,
      for (final type in _filter.types)
        if (!types.contains(type.toUpperCase())) type.toUpperCase(),
    ];
  }

  Widget _content(
    BuildContext context,
    CricketScoreThemeData theme,
    List<CricketMatch> matches,
    int columns,
  ) {
    if (matches.isEmpty) {
      return _message(
        theme,
        switch (controller.state) {
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

    final shown = filterMatches(matches, _filter);
    if (shown.isEmpty) {
      return _message(
        theme,
        Text(
          widget.labels.noFilteredMatches,
          style: theme.messageStyle,
          textAlign: TextAlign.center,
        ),
      );
    }

    final gap = theme.listGap!;
    if (columns == 1) {
      return SliverPadding(
        padding: EdgeInsets.all(theme.outerPadding!),
        sliver: SliverList.separated(
          itemCount: shown.length,
          separatorBuilder: (_, __) => SizedBox(height: gap),
          itemBuilder: (_, index) => _card(theme, shown[index]),
        ),
      );
    }

    // Rows of [columns] cards; every card in a row is as tall as the
    // tallest, and a short last row leaves its remaining cells empty.
    final rows = (shown.length + columns - 1) ~/ columns;
    return SliverPadding(
      padding: EdgeInsets.all(theme.outerPadding!),
      sliver: SliverList.separated(
        itemCount: rows,
        separatorBuilder: (_, __) => SizedBox(height: gap),
        itemBuilder: (_, row) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column > 0) SizedBox(width: gap),
                Expanded(
                  child: row * columns + column < shown.length
                      ? _card(theme, shown[row * columns + column])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(CricketScoreThemeData theme, CricketMatch match) {
    return CricketMatchCard(
      key: ValueKey(match.id),
      match: match,
      onTap: widget.onMatchTap == null ? null : () => widget.onMatchTap!(match),
      theme: theme,
      labels: widget.labels,
      logoBuilder: widget.logoBuilder,
      centerBadge: widget.centerBadge,
    );
  }

  /// [child] centred in the space below the header.
  Widget _message(CricketScoreThemeData theme, Widget child) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(theme.outerPadding!),
          child: child,
        ),
      ),
    );
  }
}
