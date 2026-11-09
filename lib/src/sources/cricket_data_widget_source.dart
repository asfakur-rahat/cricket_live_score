import 'dart:async';
import 'dart:convert';

import 'package:cricket_live_score/src/models/cricket_match.dart';
import 'package:cricket_live_score/src/parsing/cricket_data_html_parser.dart';
import 'package:cricket_live_score/src/sources/cricket_score_source.dart';
import 'package:http/http.dart' as http;

/// Reads matches from cricketdata.org's embeddable website score widget.
///
/// This scrapes the HTML the widget serves, not a documented API, so it can
/// break when the upstream markup changes. You are responsible for complying
/// with the data provider's terms; for production use consider their official
/// keyed API and a [CricketScoreSource] of your own.
class CricketDataWidgetSource implements CricketScoreSource {
  /// Creates a source that sends [referrer] as the widget's `r` parameter.
  ///
  /// [referrer] is the URL of the page the widget is embedded on; it has no
  /// default on purpose.
  ///
  /// Pass a [client] to control HTTP (for example in tests); otherwise the
  /// source creates one and [close] closes it. [endpoint] overrides the
  /// widget URL. [onLog] receives debug messages. A request that takes
  /// longer than [timeout] fails with a [CricketScoreException].
  CricketDataWidgetSource({
    required this.referrer,
    http.Client? client,
    Uri? endpoint,
    this.onLog,
    this.timeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        endpoint = endpoint ?? defaultEndpoint;

  /// The widget URL used when no `endpoint` is given.
  static final Uri defaultEndpoint = Uri.parse(
    'https://cricketdata.org/apis/prepscores.aspx',
  );

  /// URL of the page the widget is embedded on, sent as the `r` parameter.
  final String referrer;

  /// The widget URL requests are sent to.
  final Uri endpoint;

  /// Receives debug messages, or `null` to stay silent.
  final void Function(String message)? onLog;

  /// How long a single request may take.
  final Duration timeout;

  final http.Client _client;
  final bool _ownsClient;

  /// The URL [fetchMatches] requests at [now].
  ///
  /// `k` changes every five seconds so caches between the app and the widget
  /// server cannot serve a stale score for longer than that.
  Uri requestUri(DateTime now) => endpoint.replace(
        queryParameters: {
          ...endpoint.queryParameters,
          'k': '${now.millisecondsSinceEpoch ~/ 5000}',
          'r': referrer,
        },
      );

  @override
  Future<List<CricketMatch>> fetchMatches() async {
    final http.Response response;
    try {
      response = await _client.get(requestUri(DateTime.now())).timeout(timeout);
    } on TimeoutException catch (e) {
      throw CricketScoreException('Request timed out', cause: e);
    } on Exception catch (e) {
      throw CricketScoreException('Request failed', cause: e);
    }

    onLog?.call('response: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw CricketScoreException(
        'Unexpected response',
        statusCode: response.statusCode,
      );
    }

    try {
      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      return CricketDataHtmlParser.parseMultiple(html, onLog: onLog);
    } on Object catch (e) {
      throw CricketScoreException('Could not parse the response', cause: e);
    }
  }

  /// Closes the HTTP client if this source created it.
  ///
  /// A client passed to the constructor is left open for its owner to close.
  void close() {
    if (_ownsClient) _client.close();
  }
}
