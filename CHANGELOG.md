## 1.0.0

First release.

**Widgets**

- `CricketLiveScoreCarousel`: swipeable match cards for a dialog, with auto-scroll, page dots, and loading, empty and error states.
- `CricketInlineScoreCarousel`: the match cards in a sideways-scrolling row for a section of a page. It sizes itself to the tallest card, and either snaps card by card with the next card peeking in (several cards at once on wide screens) or scrolls freely with `snap: false`. Page dots and auto-scroll are optional.
- `CricketLiveScoreView`: the body of a full score screen, with a frosted floating filter header (phases and match types) and pull to refresh. It is a single column on phones and an adaptive grid on tablets, foldables and large windows (`CricketScoreLayout`).
- `showCricketLiveScoreSheet` and `CricketLiveScoreSheet`: the score screen in a draggable bottom sheet with a pinned title bar and refresh and close buttons.
- `CricketScoreTicker`: a slim strip of live scores that rotates one match at a time (`CricketTickerMode.rotate`) or scrolls them all past like a news ticker (`CricketTickerMode.crawl`). It pauses while held, highlights a changed score for a moment, and collapses when nothing is live.
- `CricketMatchFab`: a small floating button with both team logos and a LIVE chip.
- `CricketMatchCard` and `CricketBatsIcon` for building your own layouts.

**Data**

- `CricketScoreController` with a sealed `CricketScoreState`. A failed poll keeps the last matches, and polling pauses while the app is in the background.
- `CricketScoreSource`, a one-method interface for your own data, and `CricketDataWidgetSource` for cricketdata.org's website widget, with a default referrer used with cricketdata.org's permission.
- `CricketMatch.phase` (`MatchPhase`), `CricketMatchFilter`, `filterMatches`, `matchTypesOf`, `sortMatches` and `pickFeaturedMatch`.
- `CricketDataHtmlParser`.

**Customization**

- `CricketScoreThemeData`, a theme extension where every field is optional and defaults come from your colour scheme and text theme, including dark mode.
- `CricketScoreLabels` for every string the widgets show or announce to screen readers.
- Sizes scale with the screen (`CricketScoreScale`). `CricketScoreScaleScope` turns scaling off, or sets your own design size and tablet canvas.

Requires Flutter 3.27 / Dart 3.6 or later.
