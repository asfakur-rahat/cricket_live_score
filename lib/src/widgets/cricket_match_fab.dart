import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:cricket_live_score/src/widgets/team_logo_slot.dart';
import 'package:flutter/material.dart';

/// A compact floating button showing both team logos around "VS", with a
/// LIVE chip when the match is live.
class CricketMatchFab extends StatefulWidget {
  /// Creates a floating button for [match].
  const CricketMatchFab({
    required this.match,
    super.key,
    this.onTap,
    this.onHorizontalSwipe,
    this.theme,
    this.labels = const CricketScoreLabels(),
    this.logoBuilder = defaultTeamLogoBuilder,
  });

  /// The match to show.
  final CricketMatch match;

  /// Called when the button is tapped.
  final VoidCallback? onTap;

  /// Called when the button is swiped sideways, in either direction, by more
  /// than 50 logical pixels.
  final VoidCallback? onHorizontalSwipe;

  /// Overrides the ambient [CricketScoreThemeData].
  final CricketScoreThemeData? theme;

  /// The text shown on the button.
  final CricketScoreLabels labels;

  /// Builds the team logos; called even when a team has no logo URL.
  final TeamLogoBuilder logoBuilder;

  @override
  State<CricketMatchFab> createState() => _CricketMatchFabState();
}

class _CricketMatchFabState extends State<CricketMatchFab> {
  static const _swipeThreshold = 50;

  Offset? _startPosition;
  Offset? _endPosition;

  void _onPanEnd(DragEndDetails _) {
    final start = _startPosition;
    final end = _endPosition;
    _startPosition = null;
    _endPosition = null;
    if (start == null || end == null) return;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    if (dx.abs() > _swipeThreshold && dx.abs() > dy.abs()) {
      widget.onHorizontalSwipe?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, widget.theme);
    final match = widget.match;
    // `pickFeaturedMatch` falls back to the first match when nothing is live,
    // so the FAB can be showing a scheduled or finished fixture. Only the
    // match's own live flag may light up the badge.
    final isLive = match.isLive;

    // The label describes the whole button, including the LIVE chip.
    return Semantics(
      container: true,
      button: true,
      label: widget.labels.matchSemantics(match),
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            type: MaterialType.card,
            color: theme.cardColor,
            elevation: theme.fabElevation!,
            shadowColor: theme.shadowColor,
            borderRadius: BorderRadius.circular(theme.fabBorderRadius!),
            clipBehavior: Clip.antiAlias,
            child: GestureDetector(
              onTap: widget.onTap,
              onPanStart: (details) => _startPosition = details.globalPosition,
              onPanUpdate: (details) => _endPosition = details.globalPosition,
              onPanEnd: _onPanEnd,
              child: Container(
                padding: theme.fabPadding,
                height: theme.fabHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(theme.fabBorderRadius!),
                  border: Border.all(color: theme.fabBorderColor!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildTeamLogo(
                      context,
                      match.team1,
                      theme.fabLogoRadius!,
                      opponent: match.team2,
                      logoBuilder: widget.logoBuilder,
                      theme: theme,
                      labels: widget.labels,
                    ),
                    SizedBox(width: theme.mediumHorizontalGap),
                    Text(widget.labels.versus, style: theme.versusStyle),
                    SizedBox(width: theme.mediumHorizontalGap),
                    buildTeamLogo(
                      context,
                      match.team2,
                      theme.fabLogoRadius!,
                      opponent: match.team1,
                      logoBuilder: widget.logoBuilder,
                      theme: theme,
                      labels: widget.labels,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLive)
            PositionedDirectional(
              top: theme.liveChipTop,
              end: theme.liveChipEnd,
              child: Container(
                padding: theme.liveChipPadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(theme.fabBorderRadius!),
                  color: theme.liveChipColor,
                ),
                child: Text(
                  widget.labels.live,
                  style: theme.liveChipStyle?.copyWith(
                    color: theme.liveChipForeground,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
