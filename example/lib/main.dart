import 'dart:async';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:cricket_live_score_example/fake_source.dart';
import 'package:cricket_live_score_example/filtered_source.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cricket_live_score',
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
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: CricketLiveScoreCarousel(
            source: filter.isAll ? _source : FilteredSource(_source, filter),
            autoScroll: true,
            onClose: () => Navigator.pop(context),
          ),
        ),
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
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Live scores')),
            // The package provides the body; the app owns the route.
            body: CricketLiveScoreView(source: _source),
          ),
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
          SwitchListTile(
            title: const Text('Live data from cricketdata.org'),
            subtitle: Text(
              _live ? 'cricketdata.org widget feed' : 'Offline sample data',
            ),
            value: _live,
            onChanged: (live) => _setLive(live: live),
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
            onTap: () =>
                unawaited(showCricketLiveScoreSheet(context, source: _source)),
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
