import 'package:cricket_live_score/src/models/team_info.dart';
import 'package:cricket_live_score/src/models/team_score.dart';
import 'package:flutter/foundation.dart';

/// A single cricket match as reported by a score source.
@immutable
class CricketMatch {
  /// Creates a match.
  const CricketMatch({
    required this.id,
    required this.matchType,
    required this.venue,
    required this.status,
    required this.team1,
    required this.team2,
    this.startTimeText = '',
    this.startTime,
    this.fullScorecardUrl,
    this.teamScores = const [],
    this.isLive = false,
  });

  /// Creates a [CricketMatch] from the map produced by [toJson].
  factory CricketMatch.fromJson(Map<String, dynamic> json) {
    final startTime = json['startTime'] as String?;
    final teamScores = json['teamScores'] as List<dynamic>?;
    return CricketMatch(
      id: json['id'] as String,
      matchType: json['matchType'] as String,
      venue: json['venue'] as String,
      status: json['status'] as String,
      team1: TeamInfo.fromJson(json['team1'] as Map<String, dynamic>),
      team2: TeamInfo.fromJson(json['team2'] as Map<String, dynamic>),
      startTimeText: json['startTimeText'] as String? ?? '',
      startTime: startTime == null ? null : DateTime.parse(startTime).toUtc(),
      fullScorecardUrl: json['fullScorecardUrl'] as String?,
      teamScores: teamScores == null
          ? const []
          : [
              for (final score in teamScores)
                TeamScore.fromJson(score as Map<String, dynamic>),
            ],
      isLive: json['isLive'] as bool? ?? false,
    );
  }

  /// Identifier assigned by the data source.
  final String id;

  /// Match format in upper case, for example `"T20"` or `"ODI"`.
  final String matchType;

  /// Ground the match is played at.
  final String venue;

  /// Free-text status line, for example `"India won by 5 wickets"`.
  final String status;

  /// The first team listed by the data source.
  final TeamInfo team1;

  /// The second team listed by the data source.
  final TeamInfo team2;

  /// Start time exactly as the source printed it, for example
  /// `"19 Jul 2026, Sun 10:00 GMT"`; empty when the source has none.
  final String startTimeText;

  /// [startTimeText] parsed to a UTC [DateTime]; `null` if it could not be
  /// parsed.
  final DateTime? startTime;

  /// Link to the full scorecard, when the source provides one.
  final String? fullScorecardUrl;

  /// Rows of the score table; empty before the match has started.
  final List<TeamScore> teamScores;

  /// Whether the match is in progress.
  final bool isLive;

  /// Whether both teams have a logo URL.
  bool get hasBothLogos => team1.logoUrl.isNotEmpty && team2.logoUrl.isNotEmpty;

  /// Returns a copy of this match with the given fields replaced.
  ///
  /// A `null` argument keeps the current value, so [startTime] and
  /// [fullScorecardUrl] cannot be cleared this way; construct a new
  /// [CricketMatch] instead.
  CricketMatch copyWith({
    String? id,
    String? matchType,
    String? venue,
    String? status,
    TeamInfo? team1,
    TeamInfo? team2,
    String? startTimeText,
    DateTime? startTime,
    String? fullScorecardUrl,
    List<TeamScore>? teamScores,
    bool? isLive,
  }) {
    return CricketMatch(
      id: id ?? this.id,
      matchType: matchType ?? this.matchType,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      startTimeText: startTimeText ?? this.startTimeText,
      startTime: startTime ?? this.startTime,
      fullScorecardUrl: fullScorecardUrl ?? this.fullScorecardUrl,
      teamScores: teamScores ?? this.teamScores,
      isLive: isLive ?? this.isLive,
    );
  }

  /// Converts this match to a JSON-compatible map.
  ///
  /// [startTime] is written as an ISO-8601 UTC string.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'matchType': matchType,
        'venue': venue,
        'status': status,
        'team1': team1.toJson(),
        'team2': team2.toJson(),
        'startTimeText': startTimeText,
        'startTime': startTime?.toUtc().toIso8601String(),
        'fullScorecardUrl': fullScorecardUrl,
        'teamScores': [for (final score in teamScores) score.toJson()],
        'isLive': isLive,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CricketMatch &&
          other.id == id &&
          other.matchType == matchType &&
          other.venue == venue &&
          other.status == status &&
          other.team1 == team1 &&
          other.team2 == team2 &&
          other.startTimeText == startTimeText &&
          other.startTime == startTime &&
          other.fullScorecardUrl == fullScorecardUrl &&
          listEquals(other.teamScores, teamScores) &&
          other.isLive == isLive;

  @override
  int get hashCode => Object.hash(
        id,
        matchType,
        venue,
        status,
        team1,
        team2,
        startTimeText,
        startTime,
        fullScorecardUrl,
        Object.hashAll(teamScores),
        isLive,
      );

  @override
  String toString() =>
      'CricketMatch(id: $id, matchType: $matchType, venue: $venue, '
      'status: $status, team1: $team1, team2: $team2, '
      'startTimeText: $startTimeText, startTime: $startTime, '
      'fullScorecardUrl: $fullScorecardUrl, teamScores: $teamScores, '
      'isLive: $isLive)';
}
