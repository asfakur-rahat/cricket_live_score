import 'package:cricket_live_score/src/models/cricket_match.dart';

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
      formatVenue: formatVenue ?? this.formatVenue,
    );
  }
}
