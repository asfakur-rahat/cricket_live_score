import 'dart:async';

import 'package:cricket_live_score/src/controller/cricket_score_state.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:flutter/foundation.dart';

/// Polls a [CricketScoreSource] and exposes the result as a
/// [CricketScoreState].
///
/// Call [start] to fetch immediately and then every [pollInterval], [pause]
/// to stop polling (for example while the app is in the background), and
/// [dispose] when done. Listeners are notified only when [state] changes.
class CricketScoreController extends ChangeNotifier {
  /// Creates a controller for [source]. Polling does not begin until [start].
  CricketScoreController({
    required this.source,
    this.pollInterval = const Duration(seconds: 30),
  });

  /// Where matches are fetched from.
  final CricketScoreSource source;

  /// Time between fetches while polling.
  final Duration pollInterval;

  CricketScoreState _state = const CricketScoreLoading();
  Timer? _timer;
  Future<void>? _inFlight;
  bool _disposed = false;

  /// The current state; [CricketScoreLoading] until the first fetch ends.
  CricketScoreState get state => _state;

  /// Whether the controller is polling.
  bool get isPolling => _timer != null;

  /// Fetches now and then every [pollInterval]. Does nothing if already
  /// polling.
  void start() {
    if (_disposed || _timer != null) return;
    _timer = Timer.periodic(pollInterval, (_) => refresh());
    unawaited(refresh());
  }

  /// Stops polling. [state] is kept; call [start] to resume.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  /// Fetches now, whether or not the controller is polling.
  ///
  /// If a fetch is already in flight, returns that fetch instead of starting
  /// another. Never throws: failures become [CricketScoreFailure].
  Future<void> refresh() {
    if (_disposed) return Future.value();
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<void> _fetch() async {
    CricketScoreState next;
    try {
      final matches = await source.fetchMatches();
      next = matches.isEmpty
          ? const CricketScoreEmpty()
          : CricketScoreLoaded(List.unmodifiable(matches));
    } on Object catch (error, stackTrace) {
      next = CricketScoreFailure(
        error,
        stackTrace: stackTrace,
        lastMatches: _state.matches,
      );
    }
    if (_disposed || next == _state) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    pause();
    super.dispose();
  }
}
