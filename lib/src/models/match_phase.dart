/// Where a match is in its life: not started, in progress or over.
///
/// See `CricketMatch.phase` for how a match's phase is worked out.
enum MatchPhase {
  /// Not started yet: no score and no result.
  upcoming,

  /// In progress.
  live,

  /// Over: there is a result, or the match was abandoned.
  finished,
}
