import 'package:cricket_live_score/cricket_live_score.dart';

/// Passes on only the matches from [source] that [filter] accepts, so any
/// widget that takes a source can show a filtered list.
class FilteredSource implements CricketScoreSource {
  FilteredSource(this.source, this.filter);

  final CricketScoreSource source;
  final CricketMatchFilter filter;

  @override
  Future<List<CricketMatch>> fetchMatches() async =>
      filterMatches(await source.fetchMatches(), filter);
}
