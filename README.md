# cricket_live_score

Live cricket scores for Flutter apps: a self-refreshing match carousel, a compact live-match button, and a pluggable data source.

| Carousel in a dialog | Floating live-match button |
|---|---|
| <img src="https://raw.githubusercontent.com/TODO-owner/cricket_live_score/main/screenshots/carousel.png" width="270" alt="Match card carousel showing a live T20 score"> | <img src="https://raw.githubusercontent.com/TODO-owner/cricket_live_score/main/screenshots/fab.png" width="270" alt="Floating button with both team logos and a LIVE chip"> |

<!-- TODO(G4): replace TODO-owner once the GitHub repository exists. -->

## Features

- **`CricketLiveScoreCarousel`** — swipeable match cards that poll for new scores (every 30 s by default), with optional auto-scroll, and separate loading, empty and error states. A failed poll keeps the last scores on screen.
- **`CricketMatchFab`** — a small button with both team logos around "VS" and a LIVE chip, tap and sideways-swipe callbacks.
- **`CricketScoreSource`** — a one-method interface for your own data, plus `CricketDataWidgetSource`, which reads cricketdata.org's website widget (see [Data source](#data-source)).
- Polling pauses while the app is in the background and refreshes on resume.
- Themeable through a `ThemeExtension`, fully translatable, no code generation, and only `html` and `http` as dependencies.

## Install

```sh
flutter pub add cricket_live_score
```

## Usage

Show the carousel in a dialog:

```dart
import 'package:cricket_live_score/cricket_live_score.dart';

final source = CricketDataWidgetSource();

showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    backgroundColor: Colors.transparent,
    child: CricketLiveScoreCarousel(
      source: source,
      onClose: () => Navigator.pop(context),
    ),
  ),
);
```

The carousel needs a bounded height, such as a dialog's; pass `maxHeight` to cap it. Each card is only as tall as its content, centred in that height, and scrolls only when it doesn't fit. On a phone the carousel takes the full width it is given; on a wider window it is capped at the Material dialog width, unless you pass `maxWidth`.

Feature one match on a floating button:

```dart
final match = pickFeaturedMatch(await source.fetchMatches());
if (match != null) {
  CricketMatchFab(
    match: match,
    onTap: openScores,
    onHorizontalSwipe: hideScores,
  );
}
```

`pickFeaturedMatch` prefers a live match with both logos, then any live match, then the first match — so check `match.isLive` before calling it live.

### A live score screen

`CricketLiveScoreView` is the body of a full score screen: two rows of filter chips (All · Live · Upcoming · Done, then All · T20 · ODI · Test …), the match cards, and pull to refresh. It has no `Scaffold` or route, so put it wherever your app wants:

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (context) => Scaffold(
      appBar: AppBar(title: const Text('Live scores')),
      body: CricketLiveScoreView(source: source),
    ),
  ),
);
```

On a phone it fills the width; on a tablet or unfolded foldable the list is a centred, phone-width column. Start from a filter with `initialFilter`, hide a chip row with `showPhaseFilter` / `showTypeFilter`, or keep the filter in your own state with `filter` and `onFilterChanged`.

### Controlling polling yourself

Pass a `source` and the carousel owns its controller. To share one controller, or to start and stop polling yourself, pass a `controller` instead:

```dart
final controller = CricketScoreController(
  source: source,
  pollInterval: const Duration(seconds: 15),
)..start();

CricketLiveScoreCarousel(controller: controller);

// Later:
controller.pause();   // stop polling, keep the state
controller.dispose(); // you own it, so you dispose it
```

`controller.state` is one of `CricketScoreLoading`, `CricketScoreLoaded`, `CricketScoreEmpty` or `CricketScoreFailure` (which keeps `lastMatches`).

### Filtering matches

Every match has a `phase`: `MatchPhase.live`, `.upcoming` (no score and no result yet) or `.finished` (a result, or a score without being live). Filter by phase and match type:

```dart
const filter = CricketMatchFilter(
  types: {'T20', 'ODI'},          // compared ignoring case; empty = all
  phases: {MatchPhase.live},      // empty = all
);
final shown = filterMatches(matches, filter);

// Types present in the data, common formats first: [T20, ODI, TEST, T10, ...]
final choices = matchTypesOf(matches);
```

## Theming

Every field of `CricketScoreThemeData` is optional. Each one is resolved from the widget's `theme` argument, then a `CricketScoreThemeData` in your `ThemeData.extensions`, then defaults derived from your `ColorScheme` and `TextTheme`.

The default sizes and text sizes scale with the screen, from a 390 × 850 design: a smaller phone gets smaller cards and a larger phone larger ones. A tablet or unfolded foldable uses a fixed phone-sized canvas (430 × 937), so the cards don't grow into a giant phone. `CricketScoreScale` does the arithmetic; a size you set in the theme is used as given.

```dart
MaterialApp(
  theme: ThemeData(
    colorSchemeSeed: Colors.green,
    extensions: const [
      CricketScoreThemeData(
        liveColor: Color(0xFFD32F2F),
        liveChipColor: Color(0xFFD32F2F),
        cardElevation: 2,
        teamNameStyle: TextStyle(fontWeight: FontWeight.w800),
      ),
    ],
  ),
);
```

Sizes are logical pixels. If your app scales its layout, pass your scaled values.

Team logos load with `Image.network` and fall back to a flag icon. To use an image cache, pass a `logoBuilder`:

```dart
CricketLiveScoreCarousel(
  source: source,
  logoBuilder: (context, team, radius) => CircleAvatar(
    radius: radius,
    backgroundImage: CachedNetworkImageProvider(team.logoUrl),
  ),
  centerBadge: Image.asset('assets/cricket.png'),
);
```

## Labels and localization

The package ships English text and no translations. Pass your own strings through `CricketScoreLabels`:

```dart
CricketLiveScoreCarousel(
  source: source,
  labels: CricketScoreLabels(
    live: context.l10n.live,
    notAvailable: context.l10n.notAvailable,
    versus: context.l10n.versus,
    // Languages that put the venue first:
    formatVenue: (venue) => '$venue-এ',
  ),
);
```

`labels` also holds the empty and error messages, the retry and close labels, and the words screen readers use ("India versus England, live").

## Writing your own source

Implement `CricketScoreSource` to show scores from your own backend or an official API:

```dart
class MyApiSource implements CricketScoreSource {
  MyApiSource(this.client);

  final MyApiClient client;

  @override
  Future<List<CricketMatch>> fetchMatches() async {
    try {
      final dtos = await client.liveMatches();
      return sortMatches(dtos.map(toCricketMatch));
    } on Exception catch (e) {
      throw CricketScoreException('Could not load matches', cause: e);
    }
  }
}
```

Throw `CricketScoreException` on failure; the controller turns it into a `CricketScoreFailure` and keeps the last matches. `sortMatches` puts live matches first, then the newest start time.

## Data source

`CricketDataWidgetSource` reads the HTML that [cricketdata.org](https://cricketdata.org)'s free embeddable website widget serves. The data belongs to cricketdata.org, and its default `referrer` (`https://cricketdata.org/widgets-for-your-website-blog/`) is used with their permission. If cricketdata.org gives you a referrer of your own, pass it:

```dart
CricketDataWidgetSource(referrer: 'https://your.site/page-with-the-widget');
```

You remain responsible for using the data within cricketdata.org's terms. For more control over the data, consider their official keyed API with a `CricketScoreSource` of your own.

This package is not affiliated with cricketdata.org.

## Limitations

- `CricketDataWidgetSource` scrapes HTML, not a documented API. When the upstream markup changes, parsing can break or return incomplete matches. `CricketDataHtmlParser` falls back to empty values rather than throwing.
- Whether a match is live is inferred from the score table and the status text, because the upstream LIVE marker is not reliable.
- Start times are parsed only in the widget's `"19 Jul 2026, Sun 10:00 GMT"` format; any other format leaves `startTime` null.

## Example

See [`example/`](example/) for a runnable app with live scores, the carousel in a dialog, the floating button, a custom theme, and a switch to offline sample data.
