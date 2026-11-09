import 'dart:async';
import 'dart:math' as math;

import 'package:cricket_live_score/src/controller/cricket_score_controller.dart';
import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/models/match_phase.dart';
import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:cricket_live_score/src/selection/match_filter.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_scale.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/flashing_score.dart';
import 'package:cricket_live_score/src/widgets/pulsing_dot.dart';
import 'package:cricket_live_score/src/widgets/score_controller_host.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:cricket_live_score/src/widgets/ticker_crawl.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';

/// How [CricketScoreTicker] moves through its matches.
enum CricketTickerMode {
  /// One match at a time; the next slides up into place every interval,
  /// while a thin line along the bottom fills until it does.
  rotate,

  /// Every match in one line that scrolls sideways without stopping, like
  /// a TV news ticker.
  crawl,
}

/// A slim strip of live scores that keeps itself up to date, for example
/// along the top of a home screen:
///
/// `LIVE  T20 · Bangladesh 168/6 (20) vs Sri Lanka 131/4 (16)`
///
/// It sits on a soft tint of the surface colour, with rounded corners. In
/// [CricketTickerMode.rotate], the default, it shows one match at a time
/// and moves to the next every [interval]. In [CricketTickerMode.crawl] it
/// scrolls every match past at [crawlSpeed], or falls back to rotating
/// while the platform asks for reduced motion. Either way, a finger held
/// on the strip holds it still, and a score that changes glows for a
/// moment.
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
    this.mode = CricketTickerMode.rotate,
    this.filter = liveOnly,
    this.interval = const Duration(seconds: 5),
    this.crawlSpeed = 40,
    this.onMatchTap,
    this.emptyBuilder,
    this.showLogos = true,
    this.theme,
    this.labels = const CricketScoreLabels(),
    this.logoBuilder = defaultTeamLogoBuilder,
  })  : assert(
          (controller == null) != (source == null),
          'Pass exactly one of controller and source.',
        ),
        assert(crawlSpeed >= 0, 'crawlSpeed must not be negative.');

  /// The default [filter]: live matches only.
  static const liveOnly = CricketMatchFilter(phases: {MatchPhase.live});

  /// Supplies the matches; started, paused and disposed by the caller.
  final CricketScoreController? controller;

  /// Supplies the matches through a controller owned by the ticker.
  final CricketScoreSource? source;

  /// Whether to show one match at a time or crawl through them all.
  final CricketTickerMode mode;

  /// Which matches the ticker shows; [liveOnly] by default.
  final CricketMatchFilter filter;

  /// How long each match shows before the next one, in
  /// [CricketTickerMode.rotate].
  final Duration interval;

  /// How fast the line moves in [CricketTickerMode.crawl], in logical
  /// pixels a second on the design screen; it scales with the screen like
  /// the other sizes.
  final double crawlSpeed;

  /// Called with the match that was tapped.
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

  /// Runs once per [CricketScoreTicker.interval] while rotating: it draws
  /// the line along the bottom, and moves to the next match when it
  /// completes.
  late final AnimationController _progress;

  int _index = 0;

  /// The id of the match on show, so a refresh that reorders the matches
  /// keeps showing it.
  String? _currentId;

  /// The ids of the matches to rotate through, as of the last build.
  List<String> _ids = const [];

  /// Whether the last build crawled rather than rotated.
  bool _crawling = false;

  bool _touched = false;

  /// When the current touch went down and how long the last one lasted,
  /// so a finger held to read the strip is not taken as a tap when it
  /// lifts.
  Duration _touchDown = Duration.zero;
  Duration _touchLength = Duration.zero;

  /// The last scores seen, by [_scoreKey], and the matches they belong to.
  Map<String, String?> _scores = const {};
  Set<String> _matchIds = const {};

  /// Scores that changed and haven't flashed yet.
  final _unflashed = <String>{};

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: widget.interval)
      ..addStatusListener(_onProgressStatus);
    _rememberScores(controller.state.matches);
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
    final wasInBackground = inBackground;
    super.didChangeAppLifecycleState(state);
    _syncProgress();
    // The crawl reads inBackground when it builds.
    if (wasInBackground != inBackground && _crawling) setState(() {});
  }

  @override
  void onScoreStateChanged() {
    final matches = controller.state.matches;
    final before = _scores;
    final known = _matchIds;
    _rememberScores(matches);
    for (final entry in _scores.entries) {
      final matchId = entry.key.substring(0, entry.key.indexOf('|'));
      if (known.contains(matchId) &&
          entry.value != null &&
          before[entry.key] != entry.value) {
        _unflashed.add(entry.key);
      }
    }
    setState(() {});
  }

  void _rememberScores(List<CricketMatch> matches) {
    _scores = {
      for (final match in matches)
        for (final score in match.teamScores)
          _scoreKey(match, score.teamName): score.scoreText,
    };
    _matchIds = {for (final match in matches) match.id};
  }

  static String _scoreKey(CricketMatch match, String teamName) =>
      '${match.id}|${teamName.toLowerCase()}';

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

  /// Runs the progress while rotating, with something to move to and
  /// nothing holding the ticker still.
  void _syncProgress() {
    final count = _ids.length;
    final run = !_crawling && count > 1 && !_touched && !inBackground;
    if (run && !_progress.isAnimating) {
      unawaited(_progress.forward());
    } else if (!run && _progress.isAnimating) {
      _progress.stop();
    }
    if (count <= 1 || _crawling) _progress.value = 0;
  }

  void _setTouched(PointerEvent event) {
    _touched = event is PointerDownEvent;
    if (_touched) {
      _touchDown = event.timeStamp;
    } else {
      _touchLength = event.timeStamp - _touchDown;
    }
    _syncProgress();
    // The crawl reads _touched when it builds.
    if (_crawling) setState(() {});
  }

  void _onTap(CricketMatch match) {
    if (_touchLength >= kLongPressTimeout) return;
    widget.onMatchTap?.call(match);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, widget.theme);
    final shown = filterMatches(controller.state.matches, widget.filter);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final crawling = widget.mode == CricketTickerMode.crawl && !reduceMotion;

    // Keep showing the same match if a refresh moved it.
    final kept = shown.indexWhere((m) => m.id == _currentId);
    if (kept >= 0) _index = kept;
    if (shown.isNotEmpty) {
      _index %= shown.length;
      _currentId = shown[_index].id;
    }
    final changed = shown.length != _ids.length || crawling != _crawling;
    _ids = [for (final match in shown) match.id];
    _crawling = crawling;
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncProgress();
      });
    }

    final Widget child;
    if (shown.isEmpty) {
      child = widget.emptyBuilder?.call(context) ??
          const SizedBox(width: double.infinity);
    } else {
      child = Listener(
        onPointerDown: _setTouched,
        onPointerUp: _setTouched,
        onPointerCancel: _setTouched,
        child: Material(
          color: theme.tickerBackground,
          borderRadius: BorderRadius.circular(theme.tickerBorderRadius!),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: theme.tickerHeight,
            width: double.infinity,
            child: crawling
                ? _crawl(context, theme, shown)
                : _rotate(context, theme, shown),
          ),
        ),
      );
    }
    // AnimatedSize can't take a zero duration, so reduced motion skips it.
    if (reduceMotion) return child;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _rotate(
    BuildContext context,
    CricketScoreThemeData theme,
    List<CricketMatch> shown,
  ) {
    final match = shown[_index];
    final count = shown.length;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final onTap = widget.onMatchTap;
    final line = AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Names can shorten to nothing, but the rest can't; when even
            // that doesn't fit, scale the whole line down instead.
            final minNames = theme.largeHorizontalGap! * 3;
            if (_fixedWidth(context, theme, match) + minNames <=
                constraints.maxWidth) {
              return _line(context, theme, match, fill: true);
            }
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: _line(context, theme, match, fill: false),
            );
          },
        ),
      ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      label: [
        _spoken(match),
        if (count > 1) widget.labels.pagePosition(_index + 1, count),
      ].join(', '),
      child: InkWell(
        onTap: onTap == null ? null : () => _onTap(match),
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
    );
  }

  Widget _crawl(
    BuildContext context,
    CricketScoreThemeData theme,
    List<CricketMatch> shown,
  ) {
    final scale = CricketScoreScale.of(context);
    final onTap = widget.onMatchTap;
    final padding = theme.tickerPadding!.resolve(Directionality.of(context));
    return TickerCrawl(
      speed: scale.width(widget.crawlSpeed),
      paused: _touched || inBackground,
      gap: theme.largeHorizontalGap! * 1.5,
      fadeWidth: math.max(padding.left, padding.right) * 2,
      separator: _Diamond(theme: theme),
      children: [
        for (final match in shown)
          Semantics(
            container: true,
            button: onTap != null,
            label: _spoken(match),
            child: InkWell(
              onTap: onTap == null ? null : () => _onTap(match),
              child: ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.smallHorizontalGap!,
                  ),
                  child: SizedBox(
                    height: theme.tickerHeight,
                    child: _line(context, theme, match, fill: false),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _progressLine(BuildContext context, CricketScoreThemeData theme) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) => FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: _progress.value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.tickerAccentStart!, theme.tickerAccentEnd!],
            ),
          ),
          child: SizedBox(height: CricketScoreScale.of(context).width(2)),
        ),
      ),
    );
  }

  /// One line: the LIVE chip, the match type, then both teams with their
  /// logos and scores, or the status when there are no scores yet.
  ///
  /// With [fill] it takes the width it is given: when that is too narrow,
  /// the names (and the status) shorten in proportion to their length,
  /// while the chip, logos and scores keep their size. Without, it is as
  /// wide as its content, for the crawl.
  Widget _line(
    BuildContext context,
    CricketScoreThemeData theme,
    CricketMatch match, {
    required bool fill,
  }) {
    final textStyle = theme.tickerTextStyle;
    final muted = textStyle?.copyWith(
      color: textStyle.color?.withValues(alpha: 0.6),
    );
    final hasScores = match.teamScores.isNotEmpty;

    // Text that may shorten, with a flex of its natural width so that
    // every such text shortens by the same fraction.
    Widget shrinkable(String text, TextStyle? style) {
      final label = Text(
        text,
        style: style,
        maxLines: 1,
        overflow: fill ? TextOverflow.ellipsis : null,
      );
      if (!fill) return label;
      return Flexible(flex: _naturalWidth(context, text, style), child: label);
    }

    List<Widget> team(TeamInfo team) {
      final score = _scoreOf(match, team);
      final key = _scoreKey(match, team.name);
      return [
        if (widget.showLogos && team.logoUrl.isNotEmpty) ...[
          widget.logoBuilder(context, team, theme.tickerHeight! * 0.22),
          SizedBox(width: theme.smallHorizontalGap),
        ],
        shrinkable(team.name, textStyle),
        if (score != null) ...[
          SizedBox(width: theme.smallHorizontalGap! / 2),
          FlashingScore(
            text: score,
            style: theme.tickerScoreStyle,
            color: theme.tickerFlashColor!,
            flash: _unflashed.contains(key),
            onFlashed: () => _unflashed.remove(key),
          ),
        ],
      ];
    }

    return Row(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (match.isLive) ...[
          _liveChip(theme),
          SizedBox(width: theme.mediumHorizontalGap),
        ],
        if (match.matchType.isNotEmpty) ...[
          Text(
            match.matchType.toUpperCase(),
            style: textStyle?.copyWith(color: theme.accentColor),
          ),
          Text(' · ', style: muted),
        ],
        ...team(match.team1),
        Text(' ${widget.labels.versus.toLowerCase()} ', style: muted),
        ...team(match.team2),
        if (!hasScores && match.status.isNotEmpty) ...[
          Text(' · ', style: muted),
          shrinkable(match.status, muted),
        ],
      ],
    );
  }

  /// The width of everything on [match]'s line except the names and the
  /// status, which can shorten.
  double _fixedWidth(
    BuildContext context,
    CricketScoreThemeData theme,
    CricketMatch match,
  ) {
    final textStyle = theme.tickerTextStyle;
    final muted = textStyle?.copyWith(
      color: textStyle.color?.withValues(alpha: 0.6),
    );
    double text(String text, TextStyle? style) =>
        _naturalWidth(context, text, style).toDouble();
    final small = theme.smallHorizontalGap!;
    var width = text(' ${widget.labels.versus.toLowerCase()} ', muted);
    if (match.isLive) {
      final style = theme.liveChipStyle;
      final padding =
          theme.liveChipPadding!.resolve(Directionality.of(context));
      width += padding.horizontal +
          (style?.fontSize ?? 11) * 0.55 +
          small +
          text(
            widget.labels.live,
            style?.copyWith(fontWeight: FontWeight.w700),
          ) +
          theme.mediumHorizontalGap!;
    }
    if (match.matchType.isNotEmpty) {
      width +=
          text(match.matchType.toUpperCase(), textStyle) + text(' · ', muted);
    }
    for (final team in [match.team1, match.team2]) {
      if (widget.showLogos && team.logoUrl.isNotEmpty) {
        width += theme.tickerHeight! * 0.44 + small;
      }
      final score = _scoreOf(match, team);
      // Half a gap before it, and the flash's padding around it.
      if (score != null) {
        width += small / 2 + 4 + text(score, theme.tickerScoreStyle);
      }
    }
    if (match.teamScores.isEmpty && match.status.isNotEmpty) {
      width += text(' · ', muted);
    }
    return width;
  }

  /// The width [text] takes on one line, in whole pixels, at least 1.
  int _naturalWidth(BuildContext context, String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceil();
    painter.dispose();
    return math.max(1, width);
  }

  Widget _liveChip(CricketScoreThemeData theme) {
    final foreground = theme.liveChipForeground!;
    final color = theme.liveChipColor!;
    final style = theme.liveChipStyle?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
    );
    final dot = (style?.fontSize ?? 11) * 0.55;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color,
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

/// The small diamond between matches in the crawl.
class _Diamond extends StatelessWidget {
  const _Diamond({required this.theme});

  final CricketScoreThemeData theme;

  @override
  Widget build(BuildContext context) {
    final size = theme.smallHorizontalGap! * 1.6;
    return Transform.rotate(
      angle: math.pi / 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.tickerAccentStart!, theme.tickerAccentEnd!],
          ),
        ),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}
