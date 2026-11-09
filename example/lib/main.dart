import 'dart:async';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:cricket_live_score_example/fake_source.dart';
import 'package:flutter/material.dart';

// Live data needs the URL of the page the widget is embedded on:
//   flutter run --dart-define=CRICKET_REFERRER=https://your.site/page
// Check cricketdata.org's terms before using their widget feed.
const _referrer = String.fromEnvironment('CRICKET_REFERRER');

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
  bool _live = false;
  late CricketScoreSource _source = FakeSource();
  CricketMatch? _featured;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFeatured());
  }

  Future<void> _loadFeatured() async {
    try {
      final match = pickFeaturedMatch(await _source.fetchMatches());
      if (mounted) setState(() => _featured = match);
    } on CricketScoreException {
      if (mounted) setState(() => _featured = null);
    }
  }

  void _setLive({required bool live}) {
    final old = _source;
    if (old is CricketDataWidgetSource) old.close();
    setState(() {
      _live = live;
      _source =
          live ? CricketDataWidgetSource(referrer: _referrer) : FakeSource();
      _featured = null;
    });
    unawaited(_loadFeatured());
  }

  void _openScores() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: CricketLiveScoreCarousel(
            source: _source,
            autoScroll: true,
            // Phones use the full dialog width; wider windows cap it.
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            onClose: () => Navigator.pop(context),
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
              _referrer.isEmpty
                  ? 'Run with --dart-define=CRICKET_REFERRER=… to enable'
                  : _live
                      ? 'cricketdata.org widget feed'
                      : 'Offline sample data',
            ),
            value: _live,
            onChanged:
                _referrer.isEmpty ? null : (live) => _setLive(live: live),
          ),
          ListTile(
            leading: CricketBatsIcon(
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            title: const Text('Open the score carousel'),
            onTap: _openScores,
          ),
        ],
      ),
      floatingActionButton: featured == null
          ? null
          : CricketMatchFab(match: featured, onTap: _openScores),
    );
  }
}
