import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:cricket_live_score/src/widgets/close_badge.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:flutter/material.dart';

/// A card showing one match: type, start time or LIVE, venue, both teams,
/// status and the score table.
///
/// When [onClose] is set, a close button overhangs the card's top-end
/// corner; give the card room for it (the carousel pads each card by
/// [CricketScoreThemeData.outerPadding]).
class CricketMatchCard extends StatelessWidget {
  /// Creates a card for [match].
  const CricketMatchCard({
    required this.match,
    super.key,
    this.onClose,
    this.onTap,
    this.theme,
    this.labels = const CricketScoreLabels(),
    this.logoBuilder = defaultTeamLogoBuilder,
    this.centerBadge,
  });

  /// The match to show.
  final CricketMatch match;

  /// Called by the close button; `null` hides the button.
  final VoidCallback? onClose;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Overrides the ambient [CricketScoreThemeData].
  final CricketScoreThemeData? theme;

  /// The text shown on the card.
  final CricketScoreLabels labels;

  /// Builds the team logos. A team without a logo URL shows no logo.
  final TeamLogoBuilder logoBuilder;

  /// Shown inside the badge between the teams; defaults to a cricket icon.
  final Widget? centerBadge;

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, this.theme);
    final card = Material(
      type: MaterialType.card,
      color: theme.cardColor,
      elevation: theme.cardElevation!,
      shadowColor: theme.shadowColor,
      borderRadius: BorderRadius.circular(theme.cardBorderRadius!),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(theme.cardPadding!),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    match.matchType,
                    style: theme.matchTypeStyle?.copyWith(
                      color: theme.accentColor,
                    ),
                  ),
                  SizedBox(width: theme.smallHorizontalGap),
                  Expanded(
                    child: match.isLive
                        ? Text(
                            '- ${labels.live} -',
                            style: theme.liveStyle?.copyWith(
                              color: theme.liveColor,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            match.startTimeText,
                            style: theme.startTimeStyle,
                            textAlign: TextAlign.center,
                          ),
                  ),
                  SizedBox(width: theme.headerTrailingGap),
                ],
              ),
              SizedBox(height: theme.mediumVerticalGap),
              Text(
                labels.venueLine(match.venue),
                style: theme.venueStyle,
                textAlign: TextAlign.center,
              ),
              Divider(height: theme.dividerHeight),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _team(context, theme, match.team1)),
                  SizedBox(width: theme.largeHorizontalGap),
                  CircleAvatar(
                    radius: theme.badgeRadius,
                    backgroundColor: theme.badgeBackground,
                    child: centerBadge ??
                        Icon(
                          Icons.sports_cricket,
                          color: theme.badgeForeground,
                        ),
                  ),
                  SizedBox(width: theme.largeHorizontalGap),
                  Expanded(child: _team(context, theme, match.team2)),
                ],
              ),
              Divider(height: theme.dividerHeight),
              Text(
                match.status,
                style: theme.statusStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.mediumVerticalGap),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: match.teamScores.length,
                itemBuilder: (context, i) {
                  final teamScore = match.teamScores[i];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              teamScore.teamName,
                              style: theme.scoreStyle,
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 2,
                            child: Text(
                              teamScore.scoreText ?? labels.notAvailable,
                              style: theme.scoreStyle,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: labels.matchSemantics(match),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (onTap == null)
            card
          else
            GestureDetector(onTap: onTap, child: card),
          if (onClose != null)
            CloseBadge(onClose: onClose!, theme: theme, label: labels.close),
        ],
      ),
    );
  }

  Widget _team(
    BuildContext context,
    CricketScoreThemeData theme,
    TeamInfo team,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (team.logoUrl.isNotEmpty)
          logoBuilder(context, team, theme.logoRadius!),
        SizedBox(height: theme.smallVerticalGap),
        Text(team.name, style: theme.teamNameStyle),
      ],
    );
  }
}
