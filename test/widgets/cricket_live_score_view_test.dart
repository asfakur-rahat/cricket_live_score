import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const _upcoming = CricketMatch(
  id: 'next',
  matchType: 'T20',
  venue: 'Eden Gardens',
  status: 'Match starts at 14:00 GMT',
  team1: TeamInfo(name: 'Kolkata', logoUrl: ''),
  team2: TeamInfo(name: 'Mumbai', logoUrl: ''),
);

const _finishedVenue = 'At McLean Park';
const _liveVenue = 'At Bert Sutcliffe Oval';
const _upcomingVenue = 'At Eden Gardens';

List<CricketMatch> _all() => [liveMatch(), finishedMatch(), _upcoming];

/// Pumps [view] as a Scaffold body in a tall phone window, so every card of
/// a short list is built.
Future<void> _pumpView(
  WidgetTester tester,
  Widget view, {
  Size window = const Size(400, 2400),
}) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));
}

// The view's own list; each card also has a list for its score table.
final Finder _list = find.byType(ListView).first;

Finder _chip(String label) => find.widgetWithText(ChoiceChip, label);

/// The "All" chip of the phase row (first) or the type row (last).
Finder _allChip({required bool types}) =>
    types ? _chip('All').last : _chip('All').first;

void _expectVenues(List<String> shown) {
  for (final venue in [_finishedVenue, _liveVenue, _upcomingVenue]) {
    expect(
      find.text(venue),
      shown.contains(venue) ? findsOneWidget : findsNothing,
      reason: venue,
    );
  }
}

/// Scrolls [chip] into view in its row, then taps it.
Future<void> _tapChip(WidgetTester tester, Finder chip) async {
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pump();
}

bool _selected(Finder chip) =>
    (chip.evaluate().single.widget as ChoiceChip).selected;

void main() {
  testWidgets('loading, then every match with both chip rows', (tester) async {
    final source = FakeSource()..pending = true;
    await _pumpView(tester, CricketLiveScoreView(source: source));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Phase chips show at once; type chips need the data.
    expect(_chip('Live'), findsOneWidget);
    expect(_chip('T20'), findsNothing);

    source.complete(_all());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CricketMatchCard), findsNWidgets(3));
    _expectVenues([_finishedVenue, _liveVenue, _upcomingVenue]);
    for (final label in ['Live', 'Upcoming', 'Done', 'T20', 'ODI', 'TEST']) {
      expect(_chip(label), findsOneWidget, reason: label);
    }
    expect(_chip('All'), findsNWidgets(2));
    // Phase chips read All, Live, Upcoming, Done from left to right.
    final xs = [
      for (final label in ['Live', 'Upcoming', 'Done'])
        tester.getCenter(_chip(label)).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
    expect(_selected(_allChip(types: false)), isTrue);
    expect(_selected(_allChip(types: true)), isTrue);
  });

  testWidgets('phase chips filter the list, and All clears it', (tester) async {
    await _pumpView(tester, CricketLiveScoreView(source: FakeSource(_all())));
    await tester.pump();

    await _tapChip(tester, _chip('Live'));
    _expectVenues([_liveVenue]);
    expect(_selected(_chip('Live')), isTrue);
    expect(_selected(_allChip(types: false)), isFalse);

    await _tapChip(tester, _chip('Upcoming'));
    _expectVenues([_upcomingVenue]);

    await _tapChip(tester, _chip('Done'));
    _expectVenues([_finishedVenue]);

    await _tapChip(tester, _allChip(types: false));
    _expectVenues([_finishedVenue, _liveVenue, _upcomingVenue]);
  });

  testWidgets('type chips filter, and combine with the phase', (tester) async {
    await _pumpView(tester, CricketLiveScoreView(source: FakeSource(_all())));
    await tester.pump();

    await _tapChip(tester, _chip('ODI'));
    _expectVenues([_finishedVenue]);

    await _tapChip(tester, _chip('Live'));
    _expectVenues([]);
    expect(find.text('No matches for this filter'), findsOneWidget);

    await _tapChip(tester, _allChip(types: true));
    _expectVenues([_liveVenue]);
  });

  testWidgets('initialFilter applies from the start', (tester) async {
    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: FakeSource(_all()),
        initialFilter: const CricketMatchFilter(types: {'t20'}),
      ),
    );
    await tester.pump();
    _expectVenues([_upcomingVenue]);
    expect(_selected(_chip('T20')), isTrue);
  });

  testWidgets('a selected type missing from the data keeps its chip',
      (tester) async {
    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: FakeSource(_all()),
        initialFilter: const CricketMatchFilter(types: {'T10'}),
      ),
    );
    await tester.pump();
    expect(_selected(_chip('T10')), isTrue);
    expect(find.text('No matches for this filter'), findsOneWidget);
  });

  testWidgets('with filter set, chips only report the change', (tester) async {
    final changes = <CricketMatchFilter>[];
    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: FakeSource(_all()),
        filter: const CricketMatchFilter(phases: {MatchPhase.finished}),
        onFilterChanged: changes.add,
      ),
    );
    await tester.pump();
    _expectVenues([_finishedVenue]);

    await _tapChip(tester, _chip('Live'));
    expect(changes, [
      const CricketMatchFilter(phases: {MatchPhase.live}),
    ]);
    // The app has not rebuilt the view with the new filter yet.
    _expectVenues([_finishedVenue]);
  });

  testWidgets('without filter set, onFilterChanged still reports changes',
      (tester) async {
    final changes = <CricketMatchFilter>[];
    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: FakeSource(_all()),
        onFilterChanged: changes.add,
      ),
    );
    await tester.pump();
    await _tapChip(tester, _chip('TEST'));
    expect(changes, [
      const CricketMatchFilter(types: {'TEST'}),
    ]);
    _expectVenues([_liveVenue]);
  });

  testWidgets('either chip row can be hidden', (tester) async {
    await _pumpView(
      tester,
      CricketLiveScoreView(source: FakeSource(_all()), showPhaseFilter: false),
    );
    await tester.pump();
    expect(_chip('Live'), findsNothing);
    expect(_chip('T20'), findsOneWidget);

    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: FakeSource(_all()),
        showPhaseFilter: false,
        showTypeFilter: false,
      ),
    );
    await tester.pump();
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(CricketMatchCard), findsNWidgets(3));
  });

  testWidgets('pull to refresh fetches again', (tester) async {
    final source = FakeSource(_all());
    await _pumpView(tester, CricketLiveScoreView(source: source));
    await tester.pump();
    expect(source.calls, 1);

    // RefreshIndicator needs a pull of about a quarter of the list height.
    await tester.fling(_list, const Offset(0, 800), 1000);
    await tester.pumpAndSettle();
    expect(source.calls, 2);
  });

  testWidgets('pull to refresh also works on the empty state', (tester) async {
    final source = FakeSource();
    await _pumpView(tester, CricketLiveScoreView(source: source));
    await tester.pump();
    expect(find.text('No matches right now'), findsOneWidget);

    source.matches = _all();
    await tester.fling(
      find.text('No matches right now'),
      const Offset(0, 800),
      1000,
    );
    await tester.pumpAndSettle();
    expect(source.calls, 2);
    expect(find.byType(CricketMatchCard), findsNWidgets(3));
  });

  testWidgets('a first failure shows the error, and retry recovers',
      (tester) async {
    final source = FakeSource(_all())
      ..error = const CricketScoreException('down');
    await _pumpView(tester, CricketLiveScoreView(source: source));
    await tester.pump();
    expect(find.text("Couldn't load scores"), findsOneWidget);

    source.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CricketMatchCard), findsNWidgets(3));
  });

  testWidgets('custom loading, empty and error builders', (tester) async {
    final source = FakeSource()..pending = true;
    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: source,
        loadingBuilder: (_) => const Text('Fetching…'),
        emptyBuilder: (_) => const Text('Nothing on'),
        errorBuilder: (_, error, retry) => Text('Failed: $error'),
      ),
    );
    expect(find.text('Fetching…'), findsOneWidget);
    source.complete(const []);
    await tester.pump();
    expect(find.text('Nothing on'), findsOneWidget);

    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: FakeSource()..error = const CricketScoreException('down'),
        errorBuilder: (_, error, retry) => const Text('Failed'),
      ),
    );
    await tester.pump();
    expect(find.text('Failed'), findsOneWidget);
  });

  testWidgets('onMatchTap receives the tapped match', (tester) async {
    CricketMatch? tapped;
    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: FakeSource(_all()),
        onMatchTap: (match) => tapped = match,
      ),
    );
    await tester.pump();
    await tester.tap(find.text(_upcomingVenue));
    expect(tapped, _upcoming);
  });

  testWidgets('labels are used for chips and messages', (tester) async {
    await _pumpView(
      tester,
      CricketLiveScoreView(
        source: FakeSource(_all()),
        labels: const CricketScoreLabels(
          allMatches: 'Tous',
          phaseLive: 'En direct',
          noFilteredMatches: 'Aucun match',
        ),
      ),
    );
    await tester.pump();
    expect(_chip('Tous'), findsNWidgets(2));
    await _tapChip(tester, _chip('En direct'));
    await _tapChip(tester, _chip('ODI'));
    expect(find.text('Aucun match'), findsOneWidget);
  });

  testWidgets('a phone fills the width; a wide window centres a column',
      (tester) async {
    await _pumpView(
      tester,
      CricketLiveScoreView(source: FakeSource(_all())),
      window: const Size(400, 900),
    );
    await tester.pump();
    expect(tester.getSize(_list).width, 400);

    await _pumpView(
      tester,
      CricketLiveScoreView(source: FakeSource(_all())),
      window: const Size(1280, 800),
    );
    await tester.pump();
    final list = tester.getRect(_list);
    expect(list.width, 560);
    expect(list.center.dx, 640);
  });

  testWidgets('an injected controller is neither started nor disposed',
      (tester) async {
    final source = FakeSource(_all());
    final controller = CricketScoreController(source: source);
    await _pumpView(tester, CricketLiveScoreView(controller: controller));
    expect(source.calls, 0);

    controller.start();
    await tester.pump();
    expect(find.byType(CricketMatchCard), findsNWidgets(3));

    await tester.pumpWidget(const SizedBox());
    await controller.refresh();
    expect(source.calls, 2);
    controller.dispose();
  });
}
