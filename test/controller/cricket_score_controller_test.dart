import 'dart:async';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const _team = TeamInfo(name: 'A', logoUrl: '');

CricketMatch _match(String id) => CricketMatch(
      id: id,
      matchType: 'T20',
      venue: 'v',
      status: 's',
      team1: _team,
      team2: _team,
    );

/// A source whose every fetch waits for the test to complete it.
class _ManualSource implements CricketScoreSource {
  final calls = <Completer<List<CricketMatch>>>[];

  @override
  Future<List<CricketMatch>> fetchMatches() {
    final completer = Completer<List<CricketMatch>>();
    calls.add(completer);
    return completer.future;
  }

  void succeed(List<CricketMatch> matches) => calls.last.complete(matches);

  void fail(Object error) => calls.last.completeError(error);
}

void main() {
  late _ManualSource source;
  late CricketScoreController controller;
  late List<CricketScoreState> notified;

  setUp(() {
    source = _ManualSource();
    controller = CricketScoreController(source: source);
    notified = [];
    controller.addListener(() => notified.add(controller.state));
  });

  test('starts in loading and does not fetch before start', () {
    expect(controller.state, const CricketScoreLoading());
    expect(controller.isPolling, isFalse);
    expect(source.calls, isEmpty);
    controller.dispose();
  });

  test('start fetches immediately, then every pollInterval', () {
    fakeAsync((async) {
      controller.start();
      expect(controller.isPolling, isTrue);
      expect(source.calls, hasLength(1));

      source.succeed([_match('1')]);
      async.flushMicrotasks();
      expect(controller.state, CricketScoreLoaded([_match('1')]));

      async.elapse(const Duration(seconds: 29));
      expect(source.calls, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(source.calls, hasLength(2));

      controller.dispose();
    });
  });

  test('start twice does not double the polling', () {
    fakeAsync((async) {
      controller
        ..start()
        ..start();
      expect(source.calls, hasLength(1));
      source.succeed(const []);
      async.elapse(const Duration(seconds: 30));
      expect(source.calls, hasLength(2));
      controller.dispose();
    });
  });

  test('no matches is the empty state, not loading', () {
    fakeAsync((async) {
      controller.start();
      source.succeed(const []);
      async.flushMicrotasks();
      expect(controller.state, const CricketScoreEmpty());
      expect(controller.state.matches, isEmpty);
      controller.dispose();
    });
  });

  test('a failure keeps the last good matches', () {
    fakeAsync((async) {
      controller.start();
      source.succeed([_match('1'), _match('2')]);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 30));
      const error = CricketScoreException('down');
      source.fail(error);
      async.flushMicrotasks();

      final state = controller.state;
      expect(state, isA<CricketScoreFailure>());
      state as CricketScoreFailure;
      expect(state.error, error);
      expect(state.stackTrace, isNotNull);
      expect(state.lastMatches, [_match('1'), _match('2')]);
      expect(state.matches, state.lastMatches);

      // A second failure still keeps them.
      async.elapse(const Duration(seconds: 30));
      source.fail(const CricketScoreException('still down'));
      async.flushMicrotasks();
      expect(controller.state.matches, [_match('1'), _match('2')]);

      // And a success recovers.
      async.elapse(const Duration(seconds: 30));
      source.succeed([_match('3')]);
      async.flushMicrotasks();
      expect(controller.state, CricketScoreLoaded([_match('3')]));

      controller.dispose();
    });
  });

  test('a failure before any success has no last matches', () {
    fakeAsync((async) {
      controller.start();
      source.fail(StateError('not a CricketScoreException'));
      async.flushMicrotasks();
      expect(controller.state, isA<CricketScoreFailure>());
      expect(controller.state.matches, isEmpty);
      controller.dispose();
    });
  });

  test('skips a tick while a fetch is still in flight', () {
    fakeAsync((async) {
      controller.start();
      async.elapse(const Duration(seconds: 90));
      expect(source.calls, hasLength(1));

      source.succeed([_match('1')]);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 30));
      expect(source.calls, hasLength(2));
      controller.dispose();
    });
  });

  test('refresh while in flight returns the same fetch', () {
    fakeAsync((async) {
      final first = controller.refresh();
      final second = controller.refresh();
      expect(identical(first, second), isTrue);
      expect(source.calls, hasLength(1));
      expect(controller.isPolling, isFalse);
      controller.dispose();
    });
  });

  test('notifies only when the state changes', () {
    fakeAsync((async) {
      controller.start();
      source.succeed([_match('1')]);
      async.flushMicrotasks();
      expect(notified, hasLength(1));

      async.elapse(const Duration(seconds: 30));
      source.succeed([_match('1')]);
      async.flushMicrotasks();
      expect(notified, hasLength(1));

      async.elapse(const Duration(seconds: 30));
      source.succeed([_match('2')]);
      async.flushMicrotasks();
      expect(notified, hasLength(2));
      controller.dispose();
    });
  });

  test('pause stops polling and start resumes with a fetch', () {
    fakeAsync((async) {
      controller.start();
      source.succeed([_match('1')]);
      async.flushMicrotasks();

      controller.pause();
      expect(controller.isPolling, isFalse);
      async.elapse(const Duration(minutes: 5));
      expect(source.calls, hasLength(1));
      expect(controller.state.matches, [_match('1')]);

      controller.start();
      expect(source.calls, hasLength(2));
      controller.dispose();
    });
  });

  test('never notifies after dispose', () {
    fakeAsync((async) {
      controller
        ..start()
        ..dispose();
      expect(controller.isPolling, isFalse);

      source.succeed([_match('1')]);
      async.flushMicrotasks();
      expect(notified, isEmpty);

      controller.start();
      unawaited(controller.refresh());
      async.elapse(const Duration(minutes: 1));
      expect(source.calls, hasLength(1));
    });
  });

  group('state', () {
    test('equality, hashCode and toString', () {
      // ignore: prefer_const_constructors, comparing distinct instances
      expect(CricketScoreLoading(), const CricketScoreLoading());
      // ignore: prefer_const_constructors, comparing distinct instances
      expect(CricketScoreEmpty(), const CricketScoreEmpty());
      expect(
        const CricketScoreLoading().hashCode,
        isNot(const CricketScoreEmpty().hashCode),
      );
      expect(const CricketScoreLoading() == const CricketScoreEmpty(), isFalse);
      expect(
        CricketScoreLoaded([_match('1')]).hashCode,
        CricketScoreLoaded([_match('1')]).hashCode,
      );
      expect(
        CricketScoreFailure('e', lastMatches: [_match('1')]),
        CricketScoreFailure('e', lastMatches: [_match('1')]),
      );
      expect(
        CricketScoreFailure('e', lastMatches: [_match('1')]).hashCode,
        CricketScoreFailure('e', lastMatches: [_match('1')]).hashCode,
      );
      expect(const CricketScoreLoading().toString(), 'CricketScoreLoading()');
      expect(const CricketScoreEmpty().toString(), 'CricketScoreEmpty()');
      expect(
        CricketScoreLoaded([_match('1')]).toString(),
        'CricketScoreLoaded(1 matches)',
      );
      expect(
        const CricketScoreFailure('e').toString(),
        'CricketScoreFailure(e, 0 last matches)',
      );
    });
  });
}
