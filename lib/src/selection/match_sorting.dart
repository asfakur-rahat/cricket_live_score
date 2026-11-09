import 'package:cricket_live_score/src/models/cricket_match.dart';

/// Returns [matches] in display order.
///
/// Live matches come first, and among those, ones that already have a score.
/// Then matches are ordered by [CricketMatch.startTime], newest first, with
/// unparseable start times last. Matches that tie keep their input order.
List<CricketMatch> sortMatches(Iterable<CricketMatch> matches) {
  final indexed = matches.indexed.toList()
    ..sort((a, b) {
      final byRank = _compare(a.$2, b.$2);
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
  return [for (final (_, match) in indexed) match];
}

int _compare(CricketMatch a, CricketMatch b) {
  if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
  if (a.isLive) {
    final aScored = a.teamScores.isNotEmpty;
    final bScored = b.teamScores.isNotEmpty;
    if (aScored != bScored) return aScored ? -1 : 1;
  }

  final aTime = a.startTime;
  final bTime = b.startTime;
  if (aTime == null || bTime == null) {
    if (aTime == bTime) return 0;
    return aTime == null ? 1 : -1;
  }
  return bTime.compareTo(aTime);
}
