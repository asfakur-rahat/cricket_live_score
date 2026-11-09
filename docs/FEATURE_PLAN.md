# Feature plan

Based on `docs/FEATURE_REQUESTS.md`. **Status: approved on 2026-11-09. Building Part 1.**

Decisions:
- The names below are approved.
- The filter bar uses two chip rows: phase, then type.
- These features ship as **0.2.0**.
- The second data source (old Part 9) is **dropped**.

Each part is built, tested on the tablet, and committed on its own. I wait for your OK between parts.

Rules for every part:
- The existing popup carousel and floating button keep working exactly as they do today, like the app. Every new option is off by default.
- No new dependencies.
- Each part comes with tests, an update to the example app, README and CHANGELOG entries, and a check on the tablet in portrait and landscape.

---

## 1. Shared building blocks: match phase and filters

The score screen, the bottom sheet and the ticker all need the same filtering, so it is built once.

- `CricketMatch.phase` returns `MatchPhase.live`, `.upcoming` or `.finished`:
  - **live:** the existing `isLive`.
  - **finished:** the status says won, tied, drawn, no result or abandoned. This is the same rule the parser already uses.
  - **upcoming:** everything else, meaning no score yet.
- `CricketMatchFilter` holds a set of match types (T20, ODI, Test, T10…) and a set of phases. An empty set means all.
- `filterMatches(matches, filter)` is a pure function.
- `matchTypesOf(matches)` returns the types present in the data, so the chips only show types that exist.

```dart
final filter = CricketMatchFilter(types: {'T20'}, phases: {MatchPhase.live});
final shown = filterMatches(matches, filter);
```

## 2. Live score screen body: `CricketLiveScoreView`

This is your "live score screen". It is a body widget with no `Scaffold` and no route, so the app places it wherever it wants.

```dart
Scaffold(
  appBar: AppBar(title: const Text('Live scores')),
  body: CricketLiveScoreView(source: CricketDataWidgetSource()),
);
```

- Takes a `source` or a `controller`, the same as the carousel. With a source it owns the controller and pauses polling in the background.
- **Filter bar** at the top:
  - Phase chips: All · Live · Upcoming · Done.
  - Type chips: All · T20 · ODI · Test …, built from the data.
  - Either bar can be hidden. An app can also pass an `initialFilter`, or control the filter from outside.
- **List of match cards**, reusing `CricketMatchCard`.
- **Pull to refresh**, which fetches immediately.
- Loading, empty ("no matches for this filter"), and error with retry. These reuse the existing builders and labels.
- `onMatchTap`, `theme`, `labels`, `logoBuilder` and `centerBadge` work the same way as on the carousel.
- New text (Live / Upcoming / Done, All, "No matches for this filter") goes into `CricketScoreLabels` so it can be translated.

## 3. Phone or adaptive layout (foldables and tablets)

**Done with Part 2 on 2026-11-09.** Changed from the original plan: `adaptive` is the default, because the single column looked bad on large landscape and foldable displays.

A `layout:` option on the view:

- `CricketScoreLayout.adaptive` (default): one column on a phone. On a wider window, as many columns as fit (each at least `gridTileMinWidth`, at most 4). Cards in a row share its height. The phase capsule and the type tabs sit side by side on one row. In practice:
  - a tablet in portrait or a foldable's inner display gets 2 columns;
  - a large landscape window gets 3.
- `CricketScoreLayout.phone`: always a single phone-width column, centred on wide windows.

## 4. Live score bottom sheet

```dart
showCricketLiveScoreSheet(context, source: source);   // one-liner
```

- Opens a draggable modal sheet with the same view, filters and pull to refresh as Part 2. It has a drag handle and an optional title.
- Dragging the list and dragging the sheet work together, using a draggable sheet's own scroll controller.
- On a wide window the sheet is capped at the Material width (640) and centred, so it doesn't stretch across a tablet.
- `CricketLiveScoreSheet` is also public, for apps that open sheets their own way.

## 5. Page dots on the carousel

- `CricketLiveScoreCarousel(showPageIndicator: true)` shows dots under the card for the current match. Off by default, as in the app.
- Dot size, gap and colours are new theme fields. The defaults scale with the screen and come from the colour scheme.
- With many matches (for example 26), show at most about 7 dots, which slide along as you page, so the row never overflows. You can say if you'd rather have simple dots.
- Tapping a dot jumps to that match.

## 6. Score ticker banner: `CricketScoreTicker`

A slim strip for the top of a home screen, showing one live match at a time:

`T20 · Bangladesh 168/6 (20) vs Sri Lanka 131/4 (16)`

- Moves to the next live match every few seconds with a slide animation and pauses while the user touches it. Tapping it calls `onMatchTap`.
- Takes a `source` or a `controller`.
- **Live matches only** by default. A `filter` option allows other choices.
- When nothing matches, it **collapses to nothing** by default. A builder can show something instead.
- Height, padding, colours and text style are new theme fields.

## 7. Scaling control

`CricketScoreScaleScope` sits above the widgets (for example in `MaterialApp.builder`):

```dart
CricketScoreScaleScope(
  enabled: true,                       // false = fixed sizes, no scaling
  designSize: Size(390, 850),          // your app's design size
  wideCanvas: Size(430, 937),          // the tablet/foldable canvas
  child: child,
)
```

- With no scope, behaviour is exactly as today.
- With `enabled: false`, every size is the plain design value and text uses your text theme's sizes unchanged.

## 8. Dark mode (the app passes its colours)

This mostly works already: `CricketScoreThemeData` is a `ThemeExtension`, so an app registers one in `theme` and another in `darkTheme`, and Flutter switches between them. This part:

- adds a light/dark example and a README section showing it,
- adds a dark golden test so it doesn't break,
- fixes any default that looks wrong on a dark colour scheme. The package picks no brand colours itself.

---

## Proposed order

| Part | What | Depends on |
|---|---|---|
| 1 | Match phase and filters | – |
| 2 | Score screen body, filters, pull to refresh | 1 |
| 3 | Phone / adaptive layout | 2 |
| 4 | Bottom sheet | 2 |
| 5 | Carousel page dots | – |
| 6 | Ticker banner | 1 |
| 7 | Scaling control | – |
| 8 | Dark mode | – |

Parts 5, 7 and 8 stand alone and can move anywhere in the order.
