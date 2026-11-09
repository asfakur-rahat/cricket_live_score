import 'dart:async';

import 'package:cricket_live_score/src/controller/cricket_score_controller.dart';
import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/models/match_phase.dart';
import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:cricket_live_score/src/selection/match_filter.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_scale.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/pulsing_dot.dart';
import 'package:cricket_live_score/src/widgets/score_controller_host.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';

/// A slim strip that shows one match at a time and keeps itself up to date,
/// for example along the top of a home screen:
///
/// `LIVE  T20 · Bangladesh 168/6 (20) vs Sri Lanka 131/4 (16)`
///
/// With more than one match it moves to the next every [interval], sliding
/// the new match up into place, while a thin line along the bottom fills
/// until the next move. Touching the strip holds the current match until
/// the finger lifts.
///
/// It shows live matches only, unless [filter] says otherwise. When no
/// match passes the filter (also before the first fetch finishes, and
/// after a first fetch that failed) it collapses to nothing, or shows
/// [emptyBuilder].
///
/// Give it either a [source], and the ticker creates, starts and disposes
/// its own [CricketScoreController] (pausing it while the app is in the
/// background), or a [controller] that you start, pause and dispose
/// yourself.
class CricketScoreTicker extends StatefulWidget {
  /// Creates a ticker. Exactly one of [controller] and [source] must be
  /// given.
  const CricketScoreTicker({
    super.key,
    this.controller,
    this.source,
    this.filter = liveOnly,
    this.interval = const Duration(seconds: 5),
    this.onMatchTap,
    this.emptyBuilder,
    this.showLogos = true,
    this.theme,
    this.labels = const CricketScoreLabels(),
    this.logoBuilder = defaultTeamLogoBuilder,
  }) : assert(
          (controller == null) != (source == null),
          'Pass exactly one of controller and source.',
        );

  /// The default [filter]: live matches only.
  static const liveOnly = CricketMatchFilter(phases: {MatchPhase.live});

  /// Supplies the matches; started, paused and disposed by the caller.
  final CricketScoreController? controller;

  /// Supplies the matches through a controller owned by the ticker.
  final CricketScoreSource? source;

  /// Which matches the ticker shows; [liveOnly] by default.
  final CricketMatchFilter filter;

  /// How long each match shows before the next one.
  final Duration interval;

  /// Called with the match on show when the strip is tapped.
  final void Function(CricketMatch match)? onMatchTap;

  /// Builds what shows when no match passes the filter; `null` collapses the
  /// ticker to nothing.
  final WidgetBuilder? emptyBuilder;

  /// Whether to show the team logos beside the names.
  final bool showLogos;

  /// Overrides the ambient [CricketScoreThemeData].
  final CricketScoreThemeData? theme;

  /// The text shown by the ticker.
  final CricketScoreLabels labels;

  /// Builds the team logos.
  final TeamLogoBuilder logoBuilder;

  @override
  State<CricketScoreTicker> createState() => _CricketScoreTickerState();
}

class _CricketScoreTickerState extends State<CricketScoreTicker>
    with
        WidgetsBindingObserver,
        ScoreControllerHost,
        SingleTickerProviderStateMixin {
  @override
  CricketScoreController? get widgetController => widget.controller;

  @override
  CricketScoreSource? get widgetSource => widget.source;

  /// Runs once per [CricketScoreTicker.interval]: it draws the line along
  /// the bottom, and moves to the next match when it completes.
  late final AnimationController _progress;

  int _index = 0;

  /// The id of the match on show, so a refresh that reorders the matches
  /// keeps showing it.
  String? _currentId;

  /// The ids of the matches to rotate through, as of the last build.
  List<String> _ids = const [];

  bool _touched = false;

  /// When the current touch went down and how long the last one lasted,
  /// so a finger held to read the strip is not taken as a tap when it
  /// lifts.
  Duration _touchDown = Duration.zero;
  Duration _touchLength = Duration.zero;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: widget.interval)
      ..addStatusListener(_onProgressStatus);
  }

  @override
  void didUpdateWidget(CricketScoreTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interval != oldWidget.interval) {
      _progress.duration = widget.interval;
      if (_progress.isAnimating) unawaited(_progress.forward(from: 0));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _syncProgress();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_ids.length < 2) return;
    setState(() {
      _index = (_index + 1) % _ids.length;
      _currentId = _ids[_index];
    });
    unawaited(_progress.forward(from: 0));
  }

  /// Runs the progress while there is something to move to and nothing
  /// holds the ticker still.
  void _syncProgress() {
    final count = _ids.length;
    final run = count > 1 && !_touched && !inBackground;
    if (run && !_progress.isAnimating) {
      unawaited(_progress.forward());
    } else if (!run && _progress.isAnimating) {
      _progress.stop();
    }
    if (count <= 1) _progress.value = 0;
  }

  void _setTouched(PointerEvent event) {
    _touched = event is PointerDownEvent;
    if (_touched) {
      _touchDown = event.timeStamp;
    } else {
      _touchLength = event.timeStamp - _touchDown;
    }
    _syncProgress();
  }

  void _onTap(CricketMatch match) {
    if (_touchLength >= kLongPressTimeout) return;
    widget.onMatchTap?.call(match);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, widget.theme);
    final shown = filterMatches(controller.state.matches, widget.filter);

    // Keep showing the same match if a refresh moved it.
    final kept = shown.indexWhere((m) => m.id == _currentId);
    if (kept >= 0) _index = kept;
    if (shown.isNotEmpty) {
      _index %= shown.length;
      _currentId = shown[_index].id;
    }
    final countChanged = shown.length != _ids.length;
    _ids = [for (final match in shown) match.id];
    if (countChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncProgress();
      });
    }

    final Widget child;
    if (shown.isEmpty) {
      child = widget.emptyBuilder?.call(context) ??
          const SizedBox(width: double.infinity);
    } else {
      child = _strip(context, theme, shown[_index], shown.length);
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSize(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _strip(
    BuildContext context,
    CricketScoreThemeData theme,
    CricketMatch match,
    int count,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(theme.tickerBorderRadius!);
    final onTap = widget.onMatchTap;
    final line = AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) {
        // The new match rises from below while the old one leaves upwards.
        final incoming = child.key == ValueKey(match.id);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: Offset(0, incoming ? 1 : -1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(match.id),
        child: _line(context, theme, match),
      ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      label: [
        _spoken(match),
        if (count > 1) widget.labels.pagePosition(_index + 1, count),
      ].join(', '),
      child: Listener(
        onPointerDown: _setTouched,
        onPointerUp: _setTouched,
        onPointerCancel: _setTouched,
        child: Material(
          color: theme.tickerBackground,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: theme.tickerBorder!),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null ? null : () => _onTap(match),
            child: SizedBox(
              height: theme.tickerHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: theme.tickerPadding!,
                        child: ClipRect(child: line),
                      ),
                    ),
                  ),
                  if (count > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _progressLine(context, theme),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressLine(BuildContext context, CricketScoreThemeData theme) {
    final color = theme.tickerProgressColor!;
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) => FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: _progress.value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.15), color],
            ),
          ),
          child: SizedBox(height: CricketScoreScale.of(context).width(2)),
        ),
      ),
    );
  }

  /// One line: the LIVE chip, the match type, then both teams with their
  /// scores, or the status when there are no scores yet.
  Widget _line(
    BuildContext context,
    CricketScoreThemeData theme,
    CricketMatch match,
  ) {
    final textStyle = theme.tickerTextStyle;
    final muted = textStyle?.copyWith(
      color: textStyle.color?.withValues(alpha: 0.6),
    );
    final gap = SizedBox(width: theme.mediumHorizontalGap);
    final hasScores = match.teamScores.isNotEmpty;
    return Row(
      children: [
        if (match.isLive) ...[_liveChip(theme), gap],
        if (match.matchType.isNotEmpty) ...[
          Text(
            match.matchType.toUpperCase(),
            style: textStyle?.copyWith(color: theme.accentColor),
          ),
          Text(' · ', style: muted),
        ],
        Flexible(child: _team(context, theme, match, match.team1)),
        Text(' ${widget.labels.versus.toLowerCase()} ', style: muted),
        Flexible(child: _team(context, theme, match, match.team2)),
        if (!hasScores && match.status.isNotEmpty) ...[
          Text(' · ', style: muted),
          Flexible(
            child: Text(
              match.status,
              style: muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _team(
    BuildContext context,
    CricketScoreThemeData theme,
    CricketMatch match,
    TeamInfo team,
  ) {
    final score = _scoreOf(match, team);
    final logoRadius = theme.tickerHeight! * 0.22;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLogos && team.logoUrl.isNotEmpty) ...[
          widget.logoBuilder(context, team, logoRadius),
          SizedBox(width: theme.smallHorizontalGap),
        ],
        Flexible(
          child: Text(
            team.name,
            style: theme.tickerTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score != null) ...[
          SizedBox(width: theme.smallHorizontalGap),
          Text(score, style: theme.tickerScoreStyle),
        ],
      ],
    );
  }

  Widget _liveChip(CricketScoreThemeData theme) {
    final foreground = theme.liveChipForeground!;
    final style = theme.liveChipStyle?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
    );
    final dot = (style?.fontSize ?? 11) * 0.55;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: theme.liveChipColor,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: theme.liveChipPadding!,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulsingDot(color: foreground, size: dot, pulse: true),
            SizedBox(width: theme.smallHorizontalGap),
            Text(widget.labels.live, style: style),
          ],
        ),
      ),
    );
  }

  /// The score of [team], matched by name since the feed lists the scores
  /// in batting order.
  String? _scoreOf(CricketMatch match, TeamInfo team) {
    final name = team.name.toLowerCase();
    for (final score in match.teamScores) {
      if (score.teamName.toLowerCase() == name) return score.scoreText;
    }
    return null;
  }

  /// What a screen reader says for [match], for example
  /// "T20, India 168/6 versus England, live".
  String _spoken(CricketMatch match) {
    String team(TeamInfo team) =>
        [team.name, _scoreOf(match, team)].nonNulls.join(' ');
    final labels = widget.labels;
    return [
      if (match.matchType.isNotEmpty) match.matchType.toUpperCase(),
      '${team(match.team1)} ${labels.spokenVersus} ${team(match.team2)}',
      if (match.isLive) labels.spokenLive,
      if (match.teamScores.isEmpty && match.status.isNotEmpty) match.status,
    ].join(', ');
  }
}
