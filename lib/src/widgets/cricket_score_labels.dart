import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/models/match_phase.dart';

/// The text shown by the cricket score widgets.
///
/// Defaults are English. The package ships no translations: pass translated
/// strings from your own localization setup.
class CricketScoreLabels {
  /// Creates a set of labels; every argument has an English default.
  const CricketScoreLabels({
    this.live = 'LIVE',
    this.notAvailable = 'N/A',
    this.venuePrefix = 'At',
    this.versus = 'VS',
    this.close = 'Close',
    this.noMatches = 'No matches right now',
    this.loadFailed = "Couldn't load scores",
    this.retry = 'Retry',
    this.spokenVersus = 'versus',
    this.spokenLive = 'live',
    this.allMatches = 'All',
    this.phaseLive = 'Live',
    this.phaseUpcoming = 'Upcoming',
    this.phaseFinished = 'Done',
    this.noFilteredMatches = 'No matches for this filter',
    this.phaseFilter = 'Match status',
    this.typeFilter = 'Match type',
    this.formatVenue,
  });

  /// Marks a live match: the card heading and the floating button's chip.
  final String live;

  /// Shown in the score table when a team has no score.
  final String notAvailable;

  /// Put before the venue: `'$venuePrefix $venue'`.
  ///
  /// Use [formatVenue] when the translation needs a different word order.
  final String venuePrefix;

  /// Shown between the two team logos on the floating button.
  final String versus;

  /// Accessibility label of the close button.
  final String close;

  /// Shown when the source returned no matches.
  final String noMatches;

  /// Shown when the first fetch failed.
  final String loadFailed;

  /// Label of the button that retries a failed fetch.
  final String retry;

  /// Spoken between team names by screen readers.
  final String spokenVersus;

  /// Spoken by screen readers after the team names of a live match.
  final String spokenLive;

  /// Filter chip that removes a filter: every phase or every match type.
  final String allMatches;

  /// Filter chip for live matches.
  final String phaseLive;

  /// Filter chip for matches that have not started.
  final String phaseUpcoming;

  /// Filter chip for finished matches.
  final String phaseFinished;

  /// Shown on the score screen when there are matches, but none pass the
  /// filter.
  final String noFilteredMatches;

  /// Screen-reader label of the row of phase filter chips.
  final String phaseFilter;

  /// Screen-reader label of the row of match-type filter chips.
  final String typeFilter;

  /// Builds the venue line; when `null` it is `'$venuePrefix $venue'`.
  final String Function(String venue)? formatVenue;

  /// The venue line for [venue].
  String venueLine(String venue) =>
      formatVenue?.call(venue) ?? '$venuePrefix $venue';

  /// The screen-reader description of [match], for example
  /// `"India versus England, live"`.
  String matchSemantics(CricketMatch match) {
    final teams = '${match.team1.name} $spokenVersus ${match.team2.name}';
    return match.isLive ? '$teams, $spokenLive' : teams;
  }

  /// The filter chip label for [phase].
  String phaseLabel(MatchPhase phase) => switch (phase) {
        MatchPhase.live => phaseLive,
        MatchPhase.upcoming => phaseUpcoming,
        MatchPhase.finished => phaseFinished,
      };

  /// Returns a copy with the given labels replaced.
  CricketScoreLabels copyWith({
    String? live,
    String? notAvailable,
    String? venuePrefix,
    String? versus,
    String? close,
    String? noMatches,
    String? loadFailed,
    String? retry,
    String? spokenVersus,
    String? spokenLive,
    String? allMatches,
    String? phaseLive,
    String? phaseUpcoming,
    String? phaseFinished,
    String? noFilteredMatches,
    String? phaseFilter,
    String? typeFilter,
    String Function(String venue)? formatVenue,
  }) {
    return CricketScoreLabels(
      live: live ?? this.live,
      notAvailable: notAvailable ?? this.notAvailable,
      venuePrefix: venuePrefix ?? this.venuePrefix,
      versus: versus ?? this.versus,
      close: close ?? this.close,
      noMatches: noMatches ?? this.noMatches,
      loadFailed: loadFailed ?? this.loadFailed,
      retry: retry ?? this.retry,
      spokenVersus: spokenVersus ?? this.spokenVersus,
      spokenLive: spokenLive ?? this.spokenLive,
      allMatches: allMatches ?? this.allMatches,
      phaseLive: phaseLive ?? this.phaseLive,
      phaseUpcoming: phaseUpcoming ?? this.phaseUpcoming,
      phaseFinished: phaseFinished ?? this.phaseFinished,
      noFilteredMatches: noFilteredMatches ?? this.noFilteredMatches,
      phaseFilter: phaseFilter ?? this.phaseFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      formatVenue: formatVenue ?? this.formatVenue,
    );
  }
}
