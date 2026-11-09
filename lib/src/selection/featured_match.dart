import 'package:cricket_live_score/src/models/cricket_match.dart';

/// Picks the one match to feature, for example on a floating button.
///
/// Prefers a live match with both team logos, then any live match, then the
/// first match. Returns `null` when [matches] is empty. Note that the result
/// is not necessarily live; check [CricketMatch.isLive] before calling it so.
CricketMatch? pickFeaturedMatch(List<CricketMatch> matches) {
  if (matches.isEmpty) return null;
  for (final match in matches) {
    if (match.isLive && match.hasBothLogos) return match;
  }
  for (final match in matches) {
    if (match.isLive) return match;
  }
  return matches.first;
}
