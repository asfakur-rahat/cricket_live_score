import 'dart:async';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:cricket_live_score_example/fake_source.dart';
import 'package:cricket_live_score_example/filtered_source.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// Whether the cricket widgets scale with the screen; the home page's
/// switch flips it.
final _scaling = ValueNotifier<bool>(true);

/// Light, dark or the system's choice; the home page's buttons set it.
final _themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, themeMode, _) => _app(themeMode),
    );
  }

  Widget _app(ThemeMode themeMode) {
    return MaterialApp(
      title: 'cricket_live_score',
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        // A custom theme: every field is optional.
        extensions: const [
          CricketScoreThemeData(
            liveColor: Color(0xFFD32F2F),
            liveChipColor: Color(0xFFD32F2F),
            cardElevation: 2,
          ),
        ],
      ),
      // The app's own dark colours; anything left out comes from the dark
      // colour scheme.
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
        extensions: const [
          CricketScoreThemeData(
            liveColor: Color(0xFFFF6B6B),
            liveChipColor: Color(0xFFE53935),
            liveChipForeground: Color(0xFFFFFFFF),
          ),
        ],
      ),
      // A scope in the builder reaches dialogs and sheets too.
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: _scaling,
        builder: (context, scaling, _) =>
            CricketScoreScaleScope(enabled: scaling, child: child!),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _live = true;
  late CricketScoreSource _source = CricketDataWidgetSource();
  CricketMatch? _featured;
  List<CricketMatch> _matches = const [];
  CricketTickerMode _tickerMode = CricketTickerMode.rotate;
  bool _snap = true;
  bool _closeOnlyByButton = false;
  bool _blur = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFeatured());
  }

  Future<void> _loadFeatured() async {
    try {
      final matches = await _source.fetchMatches();
      if (mounted) {
        setState(() {
          _matches = matches;
          _featured = pickFeaturedMatch(matches);
        });
      }
    } on CricketScoreException {
      if (mounted) {
        setState(() {
          _matches = const [];
          _featured = null;
        });
      }
    }
  }

  void _setLive({required bool live}) {
    final old = _source;
    if (old is CricketDataWidgetSource) old.close();
    setState(() {
      _live = live;
      _source = live ? CricketDataWidgetSource() : FakeSource();
      _featured = null;
      _matches = const [];
    });
    unawaited(_loadFeatured());
  }

  void _openScores({CricketMatchFilter filter = CricketMatchFilter.all}) {
    unawaited(
      showCricketLiveScoreDialog(
        context,
        source: filter.isAll ? _source : FilteredSource(_source, filter),
        autoScroll: true,
        showPageIndicator: true,
        barrierDismissible: !_closeOnlyByButton,
        barrierBlur: _blur ? 28 : 0,
      ),
    );
  }

  String _phaseSummary() {
    String count(MatchPhase phase) => filterMatches(
          _matches,
          CricketMatchFilter(phases: {phase}),
        ).length.toString();
    return '${count(MatchPhase.live)} live · '
        '${count(MatchPhase.upcoming)} upcoming · '
        '${count(MatchPhase.finished)} finished';
  }

  void _openScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Live scores')),
          // The package provides the body; the app owns the route.
          body: CricketLiveScoreView(source: _source),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = _featured;
    return Scaffold(
      appBar: AppBar(title: const Text('cricket_live_score')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CricketScoreTicker(
              source: _source,
              mode: _tickerMode,
              onMatchTap: (_) => _openScores(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<CricketTickerMode>(
              segments: const [
                ButtonSegment(
                  value: CricketTickerMode.rotate,
                  label: Text('Rotate'),
                  icon: Icon(Icons.swap_vert),
                ),
                ButtonSegment(
                  value: CricketTickerMode.crawl,
                  label: Text('News crawl'),
                  icon: Icon(Icons.double_arrow),
                ),
              ],
              selected: {_tickerMode},
              onSelectionChanged: (modes) =>
                  setState(() => _tickerMode = modes.single),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Live now',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Snap')),
                    ButtonSegment(value: false, label: Text('Free')),
                  ],
                  selected: {_snap},
                  onSelectionChanged: (values) =>
                      setState(() => _snap = values.single),
                ),
              ],
            ),
          ),
          // A carousel inside the page; it sizes itself to its cards.
          CricketInlineScoreCarousel(
            source: _source,
            snap: _snap,
            showPageIndicator: true,
            autoScroll: true,
            onMatchTap: (_) => _openScores(),
          ),
          SwitchListTile(
            title: const Text('Live data from cricketdata.org'),
            subtitle: Text(
              _live ? 'cricketdata.org widget feed' : 'Offline sample data',
            ),
            value: _live,
            onChanged: (live) => _setLive(live: live),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: _themeMode,
              builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (modes) => _themeMode.value = modes.single,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _scaling,
            builder: (context, scaling, _) => SwitchListTile(
              title: const Text('Scale with the screen'),
              subtitle: Text(
                scaling
                    ? 'Sizes scale from a 390 × 850 design'
                    : 'Plain design sizes and text theme sizes',
              ),
              value: scaling,
              onChanged: (value) => _scaling.value = value,
            ),
          ),
          ListTile(
            leading: CricketBatsIcon(
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            title: const Text('Open the score carousel'),
            onTap: _openScores,
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Open the live score screen'),
            onTap: _openScreen,
          ),
          ListTile(
            leading: const Icon(Icons.vertical_align_top),
            title: const Text('Open the score sheet'),
            onTap: () => unawaited(
              showCricketLiveScoreSheet(
                context,
                source: _source,
                isDismissible: !_closeOnlyByButton,
                enableDrag: !_closeOnlyByButton,
                barrierBlur: _blur ? 6 : 0,
                barrierColor: _blur ? const Color(0x1A1925A6) : null,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Close only with the close button'),
            subtitle: Text(
              _closeOnlyByButton
                  ? 'A tap outside or a drag down does nothing'
                  : 'A tap outside or a drag down closes the popup and sheet',
            ),
            value: _closeOnlyByButton,
            onChanged: (value) => setState(() => _closeOnlyByButton = value),
          ),
          SwitchListTile(
            title: const Text('Blur the page behind the popup and sheet'),
            subtitle: Text(
              _blur ? 'Blurred as well as dimmed' : 'Dimmed only',
            ),
            value: _blur,
            onChanged: (value) => setState(() => _blur = value),
          ),
          ListTile(
            leading: const Icon(Icons.filter_alt_outlined),
            title: const Text('Open live matches only'),
            onTap: () => _openScores(
              filter: const CricketMatchFilter(phases: {MatchPhase.live}),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text(_phaseSummary()),
            subtitle: Text('Types: ${matchTypesOf(_matches).join(', ')}'),
          ),
        ],
      ),
      floatingActionButton: featured == null
          ? null
          : CricketMatchFab(match: featured, onTap: _openScores),
    );
  }
}
