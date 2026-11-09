## 0.2.0 — Unreleased

- `CricketMatch.phase` and `MatchPhase`: upcoming, live or finished.
- `CricketMatchFilter`, `filterMatches` and `matchTypesOf` for filtering matches by phase and match type.
- `CricketLiveScoreView`: the body of a live score screen, with a frosted, floating filter header (a sliding-pill phase capsule and match-type tabs) and pull to refresh.
- `CricketScoreLayout`: the score screen is an adaptive grid on tablets, foldables and large landscape windows by default, or one phone-width column with `CricketScoreLayout.phone`.
- `showCricketLiveScoreSheet` and `CricketLiveScoreSheet`: the live scores in a draggable bottom sheet, with a pinned title bar and refresh and close buttons. On a wide window it is capped at the dialog width and centred.
- `CricketLiveScoreView` takes a `scrollController`, a `pinnedHeader` that stays above the filters, and `enablePullToRefresh`.
- `CricketLiveScoreCarousel(showPageIndicator: true)`: page dots under the card, sliding along when there are more than seven matches. Tap a dot to jump to its match.
- `CricketScoreTicker`: a slim strip that rotates through the live scores, pauses while held, and collapses when nothing is live.
- New theme fields for the score screen (`listGap`, `gridTileMinWidth`, `sheetTitleStyle`, `filterChipStyle` and the `filter…` colours and sizes) and the page dots (`pageDot…` and `pageIndicatorBackground`) and the ticker (`ticker…`), and new labels for the filters, the sheet (`scoresTitle`, `refresh`) and the page dots (`formatPagePosition`).
- **Breaking:** requires Flutter 3.27 / Dart 3.6 or later (was Flutter 3.24 / Dart 3.5).

## 0.1.0 — Initial release

- `CricketLiveScoreCarousel`: polling match carousel with optional auto-scroll and loading, empty and error states.
- `CricketMatchCard` and `CricketMatchFab` widgets.
- `CricketScoreController` with sealed `CricketScoreState`; a failed poll keeps the last matches, and polling pauses while the app is in the background.
- `CricketScoreSource` interface and `CricketDataWidgetSource` for cricketdata.org's website widget, with a default referrer used with cricketdata.org's permission.
- `CricketDataHtmlParser`, `sortMatches` and `pickFeaturedMatch`.
- `CricketScoreThemeData` theme extension and `CricketScoreLabels` for localization.
- Default sizes and text sizes scale with the screen (`CricketScoreScale`).
- `CricketBatsIcon`: crossed bats and ball, the default centre badge on match cards.
