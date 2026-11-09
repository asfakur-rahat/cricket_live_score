import 'package:flutter/foundation.dart';

/// One side of a cricket match: its name, logo and whether it won.
@immutable
class TeamInfo {
  /// Creates a team description.
  const TeamInfo({
    required this.name,
    required this.logoUrl,
    this.isWinner = false,
  });

  /// Creates a [TeamInfo] from the map produced by [toJson].
  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String,
      isWinner: json['isWinner'] as bool? ?? false,
    );
  }

  /// Team name as shown by the data source, for example `"India"`.
  final String name;

  /// Absolute URL of the team's logo or flag; empty when there is none.
  final String logoUrl;

  /// Whether the match status names this team as the winner.
  final bool isWinner;

  /// Returns a copy of this team with the given fields replaced.
  TeamInfo copyWith({String? name, String? logoUrl, bool? isWinner}) {
    return TeamInfo(
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      isWinner: isWinner ?? this.isWinner,
    );
  }

  /// Converts this team to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'logoUrl': logoUrl,
        'isWinner': isWinner,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamInfo &&
          other.name == name &&
          other.logoUrl == logoUrl &&
          other.isWinner == isWinner;

  @override
  int get hashCode => Object.hash(name, logoUrl, isWinner);

  @override
  String toString() =>
      'TeamInfo(name: $name, logoUrl: $logoUrl, isWinner: $isWinner)';
}
