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

final source = CricketDataWidgetSource(
  referrer: 'https://your.site/page-with-the-widget',
);

showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    backgroundColor: Colors.transparent,
    child: CricketLiveScoreCarousel(
      source: source,
      maxHeight: MediaQuery.sizeOf(context).height * 0.45,
      onClose: () => Navigator.pop(context),
    ),
  ),
);
```

The carousel needs a bounded height: pass `maxHeight` or put it where the height is constrained.

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

## Theming

Every field of `CricketScoreThemeData` is optional. Each one is resolved from the widget's `theme` argument, then a `CricketScoreThemeData` in your `ThemeData.extensions`, then defaults derived from your `ColorScheme` and `TextTheme`.

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

`CricketDataWidgetSource` reads the HTML that [cricketdata.org](https://cricketdata.org)'s free embeddable website widget serves. The data belongs to cricketdata.org, and **you are responsible for using it within their terms**. The source has no default `referrer`: you must pass the URL of the page you embed the widget on. For production apps, consider cricketdata.org's official keyed API with a `CricketScoreSource` of your own.

This package is not affiliated with or endorsed by cricketdata.org.

## Limitations

- `CricketDataWidgetSource` scrapes HTML, not a documented API. When the upstream markup changes, parsing can break or return incomplete matches. `CricketDataHtmlParser` falls back to empty values rather than throwing.
- Whether a match is live is inferred from the score table and the status text, because the upstream LIVE marker is not reliable.
- Start times are parsed only in the widget's `"19 Jul 2026, Sun 10:00 GMT"` format; any other format leaves `startTime` null.

## Example

See [`example/`](example/) for a runnable app with the carousel in a dialog, the floating button, a custom theme, and an offline sample-data source.
