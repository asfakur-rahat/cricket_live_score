import 'package:flutter/foundation.dart';

/// One row of a match's score table: a team and its score so far.
@immutable
class TeamScore {
  /// Creates a score row.
  const TeamScore({required this.teamName, this.scoreText});

  /// Creates a [TeamScore] from the map produced by [toJson].
  factory TeamScore.fromJson(Map<String, dynamic> json) {
    return TeamScore(
      teamName: json['teamName'] as String,
      scoreText: json['scoreText'] as String?,
    );
  }

  /// Team name as it appears in the score table.
  final String teamName;

  /// Score as shown by the data source, for example `"245/6 (42.3 ov)"`;
  /// `null` when the source has none.
  final String? scoreText;

  /// Returns a copy of this row with the given fields replaced.
  ///
  /// A `null` argument keeps the current value, so [scoreText] cannot be
  /// cleared this way; construct a new [TeamScore] instead.
  TeamScore copyWith({String? teamName, String? scoreText}) {
    return TeamScore(
      teamName: teamName ?? this.teamName,
      scoreText: scoreText ?? this.scoreText,
    );
  }

  /// Converts this row to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'teamName': teamName,
        'scoreText': scoreText,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamScore &&
          other.teamName == teamName &&
          other.scoreText == scoreText;

  @override
  int get hashCode => Object.hash(teamName, scoreText);

  @override
  String toString() => 'TeamScore(teamName: $teamName, scoreText: $scoreText)';
}
