## 0.1.0 — Initial release

- `CricketLiveScoreCarousel`: polling match carousel with optional auto-scroll and loading, empty and error states.
- `CricketMatchCard` and `CricketMatchFab` widgets.
- `CricketScoreController` with sealed `CricketScoreState`; a failed poll keeps the last matches, and polling pauses while the app is in the background.
- `CricketScoreSource` interface and `CricketDataWidgetSource` for cricketdata.org's website widget (referrer required).
- `CricketDataHtmlParser`, `sortMatches` and `pickFeaturedMatch`.
- `CricketScoreThemeData` theme extension and `CricketScoreLabels` for localization.
