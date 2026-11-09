import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:cricket_live_score/src/widgets/team_logo.dart';
import 'package:cricket_live_score/src/widgets/team_monogram.dart';
import 'package:flutter/material.dart';

/// The logo of [team], playing [opponent], in the package's widgets.
///
/// A team without a logo URL gets a [TeamMonogram], so a custom
/// [logoBuilder] is only called with a URL to load. The default builder
/// gets [theme] and [labels] too, for the initials it shows while loading
/// and on failure.
Widget buildTeamLogo(
  BuildContext context,
  TeamInfo team,
  double radius, {
  required TeamInfo opponent,
  required TeamLogoBuilder logoBuilder,
  required CricketScoreThemeData theme,
  required CricketScoreLabels labels,
}) {
  if (team.logoUrl.isEmpty || logoBuilder == defaultTeamLogoBuilder) {
    return NetworkTeamLogo(
      team: team,
      radius: radius,
      opponent: opponent,
      theme: theme,
      labels: labels,
    );
  }
  return logoBuilder(context, team, radius);
}

/// The default logo: the image at the team's logo URL, with its initials
/// while it loads, when it fails, and when there is no URL.
class NetworkTeamLogo extends StatelessWidget {
  /// Creates the logo of [team].
  const NetworkTeamLogo({
    required this.team,
    required this.radius,
    super.key,
    this.opponent,
    this.theme,
    this.labels = const CricketScoreLabels(),
  });

  /// The team.
  final TeamInfo team;

  /// The other side of the match, so the initials get a different colour.
  final TeamInfo? opponent;

  /// The radius of the circle.
  final double radius;

  /// Overrides the ambient [CricketScoreThemeData].
  final CricketScoreThemeData? theme;

  /// Supplies the initials.
  final CricketScoreLabels labels;

  @override
  Widget build(BuildContext context) {
    final initials = TeamMonogram(
      team: team,
      radius: radius,
      opponent: opponent,
      theme: theme,
      labels: labels,
    );
    if (team.logoUrl.isEmpty) return initials;
    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: Image.network(
          team.logoUrl,
          frameBuilder: (context, child, frame, loadedAtOnce) =>
              loadedAtOnce || frame != null ? child : initials,
          errorBuilder: (_, __, ___) => initials,
        ),
      ),
    );
  }
}
