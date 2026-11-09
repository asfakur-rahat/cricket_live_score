import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cricket_live_score/cricket_live_score.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _referrer = 'https://cricketdata.org/widgets-for-your-website-blog/';

class _RecordingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() => closed = true;
}

void main() {
  final feed = File(
    'test/fixtures/live_feed_2026-11-09.html',
  ).readAsBytesSync();

  group('requestUri', () {
    test('by default matches the URL the app built before the package', () {
      final source = CricketDataWidgetSource(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(source.referrer, CricketDataWidgetSource.defaultReferrer);
      final now = DateTime.utc(2026, 11, 9, 10);
      final k = now.millisecondsSinceEpoch ~/ 5000;
      expect(
        source.requestUri(now).toString(),
        'https://cricketdata.org/apis/prepscores.aspx?k=$k'
        '&r=https%3A%2F%2Fcricketdata.org%2Fwidgets-for-your-website-blog%2F',
      );
    });

    test('k changes every five seconds', () {
      final source = CricketDataWidgetSource(
        client: MockClient((_) async => http.Response('', 200)),
      );
      final t0 = DateTime.utc(2026, 11, 9, 10);
      String k(DateTime t) => source.requestUri(t).queryParameters['k']!;
      expect(k(t0.add(const Duration(seconds: 4))), k(t0));
      expect(k(t0.add(const Duration(seconds: 5))), isNot(k(t0)));
    });

    test('keeps query parameters already on a custom endpoint', () {
      final source = CricketDataWidgetSource(
        referrer: 'https://example.com/',
        endpoint: Uri.parse('https://proxy.example.com/scores?key=abc'),
        client: MockClient((_) async => http.Response('', 200)),
      );
      final uri = source.requestUri(DateTime.utc(2026));
      expect(uri.host, 'proxy.example.com');
      expect(uri.path, '/scores');
      expect(uri.queryParameters['key'], 'abc');
      expect(uri.queryParameters['r'], 'https://example.com/');
    });
  });

  group('fetchMatches', () {
    test('requests the widget URL and parses the response', () async {
      late Uri requested;
      final logs = <String>[];
      final source = CricketDataWidgetSource(
        onLog: logs.add,
        client: MockClient((request) async {
          requested = request.url;
          return http.Response.bytes(feed, 200);
        }),
      );

      final before = DateTime.now().millisecondsSinceEpoch ~/ 5000;
      final matches = await source.fetchMatches();
      final after = DateTime.now().millisecondsSinceEpoch ~/ 5000;

      expect(matches, hasLength(26));
      // Sorted: the one live match first, then newest start time first.
      expect(matches.first.isLive, isTrue);
      final rest = [for (final m in matches.skip(1)) m.startTime!];
      for (var i = 1; i < rest.length; i++) {
        expect(rest[i].isAfter(rest[i - 1]), isFalse);
      }
      expect(requested.origin, 'https://cricketdata.org');
      expect(requested.path, '/apis/prepscores.aspx');
      expect(requested.queryParameters['r'], _referrer);
      expect(
        int.parse(requested.queryParameters['k']!),
        inInclusiveRange(before, after),
      );
      expect(logs, ['response: 200', 'Parsed 26 of 26 matches']);
    });

    test('decodes the body as UTF-8 without a charset header', () async {
      final source = CricketDataWidgetSource(
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              '<div class="slab" data-id="1"><b>Lord’s</b></div>',
            ),
            200,
            headers: {'content-type': 'text/html'},
          ),
        ),
      );
      final matches = await source.fetchMatches();
      expect(matches.single.venue, 'Lord’s');
    });

    test('returns an empty list when there are no matches', () async {
      final source = CricketDataWidgetSource(
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(await source.fetchMatches(), isEmpty);
    });

    test('a non-200 response throws CricketScoreException', () async {
      final source = CricketDataWidgetSource(
        client: MockClient((_) async => http.Response('busy', 503)),
      );
      await expectLater(
        source.fetchMatches(),
        throwsA(
          isA<CricketScoreException>().having(
            (e) => e.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('a transport error throws CricketScoreException', () async {
      const failure = SocketException('no network');
      final source = CricketDataWidgetSource(
        client: MockClient((_) async => throw failure),
      );
      await expectLater(
        source.fetchMatches(),
        throwsA(
          isA<CricketScoreException>().having((e) => e.cause, 'cause', failure),
        ),
      );
    });

    test('a slow response times out with CricketScoreException', () async {
      final source = CricketDataWidgetSource(
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) => Completer<http.Response>().future),
      );
      await expectLater(
        source.fetchMatches(),
        throwsA(
          isA<CricketScoreException>().having(
            (e) => e.cause,
            'cause',
            isA<TimeoutException>(),
          ),
        ),
      );
    });
  });

  group('close', () {
    test('leaves an injected client open', () {
      final client = _RecordingClient();
      CricketDataWidgetSource(client: client).close();
      expect(client.closed, isFalse);
    });

    test('closes a client it created', () {
      // Nothing to observe from outside; this must simply not throw.
      CricketDataWidgetSource().close();
    });
  });

  test('CricketScoreException.toString includes status and cause', () {
    expect(
      const CricketScoreException('Boom').toString(),
      'CricketScoreException: Boom',
    );
    expect(
      const CricketScoreException(
        'Unexpected response',
        statusCode: 500,
        cause: 'x',
      ).toString(),
      'CricketScoreException: Unexpected response (HTTP 500): x',
    );
  });
}
