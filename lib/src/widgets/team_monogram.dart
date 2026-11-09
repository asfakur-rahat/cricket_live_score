import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_labels.dart';
import 'package:cricket_live_score/src/widgets/cricket_score_theme.dart';
import 'package:flutter/material.dart';

/// A circle of [radius] with [team]'s initials, shown in place of a logo
/// when the team has none or it fails to load.
///
/// The letters come from [CricketScoreLabels.teamInitials], which is
/// [TeamInfo.initials] unless you pass your own `formatTeamInitials`. Each
/// team gets its own colour from [palette], picked from its name, unless
/// the theme sets [CricketScoreThemeData.monogramBackground]. Pass the
/// [opponent] so the two sides of a match never share a colour. Screen
/// readers skip the circle: the team name is read already.
///
/// Use it in your own `logoBuilder`, for example as the placeholder of a
/// cached image.
class TeamMonogram extends StatelessWidget {
  /// Creates the circle for [team].
  const TeamMonogram({
    required this.team,
    required this.radius,
    super.key,
    this.opponent,
    this.theme,
    this.labels = const CricketScoreLabels(),
  });

  /// The team whose initials to show.
  final TeamInfo team;

  /// The other side of the match, if any; see [colorOf].
  final TeamInfo? opponent;

  /// The radius of the circle.
  final double radius;

  /// Overrides the ambient [CricketScoreThemeData].
  final CricketScoreThemeData? theme;

  /// Supplies the initials.
  final CricketScoreLabels labels;

  /// The team colours, dark enough for white letters in light and dark
  /// mode.
  static const palette = <Color>[
    Color(0xFFC62828), // red
    Color(0xFFAD1457), // pink
    Color(0xFF6A1B9A), // purple
    Color(0xFF283593), // indigo
    Color(0xFF1565C0), // blue
    Color(0xFF006064), // cyan
    Color(0xFF00695C), // teal
    Color(0xFF2E7D32), // green
    Color(0xFF33691E), // olive
    Color(0xFFBF360C), // deep orange
    Color(0xFF4E342E), // brown
    Color(0xFF37474F), // blue grey
  ];

  /// The [palette] colour of [team], the same every time for its name.
  ///
  /// When [opponent] would get the same colour, the team whose name sorts
  /// later takes the next colour, so the two sides of a match differ.
  static Color colorOf(TeamInfo team, {TeamInfo? opponent}) {
    final key = _key(team);
    var index = _index(key);
    if (opponent != null) {
      final other = _key(opponent);
      if (other != key && _index(other) == index && key.compareTo(other) > 0) {
        index = (index + 1) % palette.length;
      }
    }
    return palette[index];
  }

  static String _key(TeamInfo team) => team.name.trim().toLowerCase();

  static int _index(String key) {
    // FNV-1a, so the colour doesn't depend on String.hashCode, which may
    // differ between platforms and runs.
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash % palette.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CricketScoreThemeData.resolve(context, this.theme);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: radius * 2,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            color:
                theme.monogramBackground ?? colorOf(team, opponent: opponent),
          ),
          child: Padding(
            padding: EdgeInsets.all(radius * 0.3),
            // Three letters shrink to fit; one or two stay at full size.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                labels.teamInitials(team),
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: (theme.monogramTextStyle ?? const TextStyle()).copyWith(
                  color: theme.monogramForeground,
                  fontSize: radius * 0.8,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
