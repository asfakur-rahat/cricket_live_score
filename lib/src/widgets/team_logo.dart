import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:cricket_live_score/src/widgets/team_logo_slot.dart';
import 'package:cricket_live_score/src/widgets/team_monogram.dart';
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

/// The default [TeamLogoBuilder]: the logo loaded by [Image.network] in a
/// [CircleAvatar], with a [TeamMonogram] of the team's initials while it
/// loads, when it fails to load, and when there is no logo.
Widget defaultTeamLogoBuilder(
  BuildContext context,
  TeamInfo team,
  double radius,
) =>
    NetworkTeamLogo(team: team, radius: radius);
