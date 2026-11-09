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
/// fetches straight away. The view needs a bounded height. On a phone it
/// fills the width it is given; on a wider window it is a centred,
/// phone-width column.
class CricketLiveScoreView extends StatefulWidget {
  /// Creates a score view. Exactly one of [controller] and [source] must be
  /// given.
  const CricketLiveScoreView({
    super.key,
    this.controller,
    this.source,
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
    final maxWidth = CricketScoreScale.isCompactWidth(windowWidth)
        ? double.infinity
        : CricketScoreScale.of(context).dialogWidth(windowWidth);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (widget.showPhaseFilter || types.isNotEmpty)
                SliverFloatingHeader(
                  child: ScoreFilterBar(
                    filter: _filter,
                    types: types,
                    showPhases: widget.showPhaseFilter,
                    hasLive: matches.any((m) => m.isLive),
                    theme: theme,
                    labels: widget.labels,
                    onChanged: _setFilter,
                  ),
                ),
              _content(context, theme, matches),
            ],
          ),
        ),
      ),
    );
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

    return SliverPadding(
      padding: EdgeInsets.all(theme.outerPadding!),
      sliver: SliverList.separated(
        itemCount: shown.length,
        separatorBuilder: (_, __) => SizedBox(height: theme.listGap),
        itemBuilder: (_, index) {
          final match = shown[index];
          return CricketMatchCard(
            key: ValueKey(match.id),
            match: match,
            onTap: widget.onMatchTap == null
                ? null
                : () => widget.onMatchTap!(match),
            theme: theme,
            labels: widget.labels,
            logoBuilder: widget.logoBuilder,
            centerBadge: widget.centerBadge,
          );
        },
      ),
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
