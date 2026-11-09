# Feature requests

Write down what you want the package to do next. You don't need to fill in every field, and rough notes are fine.

## How this works

1. **You** fill in the features below and tell Claude the file is ready.
2. **Claude** writes a plan: what each feature changes, the public API it adds, the trade-offs, and any questions. You approve or change it.
3. **Claude** splits the approved plan into small parts. Each part can be tested and committed on its own. You approve the order.
4. **Claude** builds one part at a time, tests it on the tablet, and waits for your approval before starting the next one.

## What the package does today

So you can see what's already there:

- **Data:** `CricketDataWidgetSource` reads the cricketdata.org widget feed. You can write your own source by implementing `CricketScoreSource`.
- **Updates:** `CricketScoreController` polls on a timer. Its states are loading, loaded, empty and failure.
- **Ordering:** `sortMatches` puts live matches first. `pickFeaturedMatch` chooses the match for the floating button.
- **Widgets:**
  - `CricketLiveScoreCarousel`: a swipeable carousel with auto-scroll, a close button, and loading, empty and error cards.
  - `CricketMatchCard`: a single match.
  - `CricketMatchFab`: a floating button with a LIVE chip and swipe-to-hide.
  - `CricketBatsIcon` and the team logos.
- **Customising:**
  - `CricketScoreThemeData` sets colours, sizes and text styles. Sizes scale with the screen, the same way as in the app.
  - `CricketScoreLabels` holds all the text, so it can be translated.
  - You can supply your own logo builder, centre badge, and loading, empty and error builders.
  - `onMatchTap` is called when a match is tapped.

---

## Features

Copy this block once for each feature.

### Feature: _short name_

- **What:** what it should do, in one or two sentences.
- **Why / who uses it:** for example, "another app wants only live matches".
- **How a developer would use it:** a rough code sketch or a description. This part is optional.
- **Priority:** must have / nice to have
- **Done when:** how you'll know it works. For example, "the tablet shows only live matches".
- **Notes / limits:** for example, "no new dependencies" or "must still work like the app".

<!-- Add your features below this line. -->

### Feature: live score screen

- **What:** now we will allow user to navigate to a screen where the score is showing
- **Why / who uses it:** an app who don't want pop up can look for this
- **How a developer would use it:** this might be a bit hard because it need a new route so we will provide the whole body only user can just use it under a scafold also we will provide foldable adaptibility so user can choose from only phone factor or responsive one
- **Priority:** must have
- **Done when:** how you'll know it works. For example, "the tablet shows only live matches".
- **Notes / limits:** also we will add filter for match type like t20 test or odi

### Feature: live score-sheet

same as screen but on a bottom-sheet

### Picked from the suggestions (2026-11-09)

**For the score screen and sheet**
- **Pull to refresh:** drag down to fetch now, as well as the timer polling.
- **Live / Upcoming / Done filter:** a status filter next to the T20 / ODI / Test filter.

**Data**
- ~~**Another data source:**~~ dropped on 2026-11-09. The free option found was CricAPI, limited to 100 calls a day.

**Widgets**
- **Score ticker banner:** a slim strip that scrolls through live scores.
- **Carousel page dots:** dots under the popup carousel showing the current match.

**Polish**
- **Scaling control:** turn screen-based scaling off, or set your own design size or tablet canvas.
- **Dark mode:** the app passes its own dark colours. The package doesn't choose them; it only makes it easy to supply a light and a dark set.


---

## Ideas you can use or ignore

Starting points only. Tick the ones you want, or move them into Features above with more detail.

**Data**
- [ ] Another data source, such as an official JSON API with an API key.
- [ ] Keep the last result and show it straight away on the next launch (offline cache).
- [ ] Filter matches by live only, match type (T20/ODI/Test), team or series.
- [ ] Favourite teams pinned to the top.
- [ ] Your own featured-match rule instead of `pickFeaturedMatch`.

**Widgets**
- [ ] A vertical match list, as an alternative to the carousel.
- [ ] A slim one-line ticker or banner for the top of a screen.
- [ ] Page indicator dots on the carousel.
- [ ] A full scorecard view, or opening the scorecard link (`fullScorecardUrl`).
- [ ] A floating-button layout that shows the score, not just the logos.
- [ ] An animation or highlight when a score changes.
- [ ] Builders to replace parts of the card: header, teams or score rows.

**Other**
- [ ] Show the start time in the user's local time zone and date format.
- [ ] Better dark mode defaults.
- [ ] Turn the screen-based size scaling on or off, or set your own design size.

## Open questions for Claude

Anything you're unsure about, such as "is X possible without a new dependency?".


