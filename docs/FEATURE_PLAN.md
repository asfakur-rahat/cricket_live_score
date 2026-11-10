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

**Done on 2026-11-09.** Changed from the original plan:

- Pull to refresh is replaced by a refresh button in the sheet's title bar, because pulling down drags the sheet.
- On a wide window the sheet is capped at the same dialog width as the carousel (560), not 640.
- The title bar (handle, title, refresh, close) stays pinned while the filters float under it.

```dart
showCricketLiveScoreSheet(context, source: source);   // one-liner
```

- Opens a draggable modal sheet with the same view, filters and pull to refresh as Part 2. It has a drag handle and an optional title.
- Dragging the list and dragging the sheet work together, using a draggable sheet's own scroll controller.
- On a wide window the sheet is capped at the Material width (640) and centred, so it doesn't stretch across a tablet.
- `CricketLiveScoreSheet` is also public, for apps that open sheets their own way.

## 5. Page dots on the carousel

**Done on 2026-11-09.** The dots sit in a small capsule right under each card, so they stay readable over the dialog's dark backdrop. While swiping they stay in place and fade into the next card's dots. Screen readers can step through the matches with them.

- `CricketLiveScoreCarousel(showPageIndicator: true)` shows dots under the card for the current match. Off by default, as in the app.
- Dot size, gap and colours are new theme fields. The defaults scale with the screen and come from the colour scheme.
- With many matches (for example 26), show at most about 7 dots, which slide along as you page, so the row never overflows. You can say if you'd rather have simple dots.
- Tapping a dot jumps to that match.

## 6. Score ticker banner: `CricketScoreTicker`

**Done on 2026-11-09.** The plan, plus:

- A pulsing LIVE chip.
- Team logos, which `showLogos: false` turns off.
- A thin progress line that fills until the next match.
- Lifting a finger after holding the strip is not treated as a tap.

A slim strip for the top of a home screen, showing one live match at a time:

`T20 · Bangladesh 168/6 (20) vs Sri Lanka 131/4 (16)`

- Moves to the next live match every few seconds with a slide animation and pauses while the user touches it. Tapping it calls `onMatchTap`.
- Takes a `source` or a `controller`.
- **Live matches only** by default. A `filter` option allows other choices.
- When nothing matches, it **collapses to nothing** by default. A builder can show something instead.
- Height, padding, colours and text style are new theme fields.

## 6b. Ticker styles and a glass design

**Done on 2026-11-09.** Differences from the plan:

- `tickerProgressColor` is gone too; the progress line uses the accent gradient.
- **Design changed after review:** the user didn't like the glass card's glow and shadow, and chose a flat tint instead. The card is now a solid `tickerBackground` (`surfaceContainerHigh`) with rounded corners and no border, shadow, glow or blur. The LIVE chip, progress line, diamonds and score flash have no shadows either. The theme has `tickerAccentStart` and `tickerAccentEnd` (for the progress line and diamonds) and `tickerFlashColor`; `tickerGlowColor` and `tickerBlur` are gone.
- On a narrow screen the team names shorten in proportion to their length, so the chip, logos and scores always fit. If even those don't fit, for example with very large text, the line scales down.

Asked for after Part 6. The choices made were: news crawl and rotate modes, the glass design, a flash when a score changes, and crawl speed control.

**Modes.** A `mode:` option takes a `CricketTickerMode`:

- `rotate` (the default, as in Part 6): one match at a time slides up, with the progress line.
- `crawl`: every match in one line that scrolls sideways without stopping, like a TV news ticker.
  - The matches are separated by a small glowing diamond, and the line loops seamlessly.
  - Holding pauses it, and tapping calls `onMatchTap` with the match under the finger.
  - The left and right edges fade out softly.
  - `crawlSpeed` sets the speed in logical pixels per second (default 40, scaled with the screen). It scrolls the other way in right-to-left languages.
  - If every match fits, it stays still.
  - With "reduce motion" on, it falls back to `rotate`.

**Glass design, for both modes:**

- A frosted, see-through background (a backdrop blur).
- A thin gradient edge from primary to tertiary, with a soft outer glow.
- A LIVE chip that glows as it pulses.
- A gradient progress line in rotate mode.
- Theme changes:
  - `tickerBorder` is replaced by `tickerEdgeStart`, `tickerEdgeEnd` and `tickerGlowColor`.
  - `tickerBackground` becomes translucent by default.
  - New field `tickerBlur`.

**Flash on score change.** When a refresh changes a match's score, the new score glows briefly (about 1.5 s) in `tickerFlashColor`, in both modes. A rotating ticker doesn't jump to the changed match; the flash shows when it comes round. Flashes don't show while "reduce motion" is on.

**Tests and device check:** both modes, crawl looping and pausing, tapping a match in the crawl, flash on change, right-to-left, reduce motion; then on the tablet.

## 7. Scaling control

**Done on 2026-11-09.** As planned. `CricketScoreScale` also gains `design` and `enabled`, so code that uses the scale directly can see the scope's settings.

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

**Done on 2026-11-09.** On the tablet the cards were invisible in dark mode: they used `surface`, the page colour, and shadows don't show on dark. The dark defaults changed; light is unchanged.

- Cards and the floating button use `surfaceContainerHigh`.
- The close badge uses `surfaceContainerHighest`.
- The page-dot capsule is lighter and the inactive dots are stronger.

The example has a System / Light / Dark switch with the app's own dark colours. There are dark golden images, and a "Dark mode" section in the README.

This mostly works already: `CricketScoreThemeData` is a `ThemeExtension`, so an app registers one in `theme` and another in `darkTheme`, and Flutter switches between them. This part:

- adds a light/dark example and a README section showing it,
- adds a dark golden test so it doesn't break,
- fixes any default that looks wrong on a dark colour scheme. The package picks no brand colours itself.

## 9. Inline score carousel: `CricketInlineScoreCarousel`

**Done on 2026-11-09.** As planned, with two details settled while building. Page dots show one dot for each place the row stops, so several cards on screen mean fewer dots than cards. After a rotation or a change in the matches, the row settles on the nearest card.

Asked for after Part 8: a carousel that sits in a section of a normal page instead of a dialog. The choices made were: snapping and free scrolling as an option, page dots, auto-scroll, and a height that fits the tallest card.

```dart
CricketInlineScoreCarousel(
  source: source,            // or controller:
  snap: true,                // false = free scrolling shelf
  showPageIndicator: true,
  autoScroll: true,
  onMatchTap: (match) => ...,
)
```

**Layout:**

- A horizontal row of match cards with no close button. It goes straight into a `ListView`, `Column` or `CustomScrollView` (through `SliverToBoxAdapter`) with no height to set.
- The height is the tallest card's height, and shorter cards stretch to match. It follows the cards as scores change and as the screen is resized.
- `padding` (default 16 at the sides, scaled) lines the first card up with the rest of the page. Cards scroll edge to edge through it, and cards sit `spacing` apart.
- The card shadows aren't clipped at the top and bottom.

**`snap: true`, the default:**

- One card at a time snaps into place, with the next card peeking in at the edge so people can see there's more.
- On a phone a card takes about 85% of the width. On tablets and foldables cards keep a phone card's width, so two or three show at once and a swipe moves one card.

**`snap: false`:** fixed-width cards (`cardWidth`, default a phone card's width) that scroll freely with no snapping, like an app store shelf.

**Page dots (`showPageIndicator`):**

- The Part 5 dots under the cards, one per card, including the sliding window and tap to jump.
- When several cards show at once, the first card on screen is the current one.
- Snap mode only.

**Auto-scroll (`autoScroll`, `autoScrollInterval`):**

- Moves on one card every few seconds (default 5 s) and wraps to the start. It works like the dialog carousel: it waits while the user is touching or scrolling, and stops while the app is in the background.
- Snap mode only.
- With "reduce motion" on it jumps instead of sliding.

**Loading, empty and error:** shown in a single full-width card at the section's place, using the same `loadingBuilder`, `emptyBuilder` and `errorBuilder` as the other widgets. The error card has a retry button.

**Everything else** is the same as the dialog carousel: `theme`, `labels`, `logoBuilder`, `centerBadge`, and lifecycle handling through `ScoreControllerHost`. It is right-to-left aware: the first card starts at the right, and swipes and auto-scroll go the other way. Dots and cards have screen reader labels.

**Example:** a "Live now" section on the home page, under the ticker, with a Snap / Free switch.

**Tests and device check:**

- The height fits the tallest card and updates when the matches change.
- Snapping, peeking, and several cards on wide screens.
- Free scrolling.
- Dots and tap to jump.
- Auto-scroll: pausing while touched and wrapping.
- Loading, empty and error states, right-to-left, reduce motion, and inside a `ListView`.
- Then on the tablet in portrait and landscape, light and dark.

**Version:** 0.2.0 isn't published yet, so this goes into 0.2.0 too.

## 10. Team initials instead of a missing logo (1.1.0)

**Done on 2026-11-09.** As planned, with one addition: when the two teams of a match get the same palette colour, the team whose name sorts later takes the next colour, so the two sides always differ. Checked on the tablet with live data (U19, domestic and T10 teams) in light and dark.

Asked for after 1.0.1. Today a team with no logo URL shows nothing in the cards and the ticker, so those cards look different from the rest. A logo that fails to load shows a generic flag icon. The choices made were: a colour per team, qualifiers dropped, and initials in the ticker too.

**What changes:**

- Every place that shows a team logo shows a circle with the team's initials instead when the team has no logo URL. That covers cards, the ticker and the floating button, in every widget that uses them, so all cards look alike.
- The default logo builder shows the initials while the logo loads and if it fails to load. The flag icon goes.
- A custom `logoBuilder` is still only called for teams that have a logo URL, so existing builders that load `team.logoUrl` don't break.

**How the initials are made** (`TeamInfo.initials`):

1. Strip punctuation, split on spaces, and drop trailing qualifiers: `A`, `B`, `W`, `XI`, `Women`, `Men`, `U19` / `U-19` / `Under-19` and similar. Then drop the joining words `of`, `and`, `the` and `&`. Each of these is dropped only when something is left.
2. **One word:** a word that is already 2–4 capital letters is kept as it is (`USA`, `UAE`, `MSW`). Otherwise it's the first three letters, upper-cased.
3. **Several words:** the first letter of each word, up to three.
4. Letters are counted as characters a reader sees, so names in other scripts work. An empty name gives `?`.

| Team | Initials |
|---|---|
| Australia, Bangladesh, India, Afghanistan | AUS, BAN, IND, AFG |
| New Zealand, Sri Lanka, West Indies, South Africa | NZ, SL, WI, SA |
| Papua New Guinea, United Arab Emirates | PNG, UAE |
| United States of America | USA |
| Chennai Super Kings, Royal Challengers Bengaluru | CSK, RCB |
| India A, Afghanistan U19, Namibia Women | IND, AFG, NAM |

`CricketScoreLabels.formatTeamInitials` replaces the rule, for example to use your own codes (`'Bangladesh' → 'BNG'`) or for another language.

**The circle** (`TeamMonogram`, public, so custom builders can use it as their own placeholder):

- Each team gets a colour from a built-in palette of 12, picked from its name, so it's always the same for that team. The letters are white and readable on every palette colour, in light and dark mode.
- The letters are bold and shrink to fit, including the small circles in the ticker.
- Screen readers skip it, since the team name is read already.
- New theme fields: `monogramBackground` (one colour for every team instead of the palette), `monogramForeground` and `monogramTextStyle`.

**Also:**

- The README screenshots use the package's own initials instead of the made-up logos in the screenshot script.
- The README "Logos and badges" section explains the fallback.

**Tests and device check:**

- The initials rule against the table above, plus edge cases: an empty name, extra spaces, all capitals, and other scripts.
- The same team always gets the same colour, and the theme overrides work.
- No logo URL shows initials in the card, the ticker and the floating button.
- A logo that fails to load shows initials.
- A custom `logoBuilder` isn't called for a team without a URL.
- Updated golden images.
- Then on the tablet with live data, which has teams without logos, in light and dark.

**Version:** 1.1.0, since it adds public API (`TeamMonogram`, `TeamInfo.initials`, theme and label fields) and changes how cards look. Released through the tag workflow.

## 11. Control over closing the popup and the sheet (1.2.0)

**Done on 2026-11-10.** As planned, with two details settled while building. Flutter's modal sheet also closes when the draggable sheet inside it reaches its smallest size, so `enableDrag: false` turns that off too (`shouldCloseOnMinExtent`). Blocking the back button needs a `PopScope` inside the popup or sheet, not around the page, and inside it the sheet needs `onClose: () => Navigator.pop(context)`, since its default close button respects the `PopScope`; the README shows this and tests cover it. Checked on the tablet with live data: a tap outside, a slow drag and a fast fling all leave the sheet open with the option off, and the close and back buttons close both.

Asked for after 1.1.0. The score sheet always closes on a tap outside it or a drag down, and the app can't change that. Some apps want the user to close it on purpose, for example while a big match is on. The popup carousel has no helper at all: every app writes the same `showDialog`, transparent `Dialog` and close-button wiring by hand.

**Sheet** (`showCricketLiveScoreSheet`):

- `isDismissible` (default `true`): whether a tap outside the sheet closes it.
- `enableDrag` (default `true`): whether dragging the sheet down closes it. With `false`, the sheet still drags between `minChildSize` and `maxChildSize`, but it stops at `minChildSize` instead of closing. The handle stays, since the sheet still resizes.
- These are the names Flutter's `showModalBottomSheet` uses.
- The close button in the title bar is always there, so a sheet that can't be tapped or dragged away can still be closed.

**Popup** (new `showCricketLiveScoreDialog`):

- Opens a `CricketLiveScoreCarousel` in a transparent dialog and completes when the dialog closes, like the sheet helper.
- `barrierDismissible` (default `true`): whether a tap outside the cards closes the dialog.
- Every card has a close button that closes the dialog, so there is always a way out.
- It takes the carousel's options (`controller` or `source`, `autoScroll`, `autoScrollInterval`, `showPageIndicator`, `maxWidth`, `maxHeight`, `onMatchTap`, `theme`, `labels`, `logoBuilder`, `centerBadge` and the loading, empty and error builders), plus `barrierColor`.
- `CricketLiveScoreCarousel` doesn't change. An app that opens its own dialog keeps doing so; the README shows both ways.

**The back button:** it still closes both, as in Flutter's own dialogs and sheets even when tapping outside is off. Blocking it can trap the user. An app that really needs that opens the popup or sheet itself and puts a `PopScope` around the package's widget, and the README says so.

**Also:**

- The README popup section leads with `showCricketLiveScoreDialog`, and the sheet section lists the two new options.
- The example app gets a switch to try both without tap-outside closing.

**Tests and device check:**

- Sheet: with the defaults a tap outside and a drag down close it. With `isDismissible: false` a tap outside doesn't, and with `enableDrag: false` a drag down doesn't. The close button and the back button close it in every case.
- Dialog: it shows the cards with close buttons. A tap outside closes it, unless `barrierDismissible` is `false`. The close button and the back button close it, and the returned future completes.
- Then on the tablet: the drag check matters most, since the sheet is a draggable sheet inside a modal sheet.

**Version:** 1.2.0, since it adds public API without changing any default. Released through the tag workflow.

## 12. A blurred background behind the popup and the sheet

**Done on 2026-11-10, in 1.2.0.** As planned, with one correction. While the sheet is dragged down the blur stays, because the drag resizes the draggable sheet rather than moving the route; the blur fades once the sheet lets go and closes. Checked on the tablet with the app's values, in light and dark.

Asked for after Part 11. In the MyRace app, the page behind a popup or bottom sheet is blurred, not just dimmed. The package's popup and sheet only dim it, so they look different from the app's own popups.

**What the app does** (`app_alerts.dart`, read only):

- Popups (`showPopupDialog`): a strong blur (28) and a light white wash on top of Flutter's default dimming.
- Bottom sheets (`openBottomSheet`): a light blur (6) and a faint navy barrier (`0x1A1925A6`).
- In both, the blur appears at full strength the moment the popup opens instead of fading in. The popup's blur also stops at the status and navigation bars, since it sits inside the dialog's safe area.

**What changes:**

- `showCricketLiveScoreDialog` and `showCricketLiveScoreSheet` take `barrierBlur`, the blur strength (the sigma in logical pixels). The default `0` means no blur, so nothing changes for existing apps.
- The blur fades in and out with the popup or sheet. It covers the whole screen, the status bar included, and taps on it behave as before (they close the popup or sheet unless that's turned off).
- `showCricketLiveScoreSheet` also takes `barrierColor`, like the popup already does, so an app can match its own tint.
- The README shows how to match the app: `barrierBlur: 28` for the popup and `barrierBlur: 6, barrierColor: Color(0x1A1925A6)` for the sheet. It also notes that blurring costs more to draw on low-end phones.

**How:** neither `showDialog` nor `showModalBottomSheet` accepts a blur. Flutter's routes have one, but it doesn't fade with the route. The blur can't go inside the sheet either, since the sheet clips its content to its rounded shape. So with a blur, the helpers open Flutter's own `DialogRoute` and `ModalBottomSheetRoute` with the blur added to their barrier. These constructors are the same in Flutter 3.27 and 3.47. Without a blur, the helpers keep calling `showDialog` and `showModalBottomSheet` exactly as now.

**Tests and device check:**

- No blur by default; with `barrierBlur` the barrier has a blur that grows as the route opens and goes when it closes.
- A tap outside, `barrierDismissible`, `isDismissible`, `enableDrag`, the close buttons and the back button behave the same with a blur.
- `barrierColor` reaches the sheet's barrier.
- The theme, text direction and scaling still reach the popup and sheet when they open through the new route.
- Then on the tablet: both with the app's values, in light and dark, including dragging the sheet down.

**Version:** joins 1.2.0, which hadn't been pushed; the local `v1.2.0` tag moves to the new commit.

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
| 9 | Inline score carousel | 5 |
| 10 | Team initials instead of a missing logo (1.1.0) | – |
| 11 | Control over closing the popup and the sheet (1.2.0) | 4 |
| 12 | A blurred background behind the popup and the sheet | 11 |

Parts 5, 7 and 8 stand alone and can move anywhere in the order.
