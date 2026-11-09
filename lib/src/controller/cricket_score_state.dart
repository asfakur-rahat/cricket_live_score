import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:flutter/foundation.dart';

/// What a CricketScoreController currently knows about the matches.
@immutable
sealed class CricketScoreState {
  const CricketScoreState();

  /// The matches to show in this state; empty unless there are some.
  List<CricketMatch> get matches;
}

/// The first fetch has not finished yet.
final class CricketScoreLoading extends CricketScoreState {
  /// Creates the loading state.
  const CricketScoreLoading();

  @override
  List<CricketMatch> get matches => const [];

  @override
  bool operator ==(Object other) => other is CricketScoreLoading;

  @override
  int get hashCode => (CricketScoreLoading).hashCode;

  @override
  String toString() => 'CricketScoreLoading()';
}

/// The last fetch returned at least one match.
final class CricketScoreLoaded extends CricketScoreState {
  /// Creates a loaded state holding [matches].
  const CricketScoreLoaded(this.matches);

  @override
  final List<CricketMatch> matches;

  @override
  bool operator ==(Object other) =>
      other is CricketScoreLoaded && listEquals(other.matches, matches);

  @override
  int get hashCode => Object.hashAll(matches);

  @override
  String toString() => 'CricketScoreLoaded(${matches.length} matches)';
}

/// The last fetch succeeded but returned no matches.
final class CricketScoreEmpty extends CricketScoreState {
  /// Creates the empty state.
  const CricketScoreEmpty();

  @override
  List<CricketMatch> get matches => const [];

  @override
  bool operator ==(Object other) => other is CricketScoreEmpty;

  @override
  int get hashCode => (CricketScoreEmpty).hashCode;

  @override
  String toString() => 'CricketScoreEmpty()';
}

/// The last fetch failed.
///
/// [lastMatches] keeps the matches from the last successful fetch, so a
/// single failed poll does not blank the screen.
final class CricketScoreFailure extends CricketScoreState {
  /// Creates a failure state for [error].
  const CricketScoreFailure(
    this.error, {
    this.stackTrace,
    this.lastMatches = const [],
  });

  /// The error thrown by the source, usually a `CricketScoreException`.
  final Object error;

  /// Where [error] was thrown, when known.
  final StackTrace? stackTrace;

  /// Matches from the last successful fetch; empty if there was none.
  final List<CricketMatch> lastMatches;

  @override
  List<CricketMatch> get matches => lastMatches;

  @override
  bool operator ==(Object other) =>
      other is CricketScoreFailure &&
      other.error == error &&
      listEquals(other.lastMatches, lastMatches);

  @override
  int get hashCode => Object.hash(error, Object.hashAll(lastMatches));

  @override
  String toString() =>
      'CricketScoreFailure($error, ${lastMatches.length} last matches)';
}
