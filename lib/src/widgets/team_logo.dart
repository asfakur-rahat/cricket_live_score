import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:flutter/material.dart';

/// Builds the logo of [team] as a circle of [radius].
///
/// Pass one to the widgets to load logos your own way, for example through
/// an image cache.
typedef TeamLogoBuilder = Widget Function(
  BuildContext context,
  TeamInfo team,
  double radius,
);

/// The default [TeamLogoBuilder]: a [CircleAvatar] with the logo loaded by
/// [Image.network], or a flag icon when there is no logo or it fails to load.
Widget defaultTeamLogoBuilder(
  BuildContext context,
  TeamInfo team,
  double radius,
) {
  final fallback = Icon(Icons.flag_outlined, size: radius);
  return CircleAvatar(
    radius: radius,
    child: ClipOval(
      child: team.logoUrl.isEmpty
          ? fallback
          : Image.network(
              team.logoUrl,
              errorBuilder: (_, __, ___) => fallback,
            ),
    ),
  );
}
