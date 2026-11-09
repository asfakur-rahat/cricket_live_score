## 0.2.0 — Unreleased

- `CricketMatch.phase` and `MatchPhase`: upcoming, live or finished.
- `CricketMatchFilter`, `filterMatches` and `matchTypesOf` for filtering matches by phase and match type.
- `CricketLiveScoreView`: the body of a live score screen, with phase and match-type filter chips and pull to refresh.
- New theme fields `listGap` and `filterChipStyle`, and new labels for the filter chips.

## 0.1.0 — Initial release

- `CricketLiveScoreCarousel`: polling match carousel with optional auto-scroll and loading, empty and error states.
- `CricketMatchCard` and `CricketMatchFab` widgets.
- `CricketScoreController` with sealed `CricketScoreState`; a failed poll keeps the last matches, and polling pauses while the app is in the background.
- `CricketScoreSource` interface and `CricketDataWidgetSource` for cricketdata.org's website widget, with a default referrer used with cricketdata.org's permission.
- `CricketDataHtmlParser`, `sortMatches` and `pickFeaturedMatch`.
- `CricketScoreThemeData` theme extension and `CricketScoreLabels` for localization.
- Default sizes and text sizes scale with the screen (`CricketScoreScale`).
- `CricketBatsIcon`: crossed bats and ball, the default centre badge on match cards.
